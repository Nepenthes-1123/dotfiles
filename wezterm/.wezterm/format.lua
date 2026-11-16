local wezterm = require("wezterm")
local colors = require("colors")

local function BaseName(s)
	return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

local M = {}

function M.apply(config)
	config.window_frame = {
		active_titlebar_bg = colors.titlebar.active,
		inactive_titlebar_bg = colors.titlebar.inactive,
	}

	-- タブバーの設定

	-- タブバーを下に配置し、新しいタブボタンを非表示にする
	config.tab_bar_at_bottom = true
	config.show_new_tab_button_in_tab_bar = false
	config.tab_max_width = 30

	-- タイトルバーの設定
	config.window_decorations = "RESIZE"

	-- ペーンの設定
	config.inactive_pane_hsb = {
		saturation = 0.8,
		brightness = 0.4,
	}

	-- カーソルの設定
	config.default_cursor_style = "BlinkingBlock"

	wezterm.on("format-tab-title", function(tab, _, _, _, hover, _)
		local color = colors.tab.inactive
		if tab.is_active then
			color = colors.tab.active
		elseif hover then
			color = colors.tab.hover
		end

		local title = tab.tab_title
		if not title or title == "" then
			title = BaseName(tab.active_pane.title)
		end

		if tab.active_pane.is_zoomed then
			title = title .. " 🔍"
		end

		return {
			{ Background = { Color = color.bg } },
			{ Foreground = { Color = color.fg } },
			{ Text = " " .. title .. " " },
		}
	end)
end

return M
