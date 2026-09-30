# scripts

dotfiles のセットアップ・更新・リンク管理を行うスクリプト。入口は `scripts/dot.sh` の 1 本だけ。
Windows では Git Bash (MSYS2) から実行する。

## 使い方

```bash
git clone git@github.com:Nepenthes-1123/dotfiles.git ~/dotfiles
~/dotfiles/scripts/dot.sh setup
```

| コマンド | 内容 |
| --- | --- |
| `setup` | 新しい環境を構築する (OS のパッケージ → 非公開素材 → リンク → mise → zsh プラグイン → git のユーザー設定 → ログインシェルを zsh に切り替え → GitHub CLI のログイン → リンクの状態の確認)。新しい PC ではリポジトリ直下の `bootstrap.sh` / `bootstrap.ps1` から呼ばれる |
| `update` | OS のパッケージ・mise のツール・Neovim プラグイン・VSCode 拡張・非公開素材を更新し、zsh プラグインを固定タグに合わせる |
| `link` | `links.conf` のリンクを作成する。何度実行してもよい。既存の実ファイルは `<元の名前>.bak.<日時>` に退避する |
| `status` | 各リンクの状態を表示する。すべて正常なら終了コード 0 |
| `prune [-n\|--dry-run]` | dotfiles を指しているが `links.conf` に無いリンクと、壊れたリンクを削除する。`-n` を付けると削除せずに対象だけを表示する |
| `adopt <設定ファイル> <保存先>` | 既存の設定ファイルを dotfiles に移してリンクに置き換え、`links.conf` に追記する |
| `vscode-extensions` | `vscode/extensions.txt` の拡張をインストールする |
| `assets` | 非公開素材 (wezterm の背景アニメーション) を取得・更新する |

## 構成

| ファイル | 役割 |
| --- | --- |
| `dot.sh` | サブコマンドの振り分けと、setup / update の手順 |
| `links.conf` | リンクの一覧 (`dotfiles 内のパス \| 配置先 \| 対象`)。3 OS 共通。対象 (`gui` / `cli`、省略時は `cli`) で Windows 側と WSL の中のどちらでリンクするかを分ける |
| `packages.conf` | OS のパッケージマネージャーで入れるもの (winget / brew / apt) |
| `zsh_plugins.conf` | zsh プラグインと固定するタグ |
| `lib/common.sh` | ログ出力・OS 判定・OS ごとの配置先パス (`links.conf` の変数) |
| `lib/links.sh` | link / status / prune / adopt |
| `lib/packages.sh` | OS のパッケージのインストール・更新 |
| `lib/tools.sh` | mise・zsh プラグイン・Neovim プラグイン・VSCode 拡張・非公開素材・git のユーザー設定 |
| `tests/bootstrap.test.ps1` | `bootstrap.ps1` のテスト。Windows 固有の部分をモックにして pwsh (Linux / macOS でも可) で実行する: `pwsh -NoProfile -File scripts/tests/bootstrap.test.ps1` |

CLI ツール (ripgrep / gh / starship / fzf / herdr / neovim / node) は `packages.conf` ではなく `mise/config.toml` で管理する。

## 設定の追加

- 新しい設定ファイルをリンクする: `links.conf` に 1 行追加して `dot.sh link`。GUI アプリの設定なら 3 列目に `gui` を付ける。既存の設定ファイルを取り込むなら `dot.sh adopt`
- OS ごとに配置先が違う場合: `lib/common.sh` に変数を追加し、`PATH_VARS` にも登録する
- CLI ツールを追加する: `mise use -g <tool>` (`mise/config.toml` に追記される)
- zsh プラグインを更新する: `zsh_plugins.conf` のタグを書き換えて `dot.sh update`

`.gitignore` はホワイトリスト方式のため、新しく追加したファイルは `.gitignore` にも追記する。

`~/.zshenv` は dotfiles からリンクするため、rustup など `~/.zshenv` に追記するツールの設定は `~/.zshenv.local` に移す (`link` で退避された `~/.zshenv.bak.<日時>` から移す)。`~/.zshrc` 用の `~/.zshrc.local` と同じ扱い。

## Windows (WSL2) での使い方

Windows では、GUI アプリは Windows 側で、シェル・CLI ツールは WSL2 の中 (Ubuntu) で使う。
dotfiles は Windows 側と WSL の中にそれぞれ clone し、両方で `dot.sh setup` を実行する。

| 環境 | 担当 | 入れるもの | リンクするもの (`links.conf`) |
| --- | --- | --- | --- |
| Windows 側 (Git Bash) | GUI アプリ | WezTerm / VSCode / フォント / Git (winget) | 対象が `gui` の行 (WezTerm / VSCode) |
| WSL の中 (Ubuntu) | シェル・CLI ツール | zsh / git / mise (apt)、CLI ツール (mise) | 対象が `cli` の行 (zsh / git / Neovim など) |
| mac / Ubuntu | 両方 | すべて | すべて |

どちらで実行しているかは自動で判定する (`lib/common.sh` の `want_gui` / `want_cli`)。

### 初回の手順

管理者の PowerShell で `bootstrap.ps1` を実行する (手順はルートの [README](../README.md#windows))。
開発者モード・Git for Windows・WSL の導入、Windows 側と WSL の中の両方の `dot.sh setup` をまとめて行う。

WezTerm は WSL を見つけると WSL の中の zsh を開く (`wezterm/.wezterm/shell.lua`)。WSL が無い場合は Windows 側の zsh (MSYS2 など) を探す。

### 注意点

- Windows 側でシンボリックリンクを作るには開発者モードが必要。`MSYS=winsymlinks:nativestrict` を設定しているため、権限が無いとコピーで済まさずにエラーになる
- WSL の中の Neovim から Windows のクリップボードを使うには、Windows 側に `win32yank.exe` を入れて PATH に通す
- 以前 Windows 側 (MSYS2) で作ったシェル用のリンク (`~/.zshrc` など) は、Windows 側の `links.conf` の対象外になる。
  不要になったら Windows 側で `dot.sh prune -n` で確認してから `dot.sh prune` で削除する
