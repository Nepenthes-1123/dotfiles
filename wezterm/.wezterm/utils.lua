local wezterm = require 'wezterm'
local act = wezterm.action

local M = {}
local pane_state_cache = {}

local function is_herdr_pane(pane)
  local pane_id = pane:pane_id()
  local current_title = pane:get_title() or ""
  local pinfo = pane:get_foreground_process_info()
  local current_fg_pid = pinfo and pinfo.pid or -1

  -- キャッシュ判定
  if pane_state_cache[pane_id] and
     pane_state_cache[pane_id].fg_pid == current_fg_pid and
     pane_state_cache[pane_id].title == current_title then
    return pane_state_cache[pane_id].is_herdr
  end

  local is_herdr = false
  if pinfo then
    if pinfo.name and (pinfo.name:match('[/\\\\]?herdr%.exe$') or pinfo.name:match('[/\\\\]?herdr$')) then
      is_herdr = true
    else
      local visited = {}
      local depth = 0
      local current_pinfo = pinfo
      while current_pinfo and current_pinfo.ppid and depth < 20 do
        if current_pinfo.pid == current_pinfo.ppid or current_pinfo.ppid == 0 or visited[current_pinfo.ppid] then
          break
        end
        visited[current_pinfo.ppid] = true
        current_pinfo = wezterm.procinfo.get_info_for_pid(current_pinfo.ppid)
        if current_pinfo and current_pinfo.name and (current_pinfo.name:match('[/\\\\]?herdr%.exe$') or current_pinfo.name:match('[/\\\\]?herdr$')) then
          is_herdr = true
          break
        end
        depth = depth + 1
      end
    end
  end

  -- フォールバック: プロセスツリーにherdrがない場合でも、タイトルがherdrであれば許可
  if not is_herdr then
    if current_title == "herdr" or current_title:match("^herdr ") then
      is_herdr = true
    end
  end

  -- キャッシュを保存
  pane_state_cache[pane_id] = {
    fg_pid = current_fg_pid,
    title = current_title,
    is_herdr = is_herdr
  }

  return is_herdr
end

function M.conditional_action(wezterm_action, herdr_key, herdr_mods)
  herdr_mods = herdr_mods or "NONE"
  return wezterm.action_callback(function(window, pane)
    if is_herdr_pane(pane) then
      window:perform_action(act.Multiple{
        act.SendKey{key="b", mods="CTRL"},
        act.SendKey{key=herdr_key, mods=herdr_mods}
      }, pane)
    elseif wezterm_action then
      window:perform_action(wezterm_action, pane)
    end
  end)
end

function M.conditional_resize_action(wezterm_action, resize_key)
  return wezterm.action_callback(function(window, pane)
    if is_herdr_pane(pane) then
      window:perform_action(act.Multiple{
        act.SendKey{key="b", mods="CTRL"},
        act.SendKey{key="r", mods="NONE"},
        act.SendKey{key=resize_key, mods="NONE"},
        act.SendKey{key="Escape", mods="NONE"}
      }, pane)
    elseif wezterm_action then
      window:perform_action(wezterm_action, pane)
    end
  end)
end

return M
