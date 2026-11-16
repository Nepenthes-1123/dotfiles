### zsh-plugins
# fzf-tab は compinit の後 (completion.zsh より後)、ウィジェットを包むプラグインより前に読み込む
# プラグインは dot.sh setup / update で ~/.zsh に入る。入れる前のシェルでもエラーを出さないよう、有るものだけ読む
[[ -r $HOME/.zsh/fzf-tab/fzf-tab.plugin.zsh ]] && source $HOME/.zsh/fzf-tab/fzf-tab.plugin.zsh
[[ -r $HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source $HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

### other-plugins
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

# zsh-syntax-highlighting は他のウィジェットをすべて定義した後、最後に読み込む
[[ -r $HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source $HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
