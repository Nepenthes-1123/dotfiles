-- =============================================================================
-- lsp/docker_compose_language_service.lua  –  docker-compose LSP サーバー設定
-- VSCode: ms-azuretools.vscode-containers の docker-compose 補完を再現
-- =============================================================================
-- lsp.lua など、LSPをセットアップするファイル内
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok, blink = pcall(require, "blink.cmp")
if ok then
	capabilities = blink.get_lsp_capabilities(capabilities)
end

return {
	cmd = { "docker-compose-langserver", "--stdio" },
	filetypes = { "yaml.docker-compose" },
	root_markers = { "docker-compose.yml", "docker-compose.yaml", ".git" },
	capabilities = capabilities,
}
