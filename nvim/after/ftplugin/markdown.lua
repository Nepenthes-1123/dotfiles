-- =============================================================================
-- after/ftplugin/markdown.lua  –  Markdown ファイルタイプ固有設定
-- VSCode: "[markdown]" セクション、yzhang.markdown-all-in-one の設定を移植
-- =============================================================================

-- インデント設定
vim.bo.tabstop = 2
vim.bo.shiftwidth = 2
vim.bo.expandtab = true

-- テキスト折り返し (Markdown は見やすく折り返す)
vim.wo.wrap = true
vim.wo.linebreak = true

-- スペルチェック有効 (VSCode: Markdown でスペルチェックが有効)
vim.wo.spell = true

-- 末尾スペースを維持 (Markdown の改行は 2 スペース)
-- autocmds.lua の trimTrailingWhitespace は markdown を除外済み

-- テーブル整形ヘルパー (VSCode: "markdown.extension.tableFormatter.enabled": true の代替)
-- 選択範囲のテーブルを整形する簡易コマンド
vim.keymap.set("n", "<LocalLeader>t", function()
	-- column コマンドを使ったテーブル整形
	vim.cmd("'<,'>!column -t -s '|' -o '|'")
end, { buffer = true, desc = "Format table" })

-- プレビュー: glow (CLI Markdown ビューワー) があれば使用
vim.keymap.set("n", "<LocalLeader>p", function()
	if vim.fn.executable("glow") == 1 then
		local file = vim.fn.expand("%")
		vim.cmd("split | terminal glow " .. file)
	else
		vim.notify("glow not found. Install: brew install glow / cargo install glow", vim.log.levels.INFO)
	end
end, { buffer = true, desc = "Preview Markdown (glow)" })

-- リスト項目の自動継続 (VSCode: yzhang.markdown-all-in-one の機能)
-- Enter キーでリストマーカーを自動継続
vim.keymap.set("i", "<CR>", function()
	local line = vim.api.nvim_get_current_line()
	local cursor_col = vim.api.nvim_win_get_cursor(0)[2]
	-- 現在行がリスト項目なら次行にも同じマーカーを挿入
	local list_marker = line:match("^(%s*[-*+] )")
	if list_marker and cursor_col >= #line then
		-- 空のリスト項目では継続を終了
		if line:match("^%s*[-*+] $") then
			return "<BS><BS><BS>"
		end
		return "<CR>" .. list_marker
	end
	local num_marker = line:match("^(%s*%d+%. )")
	if num_marker and cursor_col >= #line then
		local num = tonumber(line:match("(%d+)%.")) or 0
		local indent = num_marker:match("^(%s*)") or ""
		return "<CR>" .. indent .. (num + 1) .. ". "
	end
	return "<CR>"
end, { buffer = true, expr = true, desc = "Continue list item" })
