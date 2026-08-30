source ~/dotfiles/scripts/check_os.sh

OS=$(check_os)

if [[ $OS == "Cygwin" ]]; then
    alias cursor-agent="${HOME}/AppData/Local/cursor-agent/agent.cmd"
elif [[ $OS == "Mac" ]]; then
    :
elif [[ $OS == "CentOS" ]]; then
    :
elif [[ $OS == "Amazon Linux" ]]; then
    :
elif [[ $OS == "Ubuntu" ]]; then
    :
else
    echo "Unsupported OS: $OS @alias.zsh"
    return 1
fi

# safty
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# ls 系
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'

# cd 系
alias c~='cd ~'
alias ..2='cd ../..'
alias ..3='cd ../../..'
alias ..4='cd ../../../..'

# git 系
alias g='git'
alias ga='git add'
alias gd='git diff'
alias gs='git status'
alias gph='git push'
alias gpl='git pull'
alias gco='git checkout'
alias gf='git fetch'
alias gl='git log'
alias gc='git commit'
alias gwt='git worktree'
alias gwtip='git --git-dir=.bare worktree' # 親ディレクトリにいる時用

## Git worktree用のベアリポジトリ環境を自動構築する関数
function gwt-init() {
  # 1. 引数のチェック
  if [[ -z "$1" ]]; then
    echo "エラー: リポジトリのURLを指定してください。"
    echo "使い方: gwt-init <リポジトリURL> [プロジェクトディレクトリ名]"
    return 1
  fi

  local repo_url="$1"
  local project_name="$2"

  # 2. プロジェクト名が指定されていない場合、URLから自動で推測
  if [[ -z "$project_name" ]]; then
    project_name=$(basename "$repo_url" .git)
  fi

  # herdr・lazygit・gwt-initで作成先を揃えるため、共有ルート配下に固定する。
  # herdrの [worktrees].directory と同じ値にすること
  local gwt_root="$HOME/.worktree"
  local project_dir="$gwt_root/$project_name"

  # 既に同名のディレクトリが存在しないかチェック
  if [[ -d "$project_dir" ]]; then
    echo "エラー: ディレクトリ '$project_dir' は既に存在します。"
    return 1
  fi

  echo "プロジェクトディレクトリ '$project_dir' を作成中..."
  mkdir -p "$project_dir" || return 1

  echo "ベアリポジトリを .bare にクローン中..."
  git clone --bare "$repo_url" "$project_dir/.bare"

  # クローンに失敗した場合は作成したディレクトリを消して終了
  if [[ $? -ne 0 ]]; then
    echo "エラー: クローンに失敗しました。"
    rm -rf "$project_dir"
    return 1
  fi

  # herdrがembedded bareレイアウトとして認識するためのマーカー。
  # これが無いとherdr側のリポジトリ名が".bare"になり、worktreeがプロジェクト外に作られる
  printf 'gitdir: ./.bare\n' > "$project_dir/.git"

  echo "⚙️ fetch設定を修正中..."
  # .bareディレクトリに入らずに直接設定を書き換える
  git --git-dir="$project_dir/.bare" config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"

  cd "$project_dir" || return 1

  echo "セットアップが完了しました！"
  echo "現在のディレクトリ: $(pwd)"
  echo ""
  echo "続けて、以下のコマンドでメインのブランチを展開できます:"
  echo "  git worktree add main main"
}

