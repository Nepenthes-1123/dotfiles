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
