-- =============================================================================
-- lsp/eslint.lua  –  ESLint LSP (vscode-eslint-language-server)
-- VSCode: dbaeumer.vscode-eslint
-- =============================================================================
-- 診断に加えて textDocument/formatting も提供する (settings.format = true)。
-- conform.nvim の lsp_format = "prefer" 経由で保存時整形に使うため、
-- LspEslintFixAll 相当のコマンドは定義していない (vim.lsp.buf.format で足りる)。
-- =============================================================================
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok, blink = pcall(require, "blink.cmp")
if ok then
	capabilities = blink.get_lsp_capabilities(capabilities)
end

local eslint_config_files = {
	"eslint.config.js",
	"eslint.config.mjs",
	"eslint.config.cjs",
	"eslint.config.ts",
	"eslint.config.mts",
	"eslint.config.cts",
	".eslintrc",
	".eslintrc.js",
	".eslintrc.cjs",
	".eslintrc.json",
	".eslintrc.yaml",
	".eslintrc.yml",
}

return {
	cmd = { "vscode-eslint-language-server", "--stdio" },
	filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
	workspace_required = true,
	capabilities = capabilities,

	-- ESLint 設定が存在するプロジェクトでのみ起動する。
	-- root は node_modules の解決基点となるロックファイルの位置に合わせる。
	root_dir = function(bufnr, on_dir)
		local fname = vim.api.nvim_buf_get_name(bufnr)
		if #vim.fs.find(eslint_config_files, { path = fname, upward = true, type = "file", limit = 1 }) == 0 then
			return
		end
		local markers = { "pnpm-lock.yaml", "package-lock.json", "yarn.lock", "bun.lock", ".git" }
		on_dir(vim.fs.root(bufnr, markers) or vim.fn.getcwd())
	end,

	-- vscode-eslint は workspace/configuration で以下を要求する。
	-- 欠けているとサーバ側が undefined 参照で落ちるため省略できない。
	-- https://github.com/microsoft/vscode-eslint#settings-options
	settings = {
		validate = "on",
		useESLintClass = false,
		experimental = {},
		codeActionOnSave = { enable = false, mode = "all" },
		format = true,
		quiet = false,
		onIgnoredFiles = "off",
		rulesCustomizations = {},
		run = "onType", -- 型情報付き lint が重い場合は "onSave" に変更する
		problems = { shortenToSingleLine = false },
		nodePath = "",
		workingDirectory = { mode = "auto" },
		codeAction = {
			disableRuleComment = { enable = true, location = "separateLine" },
			showDocumentation = { enable = true },
		},
	},

	-- workspaceFolder は VSCode 固有の概念で、サーバが設定ファイルを探索する
	-- 上限ディレクトリとして使われる。未設定だと config を見つけられない。
	before_init = function(_, config)
		if config.root_dir then
			config.settings = config.settings or {}
			config.settings.workspaceFolder = {
				uri = config.root_dir,
				name = vim.fn.fnamemodify(config.root_dir, ":t"),
			}
		end
	end,

	handlers = {
		-- ローカルの ESLint を実行してよいかの確認。4 (approved) を返さないと lint が走らない
		["eslint/confirmESLintExecution"] = function(_, result)
			if not result then
				return
			end
			return 4
		end,
		["eslint/openDoc"] = function(_, result)
			if result then
				vim.ui.open(result.url)
			end
			return {}
		end,
		["eslint/probeFailed"] = function()
			vim.notify("ESLint probe failed.", vim.log.levels.WARN)
			return {}
		end,
		["eslint/noLibrary"] = function()
			vim.notify("ESLint library が見つかりません。", vim.log.levels.WARN)
			return {}
		end,
	},
}
