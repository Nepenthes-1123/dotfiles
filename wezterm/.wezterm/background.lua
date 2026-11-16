local wezterm = require("wezterm")

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

function M.apply(config)
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
				width = 150,
				height = 200,
				horizontal_align = "Left",
				vertical_align = "Bottom",
				repeat_x = "NoRepeat",
				repeat_y = "NoRepeat",
				opacity = 0.4,
			})
		end

		return layers
	end

	local show_anim_by_default = true
	config.background = build_layers(show_anim_by_default)

	-- 右下アニメーションのON/OFF切替用トグルイベント
	-- 状態はウィンドウごとに wezterm.GLOBAL に置く。設定の再読み込みで Lua の変数は初期値に戻るが、
	-- ウィンドウの config override は残るため、変数に持つと再読み込み後の最初のトグルが空振りする
	wezterm.on("toggle-bg-image", function(window, _)
		local states = wezterm.GLOBAL.bg_anim_shown or {}
		local key = tostring(window:window_id())
		local shown = states[key]
		if shown == nil then
			shown = show_anim_by_default
		end
		shown = not shown
		states[key] = shown
		wezterm.GLOBAL.bg_anim_shown = states

		local overrides = window:get_config_overrides() or {}
		overrides.background = build_layers(shown)
		window:set_config_overrides(overrides)
	end)
end

return M
