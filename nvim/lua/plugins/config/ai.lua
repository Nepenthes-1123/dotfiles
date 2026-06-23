-- =============================================================================
-- lua/plugins/config/ai.lua  –  AI協同設定 (Copilot + CodeCompanion)
-- =============================================================================
local setup = require("plugins.config.utils").setup

-- ── copilot.lua (自動補完) ───────────────────────────────────────────────────
setup("copilot", function(copilot)
	copilot.setup({
		panel = { enabled = false },
		suggestion = {
			enabled = true,
			auto_trigger = true,
			debounce = 75,
			keymap = {
				accept = "<M-l>", -- Alt + L で提案を確定
				accept_word = false,
				accept_line = false,
				next = "<M-]>", -- Alt + ] で次の提案
				prev = "<M-[>", -- Alt + [ で前の提案
				dismiss = "<C-]>",
			},
		},
		filetypes = {
			markdown = false,
			help = false,
			gitcommit = true,
			gitrebase = false,
			hgcommit = false,
			svn = false,
			cvs = false,
			["."] = false,
		},
		copilot_node_command = vim.env.COPILOT_NODE_CMD or "node", -- Node.js がパスに通っている必要があります
	})
end)
