DOTFILES_DIR="${HOME}/dotfiles"

zsh_d_list=($(find "${HOME}/.zsh.d/"*.zsh -type f | awk -F '/' '{ print $NF }' | sort))
source "${HOME}/.zsh.d/priorities.conf"
zsh_confs=$(printf "%s\n" "${ZSH_CONFS[@]}" | sort)

invaders=$(echo ${zsh_d_list[@]} ${zsh_confs[@]} | tr ' ' '\n' | sort | uniq -u | tr '\n' ' ')

if test -n "${invaders}"; then
  echo "Not managed in ${HOME}/.zsh.d/priorities.conf: ${invaders}"
fi
