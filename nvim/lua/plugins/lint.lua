return {
	{
		"mfussenegger/nvim-lint",
		-- ファイルを開いたタイミングでバックグラウンド起動
		event = { "BufReadPre", "BufNewFile" },

		config = function()
			local lint = require("lint")

			-- 言語ごとに使用するLinterを指定
			lint.linters_by_ft = {
				python = { "flake8", "mypy" },
				javascript = { "eslint_d" },
				typescript = { "eslint_d" },
			}

			-- ファイルを保存したときに自動でLinter（エラーチェック）を実行する設定
			vim.api.nvim_create_autocmd({ "BufWritePost" }, {
				callback = function()
					require("lint").try_lint()
				end,
			})
		end,
	},
}
