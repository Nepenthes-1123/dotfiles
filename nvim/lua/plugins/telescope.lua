return {
	{
		"nvim-telescope/telescope.nvim",

		dependencies = {
			"nvim-lua/plenary.nvim",
		},

		build = "make",

		config = function()
			local telescope = require("telescope")

			telescope.setup({
				defaults = {
					path_display = function(_, path)
						if type(path) ~= "string" then
							return path
						end

						local local_path = string.gsub(path, "\\", "/")
						return local_path
					end,
				},
			})

			local builtin = require("telescope.builtin")

			vim.keymap.set("n", "<leader>ff", builtin.find_files)
			vim.keymap.set("n", "<leader>fg", builtin.live_grep)
			vim.keymap.set("n", "<leader>fb", builtin.buffers)
			vim.keymap.set("n", "<leader>fh", builtin.help_tags)
		end,
	},
}
