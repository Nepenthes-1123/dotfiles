-- Color palette for the backgrounds of each cell
local COLORS = {
	"#8a3375",
	"#b33c86",
}

-- Foreground color for the text across the fade
local TEXT_FG = "#fee6ee"

-- 1. トライアングル（標準的な尖ったデザイン）
-- local SOLID_LEFT_ARROW = utf8.char(0xe0b2)

-- 2. ハーフサークル（丸みのあるピル型デザイン）
local SOLID_LEFT_ARROW = utf8.char(0xe0b6)

-- 5. ピクセル（レトロ・ドット絵風）
-- local SOLID_LEFT_ARROW = utf8.char(0xe0c7)

-- 6. 炎（メラメラとした波打ち）
-- local SOLID_LEFT_ARROW = utf8.char(0xe0c2)

-- 7. トラペゾイド（台形・折り紙のようなデザイン）
-- local SOLID_LEFT_ARROW = utf8.char(0xe0d2)

local function getTime(elems, window, wezterm)
	-- 時刻表示
	local date = wezterm.strftime("%m/%-d %H:%M:%S %a")
	table.insert(elems, "  " .. date)
end

local function rightUpdate(window, pane, wezterm)
	local cells = {}
	getTime(cells, window, wezterm)

	local elements = {}

	-- 1. モードインジケーターの取得
	local mode = "NORMAL"
	local mode_color = "#cbb6ff"

	if window:active_key_table() == "resize_pane" then
		mode = "RESIZE"
		mode_color = "#f59574"
	elseif window:active_key_table() == "copy_mode" then
		mode = "COPY"
		mode_color = "#f41d99"
	elseif window:active_key_table() == "search_mode" then
		mode = "SEARCH"
		mode_color = "#22e529"
	elseif window:leader_is_active() then
		mode = "LEADER"
		mode_color = "#f59574"
	end

	-- モード部分を右側の先頭(一番左側)に配置
	local mode_text = string.format(" %-6s ", mode)
	table.insert(elements, { Foreground = { Color = mode_color } })
	table.insert(elements, { Background = { Color = COLORS[1] } })
	table.insert(elements, { Text = mode_text })

	-- モードと次のセルの間に矢印を挿入
	if #cells > 0 then
		local next_bg = COLORS[2] or COLORS[1]
		table.insert(elements, { Foreground = { Color = next_bg } })
		table.insert(elements, { Text = SOLID_LEFT_ARROW })
	end

	-- 2. その他の情報（時計など）
	local num_cells = 1 -- COLORS[1]はモードで使ったので2からスタートさせる
	function push(text, is_last)
		local cell_no = num_cells + 1
		if cell_no > #COLORS then
			cell_no = #COLORS
		end
		table.insert(elements, { Foreground = { Color = TEXT_FG } })
		table.insert(elements, { Background = { Color = COLORS[cell_no] } })
		table.insert(elements, { Text = " " .. text .. " " })
		if not is_last then
			local next_color = COLORS[cell_no + 1] or COLORS[cell_no]
			table.insert(elements, { Foreground = { Color = next_color } })
			table.insert(elements, { Text = SOLID_LEFT_ARROW })
		end
		num_cells = num_cells + 1
	end

	while #cells > 0 do
		local cell = table.remove(cells, 1)
		push(cell, #cells == 0)
	end

	window:set_right_status(wezterm.format(elements))
end

local M = {}

local function leftUpdate(window, pane, wezterm)
	-- 左側は空にしてタブだけを表示する
	window:set_left_status("")
end

function M.setup(wezterm, config)
	wezterm.on("update-status", function(window, pane)
		leftUpdate(window, pane, wezterm)
		rightUpdate(window, pane, wezterm)
	end)
end

return M
