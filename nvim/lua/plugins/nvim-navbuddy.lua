return {
	{
		"SmiteshP/nvim-navbuddy",

		-- ファイルを開いた時に読み込む
		event = { "BufReadPre", "BufNewFile" },

		-- 依存するプラグイン（これらが無いと動かないため自動で読み込ませる）
		dependencies = {
			"neovim/nvim-lspconfig",
			"SmiteshP/nvim-navic",
			"MunifTanjim/nui.nvim",
			"nvim-telescope/telescope.nvim",
		},

		-- lazy.nvim流のキーバインド設定
		keys = {
			{ "<leader>nb", "<cmd>Navbuddy<cr>", desc = "Navbuddyを開く" },
		},

		-- 設定の中に require が必要な場合は opts を関数にして return します
		opts = function()
			local actions = require("nvim-navbuddy.actions")

			return {
				window = {
					size = { height = "40%", width = "100%" },
					position = { row = "96%", col = "50%" },
				},
				mappings = {
					-- Navbuddyを開いている時に 't' を押すとTelescopeで検索できる設定
					["t"] = actions.telescope({
						layout_config = {
							height = 0.40,
							width = 0.90,
							prompt_position = "top",
							preview_width = 0.70,
						},
						layout_strategy = "horizontal",
					}),
				},
				lsp = {
					auto_attach = true,
				},
			}
		end,
	},
}
