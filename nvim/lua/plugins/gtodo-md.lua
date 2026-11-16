-- =============================================================================
-- lua/plugins/gtodo-md.lua  –  gtodo-md.nvim 設定
-- =============================================================================

local setup = require("plugins.utils").setup

setup("gtodo-md", function(m)
	m.setup({
		use_default_keymaps = true,
		picker = "auto",
		conceal_tags = { "id", "created", "completed_at" },
		float_ratio = { width = 0.95, height = 0.95 },
		kanban_ratio = { width = 1, height = 1 },
	})
end)
