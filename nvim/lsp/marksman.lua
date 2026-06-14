-- =============================================================================
-- lsp/marksman.lua  –  Markdown LSP サーバー設定
-- VSCode: yzhang.markdown-all-in-one, davidanson.vscode-markdownlint の再現
-- =============================================================================
-- marksman はドキュメント内リンク補完・参照ジャンプを提供する

return {
  cmd          = { "marksman", "server" },
  filetypes    = { "markdown", "markdown.mdx" },
  root_markers = { ".marksman.toml", ".git" },
  -- marksman はフォーマット機能を持たないため、
  -- フォーマットは conform.nvim の prettier (markdown 用) に任せる
}
