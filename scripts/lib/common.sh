# shellcheck shell=bash
# 共通処理: ログ出力・OS 判定・OS ごとの配置先パス
# macOS 標準の bash 3.2 でも動くように、連想配列や mapfile は使わない

DOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPTS_DIR="${DOT_DIR}/scripts"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die() {
  printf '\033[1;31merror:\033[0m %s\n' "$*" >&2
  exit 1
}
has() { command -v "$1" >/dev/null 2>&1; }

# mac / ubuntu (Debian 系。WSL の中も含む) / windows (Git Bash) / unsupported
detect_os() {
  case "$(uname -s)" in
  Darwin) echo mac ;;
  Linux)
    if [[ -r /etc/os-release ]] && grep -qE '^(ID|ID_LIKE)=.*(ubuntu|debian)' /etc/os-release; then
      echo ubuntu
    else
      echo unsupported
    fi
    ;;
  MINGW* | MSYS* | CYGWIN*) echo windows ;;
  *) echo unsupported ;;
  esac
}

OS="$(detect_os)"

# WSL の中の Ubuntu かどうか
IS_WSL=0
if [[ "$OS" == ubuntu ]] && grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
  IS_WSL=1
fi

# この環境が担当する範囲
#   gui: GUI アプリとその設定 (WezTerm / VSCode / フォント)
#   cli: シェルと CLI ツール (zsh / mise / Neovim / git の設定など)
# Windows では GUI アプリだけを Windows 側に入れ、シェルと CLI ツールは WSL の中で使う。
# そのため Windows 側 (Git Bash) は gui だけ、WSL の中は cli だけを扱う。mac と Ubuntu は両方を扱う
want_gui() { [[ "$IS_WSL" -eq 0 ]]; }
want_cli() { [[ "$OS" != windows ]]; }

# links.conf で使える配置先の変数。OS ごとの違いはここだけで吸収する
CONFIG_DIR="${HOME}/.config"
VSCODE_USER_DIR="${CONFIG_DIR}/Code/User"
NVIM_DIR="${CONFIG_DIR}/nvim"
HERDR_DIR="${CONFIG_DIR}/herdr"
case "$OS" in
mac)
  VSCODE_USER_DIR="${HOME}/Library/Application Support/Code/User"
  ;;
windows)
  VSCODE_USER_DIR="$(cygpath -u "${APPDATA}")/Code/User"
  # Git Bash の ln -s は既定だと失敗時にコピーで済ませてしまうため、
  # 本物のシンボリックリンクだけを作り、作れなければエラーにする
  export MSYS=winsymlinks:nativestrict
  ;;
esac

# links.conf で置換する変数名。adopt で逆変換するときは先頭から順に照合するため、深いパスを先に並べる
PATH_VARS=(VSCODE_USER_DIR NVIM_DIR HERDR_DIR CONFIG_DIR HOME)

require_supported_os() {
  [[ "$OS" != unsupported ]] || die "未対応の OS です: $(uname -a)"
}
