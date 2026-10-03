## Ubuntu (WSL を含む) の /etc/zsh/zshrc が行う compinit を止める
# compinit は completion.zsh で行うため、ここで止めないと起動時に 2 回走って遅くなる。
# /etc/zsh/zshrc は ~/.zshrc より先に読まれるので、ここ (.zshenv) で指定する必要がある。
# macOS の /etc/zshrc は compinit を行わないため影響しない。
skip_global_compinit=1

## ロケール
# 環境変数なので、対話シェルだけでなく zsh -l -c (WezTerm や herdr から起動するコマンド) にも効くようここで設定する。
# LC_ALL はほかの LC_* より優先されて個別の指定を打ち消すため使わない
export LANG='ja_JP.UTF-8'

## .zshenv.local が存在する場合は読み込む
# rustup など ~/.zshenv に追記するツールの設定は、こちらに書く
[ -f "${HOME}/.zshenv.local" ] && source "${HOME}/.zshenv.local"
