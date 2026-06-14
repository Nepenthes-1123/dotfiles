# Neovim 設定 (VSCode dotfiles 移植版)

Neovim v0.12 向け設定。外部プラグインマネージャ不使用、Neovim 標準 `packpath` で管理。

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
│   ├── volar.lua                 # Vue 3
│   ├── ts_ls.lua                 # TypeScript / JavaScript
│   ├── texlab.lua                # LaTeX
│   ├── marksman.lua              # Markdown
│   └── jsonls.lua                # JSON / JSONC
├── lua/
│   ├── config/
│   │   ├── options.lua           # エディタ基本設定
│   │   ├── keymaps.lua           # キーマップ
│   │   ├── autocmds.lua          # 自動コマンド (formatOnSave 等)
│   │   └── lsp.lua               # LSP 有効化 & 診断設定
│   └── plugins/
│       └── init.lua              # プラグイン設定 (packpath 経由)
├── after/
│   └── ftplugin/                 # ファイルタイプ別設定
│       ├── python.lua
│       ├── tex.lua
│       ├── markdown.lua
│       └── json.lua
└── pack/
    └── plugins/
        └── start/                # ← ここに git clone する
            ├── rose-pine/
            ├── nvim-tree.lua/
            ├── nvim-web-devicons/
            ├── telescope.nvim/
            ├── plenary.nvim/
            ├── gitsigns.nvim/
            ├── nvim-cmp/
            ├── cmp-nvim-lsp/
            ├── cmp-buffer/
            ├── cmp-path/
            ├── LuaSnip/
            ├── cmp_luasnip/
            ├── nvim-treesitter/
            ├── rainbow-delimiters.nvim/
            ├── conform.nvim/
            ├── nvim-lint/
            ├── Comment.nvim/
            ├── lualine.nvim/
            ├── indent-blankline.nvim/
            ├── nvim-autopairs/
            ├── vim-illuminate/
            └── which-key.nvim/
```

---

## 必要な外部ツール (LSP サーバー・フォーマッター)

### LSP サーバー

```bash
# Python
pip install pyright
pip install ruff          # black + flake8 + isort 統合

# C/C++
# Ubuntu/Debian
sudo apt install clangd
# macOS
brew install llvm

# Lua
# Ubuntu/Debian
sudo apt install lua-language-server
# macOS
brew install lua-language-server

# TypeScript/JavaScript
npm install -g typescript-language-server typescript

# Vue (Volar v2)
npm install -g @vue/language-server

# LaTeX
# Ubuntu/Debian
sudo apt install texlab
# macOS
brew install texlab
# または cargo install texlab

# Markdown
# Ubuntu/Debian: GitHub Release から取得
# https://github.com/artempyanykh/marksman/releases
# macOS
brew install marksman

# JSON
npm install -g vscode-langservers-extracted
```

### フォーマッター・リンター

```bash
# Python フォーマッター (ruff が black/isort を兼ねる)
pip install ruff

# Lua フォーマッター
# Ubuntu/Debian: GitHub Release から取得 (https://github.com/JohnnyMorganz/StyLua/releases)
# macOS
brew install stylua

# Prettier (JS/TS/JSON/Markdown)
npm install -g prettier

# ESLint (JavaScript/TypeScript)
npm install -g eslint_d

# markdownlint (Markdown)
npm install -g markdownlint-cli

# jq (JSON 整形フォールバック)
sudo apt install jq   # Ubuntu
brew install jq       # macOS

# ripgrep (Telescope の grep 高速化)
sudo apt install ripgrep
brew install ripgrep
```

---

## プラグインのインストール

設定ディレクトリに移動して一括 clone する:

```bash
NVIM_PACK=~/.config/nvim/pack/plugins/start
mkdir -p "$NVIM_PACK"
cd "$NVIM_PACK"

# カラースキーム
git clone --depth 1 https://github.com/rose-pine/neovim rose-pine

# ファイルツリー
git clone --depth 1 https://github.com/nvim-tree/nvim-tree.lua
git clone --depth 1 https://github.com/nvim-tree/nvim-web-devicons

# ファジーファインダー
git clone --depth 1 https://github.com/nvim-telescope/telescope.nvim
git clone --depth 1 https://github.com/nvim-lua/plenary.nvim
# (オプション) fzf 高速化
git clone --depth 1 https://github.com/nvim-telescope/telescope-fzf-native.nvim
# ビルドが必要: cd telescope-fzf-native.nvim && make

# Git 連携
git clone --depth 1 https://github.com/lewis6991/gitsigns.nvim

# 補完エンジン
git clone --depth 1 https://github.com/hrsh7th/nvim-cmp
git clone --depth 1 https://github.com/hrsh7th/cmp-nvim-lsp
git clone --depth 1 https://github.com/hrsh7th/cmp-buffer
git clone --depth 1 https://github.com/hrsh7th/cmp-path
git clone --depth 1 https://github.com/hrsh7th/cmp-cmdline
git clone --depth 1 https://github.com/L3MON4D3/LuaSnip
git clone --depth 1 https://github.com/saadparwaiz1/cmp_luasnip
# (オプション) VS Code スニペット集
git clone --depth 1 https://github.com/rafamadriz/friendly-snippets

# シンタックスハイライト
git clone --depth 1 https://github.com/nvim-treesitter/nvim-treesitter
# 初回起動後に :TSUpdate を実行してパーサーをビルドすること

# ブラケットカラー化
git clone --depth 1 https://github.com/HiPhish/rainbow-delimiters.nvim

# フォーマッター
git clone --depth 1 https://github.com/stevearc/conform.nvim

# リンター
git clone --depth 1 https://github.com/mfussenegger/nvim-lint

# コメント
git clone --depth 1 https://github.com/numToStr/Comment.nvim

# ステータスライン
git clone --depth 1 https://github.com/nvim-lualine/lualine.nvim

# インデントガイド
git clone --depth 1 https://github.com/lukas-reineke/indent-blankline.nvim

# 自動括弧
git clone --depth 1 https://github.com/windwp/nvim-autopairs

# カーソル下単語ハイライト
git clone --depth 1 https://github.com/RRethy/vim-illuminate

# キーバインドガイド
git clone --depth 1 https://github.com/folke/which-key.nvim
```

---

## 初回起動手順

```bash
# 1. Neovim を起動
nvim

# 2. Treesitter パーサーをビルド (初回のみ・数分かかる)
:TSUpdate

# 3. ヘルスチェックで不足ツールを確認
:checkhealth

# 4. LSP が正しく動作しているか確認
:lua vim.print(vim.lsp.get_clients())
```

---

## VSCode → Neovim 機能対応表

| VSCode 機能                | Neovim での実現方法                  | キーバインド                     |
| -------------------------- | ------------------------------------ | -------------------------------- |
| 定義ジャンプ (F12)         | `vim.lsp.buf.definition`             | `gd`                             |
| 宣言ジャンプ               | `vim.lsp.buf.declaration`            | `gD`                             |
| 参照ジャンプ (Shift+F12)   | `vim.lsp.buf.references`             | `gr`                             |
| 実装ジャンプ               | `vim.lsp.buf.implementation`         | `gi`                             |
| ホバー表示                 | `vim.lsp.buf.hover`                  | `K`                              |
| リネーム (F2)              | `vim.lsp.buf.rename`                 | `<F2>` / `<Leader>rn`            |
| クイックフィックス         | `vim.lsp.buf.code_action`            | `<Leader>ca`                     |
| フォーマット               | `vim.lsp.buf.format`                 | `<Leader>f`                      |
| ファイルエクスプローラー   | nvim-tree                            | `<Leader>e`                      |
| ファイル検索 (Ctrl+P)      | Telescope find_files                 | `<Leader>ff`                     |
| 全文検索 (Ctrl+Shift+F)    | Telescope live_grep                  | `<Leader>fg`                     |
| Git インライン Blame       | gitsigns current_line_blame          | 自動表示 / `<Leader>gB` でトグル |
| Git Gutter 差分            | gitsigns signs                       | 自動表示                         |
| ErrorLens (インライン診断) | `vim.diagnostic.config virtual_text` | 自動表示                         |
| コメントトグル (Ctrl+/)    | Comment.nvim                         | `gcc` (行) / `gc` (Visual)       |
| ブラケットペア色付け       | rainbow-delimiters.nvim              | 自動                             |
| 保存時フォーマット         | autocmds.lua LspFormatOnSave         | 保存時自動                       |
| import 整理                | ruff (organizeImports)               | 保存時自動                       |

---

## カスタマイズのヒント

### インライン Blame の常時表示を OFF にする

`lua/plugins/init.lua` の gitsigns 設定で `current_line_blame = false` に変更し、  
必要なときだけ `<Leader>gB` でトグルする運用も可能。

### LSP サーバーの追加

`lsp/` ディレクトリに `<server_name>.lua` を追加し、  
`lua/config/lsp.lua` の `servers` テーブルに `"<server_name>"` を追記するだけで有効になる。

### Python 仮想環境

プロジェクトルートに `.venv/` があれば pyright が自動検出する。  
手動指定する場合は `lsp/pyright.lua` の `python.pythonPath` を変更。
