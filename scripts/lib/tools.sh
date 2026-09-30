# shellcheck shell=bash
# パッケージマネージャー以外で入れるもの: mise のツール・zsh プラグイン・Neovim プラグイン・
# VSCode 拡張・非公開素材・git のユーザー設定

# --- mise (mise/config.toml, ~/.config/mise にリンク済みであること) ---

mise_install() {
  if ! has mise; then
    warn "mise が見つかりません。新しいシェルを開いて 'mise install' を実行してください"
    return 0
  fi
  mise install || warn "mise でのインストールに一部失敗しました。'mise install' を再実行してください"
}

# mise で入れたツールを、このプロセス (setup の残りの手順) から使えるようにする
mise_activate_shims() {
  has mise || return 0
  eval "$(mise activate bash --shims)"
}

mise_upgrade() {
  has mise || return 0
  mise upgrade || warn "mise でのツール更新に一部失敗しました"
}

# --- zsh プラグイン (scripts/zsh_plugins.conf) ---

zsh_plugins_sync() {
  local line name url ref dir
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    [[ -n "$(trim "$line")" ]] || continue
    IFS='|' read -r name url ref <<<"$line"
    name="$(trim "$name")"
    url="$(trim "$url")"
    ref="$(trim "$ref")"
    dir="${HOME}/.zsh/${name}"

    if [[ ! -d "${dir}/.git" ]]; then
      git clone --quiet "$url" "$dir" || {
        warn "${name} の clone に失敗しました"
        continue
      }
    fi
    # 指定のタグ・コミットが手元に無ければ取得する
    git -C "$dir" rev-parse -q --verify "${ref}^{commit}" >/dev/null ||
      git -C "$dir" fetch --quiet --tags origin ||
      warn "${name} の fetch に失敗しました"
    if git -C "$dir" -c advice.detachedHead=false checkout --quiet "$ref"; then
      info "${name} @ ${ref}"
    else
      warn "${name} を ${ref} に切り替えられませんでした"
    fi
  done <"${SCRIPTS_DIR}/zsh_plugins.conf"
}

# --- Neovim プラグイン (vim.pack) ---

nvim_plugins_update() {
  has nvim || return 0
  # force = true で確認バッファを出さずに更新し、nvim-pack-lock.json を書き換える
  nvim --headless "+lua vim.pack.update(nil, { force = true })" +qa ||
    warn "Neovim プラグインの更新に失敗しました"
}

# --- VSCode 拡張 (vscode/extensions.txt) ---

vscode_extensions_install() {
  if ! has code; then
    warn "code コマンドが見つからないため VSCode 拡張のインストールを省略します"
    return 0
  fi
  local ext
  while IFS= read -r ext || [[ -n "$ext" ]]; do
    ext="$(trim "$ext")"
    [[ -n "$ext" ]] || continue
    code --install-extension "$ext" --force >/dev/null || warn "${ext} のインストールに失敗しました"
  done <"${DOT_DIR}/vscode/extensions.txt"
}

# --- 非公開素材 (wezterm の背景アニメーション) ---

assets_fetch() {
  # 素材は配布元のガイドラインが再配布を想定していないため、公開リポジトリである
  # dotfiles 本体には含めず非公開リポジトリで管理している。
  # 取得できない環境では背景アニメーションが省略されるだけで、他の設定には影響しない。
  local dir="${DOT_DIR}/wezterm/.wezterm/assets"
  local url="git@github.com:Nepenthes-1123/dotfiles-assets.git"
  # 新しい PC では ~/.ssh/known_hosts が空で、ssh がホスト鍵の確認を求めて入力待ちになる。
  # その確認は下の 2>/dev/null で見えないため、画面に何も出ないまま止まってしまう。
  # 未知のホスト鍵は確認なしで登録し (accept-new)、鍵が無いなどで認証できなければ待たずに失敗させる (BatchMode)
  local ssh_cmd="ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10"
  if [[ -d "${dir}/.git" ]]; then
    GIT_SSH_COMMAND="$ssh_cmd" git -C "$dir" pull --quiet --ff-only || warn "素材の更新に失敗しました"
  elif ! GIT_SSH_COMMAND="$ssh_cmd" git clone --quiet "$url" "$dir" 2>/dev/null; then
    info "素材を取得できないため、背景アニメーションは省略されます"
  fi
}

# --- git のユーザー設定 (~/.gitconfig.local。git/.gitconfig から include される) ---

gitconfig_local_setup() {
  local dst="${HOME}/.gitconfig.local"
  if [[ -e "$dst" || -L "$dst" ]]; then
    info "exists   ${dst}"
    return 0
  fi
  local choice name email
  echo "git のユーザー設定を選んでください"
  echo "  1) 個人用 (git/.gitconfig.private をリンク)"
  echo "  2) 名前とメールアドレスを入力して作成"
  echo "  3) スキップ"
  # 標準入力が無い (非対話) 場合はスキップ扱いにする
  read -r -p "> " choice || choice=3
  case "$choice" in
  1)
    ln -s "${DOT_DIR}/git/.gitconfig.private" "$dst"
    info "linked   ${dst}"
    ;;
  2)
    read -r -p "user.name: " name
    read -r -p "user.email: " email
    printf '[user]\n\tname = %s\n\temail = %s\n' "$name" "$email" >"$dst"
    info "created  ${dst}"
    ;;
  *) info "skip     ${dst}" ;;
  esac
}

# --- ログインシェル (zsh に切り替える) ---

login_shell_setup() {
  has zsh || return 0
  local user current zsh_path
  user="$(id -un)"
  if [[ "$OS" == mac ]]; then
    current="$(dscl . -read "/Users/${user}" UserShell 2>/dev/null | awk '{print $2}')"
  else
    current="$(getent passwd "$user" | cut -d: -f7)"
  fi
  if [[ "$(basename "${current:-}")" == zsh ]]; then
    info "ok       ログインシェルは zsh (${current})"
    return 0
  fi
  zsh_path="$(command -v zsh)"
  if ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
    warn "${zsh_path} が /etc/shells に無いため切り替えられません"
    return 0
  fi
  info "ログインシェルを ${current:-不明} から ${zsh_path} に切り替えます (パスワードを聞かれます)"
  chsh -s "$zsh_path" || warn "切り替えに失敗しました。後で 'chsh -s ${zsh_path}' を実行してください"
}

# --- GitHub CLI のログイン (octo.nvim で使う) ---

gh_login() {
  has gh || return 0
  if gh auth status >/dev/null 2>&1; then
    info "ok       GitHub CLI にログイン済み"
    return 0
  fi
  local answer
  # 標準入力が無い (非対話) 場合はスキップ扱いにする
  read -r -p "GitHub CLI にログインしますか (ブラウザが開きます) [y/N] " answer || answer=n
  case "$answer" in
  y | Y | yes) gh auth login || warn "ログインに失敗しました。後で 'gh auth login' を実行してください" ;;
  *) info "skip     後で 'gh auth login' を実行してください" ;;
  esac
}
