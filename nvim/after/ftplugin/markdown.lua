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

	-- 現在行が記号リスト項目なら次行にも同じマーカーを挿入
	local indent, list_marker = line:match("^(%s*)([-*+] )")
	if indent and list_marker and cursor_col >= #line then
		-- 空のリスト項目では継続を終了 (マーカー部分を削除して改行)
		if line:match("^%s*[-*+] $") then
			return string.rep("<BS>", #list_marker) .. "<CR>"
		end
		-- オートインデントでインデントは引き継がれるため、マーカーのみを挿入
		return "<CR>" .. list_marker
	end

	-- 番号リスト項目
	local indent_num, num_str = line:match("^(%s*)(%d+)%. ")
	if indent_num and num_str and cursor_col >= #line then
		-- 空の番号リスト項目では継続を終了
		if line:match("^%s*%d+%. $") then
			local marker_len = #num_str + 2 -- "数字" + "." + " "
			return string.rep("<BS>", marker_len) .. "<CR>"
		end
		local num = tonumber(num_str) or 0
		-- オートインデントでインデントは引き継がれるため、次の番号とドット・スペースのみを挿入
		return "<CR>" .. (num + 1) .. ". "
	end

	return "<CR>"
end, { buffer = true, expr = true, desc = "Continue list item" })

-- リスト行での Tab / Shift-Tab によるインデント調整
vim.keymap.set("i", "<Tab>", function()
	local col = vim.fn.col(".")
	local line = vim.fn.getline(".")
	local before_cursor = line:sub(1, col - 1)

	-- カーソルがリスト記号の上（もしくはその直後）にあるか判定
	if before_cursor:match("^%s*[%-%*%+]%s*$") or before_cursor:match("^%s*%d+%.%s*$") then
		return "<C-t>" -- インデントを一段深くする
	end
	return "<Tab>"
end, { expr = true, buffer = true, desc = "Indent list item" })

vim.keymap.set("i", "<S-Tab>", function()
	-- Shift-Tab はインデントを一段浅くする
	return "<C-d>"
end, { expr = true, buffer = true, desc = "Unindent list item" })


