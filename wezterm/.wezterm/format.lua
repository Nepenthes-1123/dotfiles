local function BaseName(s)
    return string.gsub(s, '(.*[/\\])(.*)', '%2')
end

local M = {}

function M.setup(wezterm, config)
  config.window_frame = {
    active_titlebar_bg = '#442845',
    inactive_titlebar_bg = '#221622'
  }

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



  wezterm.on("format-tab-title", function(tab, tabs, panes, cfg, hover, max_width)
    local background = "#442845"   -- 非アクティブタブの色
    local foreground = "#dcc4cc"

    if tab.is_active then
      background = "#b33c86"       -- アクティブタブ
      foreground = "#fee6ee"
    elseif hover then
      background = "#8a3375"       -- ホバー時
      foreground = "#edd5dd"
    end

    local title = BaseName(tab.active_pane.title)
    if tab.active_pane.is_zoomed then
      title = title .. " 🔍"
    end

    return {
      { Background = { Color = background } },
      { Foreground = { Color = foreground } },
      { Text = " " .. title .. " " },
    }
  end)
end

return M
