-- =============================================================================
-- lsp/docker_compose_language_service.lua  –  docker-compose LSP サーバー設定
-- VSCode: ms-azuretools.vscode-containers の docker-compose 補完を再現
-- =============================================================================

return {
    cmd          = { 'docker-compose-langserver', '--stdio' },
    filetypes    = { 'yaml.docker-compose' },
    root_markers = { 'docker-compose.yml', 'docker-compose.yaml', '.git' },
}
