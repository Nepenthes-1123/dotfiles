source ~/dotfiles/scripts/check_os.sh


    OS=$(check_os)

    if [[ $OS == "Cygwin" ]]; then
	alias cursor-agent="${HOME}/AppData/Local/cursor-agent/agent.cmd"
    elif [[ $OS == "Mac" ]]; then
	:
    elif [[ $OS == "CentOS" ]]; then
        :
    elif [[ $OS == "Amazon Linux" ]]; then
        :
    elif [[ $OS == "Ubuntu" ]]; then
	:
    else
        echo "Unsupported OS: $OS"
        return 1
    fi
