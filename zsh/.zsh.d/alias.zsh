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
    echo "Unsupported OS: $OS @alias.zsh"
    return 1
fi

# safty
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# ls 系
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'

# cd 系
alias c~='cd ~'
alias ..2='cd ../..'
alias ..3='cd ../../..'
alias ..4='cd ../../../..'

# git 系
alias g='git'
alias ga='git add'
alias gd='git diff'
alias gs='git status'
alias gph='git push'
alias gpl='git pull'
alias gco='git checkout'
alias gf='git fetch'
alias gc='git commit'

