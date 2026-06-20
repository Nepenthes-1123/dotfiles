local setup = require("plugins.config.utils").setup

-- ── カラースキーム: Rosé Pine Moon ───────────────────────────────────────────
setup("rose-pine", function(m)
	m.setup({
		variant = "moon",
		dark_variant = "moon",
		styles = { bold = true, italic = false, transparency = true },
		highlight_groups = {
			DiagnosticVirtualTextError = { fg = "love", bg = "love", blend = 10 },
			DiagnosticVirtualTextWarn = { fg = "gold", bg = "gold", blend = 10 },
			DiagnosticVirtualTextInfo = { fg = "foam", bg = "foam", blend = 10 },
			DiagnosticVirtualTextHint = { fg = "iris", bg = "iris", blend = 10 },
		},
	})
	vim.cmd("colorscheme rose-pine-moon")
end)

-- ── lualine ───────────────────────────────────────────────────────────────────
setup("lualine", function(m)
	m.setup({
		options = {
			theme = "rose-pine",
			globalstatus = true,
			component_separators = { left = "", right = "" },
			section_separators = { left = "", right = "" },
			disabled_filetypes = { statusline = { "NvimTree" } },
		},
		sections = {
			lualine_a = { "mode" },
			lualine_b = {
				{ "branch", icon = "" },
				{ "diff", symbols = { added = " ", modified = " ", removed = " " } },
				{
					"diagnostics",
					sources = { "nvim_diagnostic" },
					symbols = { error = " ", warn = " ", info = " ", hint = "󰌵 " },
				},
			},
			lualine_c = {
				{ "filename", path = 1, symbols = { modified = "●", readonly = "" } },
			},
			lualine_x = {
				{
					function()
						local clients = vim.lsp.get_clients({ bufnr = 0 })
						if #clients == 0 then
							return ""
						end
						return " "
							.. table.concat(
								vim.tbl_map(function(c)
									return c.name
								end, clients),
								", "
							)
					end,
					color = { fg = "#c4a7e7" },
				},
				"encoding",
				{ "fileformat", symbols = { unix = "LF", dos = "CRLF", mac = "CR" } },
				"filetype",
			},
			lualine_y = { "progress" },
			lualine_z = { "location" },
		},
		extensions = { "nvim-tree", "quickfix" },
	})
end)

-- ── which-key ─────────────────────────────────────────────────────────────────
setup("which-key", function(m)
	m.setup({
		delay = 500,
		spec = {
			{ "<Leader>c", group = "Code (LSP)" },
			{ "<Leader>b", group = "Buffer" },
			{ "<Leader>m", group = "Mason" },
		},
	})
end)

-- =============================================================================
-- render-markdown.nvim 設定
-- VSCode: Markdown プレビュー (yzhang.markdown-all-in-one の見た目を
--         Neovim エディタ内でリアルタイムにレンダリングして再現)
-- =============================================================================
-- 依存プラグイン (いずれも plugins/init.lua の vim.pack.add() で導入済み):
--   - nvim-treesitter/nvim-treesitter
--   - nvim-tree/nvim-web-devicons
--
-- obsidian.nvim の ui モジュールは Vault 外の Markdown に適用されず、
-- 将来的に廃止予定 (専用レンダラの使用が推奨) のため、
-- Vault内外問わず一貫した見た目にするためこちらを使用する。
-- (obsidian.lua 側は ui.enable = false に設定済み)
-- =============================================================================
setup("render-markdown", function(m)
	m.setup({
		-- 対象ファイルタイプ (lazy.nvim の ft = {...} 相当)
		-- vim.pack には遅延読み込み機構が無いため、setup 内の file_types で制御する
		file_types = { "markdown", "norg", "rmd", "org" },

		enabled = true,

		-- markdown.preview.typographer: true 相当
		-- 'n' (Normal) と 'c' (Command-line) モードでレンダリングを有効化
		render_modes = { "n", "c" },

		heading = {
			enabled = true,
			sign = true,
			icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
		},

		code = {
			enabled = true,
			sign = true,
			style = "full",
			border = "thin",
		},

		dash = { enabled = true },
		bullet = { enabled = true },

		checkbox = {
			enabled = true,
			unchecked = { icon = "󰄱 " },
			checked = { icon = "󰱒 " },
		},

		pipe_table = {
			enabled = true,
			-- markdown.extension.tableFormatter.enabled: true 相当
			style = "full",
		},

		link = { enabled = true },
	})
end)
