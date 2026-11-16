local setup = require("plugins.utils").setup

-- ── nvim-treesitter ───────────────────────────────────────────────────────────
setup("nvim-treesitter.configs", function(m)
	---@diagnostic disable-next-line: missing-fields
	m.setup({
		ensure_installed = {
			"python",
			"lua",
			"c",
			"cpp",
			"vim",
			"vimdoc",
			"javascript",
			"typescript",
			"vue",
			"json",
			"jsonc",
			"markdown",
			"markdown_inline",
			"bash",
			"zsh",
			"yaml",
			"toml",
			"html",
			"css",
			"pug",
			"scss",
		},
		highlight = { enable = true, additional_vim_regex_highlighting = false },
		indent = { enable = true },
		incremental_selection = {
			enable = true,
			keymaps = {
				init_selection = "<C-Space>",
				node_incremental = "<C-Space>",
				node_decremental = "<BS>",
			},
		},
	})
end)

vim.api.nvim_create_autocmd({ "FileType" }, {
	group = vim.api.nvim_create_augroup("treesitter-vue-start", { clear = true }),
	pattern = "vue",
	callback = function()
		pcall(vim.treesitter.start)
	end,
})

-- ── nvim-treesitter-context ──────────────────────────────────────────────────
setup("treesitter-context", function(m)
	m.setup({
		enable = true,
		max_lines = 3,
		min_window_height = 0,
		line_numbers = true,
		multiline_threshold = 20,
		trim_scope = "outer",
		mode = "topline",
		separator = "▔",
		zindex = 10,
		multiwindow = true,
	})

	vim.api.nvim_set_hl(0, "TreesitterContextSeparator", { link = "DiagnosticInfo" })
end)
