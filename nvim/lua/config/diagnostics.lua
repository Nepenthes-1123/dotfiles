-- =============================================================================
-- config/diagnostics.lua  –  診断の表示
-- =============================================================================

-- ── 診断表示設定 ─────────────────────────────────────────────────────────────
-- VSCode: usernamehw.errorlens の再現
-- Neovim v0.10+ では vim.diagnostic.config の virtual_text でインライン表示
vim.diagnostic.config({
	virtual_text = {
		enabled = true,
		spacing = 4,
		prefix = "■", -- ErrorLens のアイコン風
		format = function(diag)
			-- エラーの種類ごとにアイコンを付加
			local icons = { ERROR = " ", WARN = " ", INFO = " ", HINT = "󰌵 " }
			local severity = vim.diagnostic.severity[diag.severity]
			return (icons[severity] or "") .. diag.message
		end,
	},
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "",
			[vim.diagnostic.severity.WARN] = "",
			[vim.diagnostic.severity.INFO] = "",
			[vim.diagnostic.severity.HINT] = "󰌵",
		},
	},
	underline = true,
	update_in_insert = false, -- insert 中は診断を更新しない
	severity_sort = true,
	float = {
		border = "rounded",
		source = true, -- ソース名を表示 (どの LSP からの診断か)
		header = "",
		prefix = "",
	},
})

-- ── LSP サーバー有効化 ───────────────────────────────────────────────────────
-- vim.pack.add() で Mason / mason-lspconfig が常にロードされるため、
-- サーバーの有効化は plugins/lsp.lua の mason-lspconfig.setup() が担う。
-- （mason-lspconfig の automatic_enable = true により、
--   ensure_installed の各サーバーに対して自動で vim.lsp.enable() が呼ばれる）
--
-- lsp/<server>.lua の設定ファイルは mason-lspconfig が vim.lsp.enable() を
-- 呼ぶ際に自動で読み込まれる。追加サーバーは以下の2箇所に記述すること:
--   1. lsp/<server>.lua              … サーバー固有の設定
--   2. plugins/lsp.lua の            … mason-lspconfig.setup() の ensure_installed
