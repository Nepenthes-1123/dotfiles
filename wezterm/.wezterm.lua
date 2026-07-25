local wezterm = require("wezterm")
local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- tabのフォーマットを読み込む
local format = require("format")
format.setup(wezterm, config)

-- Windows環境でzshを探索して使用
if wezterm.target_triple == "x86_64-pc-windows-msvc" then
	local function file_exists(filepath)
		local f = io.open(filepath, "r")
		if f then
			io.close(f)
			return true
		end
		return false
	end

	local function find_zsh()
		-- 1. ユーザーが明示的に指定した場合
		local custom_zsh = os.getenv("ZSH_CUSTOM_PATH")
		if custom_zsh and file_exists(custom_zsh) then
			return custom_zsh
		end

		-- 2. MSYS2_HOME環境変数から推測
		local msys2_home = os.getenv("MSYS2_HOME")
		if msys2_home then
			local msys2_zsh = msys2_home .. "\\usr\\bin\\zsh.exe"
			if file_exists(msys2_zsh) then
				return msys2_zsh
			end
		end

		-- 3. よくあるデフォルト候補を試す
		local candidates = {
			"C:\\msys64\\usr\\bin\\zsh.exe",
			"C:\\tools\\msys64\\usr\\bin\\zsh.exe",
			"C:\\Program Files\\Git\\usr\\bin\\zsh.exe",
			"C:\\cygwin64\\bin\\zsh.exe",
		}

		for _, candidate in ipairs(candidates) do
			if file_exists(candidate) then
				return candidate
			end
		end

		-- フォールバック
		return nil
	end

	local zsh_path = find_zsh()
	if zsh_path then
		config.default_prog = { zsh_path, "-l" }
	end
end

-- 環境変数の設定
config.set_environment_variables = config.set_environment_variables or {}
config.set_environment_variables.MSYSTEM = "MINGW64"
config.set_environment_variables.MSYS2_PATH_TYPE = "inherit"
config.set_environment_variables.HOME = wezterm.home_dir
config.set_environment_variables.MSYS = "winsymlinks:nativestrict"
-- Mac (darwin) 環境の場合、Homebrewのパスを追加
if wezterm.target_triple:find("darwin") then
	config.set_environment_variables.PATH = "/opt/homebrew/bin:" .. os.getenv("PATH")
end

-- Windows環境でzshが見つかった場合、それをデフォルトシェル環境変数に設定し、herdrがそれを引き継ぐようにする
if wezterm.target_triple == "x86_64-pc-windows-msvc" and config.default_prog then
	config.set_environment_variables.SHELL = config.default_prog[1]
end

-- 最初からフルスクリーンで起動
local mux = wezterm.mux
wezterm.on("gui-startup", function(cmd)
	local args = {}
	if cmd and cmd.args then
		args = cmd.args
	else
		-- 起動時に zsh 経由で herdr を実行する（OSごとのPATH差分を吸収）
		args = { "zsh", "-l", "-c", "herdr --session default" }
	end
	local tab, pane, window = mux.spawn_window({ args = args })
	if not cmd or not cmd.args then
		tab:set_title("default")
	end
end)

-- カラースキームの設定
config.color_scheme = "Sakura"

-- 背景透過
config.window_background_opacity = 0.8
config.macos_window_background_blur = 5

config.native_macos_fullscreen_mode = true

-- フォントの設定
config.font = wezterm.font_with_fallback({
	"JetBrains Mono",
	"JetBrainsMono Nerd Font",
	"游明朝",
	"Hiragino Sans",
})

-- フォントサイズの設定
config.font_size = 12

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
