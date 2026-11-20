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
      p="${p%%|*}"
      # 更新が無い場合も非 0 で終わるため失敗扱いにしない
      if winget upgrade --id "$p" -e --source winget --accept-package-agreements --accept-source-agreements >/dev/null 2>&1; then
        info "upgraded ${p}"
      else
        info "up-to-date ${p}"
      fi
    done
    _win_wezterm_nightly upgrade
    ;;
  mac)
    _brew_shellenv
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
  local entry p scope scope_args
  for entry in "${win_packages[@]}"; do
    IFS='|' read -r p scope <<<"$entry"
    if winget list --id "$p" -e >/dev/null 2>&1; then
      info "installed ${p}"
      continue
    fi
    scope_args=()
    [[ -z "$scope" ]] || scope_args=(--scope "$scope")
    winget install --id "$p" -e --source winget --accept-package-agreements --accept-source-agreements ${scope_args[@]+"${scope_args[@]}"} ||
      warn "${p} のインストールに失敗しました"
  done
  _win_wezterm_nightly install
  if ! has wsl.exe || ! wsl.exe --list --quiet >/dev/null 2>&1; then
    warn "WSL が見つかりません。管理者の PowerShell で 'wsl --install -d Ubuntu' を実行し、再起動してください"
  fi
}

# WezTerm の nightly を setup.exe から入れる。install は未導入のときだけ、upgrade は新しいビルドがあれば入れる。
# winget を通さないため、入れたビルドの SHA256 を記録して新しいビルドの有無を判定する
_win_wezterm_nightly() {
  local mode="$1"
  local state="${HOME}/.local/state/dotfiles/wezterm-nightly.sha256"
  local exe
  exe="$(cygpath -u "$PROGRAMFILES")/WezTerm/wezterm-gui.exe"
  if [[ "$mode" == install && -s "$state" && -x "$exe" ]]; then
    info "installed WezTerm nightly"
    return
  fi

  local expected
  if ! expected="$(curl -fsSL "${win_wezterm_nightly_url}.sha256")"; then
    warn "WezTerm nightly の SHA256 を取得できませんでした"
    return
  fi
  expected="${expected%% *}"
  if [[ -x "$exe" && -s "$state" && "$(<"$state")" == "$expected" ]]; then
    info "up-to-date WezTerm nightly"
    return
  fi
  # 起動中だとインストーラーがファイルを置き換えられず、/SUPPRESSMSGBOXES では WezTerm を強制終了しかねないため入れない
  if MSYS2_ARG_CONV_EXCL='*' tasklist.exe /FO CSV /NH | grep -qi '^"wezterm-gui\.exe"'; then
    warn "WezTerm が起動中のため nightly を入れられません。WezTerm を閉じてから再実行してください"
    return
  fi

  local tmp actual
  tmp="$(mktemp -d)"
  if ! curl -fsSL -o "${tmp}/setup.exe" "$win_wezterm_nightly_url"; then
    warn "WezTerm nightly のダウンロードに失敗しました"
    rm -rf "$tmp"
    return
  fi
  actual="$(sha256sum "${tmp}/setup.exe")"
  actual="${actual%% *}"
  # setup.exe と .sha256 は別々にアップロードされるため、アップロード中に取得すると一致しないことがある
  if [[ "$actual" != "$expected" ]]; then
    warn "WezTerm nightly の SHA256 が一致しません (期待値 ${expected}、実際 ${actual})。時間をおいて再実行してください"
    rm -rf "$tmp"
    return
  fi
  if MSYS2_ARG_CONV_EXCL='*' "${tmp}/setup.exe" /SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART; then
    mkdir -p "${state%/*}"
    printf '%s\n' "$expected" >"$state"
    info "installed WezTerm nightly"
  else
    warn "WezTerm nightly のインストールに失敗しました"
  fi
  rm -rf "$tmp"
}

# brew の PATH をこのプロセス内で通す。Homebrew のインストーラーは実行中のシェルの PATH を更新せず、
# bootstrap.sh が入れた直後や、~/.zprofile.local に brew shellenv を書いていない環境では PATH に無いため
_brew_shellenv() {
  local b
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$b" ]]; then
      eval "$("$b" shellenv)"
      return
    fi
  done
}

_mac_install() {
  _brew_shellenv
  if ! has brew; then
    # NONINTERACTIVE では sudo のパスワードを聞けずに失敗するため、先に認証しておく
    sudo -v || die "Homebrew のインストールには管理者のパスワードが必要です"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" ||
      die "Homebrew のインストールに失敗しました"
    _brew_shellenv
  fi

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

  # zsh/.zshenv は LANG=ja_JP.UTF-8 を使うが、Ubuntu の標準では生成されていない
  if locale -a 2>/dev/null | grep -qi '^ja_JP\.utf-\?8$'; then
    info "installed ja_JP.UTF-8 locale"
  else
    sudo locale-gen ja_JP.UTF-8 || warn "ja_JP.UTF-8 のロケールを生成できませんでした"
  fi

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
