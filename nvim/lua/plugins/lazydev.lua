return {
	{
		"folke/lazydev.nvim",
		ft = "lua", -- Luaファイルを開いた時だけ起動する（動作を軽くするため）
		opts = {
			library = {
				-- 必要に応じて追加の型定義を読み込む設定
				{ path = "luvit-meta/library", words = { "vim%.uv" } },
			},
		},
	},
	-- vim.uv（Neovimの内部API）の型定義（オプション）
	{ "Bilal2453/luvit-meta", lazy = true },
}
