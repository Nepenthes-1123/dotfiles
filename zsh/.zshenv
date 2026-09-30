## Ubuntu (WSL を含む) の /etc/zsh/zshrc が行う compinit を止める
# compinit は completion.zsh で行うため、ここで止めないと起動時に 2 回走って遅くなる。
# /etc/zsh/zshrc は ~/.zshrc より先に読まれるので、ここ (.zshenv) で指定する必要がある。
# macOS の /etc/zshrc は compinit を行わないため影響しない。
skip_global_compinit=1

## .zshenv.local が存在する場合は読み込む
# rustup など ~/.zshenv に追記するツールの設定は、こちらに書く
[ -f "${HOME}/.zshenv.local" ] && source "${HOME}/.zshenv.local"
