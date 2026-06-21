# Neovim 設定 (VSCode dotfiles 移植版)

Neovim v0.12 向け設定。プラグイン管理は外部プラグインマネージャを使わず、Neovim v0.12 組み込みの `vim.pack` API で行う。LSPサーバー/フォーマッター/リンターのインストールは Mason (`mason.nvim` + `mason-lspconfig.nvim` + `mason-tool-installer.nvim`) が自動で行う。

---

## ディレクトリ構成

```
~/.config/nvim/
├── init.lua                                  # エントリポイント (読み込み順を制御)
├── nvim-pack-lock.json                       # vim.pack のバージョン固定ファイル (自動生成)
├── lsp/                                      # LSP サーバー設定 (vim.lsp.enable() 用、mason-lspconfig が自動読込)
│   ├── pyright.lua                           # Python 型チェック (Pylance 相当)
│   ├── ruff.lua                              # Python フォーマット/リント (black+flake8+isort 統合)
│   ├── clangd.lua                            # C/C++
│   ├── lua_ls.lua                            # Lua
│   ├── vue_ls.lua                            # Vue 3 (Volar v2)
│   ├── vtsls.lua                             # TypeScript / JavaScript (Vue プラグイン連携込み)
│   ├── texlab.lua                            # LaTeX
│   ├── marksman.lua                          # Markdown
│   ├── jsonls.lua                            # JSON / JSONC
│   ├── dockerls.lua                          # Dockerfile
│   └── docker_compose_language_service.lua   # docker-compose.yml
├── lua/
│   ├── config/
│   │   ├── options.lua                       # エディタ基本設定
│   │   ├── keymaps.lua                       # グローバルキーマップ
│   │   ├── autocmds.lua                      # 自動コマンド (formatOnSave, trimTrailingWhitespace 等)
│   │   └── lsp.lua                           # 診断表示設定 & hover/signature のボーダー設定
│   └── plugins/
│       ├── init.lua                          # vim.pack.add() によるプラグイン宣言 & 各設定の読込
│       └── config/
│           ├── utils.lua                     # pcall ラッパー (未インストール時に無視する setup())
│           ├── lsp.lua                       # Mason / mason-lspconfig / conform / nvim-lint
│           ├── blink.lua                     # blink.cmp (補完エンジン)
│           ├── treesitter.lua                # nvim-treesitter (パーサー & ハイライト)
│           ├── editor.lua                    # telescope / gitsigns / rainbow-delimiters
│           ├── ui.lua                        # カラースキーム / lualine / which-key / render-markdown
│           ├── snacks.lua                    # snacks.nvim (explorer/picker/notifier/通知/Git・GitHub一覧)
│           ├── obsidian.lua                  # obsidian.nvim (Foam Vault 互換ノート機能)
│           ├── octo.lua                      # octo.nvim (GitHub Issue/PR/Review)
│           ├── docker.lua                    # nvim-dev-container / lazydocker
│           └── tiny-cmdline.lua              # コマンドラインのフローティング表示
├── after/
│   ├── ftplugin/                             # ファイルタイプ別設定 (LocalLeader キーマップ含む)
│   │   ├── python.lua
│   │   ├── tex.lua
│   │   ├── markdown.lua
│   │   ├── json.lua
│   │   └── dockerfile.lua
│   └── queries/
│       └── vue/                              # Vue SFC 用 Tree-sitter クエリ上書き (作業中)
└── pack/                                     # vim.pack が自動 clone する (手動操作不要)
```

---

## 必要な外部ツール

### Mason が自動インストールするもの

初回起動時、`plugins/config/lsp.lua` の設定に従って Mason が以下を自動インストールする(`mason-tool-installer` は `start_delay = 1500`ms 後に自動実行、`auto_update = false`)。手動でのインストール作業は不要。

LSPサーバー (`mason-lspconfig.ensure_installed`):

```
pyright, ruff, clangd, lua_ls, vue_ls, vtsls, texlab, marksman,
jsonls, dockerls, docker_compose_language_service
```

フォーマッター/リンター (`mason-tool-installer.ensure_installed`):

```
ruff, stylua, prettier, eslint_d, clang-format, markdownlint
```

これらの多くは Node.js 上で動作するため、事前に Node.js (npm) のインストールが必要。clangd / clang-format は別途 C/C++ ツールチェーンに依存する場合がある。

### 手動インストールが必要なもの

```bash
# ripgrep — snacks.picker の grep / Telescope の高速化、:grep のバックエンド
sudo apt install ripgrep   # Ubuntu/Debian
brew install ripgrep       # macOS
scoop install ripgrep      # Windows

# GitHub CLI — octo.nvim (PR/Issue/Review) に必須
# インストール後に `gh auth login` が必要
# GitHub Projects (v2) を使う場合は追加スコープも必要: gh auth refresh -s read:project
winget install GitHub.cli  # Windows
brew install gh            # macOS

# Docker または Podman — nvim-dev-container 用 (自動検出)
# docker compose v2 が無ければ docker-compose (v1) にフォールバック

# lazydocker (任意) — <Leader>Dk でフローティングターミナル起動
brew install lazydocker
scoop install lazydocker / winget install lazydocker

# hadolint (任意) — Dockerfile の :make 構文チェック
brew install hadolint

# glow (任意) — Markdown の <LocalLeader>p プレビュー
brew install glow / cargo install glow

# jq (任意) — JSON の <LocalLeader>j フォーマットフォールバック
sudo apt install jq / brew install jq

# latexmk + LaTeX ディストリビューション — tex ファイルの <LocalLeader>b ビルド
# (TeX Live / MacTeX / MiKTeX 等)
```

---

## プラグイン管理 (vim.pack)

`lua/plugins/init.lua` の `vim.pack.add({...})` に列挙したプラグインは、Neovim 起動時に未インストールであれば自動で `git clone` される(初回のみ確認ダイアログが出る)。手動での `git clone` 作業は不要。バージョンは `nvim-pack-lock.json` に固定され、`:Pack update` で更新できる。

導入しているプラグイン (用途別):

| カテゴリ | プラグイン |
| --- | --- |
| カラースキーム | rose-pine/neovim |
| アイコン | nvim-web-devicons |
| ファジーファインダー基盤 | plenary.nvim, telescope.nvim (obsidian.nvim のpickerとして使用) |
| Git連携 | gitsigns.nvim |
| 補完エンジン | blink.lib, blink.cmp |
| シンタックスハイライト | nvim-treesitter |
| ブラケット色付け | rainbow-delimiters.nvim |
| フォーマッター/リンター | conform.nvim, nvim-lint |
| LSP/ツール管理 | mason.nvim, mason-lspconfig.nvim, mason-tool-installer.nvim |
| ステータスライン | lualine.nvim |
| 自動括弧補完 | nvim-autopairs |
| キーバインドガイド | which-key.nvim |
| ノート (Foam Vault互換) | obsidian.nvim |
| Dev Container | nvim-dev-container |
| 通知/エクスプローラー/ピッカー/UI補完 | snacks.nvim |
| Markdownレンダリング | render-markdown.nvim |
| GitHub PR/Issue/Review | octo.nvim (要 `gh` CLI) |
| コマンドラインのフローティング | tiny-cmdline.nvim |

ファイルツリー・インデントガイド・カーソル下単語ハイライトは個別プラグインではなく snacks.nvim (`explorer`/`indent`/`words`) でまとめて提供している。コメントトグル (`gcc`/`gc`) は Neovim 組み込み機能を使用。

obsidian.nvim の Vault パスは環境変数 `OBSIDIAN_VAULT_PATH` で指定する(未設定時は `~/Documents/slip-box`)。

---

## 初回起動手順

```bash
# 1. Neovim を起動 (vim.pack が未インストールのプラグインを自動 clone)
nvim

# 2. Mason によるLSP/ツールの自動インストールを待つ (start_delay 1.5秒後に開始)
:Mason            " 進捗確認

# 3. Treesitter パーサーをビルド (初回のみ・数分かかる場合あり)
:TSUpdate

# 4. ヘルスチェックで不足ツールを確認
:checkhealth

# 5. LSP が正しく動作しているか確認
:lua vim.print(vim.lsp.get_clients())

# 6. (GitHub機能を使う場合) gh CLI の認証
gh auth login
```

---

## キーバインド一覧

凡例: `<Leader>` = Space, `<LocalLeader>` = `\`。キー設計は「拡張機能の単位」ではなく「ユーザーが何をしたいか」という機能カテゴリ単位でリーダー配下を分けている。

### 基本操作

| キー | 動作 |
| --- | --- |
| `<Leader>w` | 保存 |
| `<Leader>q` | 終了 |
| `<Leader>Q` | 全バッファ強制終了 |
| `<Esc>` (n) | 検索ハイライト解除 |
| `<C-h/j/k/l>` | ウィンドウ間移動 |
| `<C-Up/Down/Left/Right>` | ウィンドウサイズ変更 |
| `<Tab>` / `<S-Tab>` | 次/前のバッファへ |
| `<Leader>bd` | バッファを閉じる |
| `<Leader>t` | ターミナルを開く |
| `<Esc>` (terminal) | ターミナルモードを抜ける |
| `gcc` / `gc` | コメントトグル (行 / Visual、組み込み機能) |
| `<` / `>` (Visual) | インデント変更後も選択を維持 |

### LSP コードナビゲーション (リーダーなし)

| キー | 動作 |
| --- | --- |
| `gd` | 定義へジャンプ |
| `gD` | 宣言へジャンプ |
| `gr` | 参照一覧 |
| `gi` | 実装へジャンプ |
| `gy` | 型定義へジャンプ |
| `K` | ホバー表示 |
| `<C-s>` (n/i) | シグネチャヘルプ |

### コード操作 — `<Leader>c`

| キー | 動作 |
| --- | --- |
| `<Leader>ca` (n/v) | コードアクション |
| `<Leader>cr` / `<F2>` | リネーム |
| `<Leader>cf` (n/v) | フォーマット (バッファ全体 / 選択範囲) |

### 診断 — `<Leader>d`

単独リーフのみ(一覧/絞り込みは Find カテゴリに統合)。

| キー | 動作 |
| --- | --- |
| `<Leader>d` | カーソル位置の診断を float 表示 |
| `[d` / `]d` | 前 / 次の診断へジャンプ |

### 検索・ピッカー — `<Leader>f` (snacks.picker)

| キー | 動作 |
| --- | --- |
| `<Leader>ff` | ファイル検索 |
| `<Leader>fg` | グレップ |
| `<Leader>fb` | バッファ一覧 |
| `<Leader>fh` | ヘルプタグ検索 |
| `<Leader>fm` | マーク一覧 |
| `<Leader>fd` | 診断一覧 |
| `<Leader>fs` | ドキュメントシンボル一覧 |
| `<Leader>fr` | LSP参照一覧 |
| `<Leader>e` | エクスプローラー切替 |
| `<Leader>E` | エクスプローラーで現在ファイルを表示 |

### Git & GitHub — `<Leader>g`

ローカルの hunk 操作 (gitsigns) とリモートの GitHub 操作 (snacks picker / octo.nvim) を、拡張機能の違いに関わらず同じ機能カテゴリとして統一している。

| キー | 動作 | 実装 |
| --- | --- | --- |
| `<Leader>gs` | hunk を stage | gitsigns |
| `<Leader>gu` | hunk の stage を取り消し | gitsigns |
| `<Leader>gr` | hunk を reset | gitsigns |
| `<Leader>gv` | hunk をプレビュー | gitsigns |
| `]h` / `[h` | 次 / 前の hunk へ | gitsigns |
| `<Leader>gb` | 現在行の blame を表示 | snacks |
| `<Leader>gd` | Git diff 一覧 | snacks picker |
| `<Leader>gil` | Issue 一覧 | snacks picker (gh) |
| `<Leader>gic` | Issue を新規作成 | octo |
| `<Leader>gpl` | PR 一覧 | snacks picker (gh) |
| `<Leader>gpb` | 現在ブランチの PR 一覧 | snacks picker (gh) |
| `<Leader>gpc` | PR をチェックアウト | octo |
| `<Leader>gpm` | PR をマージ (squash) | octo |
| `<Leader>gprs` | PR レビュー開始 | octo |
| `<Leader>gprr` | PR レビュー再開 | octo |
| `<Leader>gprx` | PR レビュー送信 | octo |
| `<Leader>gn` | GitHub 通知一覧 | octo |
| `<Leader>gR` | リポジトリ一覧 | octo |
| `]q` / `[q` | 次 / 前の変更ファイルへ (quickfix) | octo |

Octo のレビューバッファ内 (filetype=`octo`) のみで有効なキー:

| キー | 動作 |
| --- | --- |
| `<Leader>ca` (n/v) | コメントを追加 (バッファローカルでグローバルのコードアクションを上書き) |
| `<Leader>sa` (n/v) | 提案 (Suggestion) を追加 |
| `<Leader>ra` | リアクションを追加 |

### Docker / DevContainer — `<Leader>D`

| キー | 動作 |
| --- | --- |
| `<Leader>Du` | コンテナをビルドして起動 |
| `<Leader>Da` | コンテナにアタッチ |
| `<Leader>Ds` | コンテナを停止 |
| `<Leader>Dr` | コンテナを削除 |
| `<Leader>De` | コンテナ内でコマンドを実行 |
| `<Leader>Dk` | lazydocker をフローティングターミナルで起動 (lazydocker インストール時のみ) |

### 通知 — `<Leader>n`

| キー | 動作 |
| --- | --- |
| `<Leader>nh` | 通知履歴を表示 |
| `<Leader>nd` | 全通知を閉じる |

### Obsidian (ノート) — `<Leader>o`

Foam Vault との互換性を保ったまま obsidian.nvim で運用する。

| キー | 動作 |
| --- | --- |
| `<Leader>of` | ノート検索 (quick switch) |
| `<Leader>og` | ノート全文検索 |
| `<Leader>od` / `<Leader>oD` | 今日 / 昨日のデイリーノートを開く |
| `<Leader>on` | 新規ノート作成 |
| `<Leader>oN` | テンプレートから新規ノート作成 |
| `<Leader>oz` + `f/l/p/i` | タイプ別新規ノート (Fleeting/Literature/Permanent/Index) |
| `<Leader>ol` / `gf` (markdownバッファのみ) | リンクを辿る |
| `<Leader>ob` | バックリンク一覧 |
| `<Leader>ot` | タグ一覧 |
| `<Leader>oT` | テンプレートを挿入 |
| `<Leader>oc` | 目次 (TOC) を表示 |
| `<Leader>or` | ノートをリネーム (リンク自動更新) |
| `<Leader>ox` | チェックボックスをトグル |
| `<Leader>oi` | リンクを挿入 |
| `<Leader>ow` | ワークスペースを切替 |

### その他

| キー | 動作 |
| --- | --- |
| `<Leader>m` | Mason を開く |

### ファイルタイプ別 (`<LocalLeader>` = `\`)

| ファイルタイプ | キー | 動作 |
| --- | --- | --- |
| markdown | `\t` | テーブル整形 |
| markdown | `\p` | glow でプレビュー (要 glow) |
| python | `\d` | docstring を挿入 |
| json | `\j` | jq で整形 (要 jq) |
| tex | `\b` | latexmk でビルド (`:make`) |
| tex | `\v` | 生成された PDF を開く |

---

## カスタマイズのヒント

### LSP サーバーの追加

1. `lsp/<server_name>.lua` にサーバー設定を追加する。
2. `lua/plugins/config/lsp.lua` の `mason-lspconfig.setup()` の `ensure_installed` に `"<server_name>"` を追記する(`automatic_enable = true` のため、追記するだけで `vim.lsp.enable()` が自動的に呼ばれる)。

### Python 仮想環境

プロジェクトルートに `.venv/` があれば pyright が自動検出する。手動指定する場合は `lsp/pyright.lua` の設定を変更する。

### インライン Blame の常時表示を OFF にする

`lua/plugins/config/editor.lua` の gitsigns 設定で `current_line_blame = false` に変更し、必要なときだけ `<Leader>gb` で該当行の blame を表示する運用も可能。

### Obsidian Vault のパスを変更する

環境変数 `OBSIDIAN_VAULT_PATH` を設定するか、`lua/plugins/config/obsidian.lua` の `workspaces` を直接書き換える。
