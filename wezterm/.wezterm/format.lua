local wezterm = require 'wezterm'

local function BaseName(s)
    return string.gsub(s, '(.*[/\\])(.*)', '%2')
end

local M = {}

function M.setup(config)
  config.window_frame = {
    active_titlebar_bg = '#442845',
    inactive_titlebar_bg = '#221622'
  }
  wezterm.on("format-tab-title", function(tab, tabs, panes, cfg, hover, max_width)
    local background = "#442845"   -- 非アクティブタブの色
    local foreground = "#dcc4cc"

    if tab.is_active then
      background = "#b33c86"       -- アクティブタブは黄金色
      foreground = "#fee6ee"
    elseif hover then
      background = "#8a3375"       -- ホバー時は少し明るく
      foreground = "#edd5dd"
    end

    local title = tab.active_pane.title

    return {
      { Background = { Color = background } },
      { Foreground = { Color = foreground } },
      { Text = BaseName(title) },
    }
  end)
end

return M
