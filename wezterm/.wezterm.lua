local wezterm = require 'wezterm'
local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

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
config.macos_window_background_blur = 20

-- フォントの設定
config.font = wezterm.font_with_fallback {
  "Consolas",
   "游明朝",
   "Monaspace Neon Var",
   "Source Han Code JP",
   "Courier New",
   "monospace",
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


wezterm.on("format-tab-title", function(tab, tabs, panes, cfg, hover, max_width)
  local background = "#3a4a52"   -- 非アクティブタブの色
  local foreground = "#aaaaaa"

  if tab.is_active then
    background = "#ae8b2d"       -- アクティブタブは黄金色
    foreground = "#ffffff"
  elseif hover then
    background = "#4a5a62"       -- ホバー時は少し明るく
    foreground = "#cccccc"
  end

  local title = tab.active_pane.title

  return {
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Text = title },
  }
end)


-- タイトルバーの設定
config.window_decorations = "RESIZE"

-- ペーンの設定
config.inactive_pane_hsb ={
    saturation = 0.8,
    brightness = 0.4,
}

-- カーソルの設定
config.default_cursor_style = "BlinkingBlock"

-- 右ステータスのカスタマイズ
wezterm.on("update-status", function(window, pane)
    local cells = {};

    -- 時刻表示
    local date = wezterm.strftime("%m/%-d %H:%M:%S %a");
    table.insert(cells, '  ' .. date);

    -- -- バッテリー
    -- for _, b in ipairs(wezterm.battery_info()) do
    --   table.insert(cells, string.format("%.0f%%", b.state_of_charge * 100))
    -- end

    -- -- The powerline < symbol
    -- local LEFT_ARROW = utf8.char(0xe0b3);
    -- -- The filled in variant of the < symbol
    -- local SOLID_LEFT_ARROW = utf8.char(0xe0b2)

    -- Color palette for the backgrounds of each cell
    local colors = {
      "#3c1361",
      "#52307c",
      "#663a82",
      "#7c5295",
      "#b491c8",
    };

    -- Foreground color for the text across the fade
    local text_fg = "#c0c0c0";

    -- The elements to be formatted
    local elements = {};
    -- How many cells have been formatted
    local num_cells = 0;

    -- Translate a cell into elements
    function push(text, is_last)
      local cell_no = num_cells + 1
      table.insert(elements, {Foreground={Color=text_fg}})
      table.insert(elements, {Background={Color=colors[cell_no]}})
      table.insert(elements, {Text=" "..text.." "})
      if not is_last then
        table.insert(elements, {Foreground={Color=colors[cell_no+1]}})
        table.insert(elements, {Text=SOLID_LEFT_ARROW})
      end
      num_cells = num_cells + 1
    end

    while #cells > 0 do
      local cell = table.remove(cells, 1)
      push(cell, #cells == 0)
    end

    window:set_right_status(wezterm.format(elements));

end);

-- keybindings.lua からショートカットキーを読み込む
local keybinds = require("keybindings")
config.disable_default_key_bindings = true -- デフォルトのキーbindingsを無効化
config.leader = keybinds.leader
config.keys = keybinds.keys



return config
