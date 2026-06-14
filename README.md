# Neovim 設定 (VSCode dotfiles 移植版)

Neovim v0.12 向け設定。外部プラグインマネージャ不使用、Neovim 標準 **`vim.pack`** で管理。
LSPサーバー・フォーマッタ・リンタは **Mason** で一元管理。

---

## ディレクトリ構成

```
~/.config/nvim/   (Windows: %LOCALAPPDATA%\nvim)
├── init.lua                          # エントリポイント
├── nvim-pack-lock.json               # vim.pack のバージョンロック (自動生成)
├── lsp/                               # LSP サーバー設定 (vim.lsp.enable() 用)
│   ├── pyright.lua                    # Python 型チェック (Pylance 相当)
│   ├── ruff.lua                       # Python フォーマット/リント (black+flake8+isort 統合)
│   ├── clangd.lua                     # C/C++
│   ├── lua_ls.lua                     # Lua
│   ├── vue_ls.lua                     # Vue 3 (Volar v2)
│   ├── ts_ls.lua                      # TypeScript / JavaScript
│   ├── texlab.lua                     # LaTeX
│   ├── marksman.lua                   # Markdown
│   ├── jsonls.lua                     # JSON / JSONC
│   ├── dockerls.lua                   # Dockerfile
│   └── docker_compose_language_service.lua  # docker-compose.yml
├── lua/
│   ├── config/
│   │   ├── options.lua                # エディタ基本設定 + ui2 有効化
│   │   ├── keymaps.lua                # グローバルキーマップ
│   │   ├── autocmds.lua               # 自動コマンド (trimTrailingWhitespace 等)
│   │   └── lsp.lua                    # 診断表示・hover/signatureHelp の border 設定
│   └── plugins/
│       ├── init.lua                   # vim.pack.add() 一覧 + 各 config 読み込み
│       └── config/
│           ├── utils.lua              # pcall setup ヘルパー (初回インストール対応)
│           ├── ui.lua                 # colorscheme/lualine/ibl/which-key/render-markdown
│           ├── editor.lua             # nvim-tree/telescope/gitsigns/rainbow/Comment/autopairs/illuminate
│           ├── lsp.lua                # mason/mason-lspconfig/mason-tool-installer/conform/nvim-lint
│           ├── cmp.lua                # nvim-cmp 補完エンジン
│           ├── treesitter.lua         # nvim-treesitter
│           ├── obsidian.lua           # obsidian.nvim (Zettelkasten ノート管理)
│           ├── docker.lua             # nvim-dev-container / lazydocker
│           ├── octo.lua               # GitHub PR/Issue 連携
│           ├── snacks.lua             # 通知(notifier)・input・scroll (noice代替)
│           └── tiny-cmdline.lua       # フローティングコマンドライン (ui2連携)
└── after/
    └── ftplugin/                      # ファイルタイプ別設定
        ├── python.lua
        ├── tex.lua
        ├── markdown.lua
        ├── json.lua
        └── dockerfile.lua
```

> プラグイン本体 (`pack/plugins/start/*`) は `vim.pack.add()` が自動で
> git clone するため、手動でのインストール作業は不要です。

---

## 全体構成の特徴

### 1. プラグイン管理: `vim.pack.add()`

`lua/plugins/init.lua` の `vim.pack.add({...})` にURLを並べるだけで、
**初回起動時に確認ダイアログが表示され `y` で自動 git clone** されます。
バージョンは `nvim-pack-lock.json` で固定管理され、`:Pack update` で更新できます。

### 2. LSP・フォーマッタ・リンタ管理: Mason

`lua/plugins/config/lsp.lua` で `mason-lspconfig` の `ensure_installed` に
列挙したLSPサーバーは自動インストール＋ `vim.lsp.enable()` されます
(`automatic_enable = true`)。`lsp/<server>.lua` がサーバー固有設定です。

フォーマッタ・リンタは `mason-tool-installer` で管理され、
`conform.nvim` / `nvim-lint` から参照されます。

### 3. UI: ui2 + snacks.nvim + tiny-cmdline.nvim (noice.nvim 代替)

Neovim v0.12 の実験的UI `vim._core.ui2` をベースに、
不足機能を以下のプラグインで補完しています。

| 役割 | 担当 |
|---|---|
| cmdline/メッセージ基盤 (`cmdheight=0`) | `vim._core.ui2` (options.lua) |
| cmdlineを画面中央にフロート表示 | `tiny-cmdline.nvim` |
| 通知のトースト表示・LSPプログレス | `snacks.nvim` (notifier) |

### 4. Markdownレンダリング: render-markdown.nvim

`obsidian.nvim` の `ui` モジュールは **Vault外のMarkdownファイルには適用されず、
将来的に廃止予定**(専用レンダラの利用が推奨)のため、
Vault内外問わず一貫した見た目にするために `render-markdown.nvim` を採用しています
(`obsidian.lua` 側は `ui.enable = false`)。

---

## 必要な外部ツール

### LSP サーバー・フォーマッタ・リンタ (Mason管理)

以下は `mason-lspconfig` / `mason-tool-installer` の `ensure_installed` に
列挙されており、**Neovim初回起動時に自動インストールされます**。
手動インストールは基本的に不要です。

| 種別 | 名前 | 対象 |
|---|---|---|
| LSP | `pyright` | Python (型チェック) |
| LSP | `ruff` | Python (フォーマット/リント) |
| LSP | `clangd` | C/C++ |
| LSP | `lua_ls` | Lua |
| LSP | `vue_ls` | Vue 3 |
| LSP | `ts_ls` | TypeScript/JavaScript |
| LSP | `texlab` | LaTeX |
| LSP | `marksman` | Markdown |
| LSP | `jsonls` | JSON/JSONC |
| LSP | `dockerls` | Dockerfile |
| LSP | `docker_compose_language_service` | docker-compose.yml |
| Formatter | `stylua` | Lua |
| Formatter | `prettier` | JS/TS/Vue/JSON |
| Formatter | `clang-format` | C/C++ |
| Lint/Fix | `markdownlint` | Markdown (フォーマット兼リント) |
| Lint | `eslint_d` | JavaScript/TypeScript |

### Mason管理外で別途インストールが必要なツール

```bash
# ripgrep (Telescope の live_grep に必須)
sudo apt install ripgrep   # Ubuntu/Debian
brew install ripgrep       # macOS
winget install BurntSushi.ripgrep.MSVC  # Windows

# GitHub CLI (octo.nvim に必須)
winget install GitHub.cli  # Windows
brew install gh             # macOS
# 初回認証
gh auth login
# GitHub Projects (v2) を使う場合
gh auth refresh -s read:project

# lazydocker (Docker UI, オプション)
scoop install lazydocker    # Windows
brew install lazydocker     # macOS

# hadolint (Dockerfile lint, オプション)
scoop install hadolint       # Windows
brew install hadolint        # macOS

# jq (JSON整形フォールバック, オプション)
winget install jqlang.jq    # Windows
brew install jq             # macOS

# Docker / Podman + docker compose (nvim-dev-container に必須)
```

---

## 初回起動手順

```bash
# 1. Neovim を起動
nvim

# 2. vim.pack の確認ダイアログが出るので y で承認
#    (バックグラウンドでプラグインが git clone される)

# 3. 一度終了して再起動 (初回インストール直後は require が失敗するため必須)
:q
nvim

# 4. Treesitter パーサーをビルド (初回のみ・PackChanged で自動実行されるが念のため)
:TSUpdate

# 5. Mason で LSP/フォーマッタ/リンタの自動インストールが走るのを待つ
:Mason   " ✓ になっていればOK

# 6. ヘルスチェックで不足ツールを確認
:checkhealth

# 7. LSP が正しく動作しているか確認
:lua vim.print(vim.lsp.get_clients())
```

---

## VSCode → Neovim 機能対応表

| VSCode 機能 | Neovim での実現方法 | キーバインド |
|---|---|---|
| 定義ジャンプ (F12) | `vim.lsp.buf.definition` | `gd` |
| 宣言ジャンプ | `vim.lsp.buf.declaration` | `gD` |
| 参照ジャンプ (Shift+F12) | `vim.lsp.buf.references` | `gr` |
| 実装ジャンプ | `vim.lsp.buf.implementation` | `gi` |
| ホバー表示 | `vim.lsp.buf.hover` | `K` |
| リネーム (F2) | `vim.lsp.buf.rename` | `<F2>` / `<Leader>rn` |
| クイックフィックス | `vim.lsp.buf.code_action` | `<Leader>ca` |
| フォーマット (手動) | `vim.lsp.buf.format` | `<Leader>f` |
| 保存時フォーマット | conform.nvim `format_on_save` | 保存時自動 |
| ファイルエクスプローラー | nvim-tree | `<Leader>e` |
| ファイル検索 (Ctrl+P) | Telescope find_files | `<Leader>ff` |
| 全文検索 (Ctrl+Shift+F) | Telescope live_grep | `<Leader>fg` |
| Git インライン Blame | gitsigns current_line_blame | 自動表示 / `<Leader>gB` でトグル |
| Git Gutter 差分 | gitsigns signs | 自動表示 |
| ErrorLens (インライン診断) | `vim.diagnostic.config virtual_text` | 自動表示 |
| コメントトグル (Ctrl+/) | Comment.nvim | `gcc` (行) / `gc` (Visual) |
| ブラケットペア色付け | rainbow-delimiters.nvim | 自動 |
| Markdownプレビュー | render-markdown.nvim | 自動 (編集中インライン表示) |
| LSPサーバー管理 | Mason | `<Leader>m` |
| 通知トースト | snacks.nvim (notifier) | 自動 / `<Leader>nh` 履歴, `<Leader>nd` 全消去 |
| GitHub PR一覧 | octo.nvim | `<Leader>hpl` |
| GitHub PRレビュー開始/送信 | octo.nvim | `<Leader>hprs` / `<Leader>hprx` |
| GitHub Issue一覧/作成 | octo.nvim | `<Leader>hil` / `<Leader>hin` |
| Dev Container でリオープン | nvim-dev-container | `<Leader>dcu` |
| Dev Container アタッチ | nvim-dev-container | `<Leader>dca` |
| Docker UI (lazydocker) | lazydocker (フロート端末) | `<Leader>dk` |

---

## obsidian.nvim (Zettelkasten ノート管理)

### Vault パスの指定 (環境変数)

Vaultパスは環境変数 `OBSIDIAN_VALUT_PATH` で指定します
(未設定時は `~/Documents/slip-box` にフォールバック)。

```bash
# Windows (PowerShell, 永続化)
[System.Environment]::SetEnvironmentVariable("OBSIDIAN_VALUT_PATH", "C:\path\to\vault", "User")

# macOS/Linux (~/.bashrc, ~/.zshrc 等に追記)
export OBSIDIAN_VALUT_PATH="$HOME/path/to/vault"
```

### ノートタイプ別の新規作成 (`<Leader>oz` + キー)

各ノートタイプには専用フォルダとテンプレートが事前に割り当てられています。
タイトルをプロンプト入力すると、対応フォルダ配下にテンプレート付きでノートが作成されます。

| キー | ノートタイプ | 保存先フォルダ | テンプレート |
|---|---|---|---|
| `<Leader>ozf` | Fleeting Note | `00_Inbox` | `fleeting-note.md` |
| `<Leader>ozl` | Literature Note | `10_Literature` | `literature-note.md` |
| `<Leader>ozp` | Permanent Note | `20_Notes` | `permanent-note.md` |
| `<Leader>ozi` | Index Note (MOC) | `30_Indes` | `index-note.md` |

> ⚠️ `30_Indes` は `30_Index` のtypoの可能性があります。意図したフォルダ名でなければ
> `lua/plugins/config/obsidian.lua` の `note_types` テーブルを修正してください。

フォルダ名・テンプレート名を変更する場合は `note_types` テーブル
(`lua/plugins/config/obsidian.lua`)を編集してください。

### その他の主なキーバインド (`<Leader>o` プレフィックス)

| キー | 動作 |
|---|---|
| `<Leader>of` | ノート検索 (quick_switch) |
| `<Leader>og` | 全文検索 |
| `<Leader>od` / `<Leader>oD` | 今日 / 昨日のデイリーノートを開く |
| `<Leader>on` | 新規ノート作成 (テンプレート選択なし) |
| `<Leader>oN` | テンプレート選択ピッカーから新規作成 |
| `gf` / `<Leader>ol` | `[[wikilink]]` を追う |
| `<Leader>ob` | バックリンク一覧 |
| `<Leader>ot` | タグ一覧 |
| `<Leader>oc` | 目次 (TOC) |
| `<Leader>or` | ノートのリネーム (リンク自動更新) |
| `<Leader>ox` | チェックボックスのトグル |

---

## カスタマイズのヒント

### インライン Blame の常時表示を OFF にする

`lua/plugins/config/editor.lua` の gitsigns 設定で
`current_line_blame = false` に変更し、必要なときだけ `<Leader>gB` でトグルする運用も可能。

### LSP サーバーの追加

1. `lsp/<server_name>.lua` を作成 (サーバー固有設定を `return {...}` で記述)
2. `lua/plugins/config/lsp.lua` の `mason-lspconfig` `ensure_installed` に
   Mason パッケージ名を追記

これだけで自動インストール＋有効化されます。

### Python 仮想環境

プロジェクトルートに `.venv/` があれば pyright が自動検出します。
手動指定する場合は `lsp/pyright.lua` の `python.pythonPath` を変更してください。

### tiny-cmdline.nvim の補完アダプター

nvim-cmp を使用しているため `adapters.blink` (blink.cmp専用) は不要です。
blink.cmp に乗り換える場合のみ `on_reposition = require("tiny-cmdline").adapters.blink`
を追加してください。
