-- =============================================================================
-- lsp/pyright.lua  –  Pyright LSP サーバー設定
-- VSCode: ms-python.vscode-pylance (Pylance の OSS コア)
-- =============================================================================
-- mypy-type-checker の設定を移植:
--   "--warn-return-any", "--no-implicit-optional",
--   "--disallow-untyped-calls", "--disallow-untyped-defs"
-- lsp.lua など、LSPをセットアップするファイル内
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok, blink = pcall(require, "blink.cmp")
if ok then
	capabilities = blink.get_lsp_capabilities(capabilities)
end

return {
	cmd = { "pyright-langserver", "--stdio" },
	filetypes = { "python" },
	root_markers = {
		"pyproject.toml",
		"setup.py",
		"setup.cfg",
		"requirements.txt",
		".git",
	},
	settings = {
		python = {
			pythonPath = (function()
				-- windows は python3 コマンドがないため ptython を優先
				if vim.fn.has("win32") == 1 then
					return vim.fn.exepath("python") ~= "" and vim.fn.exepath("python") or "python"
				end
				return vim.fn.exepath("python3") ~= "" and vim.fn.exepath("python3") or "python"
			end)(),
			venvPath = vim.fn.expand("~/.virtualenvs"),
			analysis = {
				typeCheckingMode = "basic",
				-- VSCode: mypy の "--warn-return-any" に対応
				reportReturnType = "warning",
				-- VSCode: "--no-implicit-optional" に対応
				reportOptionalCall = "warning",
				reportOptionalMemberAccess = "warning",
				-- VSCode: "--disallow-untyped-defs" に対応
				reportUnknownParameterType = "information",
				reportUnknownVariableType = "information",
				-- 未使用インポートの報告 (isort と連携)
				reportUnusedImport = "information",
				-- 自動補完でスタブを参照
				useLibraryCodeForTypes = true,
				autoSearchPaths = true,
				diagnosticMode = "workspace",
			},
		},
	},
	capabilities = capabilities,
}
