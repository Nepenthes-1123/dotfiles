# !/bin/sh
set -euC
set -o pipefail

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

        # source file must exist
        if [[ ! -e ${symlink[0]} ]]; then
            echo "Source file not found: ${symlink[0]}"
            continue
        fi

        # target file must not exist
        if [[ -e ${symlink[1]} ]]; then
            echo "Target file already exists: ${symlink[1]}"
            continue
        fi

        # create target directory if not exist
        if [[ ! -e $(dirname ${symlink[1]}) ]]; then
            mkdir -p $(dirname ${symlink[1]})
        fi

        # make symbolic link
        ln -s ${symlink[0]} ${symlink[1]}
    done
}

function setup(){
    script_dir="$(dirname "${BASH_SOURCE:-$0}")"
    source "${script_dir}/install.sh"

    install
    symlink
}

if [[ "${BASH_SOURCE:-$0}" == "${0}" ]]; then
    setup
fi
