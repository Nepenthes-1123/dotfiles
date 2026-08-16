#!/usr/bin/env bash

function prompt_read() {
    local varname="$1"
    local prompt="$2"

    if [[ -n "${ZSH_VERSION-}" ]]; then
        read -r "_${varname}?${prompt} "
    else
        read -rp "${prompt} " "$varname"
    fi
}

function safe_ln() {
    local src="$1"
    local dst="$2"

    if [[ ! -e "$src" ]]; then
        echo "Source file not found: ${src}"
        return 0
    fi

    if [[ -L "$dst" ]]; then
        if [[ "$(readlink "$dst")" == "$src" ]]; then
            echo "Already linked: ${dst}"
            return 0
        fi
    fi

    if [[ -e "$dst" || -L "$dst" ]]; then
        echo "Target file already exists: ${dst}"
        prompt_read _replace_link "Do you want to replace the file? [Yes / No]:"
        case "$_replace_link" in
            [Yy] | [Yy][Ee][Ss] )
                if [[ -d "$dst" && ! -L "$dst" ]]; then
                    rm -rf "$dst"
                else
                    rm -f "$dst"
                fi
                ;;
            [Nn] | [Nn][Oo] )
                prompt_read _backup_link "Do you want to make backup file? [Yes / No]:"
                case "$_backup_link" in
                    [Yy] | [Yy][Ee][Ss] )
                        mv "$dst" "${dst}.bak"
                        ;;
                    [Nn] | [Nn][Oo] )
                        echo "skip ${dst}"
                        return 0
                        ;;
                    * )
                        echo "skip ${dst}"
                        return 0
                        ;;
                esac
                ;;
            * )
                echo "skip ${dst}"
                return 0
                ;;
        esac
    fi

    if [[ ! -e "$(dirname "$dst")" ]]; then
        mkdir -p "$(dirname "$dst")"
    fi

    ln -s "$src" "$dst"

    return 0
}

function symlink() {
    script_dir="$(dirname "${BASH_SOURCE:-$0}")"
    source "${script_dir}/check_os.sh"

    OS=$(check_os)

    if [[ $OS == "Cygwin" ]]; then
        source "${script_dir}/props/symlink_win_list.conf"
    elif [[ $OS == "Mac" ]]; then
        source "${script_dir}/props/symlink_mac_list.conf"
    elif [[ $OS == "CentOS" ]]; then
        :
    elif [[ $OS == "Amazon Linux" ]]; then
        :
    elif [[ $OS == "Ubuntu" ]]; then
        source "${script_dir}/props/symlink_ubuntu_list.conf"
    else
        echo "Unsupported OS: $OS"
        return 1
    fi

    for path in "${symlink_list[@]}"; do
        local src dst
        IFS='|' read -r src dst <<< "$path"

        safe_ln "$src" "$dst"
    done

    return 0
}

function select_gitconfig() {
    GIT_DIR="$(cd "$(dirname "${BASH_SOURCE:-$0}")"/../git && pwd)"

    echo "select your git user config type"
    select user in "private" "make"
    do
        case $user in
            "private")
                safe_ln "${GIT_DIR}/.gitconfig.private" "${HOME}/.gitconfig.local"
                break
                ;;
            "make")
                if [[ -e "${HOME}/.gitconfig.local" ]]; then
                    echo "Target file already exists: ${HOME}/.gitconfig.local"
                    prompt_read _replace_gitconfig "Do you want to replace the file? [Yes / No]:"
                    case "$_replace_gitconfig" in
                        [Yy] | [Yy][Ee][Ss] )
                            ;;
                        [Nn] | [Nn][Oo] )
                            prompt_read _backup_gitconfig "Do you want to make backup file? [Yes / No]:"
                            case "$_backup_gitconfig" in
                                [Yy] | [Yy][Ee][Ss] )
                                    mv "${HOME}/.gitconfig.local" "${HOME}/.gitconfig.local.bak"
                                    ;;
                                * )
                                    echo "skip ${HOME}/.gitconfig.local"
                                    break
                                    ;;
                            esac
                            ;;
                        * )
                            echo "skip ${HOME}/.gitconfig.local"
                            break
                            ;;
                    esac
                fi

                read -p "Input Git User Name" -r GIT_NAME
                read -p "Input Git User Email" -r GIT_MAIL
                # ファイル書き込み
                echo "[user]" > "${HOME}/.gitconfig.local"
                echo "	name = ${GIT_NAME}" >> "${HOME}/.gitconfig.local"
                echo "	email = ${GIT_MAIL}" >> "${HOME}/.gitconfig.local"

                break
                ;;
            *)
                echo "Choice from Option Number"
                ;;
        esac
    done

    return 0
}

function setup(){
    script_dir="$(dirname "${BASH_SOURCE:-$0}")"
    source "${script_dir}/install.sh"

    install
    symlink
    select_gitconfig

    return 0
}

# source実行か直接実行かの判定処理
_is_sourced=0
_SCRIPT_NAME="setup.sh"

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
    setup
fi

# 判定に使用した内部変数をクリーンアップ (source先の環境を汚さないため)
unset _SCRIPT_NAME _is_sourced _basename_0
