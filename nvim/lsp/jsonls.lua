-- =============================================================================
-- lsp/jsonls.lua  –  JSON LSP サーバー設定
-- VSCode: esbenp.prettier-vscode (JSON フォーマット) の再現
-- =============================================================================
-- VSCode 設定の移植:
--   "[json]": { "editor.defaultFormatter": "esbenp.prettier-vscode" }
--   "[json]": { "editor.quickSuggestions": { "strings": true } }
-- jsonls は SchemaStore からスキーマを自動取得して補完・検証を行う
-- lsp.lua など、LSPをセットアップするファイル内
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok, blink = pcall(require, "blink.cmp")
if ok then
	capabilities = blink.get_lsp_capabilities(capabilities)
end

return {
	cmd = { "vscode-json-language-server", "--stdio" },
	filetypes = { "json", "jsonc" },
	root_markers = { ".git" },
	-- JSON スキーマ自動検出 (SchemaStore.nvim を利用する場合は plugins/init.lua で上書き)
	settings = {
		json = {
			-- SchemaStore プラグインが無い場合の最低限のスキーマ
			schemas = {
				{
					fileMatch = { "package.json" },
					url = "https://json.schemastore.org/package.json",
				},
				{
					fileMatch = { "tsconfig*.json" },
					url = "https://json.schemastore.org/tsconfig.json",
				},
				{
					fileMatch = { ".eslintrc", ".eslintrc.json" },
					url = "https://json.schemastore.org/eslintrc.json",
				},
				{
					fileMatch = { "pyrightconfig.json" },
					url = "https://raw.githubusercontent.com/microsoft/pyright/main/packages/pyright/schemas/pyrightconfig.schema.json",
				},
			},
			validate = { enable = true },
		},
	},
	capabilities = capabilities,
	-- VSCode: "editor.quickSuggestions": { "strings": true }
	-- jsonls はデフォルトで文字列内補完を提供するため追加設定不要
	on_attach = function(_, bufnr)
		-- JSONC (コメント付き JSON) のフォーマットを有効化
		if vim.bo[bufnr].filetype == "jsonc" then
			vim.bo[bufnr].filetype = "jsonc"
		end
	end,
}
