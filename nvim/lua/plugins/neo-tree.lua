return {
	{
		"nvim-neo-tree/neo-tree.nvim",

		branch = "v3.x",

		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},

		config = function()
			require("neo-tree").setup({
				close_if_last_window = true,

				-- キーマッピング上書き
				window = {
					mappings = {
						["<cr>"] = "open_tabnew",
					},
				},

				filesystem = {
					follow_current_file = {
						enabled = true,
					},

					filtered_items = {
						visible = true,
						hide_dotfiles = false,
						hide_gitignored = false,
					},
				},

				enable_git_status = true,
				enable_diagnostics = true,
			})

			vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>")
		end,
	},
}
