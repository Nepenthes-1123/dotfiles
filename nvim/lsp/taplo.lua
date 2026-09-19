-- =============================================================================
-- lsp/taplo.lua  –  TOML LSP (taplo)
-- =============================================================================
-- taplo は LSP と CLI (taplo fmt) が同一バイナリで整形器を内蔵するため、
-- conform 側に CLI を置かず textDocument/formatting に任せる。
-- SchemaStore から Cargo.toml / pyproject.toml 等のスキーマを取得して検証する。
-- =============================================================================

return {
	cmd = { "taplo", "lsp", "stdio" },
	filetypes = { "toml" },
	root_markers = { ".taplo.toml", "taplo.toml", ".git" },
}
