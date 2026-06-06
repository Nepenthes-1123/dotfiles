# dotfiles

新しい PC で開発環境を素早くセットアップするためのドットファイル集です。複数の OS（Windows、macOS、Linux）に対応しており、シンボリックリンクを使ってリポジトリ内の設定を各ツールの標準位置にリンクします。

## 📁 ディレクトリ構成

### `scripts/` — セットアップスクリプト

新しい PC での環境構築を自動化するスクリプトたち：

- **`setup.sh`** — メインのセットアップスクリプト。以下を実行します：
  - 必要なツールをインストール（`install.sh`）
  - 設定ファイルをシンボリックリンク（`symlink()` 関数）
  - Git ユーザー設定の選択・作成

- **`install.sh`** — OS ごとに必要なツールをインストール：
  - **Windows（winget 使用）**: wezterm, VS Code, Git
  - **macOS（Homebrew 使用）**: wezterm, VS Code, Git, Homebrew
  - **Ubuntu**: zsh, wezterm, VS Code, Git
  - **全 OS 共通**: fzf, zsh プラグイン（zsh-autosuggestions, zsh-syntax-highlighting, fzf-tab）

- **`check_os.sh`** — OS 判定スクリプト（Darwin / Linux / CYGWIN / MINGW）

- **`add_symlink.sh`** — 既存のシンボリックリンク機能に加えて、追加のリンクを設定する場合に使用

- **`props/`** — OS 別の設定ファイル：
  - `symlink_win_list.conf` — Windows 用シンボリックリンク設定
  - `symlink_mac_list.conf` — macOS 用シンボリックリンク設定
  - `symlink_ubuntu_list.conf` — Ubuntu 用シンボリックリンク設定
  - `zsh_plugins.conf` — インストールする zsh プラグインのリスト

### `zsh/` — Zsh 設定

- **`.zshrc`** — Zsh メイン設定ファイル
  - 言語・ロケール設定（日本語対応）
  - `.zsh.d` 内の設定ファイルを優先度順に自動読み込み
  - PATH、環境変数、ターミナルオプション、タイトルバー設定など
  - `.zshrc.local` が存在する場合は読み込み（個人用設定）

- **`.zsh.d/`** — 分割された機能別設定ファイル
  - 読み込みプロセス：`.zshrc` → `priorities.conf` 読み込み → 指定順序でファイル読み込み
  - `priorities.conf` — 読み込み順序の指定
  - `plugins.zsh` — zsh プラグイン（fzf-tab, zsh-autosuggestions など）の読み込み設定
  - `alias.zsh` — よく使うコマンドのエイリアス定義
  - `completion.zsh` — 補完機能設定
  - `prompt.zsh` — プロンプト表示・履歴設定
  - `audit.zsh` — 監査・ファイルチェック設定

### `wezterm/` — Wezterm ターミナル設定

- **`.wezterm.lua`** — Wezterm 設定ファイル
  - フォント、カラースキーム、タブバー設定
  - **Windows での zsh 自動探索機能**：
    - `ZSH_CUSTOM_PATH` 環境変数で明示的に指定可能
    - `MSYS2_HOME` から自動推測
    - よくあるデフォルト候補から探索
    - PATH から自動探索

- **`.wezterm/`** — 追加設定（キーバインディングなど）
  - `keybindings.lua` — カスタムキーバインディング
  - `format.lua` — タブバー、タイトルバー、ペイン、カーソルの見た目設定
  - `status.lua` — 右ステータスバー（時刻表示など）の設定

- **`WEZTERM_SETUP.md`** — Windows での zsh 設定方法

### `vscode/` — VS Code 設定

- **`settings.json`** — VS Code 全体設定
  - エディタ、ワークスペース、ターミナル、拡張機能設定
  - Windows ターミナル設定（Anaconda Prompt, Git Bash, PowerShell 7）
  - 環境変数を使ってパスの汎用性を確保

- **`keybindings.json`** — カスタムキーバインディング

- **`snippets/`** — 言語別コードスニペット
  - `c.json` — C 言語スニペット
  - `latex.json` — LaTeX スニペット

- **`extensions.txt`** — インストール推奨拡張機能のリスト

### `git/` — Git 設定

- **`.gitconfig`** — Git 共通設定
  - エイリアス、デフォルト設定など

- **`.gitconfig.private`** — 個人用 Git ユーザー設定のテンプレート
  - `setup.sh` 実行時に `.gitconfig.local` にコピーまたは作成

---

## 🚀 使い方

### 前提条件

- **Bash** — インストール必須（Windows の場合は Git for Windows または MSYS2 推奨）
- **Git** — インストール推奨
- **OS 別要件**：
  - **Windows**: winget がインストールされていること（Windows 11 標準） or MSYS2
  - **macOS**: Xcode Command Line Tools
  - **Ubuntu/Debian**: sudo アクセス権

### 対応状況

以下の OS/環境に対応しています：

- ✅ **Windows 11** (winget or MSYS2/Git Bash)
- ✅ **macOS** (Homebrew)
- ✅ **Ubuntu/Debian** (apt)
- ⚠️ **CentOS/Amazon Linux** (実装予定)
- ⚠️ **WSL** (部分対応)

### セットアップ手順

#### 1. リポジトリをクローン

```bash
git clone https://github.com/Nepenthes-1123/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

#### 2. セットアップ実行

```bash
bash scripts/setup.sh
```

セットアップでは以下の処理が順に自動実行されます：

1. **ツールのインストール** — OS ごとに必要なツール（wezterm, VS Code, Git, zsh など）をインストール
2. **プラグイン・ツールのインストール** — fzf、zsh プラグイン（zsh-autosuggestions, zsh-syntax-highlighting, fzf-tab）をインストール
3. **シンボリックリンク作成** — 設定ファイルをホームディレクトリにリンク  
   既存ファイルがある場合は「置き換え/バックアップ/スキップ」を選択できます
4. **Git ユーザー設定** — 以下の方法から選択：
   - `private`: `.gitconfig.private` をコピー (GitHub noreply メール)
   - `make`: その場で入力して `.gitconfig.local` を作成（ローカルのみ有効）

#### 3. Windows での zsh 設定（オプション）

Wezterm で zsh を使いたい場合：

```powershell
# PowerShell で実行
setx MSYS2_HOME "C:\msys64"
```

詳細は [wezterm/WEZTERM_SETUP.md](wezterm/WEZTERM_SETUP.md) を参照。

---

## 💻 セットアップ後の環境

このリポジトリでセットアップすると、以下のような環境になります：

### インストールされるツール

| ツール                      | 用途                         | 対応 OS                           |
| --------------------------- | ---------------------------- | --------------------------------- |
| **Wezterm**                 | モダンターミナルエミュレータ | Win, Mac, Linux                   |
| **VS Code**                 | コードエディタ               | Win, Mac, Linux                   |
| **Git**                     | バージョン管理               | Win, Mac, Linux                   |
| **Zsh**                     | シェル                       | Mac, Linux（Windows: MSYS2 経由） |
| **fzf**                     | ファジー検索                 | Win, Mac, Linux                   |
| **zsh-autosuggestions**     | 履歴補完                     | All                               |
| **zsh-syntax-highlighting** | シンタックスハイライト       | All                               |
| **fzf-tab**                 | fzf 統合補完                 | All                               |

### 設定内容

#### Zsh

- 複数プラグイン統合
- カスタムプロンプト
- エイリアス・補完設定
- ファイルの優先度管理

#### VS Code

**主要な拡張機能（extensions.txt より）：**

| カテゴリ       | 拡張機能                                                                                                                                                    |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Python**     | python, black-formatter, debugpy, flake8, isort, mypy-type-checker, vscode-pylance, vscode-python-envs                                                      |
| **Jupyter**    | jupyter, jupyter-keymap, jupyter-renderers, vscode-jupyter-cell-tags, vscode-jupyter-slideshow                                                              |
| **LaTeX**      | latex-workshop                                                                                                                                              |
| **言語**       | better-cpp-syntax, cmake-language-support-vscode, cmake-tools, cpp-devtools, cpptools, cpptools-extension-pack, cpptools-themes, dotnet-runtime, twxs.cmake |
| **Git/GitHub** | github-vscode-theme, vscode-pull-request-github                                                                                                             |
| **Docker**     | docker, vscode-containers, remote-containers                                                                                                                |
| **Remote**     | remote-ssh, remote-ssh-edit, remote-wsl, remote-explorer                                                                                                    |
| **Markdown**   | markdownlint, markdown-all-in-one, markdown-preview-enhanced, marp-vscode                                                                                   |
| **その他**     | drawio, foam-vscode, errorlens, autodocstring, vscode-language-pack-ja                                                                                      |

詳細は [vscode/extensions.txt](vscode/extensions.txt) を参照。

#### Wezterm

- Sakura カラースキーム
- 背景透過設定
- カスタムキーバインディング
- タブバーのカスタマイズ
- Windows での zsh 自動検出

#### Git

- ユーザー設定の柔軟な選択
- ローカル設定で個人情報保護

---

## 🔧 カスタマイズ

### シンボリックリンク設定を追加

`scripts/add_symlink.sh` で追加のリンク設定ができます：

```bash
bash scripts/add_symlink.sh
```

### 対応 OS の追加

`scripts/check_os.sh` と `scripts/props/` に OS 判定と設定を追加。

---

## ⚠️ 注意事項

- **既存ファイルの上書き**: セットアップ中に既存ファイルが検出されると、以下を対話的に選択できます：
  - 置き換え（上書き）
  - バックアップ（`.bak` 拡張子を付けて保存）
  - スキップ（処理をスキップ）

- **Symlink 対応**（環境による）：
  - **Windows (NTFS)**: 管理者権限が必要な場合あり。`symlink_win_list.conf` で設定
  - **MSYS2/Git Bash**: シンボリックリンク作成時に `-s` フラグを使用
  - **macOS/Linux**: 標準的なシンボリックリンク対応

- **環境変数**: 一部機能で環境変数設定が必要です：
  - `MSYS2_HOME` — Windows で MSYS2 を使用する場合（例: `C:\msys64`）
  - `ZSH_CUSTOM_PATH` — Wezterm で zsh のパスを明示的に指定したい場合

---

## 📝 トラブルシューティング

### セットアップが途中で失敗する

1. OS が正しく判定されているか確認：

   ```bash
   bash scripts/check_os.sh
   ```

2. 必要なコマンドが PATH に含まれているか確認：

   ```bash
   which git bash zsh
   ```

### シンボリックリンク作成に失敗する

- **Windows (Git Bash/MSYS2)**:
  - Git Bash や MSYS2 のシェルを管理者権限で実行
  - または、Git Config で `core.symlinks=true` を設定
- **Windows (PowerShell)**:
  - Developer Mode を有効化 or 管理者権限で実行
- **macOS/Linux**:
  - ホームディレクトリの書き込み権限を確認
  - `ls -ld ~` でパーミッションを確認（755 or 700）

### Wezterm で zsh が見つからない

Windowsの場合、以下を確認してください：

1. zsh がインストールされているか確認：`where zsh.exe`
2. [wezterm/WEZTERM_SETUP.md](wezterm/WEZTERM_SETUP.md) を参照
3. `ZSH_CUSTOM_PATH` または `MSYS2_HOME` 環境変数を設定

### セットアップ後に zsh がデフォルトシェルにならない

- **Windows**: `.wezterm.lua` がシェル自動検出を行います。環境変数で明示的に指定可能
- **macOS/Linux**: `chsh -s /bin/zsh` でデフォルトシェルを変更

### VS Code の拡張機能

- `git commit`時に自動的にextensions.txtファイルを更新
- `git pull`時に差分があれば自動更新を行う

拡張機能の自動同期有効化

```bash
git config --local core.hooksPath .githooks
```

拡張機能の手動同期

```bash
cd ~/dotfiles
scripts/install_vscode_exts.sh
```

---

## 🔗 関連リンク

- [Wezterm 公式](https://wezfurlong.org/wezterm/)
- [Zsh 公式](https://www.zsh.org/)
- [VS Code 公式](https://code.visualstudio.com/)
- [fzf](https://github.com/junegunn/fzf)
