-- =============================================================================
-- lsp/yamlls.lua  –  YAML LSP (yaml-language-server)
-- =============================================================================
-- 価値の中心はスキーマ検証 (GitHub Actions / docker-compose / k8s など)。
--
-- 整形は conform の prettier に任せ、ここでは無効化する。yamlls も内部では
-- prettier を呼ぶが、.prettierrc を読まず prettier のオプションも受け付けない
-- ため、CLI の prettier と結果が食い違うため。
--
-- filetypes に yaml.docker-compose を含めるのは、config/autocmds.lua の
-- vim.filetype.add で compose ファイルをその複合 filetype に振っているため。
-- =============================================================================

return {
	cmd = { "yaml-language-server", "--stdio" },
	filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab" },
	root_markers = { ".git" },
	settings = {
		yaml = {
			format = { enable = false },
			validate = true,
			keyOrdering = false, -- キーのアルファベット順を強制しない
			schemaStore = {
				enable = true,
				url = "https://www.schemastore.org/api/json/catalog.json",
			},
		},
		redhat = { telemetry = { enabled = false } },
	},
}
