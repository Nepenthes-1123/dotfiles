# Wezterm integration

autoload -Uz add-zsh-hook

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
if [[ "${TERM}" != (linux|dumb) ]]; then
  add-zsh-hook precmd _wezterm_report_cwd
fi
