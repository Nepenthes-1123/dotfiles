# !/bin/sh

function check_os() {
    declare OS="unsupported os"
    if [[ "$(uname)" == 'Darwin' ]]; then
        OS='Mac'
    elif [[ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]]; then
        RELEASE_FILE=/etc/os-release
        if grep '^NAME="CentOS' "${RELEASE_FILE}" >/dev/null; then
            OS=CentOS
        elif grep '^NAME="Amazon' "${RELEASE_FILE}" >/dev/null; then
        OS="Amazon Linux"
        elif grep '^NAME="Ubuntu' "${RELEASE_FILE}" >/dev/null; then
        OS=Ubuntu
        else
            echo "Your platform is not supported."
            uname -a
            return 1
        fi
    elif [[ "$(expr substr $(uname -s) 1 6)" == 'CYGWIN' || "$(expr substr $(uname -s) 1 5)" == 'MINGW' ]]; then
        OS='Cygwin'
    else
        echo ${OS}
        uname -a
        return 1
    fi

    echo ${OS}
}

# source実行か直接実行かの判定処理
_is_sourced=0
_SCRIPT_NAME="check_os.sh"

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
    check_os
fi

# 判定に使用した内部変数をクリーンアップ (source先の環境を汚さないため)
unset _SCRIPT_NAME _is_sourced _basename_0
