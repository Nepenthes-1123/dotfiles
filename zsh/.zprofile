## .zprofile.local が存在する場合は読み込む
# Homebrew の `brew shellenv` など、マシンごとに違う PATH の設定はこちらに書く。
# mise の shims より先に読むことで、shims が常に前に来る (mise のツールが優先される)。
[ -f "${HOME}/.zprofile.local" ] && source "${HOME}/.zprofile.local"

## Volta があるマシンでは node を Volta に任せる
# 会社の方針で Volta を使うマシン向け。mise の node を無効にすると、mise の shim と
# `mise activate` は node を扱わず、PATH 上の次の node (Volta のシム) が使われる。
# Volta 本体は Homebrew で入れると ~/.volta/bin に置かれないため、Volta のシムの node で判定する。
# Volta の PATH (~/.volta/bin) は、zsh -l -c でも読まれる ~/.zprofile.local で通しておく。
if [[ -x "${VOLTA_HOME:-${HOME}/.volta}/bin/node" && ",${MISE_DISABLE_TOOLS}," != *,node,* ]]; then
  export MISE_DISABLE_TOOLS="node${MISE_DISABLE_TOOLS:+,${MISE_DISABLE_TOOLS}}"
fi

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
