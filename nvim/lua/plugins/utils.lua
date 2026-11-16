-- =============================================================================
-- lua/plugins/utils.lua
-- =============================================================================
local M = {}

-- プラグインを読み込めたときだけ fn を呼ぶ。
-- 1 つ読み込めないだけで残りの設定まで止めないよう、エラーにはせず警告にとどめる
function M.setup(mod, fn)
	local ok, m = pcall(require, mod)
	if not ok then
		-- require のエラーは探した場所の一覧が続くため、先頭の行だけを出す
		local reason = tostring(m):match("^[^\n]*"):gsub(":$", "")
		vim.notify(("プラグインの設定を飛ばしました: %s"):format(reason), vim.log.levels.WARN)
		return
	end
	fn(m)
end

return M
