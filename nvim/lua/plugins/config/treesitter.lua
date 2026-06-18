local setup = require("plugins.config.utils").setup

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
	pattern = "vue",
	callback = function()
		pcall(vim.treesitter.start)
	end,
})
