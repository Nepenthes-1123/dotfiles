# !/bin/sh

function usage() {
    echo "Usage: $0 <source> <target>"
    exit 1
}

function add_symlink() {
    # check two arguments
    if [[ $# -ne 2 ]]; then
        usage
    fi

    # source file must exist
    if [[ ! -e $1 ]]; then
        echo "Source file not found: $1"
        return 1
    fi

    # target file must not exist
    if [[ -e $2 ]]; then
        echo "Target file already exists: $2"
        return 1
    fi

    # create target directory if not exist
    if [[ ! -e $(dirname $2) ]]; then
        mkdir -p $(dirname $2)
    fi

    # move source file to target location and create symbolic link
    mv $1 $2
    ln -s $2 $1

    script_dir="$(dirname "$0")"
    echo "${script_dir}@add"

    source "${script_dir}/check_os.sh"

    OS=$(check_os)

    if [[ $OS == "Cygwin" ]]; then
        link_path="${script_dir}/props/symlink_win_list.conf"
    elif [[ $OS == "Mac" ]]; then
        link_path="${script_dir}/props/simlink_mac_list.conf"
    elif [[ $OS == "CentOS" ]]; then
        # sudo dnf install -y zsh
        :
    elif [[ $OS == "Amazon Linux" ]]; then
        # sudo yum install -y zsh
        :
    elif [[ $OS == "Ubuntu" ]]; then
        link_path="${script_dir}/props/symlink_ubuntu_list.conf"
    else
        echo "Unsupported OS: $OS"
        return 1
    fi

    # add symlink info to symlink_win_list.conf
    local -r list_row_num=$(wc -l < $link_path)
    sed -i "${list_row_num},$((list_row_num + 1))i\"${2} ${1} \" \\\\" $link_path

    return 0
}

# source実行か直接実行かの判定処理
_is_sourced=0
_SCRIPT_NAME="add_symlink.sh"

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
    add_symlink $1 $2
fi

# 判定に使用した内部変数をクリーンアップ (source先の環境を汚さないため)
unset _SCRIPT_NAME _is_sourced _basename_0
