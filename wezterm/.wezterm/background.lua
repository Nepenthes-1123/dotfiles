local M = {}

function M.setup(wezterm, config)
	-- Sakuraカラースキームの背景色を自動取得
	local scheme = wezterm.color.get_builtin_schemes()[config.color_scheme]
	local bg_color = (scheme and scheme.background) or "#1e1e2e"

	-- 画像パスの設定
	local kuyozakura_path = wezterm.config_dir .. "/.wezterm/kuyozakura.png"
	local bg_img_path = wezterm.config_dir .. "/.wezterm/background_image.png"

	-- 背景透過設定
	config.window_background_opacity = 0.7
	config.macos_window_background_blur = 5

	-- デフォルトの背景設定（3層レイヤー構造）
	config.background = {
		-- 1層目: Sakura背景色 (透過0.7)
		{ source = { Color = bg_color }, width = "100%", height = "100%", opacity = 0.7 },
		-- 2層目: 中央の九曜桜家紋
		{
			source = { File = kuyozakura_path },
			width = 320,
			height = 320,
			horizontal_align = "Center",
			vertical_align = "Middle",
			repeat_x = "NoRepeat",
			repeat_y = "NoRepeat",
			opacity = 0.15,
		},
		-- 3層目: 右下の画像
		{
			source = { File = bg_img_path },
			width = 390,
			height = 219,
			horizontal_align = "Right",
			vertical_align = "Bottom",
			repeat_x = "NoRepeat",
			repeat_y = "NoRepeat",
			opacity = 0.4,
		},
	}

	-- 右下画像のON/OFF切替用トグルイベント
	local show_bg_image = true

	wezterm.on("toggle-bg-image", function(window, pane)
		show_bg_image = not show_bg_image
		local overrides = window:get_config_overrides() or {}

		local bg_list = {
			{ source = { Color = bg_color }, width = "100%", height = "100%", opacity = 0.7 },
			{
				source = { File = kuyozakura_path },
				width = 320,
				height = 320,
				horizontal_align = "Center",
				vertical_align = "Middle",
				repeat_x = "NoRepeat",
				repeat_y = "NoRepeat",
				opacity = 0.15,
			},
		}

		if show_bg_image then
			table.insert(bg_list, {
				source = { File = bg_img_path },
				width = 390,
				height = 219,
				horizontal_align = "Right",
				vertical_align = "Bottom",
				repeat_x = "NoRepeat",
				repeat_y = "NoRepeat",
				opacity = 0.4,
			})
		end

		overrides.background = bg_list
		window:set_config_overrides(overrides)
	end)
end

return M
