## Ubuntu (WSL を含む) の /etc/zsh/zshrc が行う compinit を止める
# compinit は completion.zsh で行うため、ここで止めないと起動時に 2 回走って遅くなる。
# /etc/zsh/zshrc は ~/.zshrc より先に読まれるので、ここ (.zshenv) で指定する必要がある。
# macOS の /etc/zshrc は compinit を行わないため影響しない。
skip_global_compinit=1

## PATH と fpath の重複を除く (最初のものだけを残すので、優先順位は変わらない)
# macOS の path_helper と brew shellenv の両方が /opt/homebrew/bin を足し、*.local が無条件に先頭へ足す
# ディレクトリも入れ子のシェルのたびに増える。
# -U が効くのは配列 (path・fpath) への代入だけで、PATH=... のような文字列での書き換えでは除かれないため、
# .zprofile と .zshrc で *.local を読んだ後に path=($path) で代入し直す
typeset -U path fpath

## ロケール
# 環境変数なので、対話シェルだけでなく zsh -l -c (WezTerm や herdr から起動するコマンド) にも効くようここで設定する。
# LC_ALL はほかの LC_* より優先されて個別の指定を打ち消すため使わない
export LANG='ja_JP.UTF-8'
# Ubuntu (WSL を含む) は ja_JP.UTF-8 を生成していないことがあり (dot.sh setup で生成する)、
# 無いロケールを指定すると C ロケールに戻って日本語をバイト単位で扱ってしまう。
# zsh は LANG を設定した時点でロケールを切り替えるので、文字コードが UTF-8 にならなければ C.UTF-8 にする
zmodload -F zsh/langinfo p:langinfo 2>/dev/null
if [[ ${langinfo[CODESET]} != UTF-8 ]]; then
  export LANG='C.UTF-8'
fi

## エディタ
# 未設定だと、Claude Code は VSCode (code) を、herdr・less・crontab などは vi を開く。
# zsh -l -c から起動する Claude Code や herdr にも渡すため、ロケールと同じくここで設定する
export EDITOR='nvim'
export VISUAL='nvim'

## .zshenv.local が存在する場合は読み込む
# rustup など ~/.zshenv に追記するツールの設定は、こちらに書く
[ -f "${HOME}/.zshenv.local" ] && source "${HOME}/.zshenv.local"
