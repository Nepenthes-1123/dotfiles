return {
	-- Mason本体
	{
		"williamboman/mason.nvim",
		dependencies = {
			"williamboman/mason-lspconfig.nvim",
			"neovim/nvim-lspconfig",
		},

		config = function()
			require("mason").setup()
		end,
	},

	-- Linter / Formatterの自動インストール
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		opts = {
			ensure_installed = {
				-- Lua
				"stylua",
				-- Python
				"black",
				"flake8",
				"mypy",
				-- C++
				"clang-format",
				-- Markdown
				"markdownlint",
				-- Web系 (もし使う場合)
				"prettier",
				"eslint_d",
			},
			-- Neovim起動時に未インストールのものがあれば自動でインストールする
			run_on_start = true,
		},
	},

	-- LSP自動インストールと設定の橋渡し
	{
		"williamboman/mason-lspconfig.nvim",

		dependencies = {
			"williamboman/mason.nvim",
		},

		opts = {
			ensure_installed = {
				"lua_ls",
				"clangd",
				"pyright",
				"marksman",
				"texlab",
				"vtsls",
			},
		},
	},

	-- LSP本体の設定
	{
		"neovim/nvim-lspconfig",

		config = function()
			vim.lsp.enable("lua_ls")
			vim.lsp.enable("clangd")
			vim.lsp.enable("pyright")
			vim.lsp.enable("marksman")
			vim.lsp.enable("texlab")
			vim.lsp.enable("vtsls")

			vim.keymap.set("n", "gd", vim.lsp.buf.definition)
			vim.keymap.set("n", "K", vim.lsp.buf.hover)
			vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename)
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action)
		end,
	},
}
