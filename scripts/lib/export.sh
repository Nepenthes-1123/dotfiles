# shellcheck shell=bash
# dotfiles の写しを別のリポジトリに作る (dot.sh export)
#   コミット済みの内容 (HEAD) を、export.conf の規則で置き換え・除外して写し先にコミットする。
#   push はしない。
#
# export.conf (リポジトリの外に置く。書式は `種類 | 値 | 値`、# 以降はコメント)
#   replace | <置き換える文字列> | <置き換え後の文字列>
#   exclude | <写さないパス (リポジトリからの相対パス)>
#   deny    | <写しに残っていたら止める語>
#   allow   | <deny に当たっても許す文字列>
#
# 次の語は export.conf に書かなくても deny として扱う:
#   このユーザーの名前 (id -un)・ホームディレクトリ・dotfiles の git の user.name / user.email・
#   dotfiles の origin の所有者

EXPORT_CONF="${CONFIG_DIR}/dotfiles/export.conf"

EXPORT_FROM=()
EXPORT_TO=()
EXPORT_EXCLUDE=()
EXPORT_DENY=()
EXPORT_ALLOW=()

load_export_conf() {
  local line kind rest a b
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    [[ -n "$(trim "$line")" ]] || continue
    [[ "$line" == *'|'* ]] || die "export.conf の形式が不正です (区切りは |): $line"
    kind="$(trim "${line%%|*}")"
    rest="${line#*|}"
    a="$(trim "${rest%%|*}")"
    b=""
    [[ "$rest" != *'|'* ]] || b="$(trim "${rest#*|}")"
    [[ -n "$a" ]] || die "export.conf の値が空です: $line"
    case "$kind" in
    replace)
      [[ "$rest" == *'|'* ]] || die "replace には置き換え後の文字列が必要です: $line"
      EXPORT_FROM+=("$a")
      EXPORT_TO+=("$b")
      ;;
    exclude)
      [[ "$a" != /* && "$a" != *..* ]] || die "exclude にはリポジトリ内の相対パスを書きます: $line"
      EXPORT_EXCLUDE+=("$a")
      ;;
    deny) EXPORT_DENY+=("$a") ;;
    allow) EXPORT_ALLOW+=("$a") ;;
    *) die "export.conf の種類は replace・exclude・deny・allow のどれかです: $line" ;;
    esac
  done <"$EXPORT_CONF"
}

# 写しに残っていてはいけない語のうち、この環境から分かるもの
add_implicit_deny() {
  local v url
  for v in "$(id -un)" "$HOME" \
    "$(git -C "$DOT_DIR" config user.name || true)" \
    "$(git -C "$DOT_DIR" config user.email || true)"; do
    [[ -z "$v" ]] || EXPORT_DENY+=("$v")
  done
  # git@host:owner/repo.git・host-alias:owner/repo.git・https://host/owner/repo.git のどれでも owner を取り出す
  url="$(git -C "$DOT_DIR" remote get-url origin 2>/dev/null || true)"
  url="${url%/*}"
  [[ -z "$url" ]] || EXPORT_DENY+=("${url##*[:/]}")
}

join_lines() {
  local IFS=$'\n'
  printf '%s' "$*"
}

# $1 のツリーで replace を適用し、deny に当たる箇所を表示する。1 つでも当たれば 1 を返す。
# 置き換え・検査はファイルの中身とパスの両方が対象。NUL を含むファイル (画像など) は中身を扱わない
rewrite_and_check() (
  export EXPORT_FROM_LIST EXPORT_TO_LIST EXPORT_DENY_LIST EXPORT_ALLOW_LIST
  EXPORT_FROM_LIST="$(join_lines ${EXPORT_FROM[@]+"${EXPORT_FROM[@]}"})"
  EXPORT_TO_LIST="$(join_lines ${EXPORT_TO[@]+"${EXPORT_TO[@]}"})"
  EXPORT_DENY_LIST="$(join_lines ${EXPORT_DENY[@]+"${EXPORT_DENY[@]}"})"
  EXPORT_ALLOW_LIST="$(join_lines ${EXPORT_ALLOW[@]+"${EXPORT_ALLOW[@]}"})"
  perl - "$1" <<'PERL'
use strict;
use warnings;
use File::Find;

my $root = shift;
my @from = split /\n/, $ENV{EXPORT_FROM_LIST}, -1;
my @to = split /\n/, $ENV{EXPORT_TO_LIST}, -1;
my %seen;
my @deny = grep { length && !$seen{lc $_}++ } split /\n/, $ENV{EXPORT_DENY_LIST};
my @allow = grep { length } split /\n/, $ENV{EXPORT_ALLOW_LIST};
my $found = 0;

sub check {
  my ($text, $where) = @_;
  $text =~ s/\Q$_\E//g for @allow;
  for my $d (@deny) {
    if (index(lc $text, lc $d) >= 0) {
      print "    $where: $d\n";
      $found = 1;
    }
  }
}

find({ no_chdir => 1, wanted => sub {
  my $path = $File::Find::name;
  return if $path eq $root;
  my $rel = substr($path, length($root) + 1);
  check($rel, "$rel (パス)");
  return if -l $path || !-f $path;
  open my $in, '<:raw', $path or die "$path: $!";
  my $s = do { local $/; <$in> };
  close $in;
  return if $s =~ /\0/;
  my $orig = $s;
  $s =~ s/\Q$from[$_]\E/$to[$_] \/\/ ''/ge for 0 .. $#from;
  if ($s ne $orig) {
    open my $out, '>:raw', $path or die "$path: $!";
    print $out $s;
    close $out;
  }
  my $n = 0;
  check($_, "$rel:" . ++$n) for split /\n/, $s, -1;
} }, $root);

exit $found;
PERL
)

export_run() {
  [[ $# -eq 1 ]] || die "使い方: dot.sh export <写し先のリポジトリ>"
  local dst own_name own_email dst_name dst_email tmp p
  dst="$(cd "$1" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)" ||
    die "写し先が git のリポジトリではありません: $1"
  [[ ! "$dst" -ef "$DOT_DIR" ]] || die "写し先に dotfiles 自身は指定できません"
  [[ -f "$EXPORT_CONF" ]] || die "設定がありません: ${EXPORT_CONF}"
  [[ "$(cd "$(dirname "$EXPORT_CONF")" && pwd -P)/" != "$(cd "$DOT_DIR" && pwd -P)/"* ]] ||
    die "export.conf は dotfiles の外に置きます: ${EXPORT_CONF}"
  [[ -z "$(git -C "$dst" status --porcelain)" ]] || die "写し先に未コミットの変更があります: ${dst}"

  # 写し先のコミットの作者が dotfiles と同じだと、作者として dotfiles の名前が写し先に残る
  own_name="$(git -C "$DOT_DIR" config user.name || true)"
  own_email="$(git -C "$DOT_DIR" config user.email || true)"
  dst_name="$(git -C "$dst" config user.name || true)"
  dst_email="$(git -C "$dst" config user.email || true)"
  [[ -n "$dst_name" && -n "$dst_email" ]] ||
    die "写し先の user.name / user.email が未設定です (git -C ${dst} config user.email ...)"
  [[ "$dst_name" != "$own_name" && "$dst_email" != "$own_email" ]] ||
    die "写し先の user.name / user.email が dotfiles と同じです。写し先のリポジトリで別の値を設定してください"

  [[ -z "$(git -C "$DOT_DIR" status --porcelain)" ]] ||
    warn "dotfiles に未コミットの変更があります。写すのはコミット済みの内容 (HEAD) だけです"

  load_export_conf
  add_implicit_deny

  tmp="$(mktemp -d)"
  # shellcheck disable=SC2064 # tmp はここで確定させる
  trap "rm -rf '$tmp'" EXIT
  git -C "$DOT_DIR" archive HEAD | tar -x -C "$tmp"
  for p in ${EXPORT_EXCLUDE[@]+"${EXPORT_EXCLUDE[@]}"}; do
    rm -rf "${tmp:?}/${p}"
  done

  log "置き換えと検査"
  rewrite_and_check "$tmp" || die "写しに残してはいけない語が見つかりました。export.conf の replace・exclude・allow を見直してください"
  info "ok"

  log "写し先に反映: ${dst}"
  git -C "$dst" rm -rq --ignore-unmatch .
  cp -R "${tmp}/." "${dst}/"
  git -C "$dst" add -A
  if git -C "$dst" diff --cached --quiet; then
    info "変更はありません"
    return 0
  fi
  git -C "$dst" commit -q -m "dotfiles を同期する"
  git -C "$dst" log -1 --shortstat --format='    %h %s'
  info "push は写し先で行ってください: git -C ${dst} push"
}
