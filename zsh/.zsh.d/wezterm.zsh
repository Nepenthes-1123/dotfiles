# Wezterm integration

# Set UserVar for Wezterm
# Usage: _wezterm_set_user_var VAR_NAME VALUE
function _wezterm_set_user_var() {
  if [[ "$TERM_PROGRAM" == "WezTerm" ]]; then
    local name=$1
    local value=$(echo -n "$2" | base64 | tr -d '\n\r')
    printf "\033]1337;SetUserVar=%s=%s\007" "$name" "$value"
  fi
}

# Update git status and send to Wezterm
function _wezterm_update_git_status() {
  if [[ "$TERM_PROGRAM" != "WezTerm" ]]; then
    return
  fi

  # Skip in .git directory
  if [[ "$PWD" =~ '/\.git(/.*)?$' ]]; then
    _wezterm_set_user_var "GIT_BRANCH" ""
    _wezterm_set_user_var "GIT_STATUS" ""
    return
  fi

  local branch=$(git symbolic-ref HEAD 2>/dev/null | sed 's!refs/heads/!!')
  if [[ -z "$branch" ]]; then
    # Not a git repository or detached HEAD
    # Check if we are in a git repo anyway (for detached HEAD)
    branch=$(git rev-parse --short HEAD 2>/dev/null)
    if [[ -z "$branch" ]]; then
      _wezterm_set_user_var "GIT_BRANCH" ""
      _wezterm_set_user_var "GIT_STATUS" ""
      return
    fi
  fi

  local st=$(git status --short 2>/dev/null)
  local status_key="clean"
  if [[ -n $(echo "$st" | grep '?? ') ]]; then
    status_key="untracked"
  elif [[ -n $(echo "$st" | grep ' M ') ]] || [[ -n $(echo "$st" | grep 'D ') ]]; then
    status_key="modified"
  elif [[ -n "$st" ]]; then
    status_key="staged"
  else
    status_key="clean"
  fi

  _wezterm_set_user_var "GIT_BRANCH" "$branch"
  _wezterm_set_user_var "GIT_STATUS" "$status_key"
}

# Register precmd hook
autoload -Uz add-zsh-hook
add-zsh-hook precmd _wezterm_update_git_status

# OSC 7 の URL に入れるため、パスを UTF-8 のバイト単位でパーセントエンコードする
function _wezterm_osc7_path() {
  emulate -L zsh
  local LC_ALL=C c hex out= i
  for (( i = 1; i <= ${#1}; i++ )); do
    c=${1[i]}
    case $c in
    [-/._~A-Za-z0-9]) out+=$c ;;
    *)
      printf -v hex '%%%02X' "'$c"
      out+=$hex
      ;;
    esac
  done
  print -rn -- "$out"
}

# カレントディレクトリを WezTerm に知らせる (OSC 7)。新しいタブ・ペインはこのディレクトリで開く。
# WSL のペインでは WezTerm から中のシェルが見えず (見えるのは wsl.exe だけ)、これが無いと
# wsl.exe 自身のカレントディレクトリ (Windows 側のホーム) で開いてしまう
function _wezterm_report_cwd() {
  printf '\033]7;file://%s%s\033\\' "${HOST}" "$(_wezterm_osc7_path "$PWD")"
}

# Linux のコンソール・dumb (エスケープシーケンスを解釈しない端末) には送らない。
# (.zshrc が後で TERM を上書きするため、読み込む時点の TERM で判定する)
if [[ "${TERM}" != (linux|dumb) ]]; then
  add-zsh-hook precmd _wezterm_report_cwd
fi
