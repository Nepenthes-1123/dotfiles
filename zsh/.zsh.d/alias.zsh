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

  # 既に同名のディレクトリが存在しないかチェック
  if [[ -d "$project_name" ]]; then
    echo "エラー: ディレクトリ '$project_name' は既に存在します。"
    return 1
  fi

  echo "プロジェクトディレクトリ '$project_name' を作成中..."
  mkdir "$project_name"
  cd "$project_name" || return 1

  # bareリポジトリを .bare ではなく .git の実体として置く。
  # herdrは .git が実体のbareディレクトリである場合のみ、ここをworktreeの親ワークスペースとして
  # 認識する。.bare + `gitdir: ./.bare` ファイル方式では親として扱われない
  echo "ベアリポジトリを .git にクローン中..."
  git clone --bare "$repo_url" .git

  # クローンに失敗した場合は作成したディレクトリを消して終了
  if [[ $? -ne 0 ]]; then
    echo "エラー: クローンに失敗しました。"
    cd ..
    rm -rf "$project_name"
    return 1
  fi

  # bare cloneはremote-trackingのrefspecを張らないため、自分で設定してfetchし直す
  echo "⚙️ fetch設定を修正中..."
  git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
  if ! git fetch origin; then
    echo "警告: fetchに失敗しました。リポジトリは作成済みなので、後で 'git fetch origin' を再実行してください。"
  fi

  echo "セットアップが完了しました！"
  echo "現在のディレクトリ: $(pwd)"
  echo ""
  echo "続けて、以下のコマンドでメインのブランチを展開できます:"
  echo "  git worktree add main main"
}

