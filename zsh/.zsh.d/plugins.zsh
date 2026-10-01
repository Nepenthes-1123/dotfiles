### zsh-plugins
# fzf-tab は compinit の後 (completion.zsh より後)、ウィジェットを包むプラグインより前に読み込む
source $HOME/.zsh/fzf-tab/fzf-tab.plugin.zsh
source $HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

### other-plugins
source <(fzf --zsh)

#### zsh-autocompleteと組み合わせる場合、いい感じに補完をするために以下の設定を追加
my-fzf-tab() {
  functions[compadd]=$functions[-ftb-compadd]
  zle fzf-tab-complete
}
zle -N my-fzf-tab
bindkey "^I" my-fzf-tab

# zsh-syntax-highlighting は他のウィジェットをすべて定義した後、最後に読み込む
source $HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
