-- =============================================================================
-- lsp/dockerls.lua  –  Dockerfile LSP サーバー設定
-- VSCode: docker.docker, ms-azuretools.vscode-containers の LSP 部分を再現
-- =============================================================================
-- lsp.lua など、LSPをセットアップするファイル内
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok, blink = pcall(require, "blink.cmp")
if ok then
	capabilities = blink.get_lsp_capabilities(capabilities)
end

return {
	cmd = { "docker-langserver", "--stdio" },
	filetypes = { "dockerfile" },
	root_markers = { "Dockerfile", ".devcontainer", "docker-compose.yml", "docker-compose.yaml", ".git" },
	capabilities = capabilities,
}
