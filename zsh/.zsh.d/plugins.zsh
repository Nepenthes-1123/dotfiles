### zsh-plugins
# fzf-tab は compinit の後 (completion.zsh より後)、ウィジェットを包むプラグインより前に読み込む
source $HOME/.zsh/fzf-tab/fzf-tab.plugin.zsh
source $HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

### other-plugins
source <(fzf --zsh)

# zsh-syntax-highlighting は他のウィジェットをすべて定義した後、最後に読み込む
source $HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
