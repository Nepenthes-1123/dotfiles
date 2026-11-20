local wezterm = require("wezterm")
local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- tabのフォーマットを読み込む
require("format").apply(config)

-- zsh の起動先 (Windows では WSL の中の zsh) を設定する
local shell = require("shell")
shell.apply(config)

-- 環境変数の設定
config.set_environment_variables = config.set_environment_variables or {}
config.set_environment_variables.HOME = wezterm.home_dir
-- Mac (darwin) 環境の場合、Homebrewのパスを追加
if wezterm.target_triple:find("darwin") then
	config.set_environment_variables.PATH = "/opt/homebrew/bin:" .. os.getenv("PATH")
end

-- 起動時のウィンドウでは herdr の default セッションを開く
local mux = wezterm.mux
wezterm.on("gui-startup", function(cmd)
	-- コマンドを指定して起動したとき (wezterm start -- ...) と、zsh が無いとき (WSL の無い Windows) は
	-- herdr を開かず、指定のコマンドか既定のシェルを開く
	if (cmd and cmd.args) or not shell.has_zsh then
		mux.spawn_window(cmd or {})
		return
	end
	local tab, pane = mux.spawn_window({ args = shell.spawn_args("herdr --session default") })
	tab:set_title("default")
	require("herdr").mark_herdr_pane(pane)
end)

-- カラースキームの設定
config.color_scheme = "Sakura"

-- 背景透過・背景画像の設定を読み込む
require("background").apply(config)

config.native_macos_fullscreen_mode = false
config.macos_fullscreen_extend_behind_notch = true

-- フォントの設定
config.font = wezterm.font_with_fallback({
	"JetBrains Mono",
	"JetBrainsMono Nerd Font",
	-- 游明朝のファミリー名は Windows では「游明朝」、macOS では「游明朝体」/「YuMincho」のため両方を書く
	{ family = "游明朝", weight = "Medium" },
	{ family = "YuMincho", weight = "Medium" },
	"Hiragino Sans",
})

-- フォントサイズの設定
config.font_size = 13
config.line_height = 0.9
config.front_end = "WebGpu"
config.freetype_load_flags = "NO_HINTING"
config.max_fps = 120

-- IMEの設定
config.use_ime = true

-- ステータスのカスタマイズ
require("status").apply(config)

-- keybindings.lua からショートカットキーを読み込む
require("keybindings").apply(config)

return config
