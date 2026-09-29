#!/usr/bin/env bash

function install_win() {
    if ! command -v winget > /dev/null 2>&1; then
        echo "winget is not installed or not available in PATH. Please install winget manually, then rerun setup."
        return 0
    fi

    script_dir="$(dirname "${BASH_SOURCE:-$0}")"
    source "${script_dir}/props/packages.conf"

    for pkg in "${win_packages[@]}"; do
        if ! winget list --id "$pkg" > /dev/null 2>&1; then
            echo "Installing $pkg..."
            winget install --id "$pkg" -e --source winget || echo "Warning: Failed to install $pkg. Skipping..."
        else
            echo "$pkg is already installed."
        fi
    done

    # winget でインストールしたコマンドは新しいシェルを開くまで PATH に反映されないため、
    # 後続の mise install 用に winget のコマンドリンク置き場をこのプロセスの PATH に通す
    if [[ -n "${LOCALAPPDATA-}" ]]; then
        local winget_links
        winget_links="$(cygpath -u "${LOCALAPPDATA}")/Microsoft/WinGet/Links"
        if [[ -d "$winget_links" ]]; then
            export PATH="${winget_links}:${PATH}"
        fi
    fi
}

function install_mac() {
    # install homebrew
    if ! type brew > /dev/null 2>&1; then
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || echo "Warning: Failed to install Homebrew."

        # インストーラーはシェルのPATHを自動更新しないため、このプロセス内で明示的に通す
        if [[ -x /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ -x /usr/local/bin/brew ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi

    script_dir="$(dirname "${BASH_SOURCE:-$0}")"
    source "${script_dir}/props/packages.conf"

    for pkg in "${mac_packages[@]}"; do
        if ! type "$pkg" > /dev/null 2>&1 && ! brew list --cask "$pkg" > /dev/null 2>&1; then
            echo "Installing $pkg..."
            brew install "$pkg" || echo "Warning: Failed to install $pkg. Skipping..."
        else
            echo "$pkg is already installed."
        fi
    done
}

function install_ubuntu() {
    sudo apt update || echo "Warning: apt update failed."

    script_dir="$(dirname "${BASH_SOURCE:-$0}")"
    source "${script_dir}/props/packages.conf"

    # 特殊なセットアップが必要なパッケージの処理
    # wezterm
    if ! type wezterm > /dev/null 2>&1; then
        echo "Setting up wezterm repository..."
        curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg || echo "Warning: Failed to add wezterm GPG key."
        echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
        sudo apt update || echo "Warning: apt update failed after adding wezterm repo."
    fi

    # vscode
    if ! type code > /dev/null 2>&1; then
        echo "Setting up VSCode repository..."
        sudo apt install -y wget gpg || echo "Warning: Failed to install wget or gpg."
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg || echo "Warning: Failed to download microsoft GPG key."
        if [[ -f microsoft.gpg ]]; then
            sudo install -D -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/microsoft.gpg
            rm -f microsoft.gpg
        fi
        echo "Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/microsoft.gpg" | sudo tee /etc/apt/sources.list.d/vscode.sources
        sudo apt update || echo "Warning: apt update failed after adding vscode repo."
    fi

    # TODO: JetBrains Mono Nerd Fontのインストールを追記
    if [[ ! -d ~/.local/share/fonts/JetBrainsMono ]] || [[ -z "$(ls -A ~/.local/share/fonts/JetBrainsMono 2>/dev/null)" ]]; then
        echo "Installing JetBrains Mono Nerd Font..."
        sudo apt install -y unzip fontconfig || echo "Warning: Failed to install unzip/fontconfig."

        # フォント用のディレクトリを作成
        mkdir -p ~/.local/share/fonts/JetBrainsMono

        # Nerd Fontsの公式リポジトリからJetBrains MonoのZIPをダウンロード (v3.2.1の例)
        local font_tmpdir
        font_tmpdir="$(mktemp -d)"
        wget -P "$font_tmpdir" https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip

        # ディレクトリに展開
        unzip "${font_tmpdir}/JetBrainsMono.zip" -d ~/.local/share/fonts/JetBrainsMono

        # 不要になった一時ディレクトリを削除
        rm -rf "$font_tmpdir"

        # フォントキャッシュを更新してシステムに認識させる
        fc-cache -fv
    else
        echo "JetBrains Mono Nerd Font is already installed."
    fi

    # mise
    # Ubuntu 公式リポジトリには無いため、mise 公式の apt リポジトリを追加する
    if ! type mise > /dev/null 2>&1; then
        echo "Setting up mise repository..."
        type -p curl > /dev/null || sudo apt install curl -y
        sudo install -dm 755 /etc/apt/keyrings
        curl -fsSL https://mise.jdx.dev/gpg-key.pub | sudo tee /etc/apt/keyrings/mise-archive-keyring.asc > /dev/null || echo "Warning: Failed to add mise GPG key."
        echo 'deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.asc] https://mise.jdx.dev/deb stable main' | sudo tee /etc/apt/sources.list.d/mise.list
        sudo apt update || echo "Warning: apt update failed after adding mise repo."
    fi

    for pkg in "${ubuntu_packages[@]}"; do
        if ! type "$pkg" > /dev/null 2>&1; then
            echo "Installing $pkg..."
            sudo apt install -y "$pkg" || echo "Warning: Failed to install $pkg. Skipping..."
        else
            echo "$pkg is already installed."
        fi
    done
}

function install_zsh_plugins() {
    script_dir="$(dirname "${BASH_SOURCE:-$0}")"
    source "${script_dir}/props/zsh_plugins.conf"

    if [[ ! -d "${HOME}/.zsh" ]]; then
        mkdir -p "${HOME}/.zsh" || echo "Warning: Failed to create ${HOME}/.zsh directory."
    fi

    for path in "${zsh_plugins[@]}"; do
        zsh_plugin=(${path[@]})
        if [[ ! -d ${zsh_plugin[1]} ]]; then
            echo "Cloning ${zsh_plugin[0]}..."
            git clone ${zsh_plugin[0]} ${zsh_plugin[1]} || echo "Warning: Failed to clone ${zsh_plugin[0]}. Skipping..."
        else
            echo "Cloned file already exists: ${zsh_plugin[1]}"
        fi
    done
}

function install_mise_tools() {
    # ~/.config/mise (mise/config.toml) がリンクされた後に実行する
    if ! command -v mise > /dev/null 2>&1; then
        echo "Warning: mise is not available in PATH. Open a new shell and run 'mise install' manually."
        return 0
    fi

    echo "Installing tools via mise..."
    mise install || echo "Warning: Failed to install some tools via mise. Please run 'mise install' manually."
}

function install() {
    script_dir="$(dirname "${BASH_SOURCE:-$0}")"
    source "${script_dir}/check_os.sh"

    OS=$(check_os)

    if [[ $OS == "Cygwin" ]]; then
        install_win
    elif [[ $OS == "Mac" ]]; then
        install_mac
    elif [[ $OS == "CentOS" ]]; then
        # sudo dnf install -y zsh
        :
    elif [[ $OS == "Amazon Linux" ]]; then
        # sudo yum install -y zsh
        :
    elif [[ $OS == "Ubuntu" ]]; then
        install_ubuntu
    else
        echo "Unsupported OS: $OS"
        return 1
    fi

    install_zsh_plugins

    return 0
}

# source実行か直接実行かの判定処理
_is_sourced=0
_SCRIPT_NAME="install.sh"

if [ -n "$BASH_VERSION" ]; then
    # Bash環境の場合の判定
    [ "${BASH_SOURCE[0]}" != "$0" ] && _is_sourced=1
elif [ -n "$ZSH_VERSION" ]; then
    # Zsh環境の場合の判定
    case $ZSH_EVAL_CONTEXT in
        *:file) _is_sourced=1 ;;
    esac
else
    # その他のPOSIX互換シェル (dash, ash, sh など) の場合
    # 実行時の $0 のファイル名が、定義したスクリプト名と一致するかで判定
    _basename_0=$(basename -- "$0" 2>/dev/null || echo "$0")
    if [ "$_basename_0" != "$_SCRIPT_NAME" ]; then
        _is_sourced=1
    fi
fi

if [ "$_is_sourced" -eq 0 ]; then
    set -euC
    set -o pipefail
    install
fi

# 判定に使用した内部変数をクリーンアップ (source先の環境を汚さないため)
unset _SCRIPT_NAME _is_sourced _basename_0
