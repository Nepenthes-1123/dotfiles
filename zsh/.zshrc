#!/bin/zsh
export LANG='ja_JP.UTF-8'
export LC_ALL='ja_JP.UTF-8'
export LC_TIME='en_US.UTF-8'
export LC_MESSAGES='ja_JP.UTF-8'


# .zsh.d ディレクトリ内の設定ファイルを読み込む
ZSH_CONFS_DIR="${HOME}/.zsh.d"
ZSH_PRIORITIES_CONF="${ZSH_CONFS_DIR}/priorities.conf"

# Load ${ZSH_CONFS} in ${ZSH_PRIORITIES_CONF}
source "${ZSH_PRIORITIES_CONF}"

# Load each zsh conf in ${ZSH_CONFS}
for zsh_conf in ${ZSH_CONFS}; do
  source "${ZSH_CONFS_DIR}/${zsh_conf}"
done


## 未分割

## タイトルバーに現在のディレクトリを表示
precmd() {
    print -Pn "\e]0; %3~\a"
}

## PATH
export PATH=/usr/bin:/usr/local/bin:/usr/local/sbin:$HOME/bin:$PATH

## カラー設定
export TERM=xterm-256color
export LSCOLORS=ExFxCxdxBxegedabagacad
export LS_COLORS='di=01;34:ln=01;35:so=01;32:ex=01;31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
export ZLS_COLORS=$LS_COLORS

## 出力の文字列末尾に改行コードが無い場合でも表示
unsetopt promptcr
## ビープを鳴らさない
setopt nobeep
## ファイル名で #, ~, ^ の 3 文字を正規表現として扱う
setopt extended_glob
## ファイル名の展開で辞書順ではなく数値的にソート
setopt numeric_glob_sort
## 出力時8ビットを通す
setopt print_eight_bit
