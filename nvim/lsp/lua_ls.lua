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
			-- 整形は conform の stylua に任せる。lua_ls の整形器は stylua と字下げの既定が違い、
			-- 経路によって整形結果が食い違うため止めておく
			format = {
				enable = false,
			},
		},
	},
}
