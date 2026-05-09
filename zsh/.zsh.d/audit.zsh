zsh_d_list=($(find "${ZSH_CONFS_DIR}/"*.zsh -type f | awk -F '/' '{ print $NF }' | sort))
source "${ZSH_PRIORITIES_CONF}"
zsh_confs=$(printf "%s\n" "${ZSH_CONFS[@]}" | sort)

invaders=$(echo ${zsh_d_list[@]} ${zsh_confs[@]} | tr ' ' '\n' | sort | uniq -u | tr '\n' ' ')

if test -n "${invaders}"; then
  echo "Not managed in ${ZSH_PRIORITIES_CONF}: ${invaders}"
fi
