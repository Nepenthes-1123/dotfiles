local wezterm = require 'wezterm'

local function BaseName(s)
    return string.gsub(s, '(.*[/\\])(.*)', '%2')
end

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
    { Text = BaseName(title) },
  }
end)

