local setup = require("plugins.config.utils").setup

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- ── telescope ─────────────────────────────────────────────────────────────────
setup("telescope", function(m)
	local actions = require("telescope.actions")
	m.setup({
		defaults = {
			prompt_prefix = "  ",
			selection_caret = " ",
			path_display = { "truncate" },
			sorting_strategy = "ascending",
			layout_config = {
				horizontal = { prompt_position = "top", preview_width = 0.55 },
				width = 0.87,
				height = 0.80,
			},
			mappings = {
				i = {
					["<C-j>"] = actions.move_selection_next,
					["<C-k>"] = actions.move_selection_previous,
					["<Esc>"] = actions.close,
				},
			},
			file_ignore_patterns = {
				"node_modules/",
				".git/",
				"__pycache__/",
				"%.pyc",
				"%.DS_Store",
			},
		},
		pickers = { find_files = { hidden = true } },
	})
end)

-- ── gitsigns ──────────────────────────────────────────────────────────────────
setup("gitsigns", function(m)
	m.setup({
		signs = {
			add = { text = "▎" },
			change = { text = "▎" },
			delete = { text = "" },
			topdelete = { text = "" },
			changedelete = { text = "▎" },
		},
		current_line_blame = true,
		current_line_blame_opts = {
			virt_text = true,
			virt_text_pos = "eol",
			delay = 500,
		},
		current_line_blame_formatter = "  <author>, <author_time:%Y-%m-%d> · <summary>",
		preview_config = { border = "rounded" },
	})
end)

-- VSCode: git.blame.editorDecoration.enabled → gitsigns blame_line
map("n", "<Leader>gs", "<Cmd>Gitsigns stage_hunk<CR>", vim.tbl_extend("force", opts, { desc = "Stage hunk" }))
map("n", "<Leader>gu", "<Cmd>Gitsigns undo_stage_hunk<CR>", vim.tbl_extend("force", opts, { desc = "Undo stage hunk" }))
map("n", "<Leader>gr", "<Cmd>Gitsigns reset_hunk<CR>", vim.tbl_extend("force", opts, { desc = "Reset hunk" }))
map("n", "<Leader>gp", "<Cmd>Gitsigns preview_hunk<CR>", vim.tbl_extend("force", opts, { desc = "Preview hunk" }))
map("n", "]h", "<Cmd>Gitsigns next_hunk<CR>", vim.tbl_extend("force", opts, { desc = "Next hunk" }))
map("n", "[h", "<Cmd>Gitsigns prev_hunk<CR>", vim.tbl_extend("force", opts, { desc = "Prev hunk" }))

-- ── rainbow-delimiters ────────────────────────────────────────────────────────
setup("rainbow-delimiters", function(m)
	vim.g.rainbow_delimiters = {
		strategy = { [""] = m.strategy["global"] },
		query = { [""] = "rainbow-delimiters", lua = "rainbow-blocks" },
		highlight = {
			"RainbowDelimiterRed",
			"RainbowDelimiterYellow",
			"RainbowDelimiterBlue",
			"RainbowDelimiterOrange",
			"RainbowDelimiterGreen",
			"RainbowDelimiterViolet",
			"RainbowDelimiterCyan",
		},
	}
end)

local wk_ok, wk = pcall(require, "which-key")
if wk_ok then
	wk.add({
		{ "<Leader>g", group = "Git" },
	})
end
