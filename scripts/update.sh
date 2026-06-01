#!/usr/bin/env bash

function update_win() {
    echo "Starting update for Windows (Cygwin)..."
    script_dir="$(dirname "${BASH_SOURCE:-$0}")"

    # OS Packages
    if command -v winget > /dev/null 2>&1; then
        echo "Updating specific OS packages via winget..."
        source "${script_dir}/props/packages.conf"
        for pkg in "${win_packages[@]}"; do
            echo "Updating $pkg..."
            winget upgrade --id "$pkg" -e --source winget || echo "No update available for $pkg or failed."
        done
    fi

    # zsh plugins
    echo "--- Updating zsh plugins ---"
    source "${script_dir}/props/zsh_plugins.conf"
    for path in "${zsh_plugins[@]}"; do
        zsh_plugin=(${path[@]})
        plugin_dir=${zsh_plugin[1]}
        if [[ -d "${plugin_dir}/.git" ]]; then
            echo "Updating ${plugin_dir}..."
            git -C "${plugin_dir}" pull
        fi
    done

    # fzf
    echo "--- Updating fzf ---"
    if [[ -d "${HOME}/.fzf" ]]; then
        echo "Updating fzf..."
        git -C "${HOME}/.fzf" pull
        "${HOME}/.fzf/install" --all
    fi

    # Neovim plugins
    echo "--- Updating Neovim plugins ---"
    if command -v nvim > /dev/null 2>&1; then
        nvim --headless "+Lazy! sync" +qa
    fi

    # VSCode extensions
    echo "--- Updating VSCode extensions ---"
    if command -v code > /dev/null 2>&1; then
        while IFS= read -r extension || [ -n "$extension" ]; do
            if [[ ! -z "$extension" ]]; then
                code --install-extension "$extension" --force
            fi
        done < "${script_dir}/../vscode/extensions.txt"
    fi
}

function update_mac() {
    echo "Starting update for Mac..."
    script_dir="$(dirname "${BASH_SOURCE:-$0}")"

    # OS Packages
    if command -v brew > /dev/null 2>&1; then
        echo "Updating specific OS packages via brew..."
        source "${script_dir}/props/packages.conf"
        brew update
        # Install new versions of packages in the list
        for pkg in "${mac_packages[@]}"; do
            echo "Updating $pkg..."
            brew upgrade "$pkg" || echo "No update available for $pkg or failed."
        done
    fi

    # zsh plugins
    echo "--- Updating zsh plugins ---"
    source "${script_dir}/props/zsh_plugins.conf"
    for path in "${zsh_plugins[@]}"; do
        zsh_plugin=(${path[@]})
        plugin_dir=${zsh_plugin[1]}
        if [[ -d "${plugin_dir}/.git" ]]; then
            echo "Updating ${plugin_dir}..."
            git -C "${plugin_dir}" pull
        fi
    done

    # fzf
    echo "--- Updating fzf ---"
    if [[ -d "${HOME}/.fzf" ]]; then
        echo "Updating fzf..."
        git -C "${HOME}/.fzf" pull
        "${HOME}/.fzf/install" --all
    fi

    # Neovim plugins
    echo "--- Updating Neovim plugins ---"
    if command -v nvim > /dev/null 2>&1; then
        nvim --headless "+Lazy! sync" +qa
    fi

    # VSCode extensions
    echo "--- Updating VSCode extensions ---"
    if command -v code > /dev/null 2>&1; then
        while IFS= read -r extension || [ -n "$extension" ]; do
            if [[ ! -z "$extension" ]]; then
                code --install-extension "$extension" --force
            fi
        done < "${script_dir}/../vscode/extensions.txt"
    fi
}

function update_ubuntu() {
    echo "Starting update for Ubuntu..."
    script_dir="$(dirname "${BASH_SOURCE:-$0}")"

    # OS Packages
    echo "Updating specific OS packages via apt..."
    source "${script_dir}/props/packages.conf"
    sudo apt update
    for pkg in "${ubuntu_packages[@]}"; do
        echo "Updating $pkg..."
        sudo apt install --only-upgrade -y "$pkg" || echo "No update available for $pkg or failed."
    done

    # zsh plugins
    echo "--- Updating zsh plugins ---"
    source "${script_dir}/props/zsh_plugins.conf"
    for path in "${zsh_plugins[@]}"; do
        zsh_plugin=(${path[@]})
        plugin_dir=${zsh_plugin[1]}
        if [[ -d "${plugin_dir}/.git" ]]; then
            echo "Updating ${plugin_dir}..."
            git -C "${plugin_dir}" pull
        fi
    done

    # fzf
    echo "--- Updating fzf ---"
    if [[ -d "${HOME}/.fzf" ]]; then
        echo "Updating fzf..."
        git -C "${HOME}/.fzf" pull
        "${HOME}/.fzf/install" --all
    fi

    # Neovim plugins
    echo "--- Updating Neovim plugins ---"
    if command -v nvim > /dev/null 2>&1; then
        nvim --headless "+Lazy! sync" +qa
    fi

    # VSCode extensions
    echo "--- Updating VSCode extensions ---"
    if command -v code > /dev/null 2>&1; then
        while IFS= read -r extension || [ -n "$extension" ]; do
            if [[ ! -z "$extension" ]]; then
                code --install-extension "$extension" --force
            fi
        done < "${script_dir}/../vscode/extensions.txt"
    fi
}

function update() {
    script_dir="$(dirname "${BASH_SOURCE:-$0}")"
    source "${script_dir}/check_os.sh"

    OS=$(check_os)

    if [[ $OS == "Cygwin" ]]; then
        update_win
    elif [[ $OS == "Mac" ]]; then
        update_mac
    elif [[ $OS == "Ubuntu" ]]; then
        update_ubuntu
    else
        echo "Unsupported OS for package update: $OS"
        return 1
    fi

    echo "Update process completed!"
    return 0
}

# source実行か直接実行かの判定処理
_is_sourced=0
_SCRIPT_NAME="update.sh"

if [ -n "$BASH_VERSION" ]; then
    [ "${BASH_SOURCE[0]}" != "$0" ] && _is_sourced=1
elif [ -n "$ZSH_VERSION" ]; then
    case $ZSH_EVAL_CONTEXT in
        *:file) _is_sourced=1 ;;
    esac
else
    _basename_0=$(basename -- "$0" 2>/dev/null || echo "$0")
    if [ "$_basename_0" != "$_SCRIPT_NAME" ]; then
        _is_sourced=1
    fi
fi

if [ "$_is_sourced" -eq 0 ]; then
    set -euC
    set -o pipefail
    update
fi

unset _SCRIPT_NAME _is_sourced _basename_0
