# !/bin/sh

function safe_ln() {
    # source file must exist
    if [[ ! -e $1 ]]; then
        echo "Source file not found: ${1}"
        return 0
    fi

    # target file must not exist
    if [[ -e $2 ]]; then
        echo "Target file already exists: ${2}"
        if [[ -n "$ZSH_VERSION" ]]; then
            read -r "_replace_link?Do you want to replace the file? [Yes / No]: "
        else
            read -p  "Do you want to replace the file? [Yes / No]: " -r _replace_link
        fi
        case "$_replace_link" in
            [Yy] | [Yy][Ee][Ss] )
                ;;
            [Nn] | [Nn][Oo] )
                if [[ -n "$ZSH_VERSION" ]]; then
                    read -r "_backup_link?Do you want to make backup file? [Yes / No]: "
                else
                    read -p "So you want to make backup file? [Yes / No]: " -r _backup_link
                fi
                case "$_backup_link" in
                    [Yy] | [Yy][Ee][Ss] )
                    mv $2 "${2}.bak"
                    ;;
                    [Nn] | [Nn][Oo] )
                        echo "skip ${2}"
                        return 0
                        ;;
                    * )
                        echo "skip ${2}"
                        return 0
                        ;;
                esac
                ;;
            * )
                echo "skip ${2}"
                return 0
                ;;
        esac
    fi

    # create target directory if not exist
    if [[ ! -e $(dirname $2) ]]; then
        mkdir -p $(dirname $2)
    fi

    # make symbolic link
    ln -s $1 $2

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
        symlink=(${path[@]})

        safe_ln ${symlink[0]} ${symlink[1]}
    done

    return 0
}

function select_gitconfig() {
    GIT_DIR="$(cd $(dirname ${BASH_SOURCE:-$0})/../git; pwd)"

    echo "select your git user config type"
    select user in "private" "make"
    do
        case $user in
            "private")
                safe_ln "${GIT_DIR}/.gitconfig.private" "${HOME}/.gitconfig.local"
                break
                ;;
            "make")
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
