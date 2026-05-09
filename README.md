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
  - `.zsh.d` 内の設定ファイルを自動読み込み
  - PATH、環境変数、ターミナルオプションなど

- **`.zsh.d/`** — 分割された機能別設定（自動読み込み）
  - `priorities.conf` — 読み込み順序の指定
  - `audit.zsh` — 管理外のファイル監査
  - `plugins.zsh` — プラグインの読み込み
  - `alias.zsh` — コマンドエイリアス
  - `completion.zsh` — 補完設定
  - `prompt.zsh` — プロンプト・履歴設定

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

- **Bash** — インストール必須（Windows の場合は Git for Windows 推奨）
- **Git** — インストール推奨
- **OS 別要件**：
  - **Windows**: winget がインストールされていること（Windows 11 標準）
  - **macOS**: Xcode Command Line Tools
  - **Ubuntu**: sudo アクセス権

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

実行中に以下の選択肢が出ます：

1. **Tool Installation** — 必要なツールをインストール
2. **Symlink Creation** — 設定ファイルをホームディレクトリにリンク
3. **Git User Config** — Git ユーザー設定を選択：
   - `private`: `git/.gitconfig.private` をコピー
   - `make`: その場で入力して `.gitconfig.local` を作成

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

| ツール | 用途 | 対応 OS |
|--------|------|--------|
| **Wezterm** | モダンターミナルエミュレータ | Win, Mac, Linux |
| **VS Code** | コードエディタ | Win, Mac, Linux |
| **Git** | バージョン管理 | Win, Mac, Linux |
| **Zsh** | シェル | Mac, Linux（Windows: MSYS2 経由） |
| **fzf** | ファジー検索 | Win, Mac, Linux |
| **zsh-autosuggestions** | 履歴補完 | All |
| **zsh-syntax-highlighting** | シンタックスハイライト | All |
| **fzf-tab** | fzf 統合補完 | All |

### 設定内容

#### Zsh

- 複数プラグイン統合
- カスタムプロンプト
- エイリアス・補完設定
- ファイルの優先度管理

#### VS Code

- Python（Black, Flake8, mypy）
- LaTeX（LaTeX Workshop）
- Jupyter Notebook
- 複数の言語サポート
- カスタムスニペット

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

- **既存ファイルの上書き**: セットアップ中に既存ファイルが検出されると、置き換え・バックアップ・スキップを選択できます
- **Symlink 対応**: Windows は NTFS シンボリックリンクに対応していますが、管理者権限が必要な場合があります
- **環境変数**: 設定によっては環境変数の設定が必要です（例: `MSYS2_HOME`）

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

- **Windows**: 管理者権限で Bash を実行
- **macOS/Linux**: ホームディレクトリの書き込み権限を確認

### Wezterm で zsh が見つからない

[wezterm/WEZTERM_SETUP.md](wezterm/WEZTERM_SETUP.md) を確認し、環境変数を設定してください。

---

## 🔗 関連リンク

- [Wezterm 公式](https://wezfurlong.org/wezterm/)
- [Zsh 公式](https://www.zsh.org/)
- [VS Code 公式](https://code.visualstudio.com/)
- [fzf](https://github.com/junegunn/fzf)
