#!/usr/bin/env bash
# 新しい PC (macOS / Ubuntu / WSL の中) で dotfiles を取得し、scripts/dot.sh setup を実行する入口
#
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/Nepenthes-1123/dotfiles/main/bootstrap.sh)"
#
# setup はパスワードや選択肢を対話で聞くため、`curl ... | bash` ではなく上の形で実行する
# (パイプで渡すと標準入力がスクリプト本体になり、入力を受け付けられない)。
# Windows 側では bootstrap.ps1 を使う。
#
# 環境変数
#   DOTFILES_DIR    clone 先 (既定: ~/dotfiles)
#   DOTFILES_BRANCH clone するブランチ (既定: main)
#   DOTFILES_REPO   clone 元 (既定: GitHub の HTTPS。新しい PC では SSH 鍵が未設定のことが多いため)
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-${HOME}/dotfiles}"
DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/Nepenthes-1123/dotfiles.git}"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() {
  printf '\033[1;31merror:\033[0m %s\n' "$*" >&2
  exit 1
}

# clone に使う git を用意する
ensure_git() {
  case "$(uname -s)" in
  Darwin)
    # /usr/bin/git は Xcode Command Line Tools が無いとインストールのダイアログを出すだけなので、
    # git の有無ではなく Command Line Tools の有無で判定する。
    # Homebrew のインストーラーが Command Line Tools も入れるため、dot.sh setup より先に Homebrew を入れる
    if ! xcode-select -p >/dev/null 2>&1; then
      log "Homebrew と Xcode Command Line Tools (git) をインストール"
      # NONINTERACTIVE では sudo のパスワードを聞けずに失敗するため、先に認証しておく
      sudo -v
      NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    ;;
  Linux)
    if ! command -v git >/dev/null 2>&1; then
      log "git をインストール"
      sudo apt-get update
      sudo apt-get install -y git
    fi
    ;;
  *)
    die "Windows 側では bootstrap.ps1 を使ってください"
    ;;
  esac
}

main() {
  ensure_git

  if [[ -d "${DOTFILES_DIR}/.git" ]]; then
    log "既存の dotfiles を更新: ${DOTFILES_DIR}"
    git -C "$DOTFILES_DIR" pull --ff-only || die "更新に失敗しました。${DOTFILES_DIR} の変更を確認してください"
  elif [[ -e "$DOTFILES_DIR" ]]; then
    die "${DOTFILES_DIR} が既にあり、git のリポジトリではありません。DOTFILES_DIR で別の場所を指定してください"
  else
    log "dotfiles を clone: ${DOTFILES_REPO} (${DOTFILES_BRANCH}) -> ${DOTFILES_DIR}"
    git clone --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi

  exec "${DOTFILES_DIR}/scripts/dot.sh" setup
}

main "$@"
