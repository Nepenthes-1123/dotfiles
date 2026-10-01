# zsh-completions がインストールされている場合は補完関数のパスに追加
if [ -e /usr/local/share/zsh-completions ]; then
  fpath=(/usr/local/share/zsh-completions $fpath)
fi

# Docker Desktop の補完 (Docker Desktop は .zshrc.local に compinit ごと追記するが、
# compinit の後に読まれて 2 回目の compinit が走るため、ここで compinit より前に追加する)
if [[ -d ~/.docker/completions ]]; then
  fpath=(~/.docker/completions $fpath)
fi

## 補完機能を初期化する (fpath への追加はすべてこれより前に行う)
# compinit は補完関数を全走査して ~/.zcompdump を作り直すため数百 ms かかる。
# ダンプが 24 時間以内に作られていれば検査を省いてそのまま読み込み (-C)、古ければ作り直す
autoload -Uz compinit
_stale_zcompdump=(~/.zcompdump(N.mh+24))
if (( ${#_stale_zcompdump} )); then
  compinit -u
else
  compinit -C
fi
unset _stale_zcompdump

## 補完候補をカラー表示
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([%0-9]#)*=0=01;31'
zstyle ':completion::complete:*' use-cache true
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

# herdrの補完スクリプト有効化
if type herdr > /dev/null 2>&1; then
    source <(herdr completion zsh)
fi
