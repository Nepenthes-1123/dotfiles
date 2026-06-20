-- lsp.lua など、LSPをセットアップするファイル内
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok, blink = pcall(require, "blink.cmp")
if ok then
	capabilities = blink.get_lsp_capabilities(capabilities)
end
-- =============================================================================
-- lsp/lua_ls.lua  –  Lua LSP サーバー設定
-- VSCode: sumneko.lua 拡張のサーバー
-- =============================================================================

return {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = { ".luarc.json", ".luarc.jsonc", ".luacheckrc", "stylua.toml", ".git" },
	settings = {
		Lua = {
			runtime = {
				-- Neovim は LuaJIT を使用
				version = "LuaJIT",
			},
			workspace = {
				-- Neovim の runtime path を追加 (vim API の補完を有効化)
				library = vim.api.nvim_get_runtime_file("", true),
				checkThirdParty = false,
			},
			diagnostics = {
				-- "vim" グローバル変数の警告を抑制
				globals = { "vim" },
			},
			telemetry = {
				enable = false,
			},
			format = {
				enable = true,
				defaultConfig = {
					indent_style = "space",
					indent_size = "2",
				},
			},
		},
	},
	capabilities = capabilities,
}
