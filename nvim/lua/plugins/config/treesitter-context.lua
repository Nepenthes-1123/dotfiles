local setup = require("plugins.config.utils").setup

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
