#!/bin/zsh
export LANG='ja_JP.UTF-8'
export LC_ALL='ja_JP.UTF-8'
export LC_TIME='en_US.UTF-8'
export LC_MESSAGES='ja_JP.UTF-8'

## plugins

### zsh-plugins
source $HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source $HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $HOME/.zsh/fzf-tab/fzf-tab.plugin.zsh

### other-plugins
source <(fzf --zsh)
#### zsh-autocompleteと組み合わせる場合、いい感じに補完をするために以下の設定を追加
my-fzf-tab() {
  functions[compadd]=$functions[-ftb-compadd]
  zle fzf-tab-complete
}
zle -N my-fzf-tab
bindkey "^I" my-fzf-tab

## タイトルバーに現在のディレクトリを表示
precmd() {
    print -Pn "\e]0; %3~\a"
}

## PATH
export PATH=/usr/bin:/usr/local/bin:/usr/local/sbin:$HOME/bin:$PATH

## ヒストリ設定
HISTFILE=$HOME/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt share_history          # ヒストリを共有
setopt hist_ignore_dups       # 重複を無視
setopt hist_ignore_space      # スペースで始まるコマンドをヒストリに保存しない
setopt hist_reduce_blanks     # 空行をヒストリに保存しない
setopt hist_save_no_dups      # 終了時に重複を削除して保存
setopt hist_no_store          # historyコマンドをヒストリに保存しない
setopt extended_history       # zsh の開始, 終了時刻をヒストリファイルに書き込む
setopt hist_verify            # ヒストリを呼び出してから実行する間に一旦編集
zstyle ':completion:*' history-size $HISTSIZE
zstyle ':completion:*' save-history $SAVEHIST

## カラー設定
export TERM=xterm-256color
export LSCOLORS=ExFxCxdxBxegedabagacad
export LS_COLORS='di=01;34:ln=01;35:so=01;32:ex=01;31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
export ZLS_COLORS=$LS_COLORS


# zsh-completions がインストールされている場合は補完関数のパスに追加
if [ -e /usr/local/share/zsh-completions ]; then
  fpath=(/usr/local/share/zsh-completions $fpath)
fi

autoload -Uz compinit
compinit -u

## 補完候補をカラー表示
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([%0-9]#)*=0=01;31'
zstyle ':completion::complete:*' use-cache true

## プロンプトにカラーを使用する
autoload -U colors; colors

## 表示毎にPROMPTで設定されている文字列を評価する
setopt prompt_subst

## gitのbranch名とstatus表示
function check_git_status() {
  local name st color

  # .gitディレクトリ内での実行をスキップ
  if [[ "$PWD" =~ '/\.git(/.*)?$' ]]; then
    return 0
  fi

  # gitのbranch名を取得
  name=$(git symbolic-ref HEAD 2> /dev/null | sed 's!refs/heads/!!')

  # ブランチ名が空の場合はスキップ
  if [[ -z $name ]]; then
    return 0
  fi

  # gitのステータスを取得
  st=$(git status --short 2> /dev/null)
  # ステータスに応じた色を設定
  case "$st" in
    "") color=${fg[green]} ;;           # Status clean
    *"\?\? "* ) color=${fg[yellow]} ;;  # Untracked
    *"\ M "* ) color=${fg[red]} ;;      # Modified
    * ) color=${fg[cyan]} ;;            # Added to commit
  esac

  echo "[%{$color%}$name%{$reset_color%}]"
}

## プロンプト表示設定
function {
  # ホスト名とディレクトリ名を表示
  #   PROMPT="%{${fg[green]}%}%n@%m %{${fg[yellow]}%}%3~%{${reset_color}%} "
  # $ のみを表示
  PROMPT="%{${fg[yellow]}%}%3~%{${reset_color}%} %{${fg[green]}%}%#%{${reset_color}%} "
  # コマンドの続きを表示する際のプロンプト
  PROMPT2="%{${fg[green]}%}%_%%%{${reset_color}%} "
  # スペルミスを修正する際のプロンプト
  SPROMPT="%{${fg[green]}%}%r is correct? [n,y,a,e]:%{${reset_color}%} "
  # リモートホストの場合はホスト名を表示
  [ -n "${REMOTEHOST}${SSH_CONNECTION}" ] && PROMPT="%{${fg[white]}%}${HOST%%.*} ${PROMPT}"
  RPROMPT='`check_git_status`'
}

## 補完機能を初期化して有効化
autoload -U compinit promptinit; compinit
## コマンドにsudoを付けても補完
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin
## スペルチェック
setopt correct
## TAB で順に補完候補を切り替える
setopt auto_menu
## 補完候補を一覧表示
setopt auto_list
## 補完候補を詰めて表示
setopt list_packed
## 補完候補一覧でファイルの種別をマーク表示
setopt list_types
## 最後のスラッシュを自動的に削除しない
setopt noautoremoveslash
## 大文字，小文字を区別しないで補完（大文字は開始は大文字限定）
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
## カッコの対応などを自動的に補完
setopt auto_param_keys
## --prefix=/usr などの = 以降も補完
setopt magic_equal_subst
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
