#!/usr/bin/env bash
# dotfiles の管理コマンド。使い方は `scripts/dot.sh help` を参照
# shellcheck source-path=SCRIPTDIR
set -euo pipefail

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"
# shellcheck source=lib/common.sh
source "${LIB_DIR}/common.sh"
# shellcheck source=lib/links.sh
source "${LIB_DIR}/links.sh"
# shellcheck source=lib/packages.sh
source "${LIB_DIR}/packages.sh"
# shellcheck source=lib/tools.sh
source "${LIB_DIR}/tools.sh"

usage() {
  cat <<'EOF'
使い方: scripts/dot.sh <command>

  setup      新しい環境を構築する (packages → assets → link → mise → zsh-plugins → gitconfig)
  update     インストール済みのものを更新する
  link       scripts/links.conf のリンクを作成する (既存の実ファイルは .bak.<日時> に退避)
  status     各リンクの状態を表示する (すべて正常なら終了コード 0)
  prune [-n|--dry-run]
             dotfiles を指す壊れたリンク・links.conf に無いリンクを削除する (-n は削除せず対象を表示)
  adopt <設定ファイル> <dotfiles 内の保存先>
             既存の設定ファイルを dotfiles に移してリンクに置き換え、links.conf に追記する
  vscode-extensions
             vscode/extensions.txt の拡張をインストールする
  assets     非公開素材 (wezterm の背景アニメーション) を取得・更新する
  help       このヘルプを表示する
EOF
}

cmd_setup() {
  require_supported_os
  log "OS のパッケージをインストール (${OS})"
  packages_install
  log "非公開素材を取得"
  assets_fetch
  log "シンボリックリンクを作成"
  links_apply
  # mise の設定 (~/.config/mise) はリンク後でないと読めないため link の後に実行する
  log "mise でツールをインストール"
  mise_install
  log "zsh プラグインを取得"
  zsh_plugins_sync
  log "git のユーザー設定"
  gitconfig_local_setup
  log "完了しました。新しいシェルを開いてください"
}

cmd_update() {
  require_supported_os
  log "OS のパッケージを更新 (${OS})"
  packages_upgrade
  log "mise のツールを更新"
  mise_upgrade
  log "zsh プラグインを zsh_plugins.conf のタグに合わせる"
  zsh_plugins_sync
  log "Neovim プラグインを更新"
  nvim_plugins_update
  log "VSCode 拡張を更新"
  vscode_extensions_install
  log "非公開素材を更新"
  assets_fetch
  log "リンクの状態"
  links_status || warn "正常でないリンクがあります。'scripts/dot.sh link' で修復できます"
}

main() {
  local cmd="${1:-help}"
  [[ $# -eq 0 ]] || shift
  case "$cmd" in
  setup) cmd_setup ;;
  update) cmd_update ;;
  link) links_apply ;;
  status) links_status ;;
  prune) links_prune "$@" ;;
  adopt) links_adopt "$@" ;;
  vscode-extensions) vscode_extensions_install ;;
  assets) assets_fetch ;;
  help | -h | --help) usage ;;
  *)
    usage >&2
    exit 1
    ;;
  esac
}

main "$@"
