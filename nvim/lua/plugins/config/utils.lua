-- =============================================================================
-- lua/plugins/config/utils.lua
-- =============================================================================
local M = {}

-- pcall ラッパー: 失敗しても通知のみで処理を続行する
function M.setup(mod, fn)
	local ok, m = pcall(require, mod)
	if not ok then
		return
	end -- 初回インストール中は無視
	fn(m)
end

return M
