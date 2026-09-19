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
			"bashls",
			"taplo",
			"yamlls",
			"html",
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
			"markdownlint",
			-- bashls が整形 / lint に使う外部バイナリ。サーバ本体には同梱されない。
			"shfmt",
			"shellcheck",
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
-- ESLint LSP は capability を申告しないため lsp/eslint.lua の on_attach で立てている。
-- それが無いと整形は一時的にではなく恒久的に走らないので、あちらを消さないこと。
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
			-- ruff format 相当は ruff LSP が textDocument/formatting で返すので CLI は不要。
			-- ただし import 整列は formatting に含まれない (isort 相当は別機能) ため
			-- ruff_organize_imports だけ CLI に残し、lsp_format = "last" で
			-- 「CLI で import 整列 → LSP で整形」の順に流す。
			python = { "ruff_organize_imports", lsp_format = "last" },
			javascript = web_formatters,
			typescript = web_formatters,
			javascriptreact = web_formatters,
			typescriptreact = web_formatters,
			vue = web_formatters,
			json = { "prettier" },
			jsonc = { "prettier" },
			markdown = { "markdownlint" },
			-- yaml / html は LSP も整形できるが、yamlls は .prettierrc を読まず
			-- html LSP は js-beautify 系で prettier と別実装のため CLI に寄せる。
			yaml = { "prettier" },
			html = { "prettier" },
			-- sh / toml は LSP (bashls / taplo) が正規 CLI を内部で呼ぶため CLI を置かない。
			-- c / cpp は clangd が .clang-format を読んで整形するため CLI を置かない。
			-- 設定ファイルが無いプロジェクトは lsp/clangd.lua の --fallback-style=Google に従う。
			lua = { "stylua" },
		},
		-- lsp_format は default_format_opts に置く。format_on_save に直接書くと
		-- conform の merge 順 (呼び出し時 opts > filetype 設定) により
		-- formatters_by_ft 側の lsp_format が上書きされて効かなくなるため。
		default_format_opts = { lsp_format = "fallback" },
		-- eslint_d はデーモン未起動時の初回のみ 3〜4 秒かかるため余裕を持たせる
		format_on_save = { timeout_ms = 5000 },
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
