## mise (CLI ツールのバージョン管理)
# starship (prompt.zsh) や fzf (plugins.zsh) は mise で入れているため、それらより先に読み込む
if command -v mise >/dev/null 2>&1; then
  case "${OSTYPE}" in
  msys* | cygwin*)
    # Windows版 mise の activate が出力するパスは MSYS2/Git Bash 配下の zsh と形式が合わない可能性があるため、
    # activate は使わず exe 形式の shims (既定の windows_shim_mode) を PATH に通す
    export PATH="$(cygpath -u "${LOCALAPPDATA}")/mise/shims:${PATH}"
    ;;
  *)
    eval "$(mise activate zsh)"
    ;;
  esac
fi
