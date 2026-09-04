local M = {}

-- アニメーション素材は別リポジトリ (dotfiles-assets) で管理しているため、
-- clone していない環境では存在しない
local function file_exists(path)
	local f = io.open(path, "r")
	if f then
		io.close(f)
		return true
	end
	return false
end

function M.setup(wezterm, config)
	-- Sakuraカラースキームの背景色を自動取得
	local scheme = wezterm.color.get_builtin_schemes()[config.color_scheme]
	local bg_color = (scheme and scheme.background) or "#1e1e2e"

	-- 画像パスの設定
	local kuyozakura_path = wezterm.config_dir .. "/.wezterm/kuyozakura.png"
	local anim_path = wezterm.config_dir .. "/.wezterm/assets/sd_animation.png"

	-- 背景透過設定
	config.window_background_opacity = 0.7
	config.macos_window_background_blur = 5

	-- 背景レイヤーを組み立てる
	-- show_anim が false、または素材が無い環境では3層目を省略する
	local function build_layers(show_anim)
		local layers = {
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
		}

		if show_anim and file_exists(anim_path) then
			-- 3層目: 右下のアニメーション
			table.insert(layers, {
				source = { File = anim_path },
				width = 360,
				height = 480,
				horizontal_align = "Right",
				vertical_align = "Bottom",
				repeat_x = "NoRepeat",
				repeat_y = "NoRepeat",
				opacity = 0.4,
			})
		end

		return layers
	end

	config.background = build_layers(true)

	-- 右下アニメーションのON/OFF切替用トグルイベント
	local show_bg_image = true

	wezterm.on("toggle-bg-image", function(window, pane)
		show_bg_image = not show_bg_image
		local overrides = window:get_config_overrides() or {}

		overrides.background = build_layers(show_bg_image)
		window:set_config_overrides(overrides)
	end)
end

return M
