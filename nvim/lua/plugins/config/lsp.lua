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
			"eslint",
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
			"clang-format",
			"markdownlint",
		},
		auto_update = false,
		run_on_start = true,
		start_delay = 1500,
	})
end)

-- ── フォーマッタの選択 ────────────────────────────────────────────────────────
-- 整形の「正」はプロジェクトの設定ファイルで決める。ESLint が正のリポジトリ (Nuxt 等)
-- で prettier を併用すると、折り返しで eslint-disable の対象行がずれ、
-- eslint --fix が抑制コメントごと削除してファイルを壊すため。
local function has_config(bufnr, tool)
	local name = vim.api.nvim_buf_get_name(bufnr or 0)
	return #vim.fs.find(function(f)
		-- string.find は integer|nil を返すため、vim.fs.find の注釈に合わせて boolean 化する
		return (f:find("^" .. tool .. "%.config%.") or f:find("^%." .. tool .. "rc")) ~= nil
	end, { upward = true, type = "file", path = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd() }) > 0
end

-- ESLint 設定があれば ESLint LSP に、無ければ prettier に整形させる。
-- ESLint LSP は textDocument/formatting を動的登録するため attach 直後は使えないが、
-- その間は整形が走らないだけなのでフォールバックは置かない。
local function web_formatters(bufnr)
	if has_config(bufnr, "eslint") then
		return { lsp_format = "prefer" }
	end
	return { "prettier" }
end

-- ── conform.nvim ──────────────────────────────────────────────────────────────
setup("conform", function(m)
	m.setup({
		formatters_by_ft = {
			python = { "ruff_format", "ruff_organize_imports" },
			javascript = web_formatters,
			typescript = web_formatters,
			javascriptreact = web_formatters,
			typescriptreact = web_formatters,
			vue = web_formatters,
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
		-- eslint_d はデーモン未起動時の初回のみ 3〜4 秒かかるため余裕を持たせる
		format_on_save = { timeout_ms = 5000, lsp_format = "fallback" },
	})
end)

-- ── nvim-lint ─────────────────────────────────────────────────────────────────
setup("lint", function(lint)
	-- python は ruff LSP、javascript / typescript / vue は ESLint LSP が診断を出すため
	-- ここに残すのは LSP の無い markdownlint だけ
	lint.linters_by_ft = {
		markdown = { "markdownlint" },
	}
	vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
		group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
		callback = function()
			lint.try_lint()
		end,
	})
end)
