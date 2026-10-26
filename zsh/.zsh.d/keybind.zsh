# キー割り当て
# 指定しないと zsh は EDITOR / VISUAL に vi が含まれるとき vi 風にするため、EDITOR=nvim でも emacs 風に固定する。
# main を切り替える前の bindkey は切り替え前の側に入るため、ほかの bindkey より先に読む (priorities.conf)
bindkey -e

# Ctrl+← / Ctrl+→ (xterm 形式)。zsh は標準では割り当てていない
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
