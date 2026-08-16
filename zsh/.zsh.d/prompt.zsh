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


## プロンプト表示設定 (starship に委譲)
# Windows版starship.exeがzsh(MSYS2/Git Bash)配下で自身のパスをバックスラッシュ形式のまま
# 埋め込み、コマンドとして解決できずエラーになるため、フォワードスラッシュに変換する
eval "$(starship init zsh | sed 's/\\/\//g')"
