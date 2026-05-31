return {
	{
		"saghen/blink.cmp",

		dependencies = {
			"rafamadriz/friendly-snippets",
		},

		version = "*",

		opts = {
			keymap = {
				preset = "default",
				-- Tab: 次の候補を選択（スニペット展開中なら次の入力項目へ）
				["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
				-- Shift+Tab: 前の候補を選択
				["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
				-- Enter: 候補を確定
				["<CR>"] = { "accept", "fallback" },

				-- 補足: 横に出る「詳細ドキュメント」をスクロールしたい場合
				["<C-d>"] = { "scroll_documentation_down", "fallback" },
				["<C-u>"] = { "scroll_documentation_up", "fallback" },
			},

			appearance = {
				nerd_font_variant = "mono",
			},

			completion = {
				documentation = {
					auto_show = true,
				},
			},

			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
		},
	},
}
