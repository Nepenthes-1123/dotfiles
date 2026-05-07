# !/bin/sh
set -euC
set -o pipefail

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

if [[ "${BASH_SOURCE:-$0}" == "${0}" ]]; then
    check_os
fi
