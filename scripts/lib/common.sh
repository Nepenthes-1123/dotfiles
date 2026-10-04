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

# 実行環境
#   mac     : macOS
#   ubuntu  : Ubuntu などの Debian 系 Linux
#   wsl     : WSL の中の Ubuntu。Windows のシェルと CLI ツールを担当する
#   windows : Windows 側 (Git Bash)。Windows の GUI アプリを担当する
detect_os() {
  case "$(uname -s)" in
  Darwin) echo mac ;;
  Linux)
    if [[ ! -r /etc/os-release ]] || ! grep -qE '^(ID|ID_LIKE)=.*(ubuntu|debian)' /etc/os-release; then
      echo unsupported
    elif grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
      echo wsl
    else
      echo ubuntu
    fi
    ;;
  MINGW* | MSYS* | CYGWIN*) echo windows ;;
  *) echo unsupported ;;
  esac
}

OS="$(detect_os)"

# この環境が担当する範囲
#   gui: GUI アプリとその設定 (WezTerm / VSCode / フォント)
#   cli: シェルと CLI ツール (zsh / mise / Neovim / git の設定など)
# mac と ubuntu は両方、windows は gui だけ、wsl は cli だけを担当する
want_gui() { [[ "$OS" != wsl ]]; }
want_cli() { [[ "$OS" != windows ]]; }

# links.conf で使える配置先の変数。OS ごとの違いはここだけで吸収する
CONFIG_DIR="${HOME}/.config"
NVIM_DIR="${CONFIG_DIR}/nvim"
LAZYGIT_DIR="${CONFIG_DIR}/lazygit"
case "$OS" in
mac)
  VSCODE_USER_DIR="${HOME}/Library/Application Support/Code/User"
  LAZYGIT_DIR="${HOME}/Library/Application Support/lazygit"
  ;;
windows)
  VSCODE_USER_DIR="$(cygpath -u "${APPDATA}")/Code/User"
  NVIM_DIR="$(cygpath -u "${LOCALAPPDATA}")/nvim"
  # Git Bash の ln -s は既定だと失敗時にコピーで済ませてしまうため、
  # 本物のシンボリックリンクだけを作り、作れなければエラーにする
  export MSYS=winsymlinks:nativestrict
  ;;
*)
  VSCODE_USER_DIR="${CONFIG_DIR}/Code/User"
  ;;
esac

# links.conf で置換する変数名。adopt で逆変換するときは先頭から順に照合するため、深いパスを先に並べる
PATH_VARS=(VSCODE_USER_DIR NVIM_DIR LAZYGIT_DIR CONFIG_DIR HOME)

require_supported_os() {
  [[ "$OS" != unsupported ]] || die "未対応の OS です: $(uname -a)"
}
