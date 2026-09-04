#!/usr/bin/env bash

function fetch_assets() {
    local dot_dir assets_dir repo_url

    dot_dir="$(cd "$(dirname "${BASH_SOURCE:-$0}")"/.. && pwd)"
    assets_dir="${dot_dir}/wezterm/.wezterm/assets"
    repo_url="git@github.com:Nepenthes-1123/dotfiles-assets.git"

    # 素材は配布元のガイドラインが再配布を想定していないため、公開リポジトリである
    # dotfiles 本体には含めず非公開リポジトリで管理している。
    # 取得できない環境では背景アニメーションが省略されるだけで、他の設定には影響しない。
    echo "--- Fetching assets ---"

    if [[ -d "${assets_dir}/.git" ]]; then
        git -C "${assets_dir}" pull --ff-only || echo "Failed to update assets. skip."
        return 0
    fi

    if ! git clone "$repo_url" "${assets_dir}"; then
        echo "Assets not available. Background animation will be skipped."
    fi

    return 0
}

# source実行か直接実行かの判定処理
_is_sourced=0
_SCRIPT_NAME="fetch_assets.sh"

if [ -n "$BASH_VERSION" ]; then
    # Bash環境の場合の判定
    [ "${BASH_SOURCE[0]}" != "$0" ] && _is_sourced=1
elif [ -n "$ZSH_VERSION" ]; then
    # Zsh環境の場合の判定
    case $ZSH_EVAL_CONTEXT in
        *:file) _is_sourced=1 ;;
    esac
else
    # その他のPOSIX互換シェル (dash, ash, sh など) の場合
    # 実行時の $0 のファイル名が、定義したスクリプト名と一致するかで判定
    _basename_0=$(basename -- "$0" 2>/dev/null || echo "$0")
    if [ "$_basename_0" != "$_SCRIPT_NAME" ]; then
        _is_sourced=1
    fi
fi

if [ "$_is_sourced" -eq 0 ]; then
    set -euC
    set -o pipefail
    fetch_assets
fi

# 判定に使用した内部変数をクリーンアップ (source先の環境を汚さないため)
unset _SCRIPT_NAME _is_sourced _basename_0
