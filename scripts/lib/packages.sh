# shellcheck shell=bash source-path=SCRIPTDIR
# OS のパッケージマネージャーによるインストール・更新 (scripts/packages.conf)

# shellcheck source=../packages.conf
source "${SCRIPTS_DIR}/packages.conf"

packages_install() {
  case "$OS" in
  windows) _win_install ;;
  mac) _mac_install ;;
  ubuntu | wsl) _ubuntu_install ;;
  esac
}

packages_upgrade() {
  local p
  case "$OS" in
  windows)
    for p in "${win_packages[@]}"; do
      # 更新が無い場合も非 0 で終わるため失敗扱いにしない
      if winget upgrade --id "$p" -e --source winget --accept-package-agreements --accept-source-agreements >/dev/null 2>&1; then
        info "upgraded ${p}"
      else
        info "up-to-date ${p}"
      fi
    done
    ;;
  mac)
    brew update
    for p in "${mac_packages[@]}"; do
      brew upgrade "$p" || warn "${p} の更新に失敗しました"
    done
    ;;
  ubuntu | wsl)
    _ubuntu_select
    sudo apt-get update
    sudo apt-get install --only-upgrade -y "${UBUNTU_PKGS[@]}" || warn "apt パッケージの更新に失敗しました"
    ;;
  esac
}

_win_install() {
  has winget || die "winget が見つかりません。App Installer をインストールしてから再実行してください"
  local p
  for p in "${win_packages[@]}"; do
    if winget list --id "$p" -e >/dev/null 2>&1; then
      info "installed ${p}"
      continue
    fi
    winget install --id "$p" -e --source winget --accept-package-agreements --accept-source-agreements ||
      warn "${p} のインストールに失敗しました"
  done
  if ! has wsl.exe || ! wsl.exe --list --quiet >/dev/null 2>&1; then
    warn "WSL が見つかりません。管理者の PowerShell で 'wsl --install -d Ubuntu' を実行し、再起動してください"
  fi
}

_mac_install() {
  if ! has brew; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" ||
      die "Homebrew のインストールに失敗しました"
  fi
  # インストーラーは現在のシェルの PATH を更新しないため、このプロセス内で通す
  local b
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$b" ]]; then
      eval "$("$b" shellenv)"
      break
    fi
  done

  local p
  for p in "${mac_packages[@]}"; do
    if brew list "$p" >/dev/null 2>&1; then
      info "installed ${p}"
      continue
    fi
    brew install "$p" || warn "${p} のインストールに失敗しました"
  done
}

# この環境で入れる apt パッケージ (UBUNTU_PKGS) とリポジトリ (UBUNTU_REPOS) を決める。
# WSL の中では GUI アプリを入れない
_ubuntu_select() {
  UBUNTU_PKGS=("${ubuntu_packages[@]}")
  UBUNTU_REPOS=("${ubuntu_apt_repos[@]}")
  if want_gui; then
    UBUNTU_PKGS+=("${ubuntu_gui_packages[@]}")
    UBUNTU_REPOS+=("${ubuntu_gui_apt_repos[@]}")
  fi
}

_ubuntu_install() {
  _ubuntu_select
  sudo apt-get update
  sudo apt-get install -y curl gpg unzip fontconfig

  local repo file keyring key_url content added=0
  for repo in "${UBUNTU_REPOS[@]}"; do
    IFS='|' read -r file keyring key_url content <<<"$repo"
    [[ ! -e "/etc/apt/sources.list.d/${file}" ]] || continue
    info "apt リポジトリを追加: ${file}"
    curl -fsSL "$key_url" | gpg --dearmor | sudo tee "/usr/share/keyrings/${keyring}" >/dev/null
    sudo chmod 644 "/usr/share/keyrings/${keyring}"
    printf '%b\n' "$content" | sudo tee "/etc/apt/sources.list.d/${file}" >/dev/null
    added=1
  done
  [[ "$added" -eq 0 ]] || sudo apt-get update

  local p
  for p in "${UBUNTU_PKGS[@]}"; do
    if dpkg -s "$p" >/dev/null 2>&1; then
      info "installed ${p}"
      continue
    fi
    sudo apt-get install -y "$p" || warn "${p} のインストールに失敗しました"
  done

  # WSL の中ではフォントは Windows 側 (winget) で入れる
  if want_gui; then
    _ubuntu_install_nerd_font
  fi
}

_ubuntu_install_nerd_font() {
  local dir="${HOME}/.local/share/fonts/${ubuntu_nerd_font}"
  if [[ -n "$(ls -A "$dir" 2>/dev/null)" ]]; then
    info "installed ${ubuntu_nerd_font} Nerd Font"
    return
  fi
  local tmp url
  tmp="$(mktemp -d)"
  url="https://github.com/ryanoasis/nerd-fonts/releases/download/${ubuntu_nerd_font_version}/${ubuntu_nerd_font}.zip"
  if curl -fsSL -o "${tmp}/font.zip" "$url" && mkdir -p "$dir" && unzip -q "${tmp}/font.zip" -d "$dir"; then
    fc-cache -f "$dir" >/dev/null
    info "installed ${ubuntu_nerd_font} Nerd Font"
  else
    warn "${ubuntu_nerd_font} Nerd Font のインストールに失敗しました"
  fi
  rm -rf "$tmp"
}
