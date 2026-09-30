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

### macOS / Ubuntu

```bash
git clone git@github.com:Nepenthes-1123/dotfiles.git ~/dotfiles
~/dotfiles/scripts/dot.sh setup
```

### Windows

1. 管理者の PowerShell で `wsl --install -d Ubuntu` を実行して再起動する
2. `wsl/.wslconfig.example` を `%UserProfile%\.wslconfig` にコピーし、PC に合わせてメモリの上限などを変える
3. Windows 側 (Git Bash) で clone して `scripts/dot.sh setup` を実行する (GUI アプリと WezTerm / VSCode の設定)
4. WSL の中で clone して `scripts/dot.sh setup` を実行する (zsh・mise・CLI ツールとその設定)

Windows 側でシンボリックリンクを作るには開発者モードが必要。

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
