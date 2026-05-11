### zsh-plugins
source $HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source $HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $HOME/.zsh/fzf-tab/fzf-tab.plugin.zsh

### other-plugins
[ -f $HOME/.fzf.zsh ] && source $HOME/.fzf.zsh
source <(fzf --zsh)

#### zsh-autocompleteと組み合わせる場合、いい感じに補完をするために以下の設定を追加
my-fzf-tab() {
  functions[compadd]=$functions[-ftb-compadd]
  zle fzf-tab-complete
}
zle -N my-fzf-tab
bindkey "^I" my-fzf-tab
