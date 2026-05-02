local wezterm = require 'wezterm'
local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- MSYS2のzshをデフォルトシェルに設定
config.default_prog = { 'C:\\msys64\\usr\\bin\\zsh.exe', '-l' }

-- 環境変数の設定
config.set_environment_variables = {
  MSYSTEM = 'MINGW64',
  MSYS2_PATH_TYPE = 'inherit',
  HOME = wezterm.home_dir,
}

-- カラースキームの設定
config.color_scheme = 'Sakura'

-- 背景透過
config.window_background_opacity = 0.8
config.macos_window_background_blur = 20

-- 最初からフルスクリーンで起動
local mux = wezterm.mux
wezterm.on("gui-startup", function(cmd)
    local tab, pane, window = mux.spawn_window(cmd or {})
    window:gui_window():toggle_fullscreen()
end)

-- フォントの設定
config.font = wezterm.font_with_fallback {
  "Consolas",
   "游明朝",
   "Monaspace Neon Var",
   "Source Han Code JP",
   "Courier New",
   "monospace",
}
-- config.font = wezterm.font("Consolas", {weight="Medium", stretch="Normal", style="Normal"})

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

-- ショートカットキー設定
local act = wezterm.action
config.keys = {
  -- Alt(Opt)+Shift+Fでフルスクリーン切り替え
  {
    key = 'f',
    mods = 'SHIFT|META',
    action = wezterm.action.ToggleFullScreen,
  },
  -- Ctrl+Shift+tで新しいタブを作成
  {
    key = 't',
    mods = 'CTRL|SHIFT',
    action = act.SpawnTab 'CurrentPaneDomain',
  },
  -- Ctrl+Shift+dで新しいペインを作成(画面を分割)
  {
    key = 'd',
    mods = 'SHIFT|CTRL',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  -- Ctrl+左矢印でカーソルを前の単語に移動
  {
    key = "LeftArrow",
    mods = "CTRL",
    action = act.SendKey {
      key = "b",
      mods = "META",
    },
  },
  -- Ctrl+右矢印でカーソルを次の単語に移動
  {
    key = "RightArrow",
    mods = "CTRL",
    action = act.SendKey {
      key = "f",
      mods = "META",
    },
  },
  -- Ctrl+Backspaceで前の単語を削除
  {
    key = "Backspace",
    mods = "CTRL",
    action = act.SendKey {
      key = "w",
      mods = "CTRL",
    },
  },
}


return config
