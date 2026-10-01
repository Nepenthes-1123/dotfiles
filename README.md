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

どの OS でも、`dot.sh setup` は既定のシェルを変えない。zsh への切り替え (`chsh`) は手動で行う。

### macOS

```bash
xcode-select --install          # git が入る (git を初めて実行したときのダイアログからでもよい)
git clone https://github.com/Nepenthes-1123/dotfiles.git ~/dotfiles
~/dotfiles/scripts/dot.sh setup # Homebrew が無ければ自動で入れる
```

zsh は macOS の既定のシェルなので切り替えは不要。

### Ubuntu

```bash
sudo apt update && sudo apt install -y git
git clone https://github.com/Nepenthes-1123/dotfiles.git ~/dotfiles
~/dotfiles/scripts/dot.sh setup # 途中で sudo のパスワードを聞かれる
chsh -s "$(which zsh)"          # 既定のシェルを zsh にする (再ログイン後に反映)
```

### Windows

Windows 側では GUI アプリとその設定だけを、WSL の中ではシェルと CLI ツールを扱う。dotfiles はそれぞれに clone する。

1. 管理者の PowerShell で `wsl --install -d Ubuntu` を実行して再起動する
2. 設定 → システム → 開発者向け で **開発者モード** を有効にする (Windows 側でシンボリックリンクを作るのに必要)
3. PowerShell で `winget install Git.Git` を実行する (clone と `dot.sh` の実行に使う Git Bash が入る)
4. `wsl/.wslconfig.example` を `%UserProfile%\.wslconfig` にコピーし、PC に合わせてメモリの上限などを変える
5. Git Bash で次を実行する (WezTerm / VSCode / フォントと、その設定のリンク)

   ```bash
   git clone https://github.com/Nepenthes-1123/dotfiles.git ~/dotfiles
   ~/dotfiles/scripts/dot.sh setup
   ```

6. WSL の中 (Ubuntu) で、上の「Ubuntu」と同じ手順を実行する (zsh・mise・CLI ツールとその設定)。
   WezTerm は WSL の既定のシェルを開くため、`chsh` で zsh に切り替えておく。
   作業用のリポジトリも WSL の中 (`~/` 以下) に clone する (Windows 側のファイルを `/mnt/c/...` から扱うと遅い)

### セットアップの後

1. 新しいシェルを開く (mise で入れたツールは新しいシェルから使える)
2. `scripts/dot.sh status` ですべて `ok` になっていることを確認する
3. `gh auth login` で GitHub CLI にログインする (octo.nvim で使う)
4. `nvim` を起動する。初回はプラグインのインストール確認が出て、その後 Mason が LSP を入れる

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
