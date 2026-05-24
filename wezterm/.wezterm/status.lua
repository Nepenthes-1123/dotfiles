-- Color palette for the backgrounds of each cell
local COLORS = {
  "#8a3375",
  "#b33c86",
};

-- Foreground color for the text across the fade
local TEXT_FG = "#fee6ee";


local function getTime(elems, window, wezterm)
    -- 時刻表示
    local date = wezterm.strftime("%m/%-d %H:%M:%S %a");
    table.insert(elems, '  ' .. date);
end

local function rightUpdate(window, pane, wezterm)
    local cells = {};

    getTime(cells, window, wezterm)


    -- The elements to be formatted
    local elements = {};
    -- How many cells have been formatted
    local num_cells = 0;

    -- Translate a cell into elements
    function push(text, is_last)
      local cell_no = num_cells + 1
      table.insert(elements, {Foreground={Color=TEXT_FG}})
      table.insert(elements, {Background={Color=COLORS[cell_no]}})
      table.insert(elements, {Text=" "..text.." "})
      if not is_last then
        table.insert(elements, {Foreground={Color=COLORS[cell_no+1]}})
        table.insert(elements, {Text=SOLID_LEFT_ARROW})
      end
      num_cells = num_cells + 1
    end

    while #cells > 0 do
      local cell = table.remove(cells, 1)
      push(cell, #cells == 0)
    end

    window:set_right_status(wezterm.format(elements));
end

local M = {}

local function leftUpdate(window, pane, wezterm)
    local vars = pane:get_user_vars()
    local branch = vars.GIT_BRANCH
    local status = vars.GIT_STATUS
    
    -- 左側の背景色（右側の最初のセル COLORS[1] と合わせる）
    local BG_COLOR = COLORS[1]
    
    -- 背景色の上でも視認性が高い「Bright」系カラーを中心に使用
    local GIT_COLORS = {
        clean     = "#22e529", -- Bright Green
        untracked = "#f59574", -- Bright Yellow
        modified  = "#f41d99", -- Bright Red (Sakura Pink)
        staged    = "#eeeeee", -- Bright Cyan (視認性重視)
    }
    
    local elements = {}
    
    -- 背景色の設定
    table.insert(elements, {Background={Color=BG_COLOR}})

    if branch and branch ~= "" then
        -- Gitリポジトリ内
        local color = GIT_COLORS[status] or GIT_COLORS.clean
        table.insert(elements, {Foreground={Color=color}})
        table.insert(elements, {Text="   " .. branch .. "  "})
    else
        -- Git管理外: ワークスペース名を表示 (Bright White)
        local workspace = window:active_workspace()
        table.insert(elements, {Foreground={Color="#cbb6ff"}}) -- Bright White (Pale Purple)
        table.insert(elements, {Text="  󱂬 " .. workspace .. "  "})
    end
    
    window:set_left_status(wezterm.format(elements))
end

function M.setup(wezterm, config)
    wezterm.on('update-status', function(window, pane)
        leftUpdate(window, pane, wezterm)
        rightUpdate(window, pane, wezterm)
    end)
end

return M
