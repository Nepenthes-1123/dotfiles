# Neovim 設定 (VSCode dotfiles 移植版)

Neovim v0.12 向け設定。外部プラグインマネージャ不使用、Neovim 組み込みのパッケージシステム `vim.pack` で管理。

---

## ディレクトリ構成

```
~/.config/nvim/
├── init.lua                      # エントリポイント
├── lsp/                          # LSP サーバー設定 (vim.lsp.enable() 用)
│   ├── pyright.lua               # Python 型チェック (Pylance 相当)
│   ├── ruff.lua                  # Python フォーマット/リント (black+flake8+isort 統合)
│   ├── clangd.lua                # C/C++
│   ├── lua_ls.lua                # Lua
│   ├── vue_ls.lua                # Vue 3
│   ├── vtsls.lua                 # TypeScript / JavaScript (vtsls)
│   ├── texlab.lua                # LaTeX
│   ├── marksman.lua              # Markdown
│   ├── jsonls.lua                # JSON / JSONC
│   ├── dockerls.lua              # Dockerfile
│   └── docker_compose_language_service.lua # Docker Compose
├── lua/
│   ├── config/
│   │   ├── options.lua           # エディタ基本設定
│   │   ├── keymaps.lua           # キーマップ
│   │   ├── autocmds.lua          # 自動コマンド (formatOnSave 等)
│   │   └── lsp.lua               # LSP 有効化 & 診断設定
│   └── plugins/
│       ├── init.lua              # プラグインのロード宣言 (vim.pack.add)
│       └── config/               # プラグインごとの詳細設定
│           ├── ai.lua            # AI補完 (Copilot)
│           ├── autopairs.lua     # 自動カッコ補完
│           ├── blink.lua         # 補完エンジン (blink.cmp)
│           ├── docker.lua        # Dockerコンテナ連携
│           ├── editor.lua        # エディタ系便利ツール
│           ├── lsp.lua           # Mason/LSPマネージャ設定
│           ├── obsidian.lua      # Obsidianノート連携
│           ├── octo.lua          # GitHub PR / Issue 連携
│           ├── snacks.lua        # Snacks.nvim (様々なコア機能の代替)
│           ├── tiny-cmdline.lua  # コマンドラインのUI改善
│           ├── treesitter.lua    # シンタックスハイライト
│           ├── ui.lua            # UI/ステータスライン/カラーテーマ
│           └── utils.lua         # ユーティリティ関数
└── after/
    └── ftplugin/                 # ファイルタイプ別設定
        ├── python.lua
        ├── tex.lua
        ├── markdown.lua
        ├── json.lua
        └── dockerfile.lua
```

---

## 必要な外部ツール (LSP サーバー・フォーマッター)

本設定では、LSPやリンター・フォーマッターなどのツールは **Mason.nvim** (`:Mason`) を介して一部自動管理されていますが、システムに手動でインストールしておくべき主要なツール群は以下の通りです。

### LSP サーバー

```zsh
# Python
pip install pyright
pip install ruff          # black + flake8 + isort 統合

# C/C++
# Ubuntu/Debian: sudo apt install clangd
# macOS: brew install llvm

# Lua
# Ubuntu/Debian: sudo apt install lua-language-server
# macOS: brew install lua-language-server

# TypeScript/JavaScript (vtsls)
npm install -g @vtsls/language-server typescript

# Vue (Volar v2)
npm install -g @vue/language-server

# LaTeX
# Ubuntu/Debian: sudo apt install texlab
# macOS: brew install texlab

# Markdown
# Ubuntu/Debian: GitHub Release から取得 (https://github.com/artempyanykh/marksman/releases)
# macOS: brew install marksman

# JSON
npm install -g vscode-langservers-extracted

# Docker / Docker Compose
npm install -g dockerfile-language-server-nodejs
npm install -g @microsoft/compose-language-service
```

### フォーマッター・リンター

```zsh
# Python フォーマッター (ruff が兼ねる)
pip install ruff

# Lua フォーマッター
# macOS: brew install stylua

# Prettier (JS/TS/JSON/Markdown)
npm install -g prettier

# ESLint (JavaScript/TypeScript)
npm install -g eslint_d

# markdownlint (Markdown)
npm install -g markdownlint-cli

# hadolint (Dockerfile リンター)
# macOS: brew install hadolint
```

---

## プラグインのインストールと管理

本設定は、Neovim v0.12 組み込みのパッケージシステム `vim.pack` を採用しています。
手動で `git clone` する必要はありません。

* `lua/plugins/init.lua` に記述されたプラグイン群は、**Neovimの初回起動時に未インストールであるものを自動的に検出して `git clone` します**（初回起動時にインストール確認ダイアログが表示されます）。
* パラメータやバージョン固定は `nvim-pack-lock.json` によって管理されています。
* `:Pack install` または `:Pack update` コマンドで、対話的にプラグインのインストールやアップデートが可能です。

### 導入される主要プラグイン

* **カラーテーマ**: `rose-pine` (Rosé Pine Moon)
* **ファイラー / ピッカー / 通知**: `snacks.nvim` (nvim-tree や telescope のコア機能を代替し高速化)
* **補完**: `blink.cmp` (極めて高速な次世代補完エンジン)
* **ハイライト**: `nvim-treesitter` & `rainbow-delimiters.nvim`
* **LSP管理**: `mason.nvim` / `mason-lspconfig.nvim` / `mason-tool-installer.nvim`
* **フォーマット**: `conform.nvim` (保存時自動フォーマットなど)
* **リンター**: `nvim-lint`
* **ノート連携**: `obsidian.nvim` (Obsidian Vaultとの直接連携)
* **Git**: `gitsigns.nvim` & `octo.nvim` (GitHub PR/Issue連携)
* **AI自動補完**: `copilot.lua` (GitHub Copilot)

---

## 初回起動手順

```zsh
# 1. Neovim を起動 (初回起動時にプラグインの自動インストールダイアログが出ます)
nvim

# 2. LSP サーバーなどの自動セットアップ (Mason が自動で裏でインストールします)
:Mason

# 3. Treesitter パーサーをビルド
:TSUpdate

# 4. ヘルスチェックで動作状況を確認
:checkhealth
```

---

## VSCode → Neovim 機能対応表

| VSCode 機能 | Neovim での実現方法 | キーバインド |
| --- | --- | --- |
| 定義ジャンプ (F12) | `vim.lsp.buf.definition` | `gd` |
| 宣言ジャンプ | `vim.lsp.buf.declaration` | `gD` |
| 参照ジャンプ (Shift+F12) | `vim.lsp.buf.references` / `Snacks.picker` | `gr` / `<Leader>fr` |
| 実装ジャンプ | `vim.lsp.buf.implementation` | `gi` |
| ホバー表示 | `vim.lsp.buf.hover` | `K` |
| リネーム (F2) | `vim.lsp.buf.rename` | `<F2>` / `<Leader>cr` |
| クイックフィックス | `vim.lsp.buf.code_action` | `<Leader>ca` |
| フォーマット (Alt+Shift+F) | `vim.lsp.buf.format` / `conform.nvim` | `<Leader>cf` |
| ファイルエクスプローラー | `snacks.explorer` | `<Leader>e` / `<Leader>E` |
| ファイル検索 (Ctrl+P) | `Snacks.picker.files` | `<Leader>ff` |
| 全文検索 (Ctrl+Shift+F) | `Snacks.picker.grep` | `<Leader>fg` |
| Git インライン Blame | `Snacks.git.blame_line` / `gitsigns` | `<Leader>gb` / 自動表示 |
| Git Diff プレビュー | `Snacks.picker.git_diff` | `<Leader>gd` |
| GitHub Issues / PR 連携 | `Snacks.picker.gh_issue` / `gh_pr` | `<Leader>gil` / `<Leader>gpl` |
| コメントトグル (Ctrl+/) | Neovim 0.10+ 組み込みコメント機能 | `gcc` (行) / `gc` (Visual) |
| 保存時フォーマット | `autocmds.lua` + `conform.nvim` | 保存時自動 |
| 付箋メモ (スクラッチバッファ) | `Snacks.scratch` / `select` | `<Leader>.` (開閉) / `<Leader>S` (履歴) |

---

## カスタマイズのヒント

### LSP サーバーの追加 / 管理

`lua/plugins/config/lsp.lua` の設定に基づいて自動インストールが行われます。新しいLSPを追加したい場合は：

1. `lsp/` ディレクトリに `<server_name>.lua` を追加。
2. `lua/plugins/config/lsp.lua` の設定テーブル、または `lua/config/lsp.lua` でサーバーを読み込むように追加。

### 保存時フォーマットのトグル

`lua/config/autocmds.lua` で `BufWritePre` による自動フォーマットが設定されています。特定の拡張子だけ無効化したい場合は、そちらのフックを修正します。
