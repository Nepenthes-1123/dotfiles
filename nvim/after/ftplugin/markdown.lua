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

-- テーブル整形 (VSCode: "markdown.extension.tableFormatter.enabled": true の代替)
-- カーソルのある表の列幅を揃える。column -o は util-linux 版にしか無く (macOS の BSD 版や
-- Windows には無い)、日本語の表示幅も数えられないため、外部コマンドを使わずに整形する
local function split_row(line)
	local cells = {}
	-- \| はセルの区切りではないので、一時的に置き換えてから分割する
	local body = line:gsub("\\|", "\0"):match("^%s*|?(.-)|?%s*$")
	for cell in (body .. "|"):gmatch("(.-)|") do
		cells[#cells + 1] = vim.trim((cell:gsub("%z", "\\|")))
	end
	return cells
end

local function format_table()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local function is_table(n)
		local line = vim.fn.getline(n)
		return line:match("^%s*|") ~= nil
	end
	if not is_table(row) then
		vim.notify("カーソルが表の中にありません", vim.log.levels.WARN)
		return
	end
	local first, last = row, row
	while first > 1 and is_table(first - 1) do
		first = first - 1
	end
	while last < vim.fn.line("$") and is_table(last + 1) do
		last = last + 1
	end

	local lines = vim.api.nvim_buf_get_lines(0, first - 1, last, false)
	local indent = lines[1]:match("^(%s*)")
	local rows, widths = {}, {}
	for i, line in ipairs(lines) do
		rows[i] = split_row(line)
		for c, cell in ipairs(rows[i]) do
			-- 区切り行 (---) の幅は数えず、見出しと本文の幅に合わせる
			local width = cell:match("^:?%-+:?$") and 3 or vim.fn.strdisplaywidth(cell)
			widths[c] = math.max(widths[c] or 3, width)
		end
	end

	local out = {}
	for i, cells in ipairs(rows) do
		local parts = {}
		for c = 1, #widths do
			local cell = cells[c] or ""
			if cell:match("^:?%-+:?$") then
				local left, right = cell:sub(1, 1) == ":", cell:sub(-1) == ":"
				local dashes = widths[c] - (left and 1 or 0) - (right and 1 or 0)
				parts[c] = (left and ":" or "") .. string.rep("-", dashes) .. (right and ":" or "")
			else
				parts[c] = cell .. string.rep(" ", widths[c] - vim.fn.strdisplaywidth(cell))
			end
		end
		out[i] = indent .. "| " .. table.concat(parts, " | ") .. " |"
	end
	vim.api.nvim_buf_set_lines(0, first - 1, last, false, out)
end

vim.keymap.set("n", "<LocalLeader>t", format_table, { buffer = true, desc = "Format table" })

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
