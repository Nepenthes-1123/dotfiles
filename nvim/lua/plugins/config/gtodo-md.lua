-- =============================================================================
-- lua/plugins/config/gtodo-md.lua  –  gtodo-md.nvim 設定
-- =============================================================================

local ok, gtodo_md = pcall(require, "gtodo-md")
if not ok then
	return
end

gtodo_md.setup({
	use_default_keymaps = true,
	picker = "auto",
	conceal_tags = { "id", "created", "completed_at" },
})
