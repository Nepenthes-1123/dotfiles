# !/bin/sh
set -euC
set -o pipefail

function install_win() {
    # install zsh
    : # Windows環境でのインストールが複雑すぎるため

    # install wezterm
    if ! winget list wezterm > /dev/null 2>&1; then
        winget install --id wez.wezterm -e --source winget
    fi

    # install vscode
    if ! winget list vscode > /dev/null 2>&1; then
        winget install --id Microsoft.VisualStudioCode -e --source winget
    fi

    # install git
    if ! winget list git > /dev/null 2>&1; then
        winget install --id Git.Git -e --source winget
    fi
}

function install_mac() {
    # install homebrew
    if ! type brew > /dev/null 2>&1; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # install zsh
    : # 現在のMacOSはzshがデフォルトシェルなので、特にインストールは必要ない

    # install wezterm
    if ! type wezterm > /dev/null 2>&1; then
        brew install --cask wezterm
    fi

    # install vscode
    if ! type code > /dev/null 2>&1; then
        brew install --cask visual-studio-code
    fi

    # install git
    if ! type git > /dev/null 2>&1; then
        brew install git
    fi
}

function install_ubuntu() {
    sudo apt update

    # install zsh
    if ! type zsh > /dev/null 2>&1; then
        sudo apt install -y zsh
    fi

    # install wezterm
    if ! type wezterm > /dev/null 2>&1; then
        # GPGキーを追加
        curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
        # リポジトリを追加
        echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
        # インストール
        sudo apt install wezterm
    fi

    # install vscode
    if ! type code > /dev/null 2>&1; then
        sudo apt update
        sudo apt install -y wget gpg

        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
        sudo install -D -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/microsoft.gpg
        rm -f microsoft.gpg

        echo "Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/microsoft.gpg" | sudo tee /etc/apt/sources.list.d/vscode.sources

        sudo apt install -y code
    fi

    # install git
    if ! type git > /dev/null 2>&1; then
        sudo apt install -y git
    fi
}

function install_zsh_plugins() {
    script_dir="$(dirname "${BASH_SOURCE:-$0}")"
    source "${script_dir}/props/zsh_plugins.conf"

    if [[ ! -d "${HOME}/.zsh" ]]; then
        mkdir "${HOME}/.zsh"
    fi

    for path in "${zsh_plugins[@]}"; do
        zsh_plugin=(${path[@]})
        git clone ${zsh_plugin[0]} ${zsh_plugin[1]}
    done
}

function install_fzf() {
    git clone --depth 1 https://github.com/junegunn/fzf.git ${HOME}/.fzf
    ${HOME}/.fzf/install
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

    install_fzf
    install_zsh_plugins

    return 0
}

if [[ "${BASH_SOURCE:-$0}" == "${0}" ]]; then
    install
fi
