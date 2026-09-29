# shellcheck shell=bash
# シンボリックリンクの管理 (scripts/links.conf)
#   links_apply  : リンクを作成する。既存の実ファイルは .bak.<日時> に退避する
#   links_status : 各リンクの状態を表示する。すべて正常でなければ 1 を返す
#   links_prune  : dotfiles を指しているが links.conf に無いリンク・壊れたリンクを削除する
#   links_adopt  : 既存の設定ファイルを dotfiles に取り込み、リンクに置き換える

LINKS_CONF="${SCRIPTS_DIR}/links.conf"

# ${VAR} 形式の変数を PATH_VARS の値に置換する
expand_path_vars() {
  local s="$1" v
  for v in "${PATH_VARS[@]}"; do
    s="${s//\$\{$v\}/${!v}}"
  done
  # shellcheck disable=SC2016 # ${ という文字列そのものを探している
  [[ "$s" != *'${'* ]] || die "links.conf に未定義の変数があります: $1"
  printf '%s' "$s"
}

# 絶対パスを ${VAR} 形式に戻す (adopt で links.conf に書き込むため)
collapse_path_vars() {
  local s="$1" v
  for v in "${PATH_VARS[@]}"; do
    if [[ "$s" == "${!v}/"* ]]; then
      # shellcheck disable=SC2016 # ${VAR} という文字列そのものを出力する
      printf '${%s}%s' "$v" "${s#"${!v}"}"
      return
    fi
  done
  printf '%s' "$s"
}

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

# links.conf を読み込み LINK_SRC (絶対パス) と LINK_DST (絶対パス) に格納する
load_links() {
  LINK_SRC=()
  LINK_DST=()
  local line src dst
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    [[ -n "$(trim "$line")" ]] || continue
    [[ "$line" == *'|'* ]] || die "links.conf の形式が不正です (区切りは |): $line"
    src="$(trim "${line%%|*}")"
    dst="$(trim "${line#*|}")"
    LINK_SRC+=("${DOT_DIR}/${src}")
    LINK_DST+=("$(expand_path_vars "$dst")")
  done <"$LINKS_CONF"
}

is_linked() { [[ -L "$2" && "$2" -ef "$1" ]]; }

links_apply() {
  load_links
  local i src dst backup
  for i in "${!LINK_SRC[@]}"; do
    src="${LINK_SRC[$i]}"
    dst="${LINK_DST[$i]}"
    if [[ ! -e "$src" ]]; then
      warn "リンク元がありません: ${src}"
      continue
    fi
    if is_linked "$src" "$dst"; then
      info "ok       ${dst}"
      continue
    fi
    if [[ -L "$dst" ]]; then
      # 別の場所を指すリンクや壊れたリンクは退避せずに張り替える
      rm -f "$dst"
    elif [[ -e "$dst" ]]; then
      backup="${dst}.bak.$(date +%Y%m%d%H%M%S)"
      mv "$dst" "$backup"
      info "backup   ${dst} -> ${backup}"
    fi
    mkdir -p "$(dirname "$dst")"
    if ! ln -s "$src" "$dst"; then
      [[ "$OS" != windows ]] || warn "Windows では開発者モードを有効にしないとシンボリックリンクを作成できません"
      die "リンクを作成できませんでした: ${dst}"
    fi
    info "linked   ${dst}"
  done
}

links_status() {
  load_links
  local i src dst ng=0
  for i in "${!LINK_SRC[@]}"; do
    src="${LINK_SRC[$i]}"
    dst="${LINK_DST[$i]}"
    if [[ ! -e "$src" ]]; then
      info "NO-SRC   ${dst} (リンク元 ${src} がありません)"
      ng=1
    elif is_linked "$src" "$dst"; then
      info "ok       ${dst}"
    elif [[ -L "$dst" ]]; then
      info "WRONG    ${dst} -> $(readlink "$dst")"
      ng=1
    elif [[ -e "$dst" ]]; then
      info "NOT-LINK ${dst} (実ファイルがあります。アプリが上書きした可能性があります)"
      ng=1
    else
      info "MISSING  ${dst}"
      ng=1
    fi
  done
  return "$ng"
}

is_managed_dst() {
  local d
  for d in "${LINK_DST[@]}"; do
    [[ "$d" != "$1" ]] || return 0
  done
  return 1
}

links_prune() {
  load_links
  # links.conf の配置先の親ディレクトリだけを走査する
  local dirs=() d i found l target
  for i in "${!LINK_DST[@]}"; do
    d="$(dirname "${LINK_DST[$i]}")"
    found=0
    for l in ${dirs[@]+"${dirs[@]}"}; do
      [[ "$l" != "$d" ]] || found=1
    done
    [[ "$found" -eq 1 ]] || dirs+=("$d")
  done

  for d in "${dirs[@]}"; do
    [[ -d "$d" ]] || continue
    while IFS= read -r l; do
      target="$(readlink "$l")"
      [[ "$target" == "${DOT_DIR}/"* ]] || continue
      if [[ ! -e "$l" ]] || ! is_managed_dst "$l"; then
        rm -f "$l"
        info "removed  ${l} -> ${target}"
      fi
    done < <(find "$d" -mindepth 1 -maxdepth 1 -type l)
  done
}

links_adopt() {
  [[ $# -eq 2 ]] || die "使い方: dot.sh adopt <取り込む設定ファイル> <dotfiles 内の保存先>"
  local dst src_rel src
  dst="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
  src_rel="${2#./}"
  src="${DOT_DIR}/${src_rel}"
  [[ -e "$dst" && ! -L "$dst" ]] || die "取り込めるのはリンクではない既存のファイル・ディレクトリだけです: ${dst}"
  [[ ! -e "$src" ]] || die "dotfiles 側に既に存在します: ${src}"

  mkdir -p "$(dirname "$src")"
  mv "$dst" "$src"
  ln -s "$src" "$dst"
  printf '%s | %s\n' "$src_rel" "$(collapse_path_vars "$dst")" >>"$LINKS_CONF"
  info "adopted  ${dst} -> ${src}"
  warn ".gitignore はホワイトリスト方式のため、${src_rel} を追跡するには .gitignore に追記してください"
}
