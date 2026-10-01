## mise (CLI ツールのバージョン管理)
# starship (prompt.zsh) や fzf (plugins.zsh) は mise で入れているため、それらより先に読み込む
# Windows では zsh と mise を WSL の中で使うため、mac / Linux / WSL のどれでも activate を使う
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi
