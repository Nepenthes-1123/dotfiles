-- =============================================================================
-- lsp/ts_ls.lua  –  TypeScript / JavaScript LSP サーバー設定
-- VSCode: dbaeumer.vscode-eslint + esbenp.prettier-vscode と連携
-- =============================================================================
-- フォーマットは prettier (conform.nvim 経由) に任せるため、
-- ts_ls のドキュメントフォーマット機能は無効化する
-- (config/autocmds.lua の LspAttach で client.server_capabilities を落としている)

return {
	cmd = { "typescript-language-server", "--stdio" },
	filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
	root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
	init_options = {
		hostInfo = "neovim",
		preferences = {
			-- 未使用インポートの自動削除 (VSCode: source.organizeImports と同等)
			includeCompletionsForModuleExports = true,
			includeCompletionsWithInsertText = true,
			importModuleSpecifierPreference = "shortest",
			-- インレイヒント (VSCode Pylance 風の型表示)
			includeInlayParameterNameHints = "all",
			includeInlayParameterNameHintsWhenArgumentMatchesName = false,
			includeInlayFunctionParameterTypeHints = true,
			includeInlayVariableTypeHints = true,
			includeInlayPropertyDeclarationTypeHints = true,
			includeInlayFunctionLikeReturnTypeHints = true,
			includeInlayEnumMemberValueHints = true,
		},
	},
	settings = {
		typescript = {
			inlayHints = {
				includeInlayParameterNameHints = "all",
				includeInlayParameterNameHintsWhenArgumentMatchesName = false,
				includeInlayFunctionParameterTypeHints = true,
				includeInlayVariableTypeHints = true,
				includeInlayPropertyDeclarationTypeHints = true,
				includeInlayFunctionLikeReturnTypeHints = true,
				includeInlayEnumMemberValueHints = true,
			},
		},
		javascript = {
			inlayHints = {
				includeInlayParameterNameHints = "all",
				includeInlayParameterNameHintsWhenArgumentMatchesName = false,
				includeInlayFunctionParameterTypeHints = true,
				includeInlayVariableTypeHints = true,
				includeInlayPropertyDeclarationTypeHints = true,
				includeInlayFunctionLikeReturnTypeHints = true,
				includeInlayEnumMemberValueHints = true,
			},
		},
	},
	on_new_config = function(new_config, _)
		local ok, mason_registry = pcall(require, "mason-registry")
		local vue_plugin_path = ""

		if ok then
			local pkg = mason_registry.get_package("vue-language-server")
			if pkg:is_installed() then
				vue_plugin_path = pkg:get_install_path() .. "/node_modules/@vue/language-server"
				-- 🚨 Windows対策: パスのバックスラッシュ(\)をスラッシュ(/)に強制統一
				vue_plugin_path = vue_plugin_path:gsub("\\", "/")
			end
		end

		new_config.init_options = new_config.init_options or {}
		new_config.init_options.plugins = {
			{
				name = "@vue/typescript-plugin",
				location = vue_plugin_path,
				languages = { "vue" },
			},
		}
	end,
}
