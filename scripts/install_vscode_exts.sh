#!/bin/sh
dotfiles_dir="$(dirname $(dirname "${BASH_SOURCE:-$0}"))"

while read -r ext; do
    if [ -z "$ext" ]; then continue; fi
    echo "Installing $ext ..."
    code --install-extension "$ext" --force
done < "$dotfiles_dir/vscode/extensions.txt"
echo "All extensions installed."
