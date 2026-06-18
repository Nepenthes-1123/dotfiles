-- =============================================================================
-- lsp/vue_ls.lua  –  Vue LSP サーバー設定 (Volar v2)
-- VSCode: vue.volar 拡張
-- =============================================================================

return {
	cmd = { "vue-language-server", "--stdio" },
	filetypes = { "vue" },
	root_markers = { "vue.config.js", "vue.config.ts", "nuxt.config.ts", "package.json", ".git" },
	init_options = {
		typescript = {
			tsdk = (function()
				-- 1. プロジェクトローカルを最優先（もし今後プロジェクト内でnpm installした時用）
				local local_ts = vim.fn.getcwd() .. "/node_modules/typescript/lib"
				if vim.fn.isdirectory(local_ts) == 1 then
					return local_ts
				end

				-- 2. 【本命】Masonがインストールした typescript-language-server の中身を借りる
				local mason_ts = vim.fn.stdpath("data")
					.. "/mason/packages/typescript-language-server/node_modules/typescript/lib"
				if vim.fn.isdirectory(mason_ts) == 1 then
					return mason_ts
				end

				-- 3. Masonの vue-language-server が内包しているTSへのフォールバック
				local mason_vue_ts = vim.fn.stdpath("data")
					.. "/mason/packages/vue-language-server/node_modules/typescript/lib"
				if vim.fn.isdirectory(mason_vue_ts) == 1 then
					return mason_vue_ts
				end

				return ""
			end)(),
		},
	},
}
