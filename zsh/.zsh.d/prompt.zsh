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


## プロンプトにカラーを使用する
autoload -U colors; colors

## 表示毎にPROMPTで設定されている文字列を評価する
setopt prompt_subst


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
