-- =============================================================================
-- lsp/dockerls.lua  –  Dockerfile LSP サーバー設定
-- VSCode: docker.docker, ms-azuretools.vscode-containers の LSP 部分を再現
-- =============================================================================

return {
    cmd          = { 'docker-langserver', '--stdio' },
    filetypes    = { 'dockerfile' },
    root_markers = { 'Dockerfile', '.devcontainer', 'docker-compose.yml', 'docker-compose.yaml', '.git' },
}
