#!/usr/bin/env bash
# ~/.config/starship.toml (sakura パレット) の見た目を再現した Claude Code の statusLine

input=$(cat)

# macOS 標準の bash 3.2 は \u を解釈せず、ロケールにも左右されるため、
# コードポイントを UTF-8 のバイト列へ自前で変換する (3 バイト領域 U+0800-U+FFFF のみ対応)
glyph() {
  local cp=$((16#$1))
  printf "$(printf '\\%03o\\%03o\\%03o' \
    $((0xE0 | (cp >> 12))) \
    $((0x80 | ((cp >> 6) & 0x3F))) \
    $((0x80 | (cp & 0x3F))))"
}

CAP_L=$(glyph e0b6)
SEP=$(glyph e0b0)
ELLIPSIS=$(glyph 2026)
BRANCH_GLYPH=$(glyph e0a0)
DIR_GLYPH=$(glyph f07b)
case "$(uname -s)" in
  Darwin) OS_GLYPH=$(glyph f179) ;;
  *) OS_GLYPH=$(glyph f17c) ;;
esac

# git_status の記号 (Octicons)。starship.toml の各記号と同じコードポイント
SYM_CONFLICTED=$(glyph f421)
SYM_STASHED=$(glyph f51e)
SYM_DELETED=$(glyph f458)
SYM_RENAMED=$(glyph f45a)
SYM_MODIFIED=$(glyph f459)
SYM_STAGED=$(glyph f457)
SYM_UNTRACKED=$(glyph f420)
SYM_AHEAD=$(glyph f431)
SYM_BEHIND=$(glyph f433)
SYM_DIVERGED=$(glyph f443)

LIMIT_GLYPH=$(glyph f463)
LIMIT_WARN_PERCENTAGE=80

# sakura パレット (R;G;B)
C_TRUNK='122;82;46'
C_GREEN='65;175;26'
C_BRIGHT_PINK='255;101;253'
C_PURPLE='152;146;241'
C_GRAY='153;142;172'
C_RED='213;35;112'
C_WHITE='238;238;238'
C_DARK='36;36;46'
# sakura パレットに青系の色が無いため、OS アイコン用に CSS の skyblue (#87ceeb) を足している
C_SKY='135;206;235'

RESET=$'\033[0m'
fgc() { printf '\033[38;2;%sm' "$1"; }
bgc() { printf '\033[48;2;%sm' "$1"; }

# ${#s} はロケールが UTF-8 でないとバイト数を返すため、UTF-8 の継続バイトを除いて文字数を数える。
# 全角文字も 1 と数えるので、日本語を含むディレクトリ名などでは実際の幅より小さくなる
vis_width() {
  local LC_ALL=C s=$1
  s=${s//[$'\x80'-$'\xbf']/}
  printf '%s' "${#s}"
}

out=""
prev_bg=""
width=0

# $1=背景色 $2=文字色 $3=本文。直前の背景色から新しい背景色へ Powerline 区切りでつなぐ
segment() {
  if [ -n "$prev_bg" ]; then
    out+="$(fgc "$prev_bg")$(bgc "$1")${SEP}"
  else
    out+="$(fgc "$1")${CAP_L}"
  fi
  out+="$(bgc "$1")$(fgc "$2")$3"
  prev_bg=$1
  width=$((width + 1 + $(vis_width "$3")))
}

# 区切りにタブを使うと、read は IFS の空白文字が連続した箇所を 1 つにまとめるため、
# 値が空のフィールドで後続の値が前にずれる。空白でない US (0x1f) で区切る
IFS=$'\x1f' read -r cwd model used five_hour seven_day spend < <(
  printf '%s' "$input" | jq -r '
    def pct: if . == null then "" else round | tostring end;
    [
      .workspace.current_dir // .cwd // "",
      .model.display_name // "",
      (.context_window.used_percentage | pct),
      (.rate_limits.five_hour.used_percentage | pct),
      (.rate_limits.seven_day.used_percentage | pct),
      (.rate_limits.spend_limit.used_percentage | pct)
    ] | join("\u001f")
  ' 2>/dev/null
)
[ -n "$cwd" ] || cwd=$PWD

# directory: ~ 置換のうえ末尾 3 階層に切り詰める (truncation_length = 3, truncate_to_repo = false)
dir=$cwd
case "$dir" in
  "$HOME") dir="~" ;;
  "$HOME"/*) dir="~${dir#"$HOME"}" ;;
esac
IFS=/ read -ra parts <<< "${dir#/}"
n=${#parts[@]}
if [ "$n" -gt 3 ]; then
  dir="${ELLIPSIS}/${parts[n-3]}/${parts[n-2]}/${parts[n-1]}"
fi
short_dir=$dir
[ "$n" -gt 2 ] && short_dir="${ELLIPSIS}/${parts[n-1]}"

# statusLine は頻繁に実行されるため、--no-optional-locks でユーザー自身の git 操作と index のロックを奪い合わない
git_segment_text() {
  local gs head rest branch line x y syms=""
  local ahead="" behind="" conflicted="" stashed="" deleted="" renamed="" modified="" staged="" untracked=""

  gs=$(git --no-optional-locks -C "$cwd" status --porcelain=v1 --branch 2>/dev/null) || return 1
  head=${gs%%$'\n'*}
  rest=${gs#"$head"}

  branch=${head#\#\# }
  branch=${branch#No commits yet on }
  branch=${branch%%...*}
  branch=${branch%% *}
  case "$head" in
    "## HEAD (no branch)"*)
      branch=$(git --no-optional-locks -C "$cwd" rev-parse --short HEAD 2>/dev/null) || return 1
      ;;
  esac

  case "$head" in *"ahead "*) ahead=1 ;; esac
  case "$head" in *"behind "*) behind=1 ;; esac

  while IFS= read -r line; do
    x=${line:0:1}
    y=${line:1:1}
    case "$x$y" in
      '??') untracked=1; continue ;;
      DD|AU|UD|UA|DU|AA|UU) conflicted=1; continue ;;
    esac
    case "$x" in
      M|A|T|C) staged=1 ;;
      R) renamed=1 ;;
      D) deleted=1 ;;
    esac
    case "$y" in
      M|T) modified=1 ;;
      D) deleted=1 ;;
    esac
  done <<< "$rest"

  git --no-optional-locks -C "$cwd" rev-parse --verify --quiet refs/stash >/dev/null 2>&1 && stashed=1

  [ -n "$conflicted" ] && syms+="${SYM_CONFLICTED} "
  [ -n "$stashed" ] && syms+="${SYM_STASHED} "
  [ -n "$deleted" ] && syms+="${SYM_DELETED} "
  [ -n "$renamed" ] && syms+="${SYM_RENAMED} "
  [ -n "$modified" ] && syms+="${SYM_MODIFIED} "
  [ -n "$staged" ] && syms+="${SYM_STAGED} "
  [ -n "$untracked" ] && syms+="${SYM_UNTRACKED} "
  if [ -n "$ahead" ] && [ -n "$behind" ]; then
    syms+="${SYM_DIVERGED} "
  elif [ -n "$ahead" ]; then
    syms+="${SYM_AHEAD} "
  elif [ -n "$behind" ]; then
    syms+="${SYM_BEHIND} "
  fi

  printf ' %s %s %s' "$BRANCH_GLYPH" "$branch" "$syms"
}

git_text=""
[ -d "$cwd" ] && git_text=$(git_segment_text)

limits=""
[ -n "$five_hour" ] && limits="5h ${five_hour}%"
[ -n "$seven_day" ] && limits="${limits:+$limits }7d ${seven_day}%"
[ -n "$spend" ] && limits="${limits:+$limits }spend ${spend}%"

# $1=省略の段階 (0: 省略なし 1: OS アイコン 2: +モデル名 3: +ディレクトリを末尾 1 階層に短縮)
render() {
  out=""
  prev_bg=""
  width=0

  [ "$1" -lt 1 ] && segment "$C_SKY" "$C_DARK" " ${OS_GLYPH} "

  # Claude Code は COLUMNS とは別に左右の余白を取り、その幅は公開されていないため、下の省略でも
  # はみ出すことがある。切れても困らないよう、コンテキストと使用量上限を左寄りに置く
  [ -n "$used" ] && segment "$C_PURPLE" "$C_DARK" " ctx ${used}% "

  if [ -n "$limits" ]; then
    if [ "${five_hour:-0}" -ge "$LIMIT_WARN_PERCENTAGE" ] || [ "${seven_day:-0}" -ge "$LIMIT_WARN_PERCENTAGE" ] \
      || [ "${spend:-0}" -ge "$LIMIT_WARN_PERCENTAGE" ]; then
      segment "$C_RED" "$C_WHITE" " ${LIMIT_GLYPH} ${limits} "
    else
      segment "$C_GRAY" "$C_DARK" " ${LIMIT_GLYPH} ${limits} "
    fi
  fi

  [ -n "$model" ] && [ "$1" -lt 2 ] && segment "$C_BRIGHT_PINK" "$C_DARK" " ${model} "

  [ -n "$git_text" ] && segment "$C_GREEN" "$C_DARK" "$git_text"

  if [ "$1" -lt 3 ]; then
    segment "$C_TRUNK" "$C_WHITE" " ${DIR_GLYPH} ${dir} "
  else
    segment "$C_TRUNK" "$C_WHITE" " ${DIR_GLYPH} ${short_dir} "
  fi

  out+="${RESET}$(fgc "$prev_bg")${SEP}${RESET}"
  width=$((width + 1))
}

# Claude Code は端末の幅を COLUMNS で渡す。渡されないときは省略しない
level=0
render "$level"
while [ -n "$COLUMNS" ] && [ "$width" -gt "$COLUMNS" ] && [ "$level" -lt 3 ]; do
  level=$((level + 1))
  render "$level"
done
printf '%s\n' "$out"
