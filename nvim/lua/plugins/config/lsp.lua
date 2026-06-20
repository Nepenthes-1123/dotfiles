local setup = require("plugins.config.utils").setup

-- ── Mason ────────────────────────────────────────────────────────────────────
setup("mason", function(m)
	m.setup({
		ui = {
			border = "rounded",
			width = 0.8,
			height = 0.8,
			icons = {
				package_installed = "✓",
				package_pending = "➜",
				package_uninstalled = "✗",
			},
		},
		max_concurrent_installers = 4,
	})
	vim.keymap.set("n", "<Leader>m", "<Cmd>Mason<CR>", { noremap = true, silent = true, desc = "Open Mason" })
end)

-- ── mason-lspconfig ───────────────────────────────────────────────────────────
setup("mason-lspconfig", function(m)
	m.setup({
		ensure_installed = {
			"pyright",
			"ruff",
			"clangd",
			"lua_ls",
			"vue_ls",
			"vtsls",
			"texlab",
			"marksman",
			"jsonls",
			"dockerls",
			"docker_compose_language_service",
		},
		automatic_enable = true,
	})
end)

-- ── mason-tool-installer ──────────────────────────────────────────────────────
setup("mason-tool-installer", function(m)
	m.setup({
		ensure_installed = {
			"ruff",
			"stylua",
			"prettier",
			"eslint_d",
			"clang-format",
			"markdownlint",
		},
		auto_update = false,
		run_on_start = true,
		start_delay = 1500,
	})
end)

-- ── conform.nvim ──────────────────────────────────────────────────────────────
setup("conform", function(m)
	m.setup({
		formatters_by_ft = {
			python = { "ruff_format", "ruff_organize_imports" },
			javascript = { "prettier" },
			typescript = { "prettier" },
			javascriptreact = { "prettier" },
			typescriptreact = { "prettier" },
			vue = { "prettier" },
			json = { "prettier" },
			jsonc = { "prettier" },
			markdown = { "markdownlint" },
			c = { "clang_format" },
			cpp = { "clang_format" },
			lua = { "stylua" },
		},
		formatters = {
			clang_format = { prepend_args = { "--style={BasedOnStyle: Google, IndentWidth: 4}" } },
		},
		format_on_save = { timeout_ms = 2000, lsp_fallback = true },
	})
end)

-- ── nvim-lint ─────────────────────────────────────────────────────────────────
setup("lint", function(lint)
	lint.linters_by_ft = {
		python = { "ruff" },
		javascript = { "eslint_d" },
		typescript = { "eslint_d" },
		vue = { "eslint_d" },
		markdown = { "markdownlint" },
	}
	vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
		group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
		callback = function()
			lint.try_lint()
		end,
	})
end)
