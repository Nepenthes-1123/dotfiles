-- 保存時 format。
return {
	{
		"stevearc/conform.nvim",

		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "black" },
				cpp = { "clang_format" },
				markdown = { "markdownlint" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				sql = { "sql_formatter" },
			},

			format_on_save = {
				timeout_ms = 500,
				lsp_format = "fallback", -- フォーマッタがない言語はLSPの標準言語で整形
			},

			formatters = {
				clang_format = {
					prepend_args = { "-style={BasedOnStale: Google, IndentWidth: 4}" },
				},
			},
		},
	},
}
