local wezterm = require('wezterm')
local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- tabのフォーマットを読み込む
local format = require('format')
format.setup(config)

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
        config.default_prog = { zsh_path, '-l' }
    end
end



-- 環境変数の設定
config.set_environment_variables = {
    MSYSTEM = 'MINGW64',
    MSYS2_PATH_TYPE = 'inherit',
    HOME = wezterm.home_dir,
    MSYS = 'winsymlinks:nativestrict',
}

-- 最初からフルスクリーンで起動
local mux = wezterm.mux
wezterm.on("gui-startup", function(cmd)
    local tab, pane, window = mux.spawn_window(cmd or {})
    window:gui_window():toggle_fullscreen()
end)

-- カラースキームの設定
config.color_scheme = 'Sakura'

-- 背景透過
config.window_background_opacity = 0.8
config.macos_window_background_blur = 5

-- フォントの設定
config.font = wezterm.font_with_fallback {
   "JetBrains Mono",
   "游明朝",
   "Hiragino Sans",
}

-- フォントサイズの設定
config.font_size = 12

-- IMEの設定
config.use_ime = true

-- タブバーの設定

-- タブバーを下に配置し、新しいタブボタンを非表示にする
config.tab_bar_at_bottom = true
config.show_new_tab_button_in_tab_bar = false
config.tab_max_width = 30

-- タイトルバーの設定
config.window_decorations = "RESIZE"

-- ペーンの設定
config.inactive_pane_hsb ={
    saturation = 0.8,
    brightness = 0.4,
}

-- カーソルの設定
config.default_cursor_style = "BlinkingBlock"

-- ステータスのカスタマイズ
local status = require('status')
status.setup()

-- keybindings.lua からショートカットキーを読み込む
local keybinds = require("keybindings")
config.disable_default_key_bindings = true -- デフォルトのキーbindingsを無効化
config.leader = keybinds.leader
config.keys = keybinds.keys



return config
