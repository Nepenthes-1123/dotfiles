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

	-- macOS は $TMPDIR の中で 3 日間アクセスの無いファイルを毎日消す。WezTerm は展開したアニメーションの
	-- フレームを $TMPDIR/wezterm-blob-lease-*/ に書き出して読み直すが、読んでもアクセス日時が更新されず、
	-- 起動したまま数日経つとフレームが消えて描画エラーが出続ける。フレームはファイルの中身のハッシュで
	-- キャッシュされ、設定の再読み込みでは作り直されないため、消されないようにアクセス日時を更新する
	if wezterm.target_triple:find("darwin") then
		-- 再読み込みのたびに新しい世代のタイマーを始め、古い世代は次に動いたときに止まる
		-- (古い Lua の状態のタイマーが再読み込み後も動き続けるかに頼らないため)
		local gen = (wezterm.GLOBAL.frame_touch_gen or 0) + 1
		wezterm.GLOBAL.frame_touch_gen = gen
		-- 異常終了した WezTerm が残したフォルダまで延命しないよう、このプロセスの起動後に作られたものだけを対象にする
		local started = wezterm.procinfo.get_info_for_pid(wezterm.procinfo.pid()).start_time
		local function touch_frames()
			if wezterm.GLOBAL.frame_touch_gen ~= gen then
				return
			end
			local ok, _, stderr = wezterm.run_child_process({
				"/bin/sh",
				"-c",
				[[
status=0
for d in "$TMPDIR"/wezterm-blob-lease-*; do
  if [ -d "$d" ] && [ "$(stat -f %B "$d")" -ge "$1" ]; then
    find "$d" -type f -exec touch -a {} + || status=1
  fi
done
exit "$status"]],
				"sh",
				tostring(started),
			})
			if not ok then
				wezterm.log_error("フレームのアクセス日時を更新できませんでした: " .. stderr)
			end
			wezterm.time.call_after(24 * 3600, touch_frames)
		end
		wezterm.time.call_after(60, touch_frames)
	end
end

return M
