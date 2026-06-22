-- =============================================================================
-- lua/plugins/init.lua  –  プラグイン管理 (vim.pack API / Neovim v0.12 組み込み)
-- =============================================================================
-- vim.pack.add() は：
--   - 未インストールのプラグインを自動で git clone（初回起動時に確認ダイアログ）
--   - インストール済みであれば即 runtimepath に追加してロード
--   - バージョンは nvim-pack-lock.json で固定管理
--   - :Pack install / :Pack update でコマンドライン操作も可能
-- =============================================================================

-- ── Treesitter ビルドフック ───────────────────────────────────────────────────
-- PackChanged イベントは vim.pack.add() より前に登録する必要がある
vim.api.nvim_create_autocmd("PackChanged", {
	group = vim.api.nvim_create_augroup("pack-changed-hooks", { clear = true }),
	callback = function(ev)
		local name = ev.data.spec.name
		local kind = ev.data.kind -- 'install' | 'update' | 'delete'
		-- nvim-treesitter: install/update 後に :TSUpdate でパーサーをビルド
		if name == "nvim-treesitter" and (kind == "install" or kind == "update") then
			if not ev.data.active then
				vim.cmd.packadd("nvim-treesitter")
			end
			vim.cmd("TSUpdate")
		end
	end,
})

-- =============================================================================
-- プラグイン宣言
-- 形式:
--   "owner/repo"               … GitHub ショートハンド (https://github.com/ を補完)
--   { src = "owner/repo", version = "vX.Y.Z" }  … バージョン固定
-- =============================================================================
vim.pack.add({

	-- ── カラースキーム ──────────────────────────────────────────────────────────
	-- VSCode: "workbench.colorTheme": "Rosé Pine Moon (no italics)"
	"https://github.com/rose-pine/neovim",

	-- ── アイコン (nvim-tree / lualine が依存) ────────────────────────────────
	"https://github.com/nvim-tree/nvim-web-devicons",

	-- ── ファイルツリー ──────────────────────────────────────────────────────────
	-- VSCode: サイドバーのファイルエクスプローラー
	-- snacksで代替

	-- ── ファジーファインダー ────────────────────────────────────────────────────
	-- VSCode: Ctrl+P / Ctrl+Shift+F
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/nvim-telescope/telescope.nvim",

	-- ── Git 連携 ────────────────────────────────────────────────────────────────
	-- VSCode: git.blame.editorDecoration.enabled + Gutter 差分表示
	"https://github.com/lewis6991/gitsigns.nvim",

	-- ── 補完エンジン ────────────────────────────────────────────────────────────
	-- VSCode: editor.suggestSelection / quickSuggestions
	"https://github.com/saghen/blink.lib",
	"https://github.com/saghen/blink.cmp",

	-- ── シンタックスハイライト ──────────────────────────────────────────────────
	"https://github.com/nvim-treesitter/nvim-treesitter",

	-- ── ブラケットペアのカラー化 ────────────────────────────────────────────────
	-- VSCode: "editor.bracketPairColorization.independentColorPoolPerBracketType": true
	"https://github.com/HiPhish/rainbow-delimiters.nvim",

	-- ── フォーマッター ──────────────────────────────────────────────────────────
	-- VSCode: esbenp.prettier-vscode / ms-python.black-formatter
	"https://github.com/stevearc/conform.nvim",

	-- ── リンター ────────────────────────────────────────────────────────────────
	-- VSCode: dbaeumer.vscode-eslint / ms-python.flake8
	"https://github.com/mfussenegger/nvim-lint",

	-- ── LSP サーバー管理 (Mason) ────────────────────────────────────────────────
	-- VSCode 拡張が言語サーバーを自動インストールしてくれる体験を再現
	"https://github.com/williamboman/mason.nvim",
	"https://github.com/williamboman/mason-lspconfig.nvim",
	"https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",

	-- ── コメントトグル ──────────────────────────────────────────────────────────
	-- VSCode: Ctrl+/
	-- 組み込みになったらしいので削除

	-- ── ステータスライン ────────────────────────────────────────────────────────
	"https://github.com/nvim-lualine/lualine.nvim",

	-- ── インデントガイド ────────────────────────────────────────────────────────
	-- VSCode: "editor.guides.bracketPairs": true
	-- snacksでやる

	-- ── 自動括弧補完 ────────────────────────────────────────────────────────────
	"https://github.com/windwp/nvim-autopairs",

	-- ── カーソル下の単語ハイライト ──────────────────────────────────────────────
	-- VSCode: 変数にカーソルを合わせると同名箇所が全てハイライト
	-- おそらく組み込み？

	-- ── キーバインドガイド ──────────────────────────────────────────────────────
	"https://github.com/folke/which-key.nvim",

	-- obsidian 用
	"https://github.com/obsidian-nvim/obsidian.nvim",

	-- Dev Container サポート (ms-vscode-remote.remote-containers の再現)
	-- .devcontainer/devcontainer.json を読み取り、コンテナ内で Neovim を起動する
	"https://github.com/esensar/nvim-dev-container",

	-- ── UI 補完 (通知・入力・スクロール) ────────────────────────────────────────
	-- ui2 がカバーしない noice.nvim 相当機能 (notifier, input, scroll) を補完
	-- 設定は lua/plugins/snacks.lua で管理
	"https://github.com/folke/snacks.nvim",

	"https://github.com/MeanderingProgrammer/render-markdown.nvim",

	-- ── GitHub PR / Issue 連携 ───────────────────────────────────────────────
	-- VSCode: GitHub.vscode-pull-request-github の代替
	-- 要: GitHub CLI (gh) のインストールと `gh auth login`
	"https://github.com/pwntester/octo.nvim",

	-- コマンドラインのフローティング
	"https://github.com/rachartier/tiny-cmdline.nvim",

	-- ── AI 自動補完 ─────────────────────────────────────────────────────────────
	"https://github.com/zbirenbaum/copilot.lua",
})

-- =============================================================================
-- 各プラグインの設定を読み込む
-- =============================================================================
require("plugins.config.snacks")
require("plugins.config.ui")
require("plugins.config.editor")
require("plugins.config.lsp")
require("plugins.config.blink")
require("plugins.config.treesitter")
require("plugins.config.obsidian")
require("plugins.config.docker")
require("plugins.config.octo")
require("plugins.config.tiny-cmdline")
require("plugins.config.ai")
