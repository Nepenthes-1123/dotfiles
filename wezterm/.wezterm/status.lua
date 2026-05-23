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

function M.setup(wezterm, config)
    wezterm.on('update-status', function(window, pane)
        rightUpdate(window, pane, wezterm)
    end)
end

return M
