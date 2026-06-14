-- =============================================================================
-- after/ftplugin/dockerfile.lua  –  Dockerfile ファイルタイプ固有設定
-- =============================================================================

vim.bo.tabstop    = 4
vim.bo.shiftwidth = 4
vim.bo.expandtab  = true

-- Dockerfile の構文チェック (hadolint がインストールされている場合)
-- hadolint: https://github.com/hadolint/hadolint
-- インストール: scoop install hadolint / brew install hadolint
if vim.fn.executable('hadolint') == 1 then
    vim.bo.makeprg     = 'hadolint %'
    vim.bo.errorformat = '%f:%l %m'
end
