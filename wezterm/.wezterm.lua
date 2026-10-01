local wezterm = require("wezterm")
local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- tabのフォーマットを読み込む
local format = require("format")
format.setup(wezterm, config)

-- zsh の起動先 (Windows では WSL の中の zsh。WSL が無ければ Windows 側の zsh) を設定する
local shell = require("shell")
shell.setup(config)

-- 環境変数の設定
config.set_environment_variables = config.set_environment_variables or {}
config.set_environment_variables.HOME = wezterm.home_dir
-- Mac (darwin) 環境の場合、Homebrewのパスを追加
if wezterm.target_triple:find("darwin") then
	config.set_environment_variables.PATH = "/opt/homebrew/bin:" .. os.getenv("PATH")
end

-- 最初からフルスクリーンで起動
local mux = wezterm.mux
wezterm.on("gui-startup", function(cmd)
	local args = (cmd and cmd.args) or shell.spawn_args("herdr --session default")
	local tab = mux.spawn_window({ args = args })
	if not cmd or not cmd.args then
		tab:set_title("default")
	end
end)

-- カラースキームの設定
config.color_scheme = "Sakura"

-- 背景透過・背景画像の設定を読み込む
local background = require("background")
background.setup(wezterm, config)

config.native_macos_fullscreen_mode = true

-- フォントの設定
config.font = wezterm.font_with_fallback({
	"JetBrains Mono",
	"JetBrainsMono Nerd Font",
	"游明朝",
	"Hiragino Sans",
})

-- フォントサイズの設定
config.font_size = 13
config.line_height = 0.9

-- IMEの設定
config.use_ime = true

-- ステータスのカスタマイズ
local status = require("status")
status.setup(wezterm, config)

-- keybindings.lua からショートカットキーを読み込む
local keybinds = require("keybindings")
config.disable_default_key_bindings = true -- デフォルトのキーbindingsを無効化
config.leader = keybinds.leader
config.keys = keybinds.keys

return config
