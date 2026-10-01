## mise の shims を PATH に載せる (ログインシェル用)
# .zshrc は対話シェルのときだけ読まれるため、WezTerm (shell.lua) や herdr 連携が使う
# `zsh -l -c` では .zsh.d/mise.zsh の `mise activate zsh` が走らず、mise のツールが見つからない。
# 非対話でも読まれるここで shims を通しておく。対話シェルでは続けて .zshrc の
# `mise activate zsh` が実体のパスを前に足すため、そちらが優先される。
# (macOS は /etc/zprofile の path_helper が PATH を並べ替えるため、.zshenv ではなくここに置く)
_mise_shims="${XDG_DATA_HOME:-${HOME}/.local/share}/mise/shims"
if [[ -d "$_mise_shims" && ":${PATH}:" != *":${_mise_shims}:"* ]]; then
  export PATH="${_mise_shims}:${PATH}"
fi
unset _mise_shims
