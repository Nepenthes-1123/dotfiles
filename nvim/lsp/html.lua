-- =============================================================================
-- lsp/html.lua  –  HTML LSP (vscode-html-language-server)
-- =============================================================================
-- jsonls と同じ vscode-langservers-extracted 由来。補完・ホバー・診断を担う。
--
-- 整形は conform の prettier に任せる。html LSP の整形は js-beautify 系で
-- prettier とは別実装のため結果が食い違う。json / css と揃えて prettier に寄せる。
-- provideFormatter を渡さないことで documentFormattingProvider を申告させない
-- (jsonls と同じ制御方法)。
-- =============================================================================

return {
	cmd = { "vscode-html-language-server", "--stdio" },
	filetypes = { "html" },
	root_markers = { "package.json", ".git" },
	init_options = {
		configurationSection = { "html", "css", "javascript" },
		embeddedLanguages = { css = true, javascript = true },
	},
	settings = {
		html = { format = { enable = false } },
	},
}
