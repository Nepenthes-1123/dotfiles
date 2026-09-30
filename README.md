# dotfiles

macOS・Ubuntu・Windows (WSL2) で共通に使う設定ファイル一式。

- 設定ファイルは生のファイルのまま置き、各 OS の配置先にシンボリックリンクで配る
- CLI ツールは mise、GUI アプリ・フォントは OS のパッケージマネージャーで入れる
- セットアップ・更新・リンク管理の入口は `scripts/dot.sh` の 1 本だけ

## 構成

| ディレクトリ | 内容 | 詳細 |
| --- | --- | --- |
| `zsh/` | `.zshrc` と `.zsh.d/` (読み込み順は `.zsh.d/priorities.conf`) | |
| `nvim/` | Neovim (v0.12, `vim.pack` + Mason) | [nvim/README.md](nvim/README.md) |
| `wezterm/` | WezTerm (Windows では WSL の zsh を開く) | [wezterm/WEZTERM_SETUP.md](wezterm/WEZTERM_SETUP.md) |
| `vscode/` | VSCode の settings / keybindings / snippets / 拡張の一覧 | |
| `git/` | `.gitconfig` (共通) と `.gitconfig.private` (個人用のユーザー設定) | |
| `starship/` | プロンプト | |
| `herdr/` | herdr (エージェントマルチプレクサ) | |
| `mise/` | mise で入れる CLI ツールの一覧 (`config.toml`) | |
| `wsl/` | WSL2 の `.wslconfig` の雛形 (リンクせずコピーして使う) | [scripts/README.md](scripts/README.md#windows-wsl2-での使い方) |
| `scripts/` | セットアップ・更新・リンク管理 (`dot.sh`) | [scripts/README.md](scripts/README.md) |

## 役割分担

| 担当 | 管理するもの | 設定 |
| --- | --- | --- |
| OS のパッケージマネージャー (brew / winget / apt) | GUI アプリ (WezTerm / VSCode)・フォント・git・zsh・mise 本体 | `scripts/packages.conf` |
| mise | CLI ツール (neovim / node / ripgrep / gh / starship / fzf / herdr)。バージョンは固定せず常に最新 | `mise/config.toml` |
| `scripts/dot.sh` | 上の 2 つの呼び出し・シンボリックリンク・zsh プラグイン・VSCode 拡張・git のユーザー設定 | `scripts/links.conf` / `scripts/zsh_plugins.conf` |
| Neovim | プラグイン (`vim.pack`)・LSP / フォーマッター (Mason) | `nvim/` |

Windows では GUI アプリだけを Windows 側に置き、シェルと CLI ツールは WSL2 の中 (Ubuntu) で使う。
`dot.sh` は実行した環境 (mac / ubuntu / Windows 側 / WSL の中) を判定し、その環境の担当分だけを処理する。

## セットアップ

新しい PC では bootstrap スクリプトを 1 行実行する。git の導入・clone・`scripts/dot.sh setup` までをまとめて行う。
既に clone してある場合は `scripts/dot.sh setup` を直接実行してもよい (中身は同じ)。

`setup` は次の順に進む。途中でパスワードや選択肢を対話で聞く。

1. OS のパッケージ (brew / winget / apt) → 2. 非公開素材 → 3. シンボリックリンク → 4. mise の CLI ツール →
5. zsh プラグイン → 6. git のユーザー設定 → 7. ログインシェルを zsh に切り替え (`chsh`) →
8. GitHub CLI のログイン (任意) → 9. リンクの状態の確認

### macOS / Ubuntu

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Nepenthes-1123/dotfiles/main/bootstrap.sh)"
```

- macOS では Homebrew (Xcode Command Line Tools = git を含む) を先に入れる
- Ubuntu では apt で git を入れる
- setup が対話で入力を受け付けるため、`curl ... | bash` ではなく上の形で実行する

### Windows

管理者の PowerShell で次を実行する。

```powershell
irm https://raw.githubusercontent.com/Nepenthes-1123/dotfiles/main/bootstrap.ps1 | iex
```

1. 1 回目は開発者モード・Git for Windows・WSL (Ubuntu) を入れて止まる
2. 再起動し、スタートメニューから Ubuntu を開いてユーザー名とパスワードを作成する
3. 同じコマンドをもう一度実行する。Windows 側の setup (WezTerm / VSCode / フォントと、その設定のリンク) と、
   WSL の中の setup (zsh・mise・CLI ツールとその設定) を続けて行う
4. 管理者でない Git Bash で、開発者モードでシンボリックリンクを作れることを確認する
   (bootstrap から起動した Git Bash は管理者権限で動くため、開発者モードが無くてもリンクを作れてしまう)

   ```bash
   MSYS=winsymlinks:nativestrict ln -sf ~/dotfiles/README.md /tmp/devmode-check && ls -l /tmp/devmode-check && rm -f /tmp/devmode-check
   ```

   失敗する場合は、設定 → システム → 開発者向け で開発者モードが有効か確認し、再起動する

`%UserProfile%\.wslconfig` は雛形 (`wsl/.wslconfig.example`) からコピーされるので、PC に合わせてメモリの上限などを変える。
作業用のリポジトリは WSL の中 (`~/` 以下) に clone する (Windows 側のファイルを `/mnt/c/...` から扱うと遅い)。

### セットアップの後

1. 新しいシェルを開く (ログインシェルの切り替えと mise のツールは新しいシェルから反映される)
2. `nvim` を起動する。初回はプラグインのインストール確認が出て、その後 Mason が LSP を入れる

### 環境変数

| 変数 | 対象 | 内容 |
| --- | --- | --- |
| `DOTFILES_BRANCH` | 両方 | clone するブランチ (既定: `main`)。PR のブランチを試すときに使う |
| `DOTFILES_DIR` | `bootstrap.sh` | clone 先 (既定: `~/dotfiles`)。Windows 側は `%UserProfile%\dotfiles` 固定 |
| `DOTFILES_WSL_DISTRO` | `bootstrap.ps1` | 使う WSL のディストリビューション (既定: `Ubuntu`) |

## 日常の操作

| やりたいこと | コマンド |
| --- | --- |
| すべて更新する | `scripts/dot.sh update` |
| CLI ツールを追加する | `mise use -g <ツール名>` (`mise/config.toml` に追記されるのでコミットする) |
| 設定ファイルを新しくリンクする | `scripts/links.conf` に 1 行追加して `scripts/dot.sh link` (既存のファイルを取り込むなら `scripts/dot.sh adopt`) |
| リンクの状態を確認する | `scripts/dot.sh status` |
| 不要なリンクを消す | `scripts/dot.sh prune -n` で確認してから `scripts/dot.sh prune` |

コマンドの一覧と、リンク・パッケージの設定の書き方は [scripts/README.md](scripts/README.md) を参照。

## 注意

- `.gitignore` はホワイトリスト方式。新しく追加したファイルは `.gitignore` にも追記しないと追跡されない
- 改行コードは `.gitattributes` で LF に固定している
