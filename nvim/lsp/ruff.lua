-- =============================================================================
-- lsp/ruff.lua  –  Ruff LSP サーバー設定
-- VSCode: ms-python.black-formatter + ms-python.flake8 + ms-python.isort の統合版
-- =============================================================================
-- VSCode 設定の移植:
--   "flake8.args": ["--ignore=E203,W503,W504", "--max-line-length=88"]
--   "black-formatter.importStrategy": "useBundled"
--   "editor.codeActionsOnSave": { "source.organizeImports": "explicit" }
-- lsp.lua など、LSPをセットアップするファイル内
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok, blink = pcall(require, "blink.cmp")
if ok then
	capabilities = blink.get_lsp_capabilities(capabilities)
end

return {
	cmd = { "ruff", "server" },
	filetypes = { "python" },
	root_markers = {
		"pyproject.toml",
		"ruff.toml",
		".ruff.toml",
		"setup.py",
		".git",
	},
	init_options = {
		settings = {
			-- black 互換の行長 88
			lineLength = 88,
			lint = {
				select = { "E", "F", "W", "I", "N", "UP" },
				-- VSCode: "flake8.args": ["--ignore=E203,W503,W504"]
				ignore = { "E203", "W503", "W504" },
			},
			format = {
				-- black 互換フォーマット
				preview = false,
			},
			-- isort 統合: import の自動整理
			organizeImports = true,
		},
	},
	-- ruff はフォーマットと診断を提供するが型チェックは pyright に任せる
	-- 保存時に organizeImports (source.organizeImports) を実行
	on_attach = function(_, bufnr)
		-- ruff 経由で保存時に import 整理を行う code action
		vim.api.nvim_create_autocmd("BufWritePre", {
			buffer = bufnr,
			callback = function()
				vim.lsp.buf.code_action({
					context = { only = { "source.organizeImports" }, diagnostics = {} },
					apply = true,
					-- ruff のみに絞る
					filter = function(action)
						return action.kind == "source.organizeImports"
					end,
				})
			end,
		})
	end,
	capabilities = capabilities,
}
