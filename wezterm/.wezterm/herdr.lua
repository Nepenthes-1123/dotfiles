local wezterm = require("wezterm")
local act = wezterm.action

local M = {}
local pane_state_cache = {}

local function is_herdr_pane(pane)
	local pane_id = pane:pane_id()
	local current_title = pane:get_title() or ""
	local pinfo = pane:get_foreground_process_info()
	local current_fg_pid = pinfo and pinfo.pid or -1

	-- キャッシュ判定
	if
		pane_state_cache[pane_id]
		and pane_state_cache[pane_id].fg_pid == current_fg_pid
		and pane_state_cache[pane_id].title == current_title
	then
		return pane_state_cache[pane_id].is_herdr
	end

	local is_herdr = false
	if pinfo then
		if pinfo.name and (pinfo.name:match("[/\\\\]?herdr%.exe$") or pinfo.name:match("[/\\\\]?herdr$")) then
			is_herdr = true
		else
			local visited = {}
			local depth = 0
			local current_pinfo = pinfo
			while current_pinfo and current_pinfo.ppid and depth < 20 do
				if
					current_pinfo.pid == current_pinfo.ppid
					or current_pinfo.ppid == 0
					or visited[current_pinfo.ppid]
				then
					break
				end
				visited[current_pinfo.ppid] = true
				current_pinfo = wezterm.procinfo.get_info_for_pid(current_pinfo.ppid)
				if
					current_pinfo
					and current_pinfo.name
					and (current_pinfo.name:match("[/\\\\]?herdr%.exe$") or current_pinfo.name:match("[/\\\\]?herdr$"))
				then
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
		is_herdr = is_herdr,
	}

	return is_herdr
end

-- =========================================================================
-- [設定] herdr連携機能の有効/無効フラグ
-- =========================================================================
-- 今後herdrを使わなくなった場合、ここを false にするだけで、プロセス監視が停止し
-- 全てのショートカットが自動的にWezTermネイティブの動作（完全退路）に戻ります。
M.ENABLE_HERDR_INTEGRATION = true
-- =========================================================================

function M.conditional_action(wezterm_action, herdr_key, herdr_mods)
	herdr_mods = herdr_mods or "NONE"
	return wezterm.action_callback(function(window, pane)
		if M.ENABLE_HERDR_INTEGRATION and is_herdr_pane(pane) then
			window:perform_action(
				act.Multiple({
					act.SendKey({ key = "b", mods = "CTRL" }),
					act.SendKey({ key = herdr_key, mods = herdr_mods }),
				}),
				pane
			)
		elseif wezterm_action then
			window:perform_action(wezterm_action, pane)
		end
	end)
end

function M.conditional_raw_action(wezterm_action, target_key, target_mods)
	target_mods = target_mods or "NONE"
	return wezterm.action_callback(function(window, pane)
		if M.ENABLE_HERDR_INTEGRATION and is_herdr_pane(pane) then
			window:perform_action(act.SendKey({ key = target_key, mods = target_mods }), pane)
		elseif wezterm_action then
			window:perform_action(wezterm_action, pane)
		end
	end)
end

function M.conditional_resize_action(wezterm_action, resize_key)
	return wezterm.action_callback(function(window, pane)
		if M.ENABLE_HERDR_INTEGRATION and is_herdr_pane(pane) then
			window:perform_action(
				act.Multiple({
					act.SendKey({ key = "b", mods = "CTRL" }),
					act.SendKey({ key = "r", mods = "NONE" }),
					act.SendKey({ key = resize_key, mods = "NONE" }),
					act.SendKey({ key = "Escape", mods = "NONE" }),
				}),
				pane
			)
		elseif wezterm_action then
			window:perform_action(wezterm_action, pane)
		end
	end)
end

function M.session_selector_action()
	return wezterm.action_callback(function(window, pane)
		-- herdr連携が無効な場合は通常のタブ追加（フォールバック）
		if not M.ENABLE_HERDR_INTEGRATION then
			window:perform_action(act.SpawnTab("CurrentPaneDomain"), pane)
			return
		end

		-- herdrのセッション一覧をJSONで取得
		local success, stdout, stderr = wezterm.run_child_process({ "herdr", "session", "list", "--json" })
		local choices = {
			{ id = "NEW_SESSION_ID", label = "  Create new session..." },
		}

		if success then
			local parsed = wezterm.json_parse(stdout)
			if parsed and parsed.sessions then
				for _, session in ipairs(parsed.sessions) do
					local status_icon = session.running and "" or ""
					local label = string.format("%s %s", status_icon, session.name)
					table.insert(choices, { id = session.name, label = label })
				end
			end
		else
			wezterm.log_error("Failed to list herdr sessions: " .. tostring(stderr))
		end

		-- WezTermのInputSelector（ポップアップメニュー）を表示
		window:perform_action(
			wezterm.action.InputSelector({
				action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
					if not id and not label then
						return -- キャンセルされた場合
					end

					if id == "NEW_SESSION_ID" then
						-- 新規作成の場合、セッション名を入力させる
						inner_window:perform_action(
							wezterm.action.PromptInputLine({
								description = "Enter new herdr session name:",
								action = wezterm.action_callback(function(w, p, line)
									if line and line ~= "" then
										local success, new_tab, new_pane, new_window = pcall(function()
											return w:mux_window():spawn_tab({
												args = { "herdr", "--session", line },
												cwd = wezterm.home_dir,
												set_environment_variables = { HERDR_ENV = "0" },
											})
										end)
										if success and new_tab then
											pcall(function() new_tab:set_title(line) end)
										else
											wezterm.log_error("Failed to spawn tab for session: " .. tostring(new_tab))
										end
									end
								end),
							}),
							inner_pane
						)
					else
						-- 既存セッションにアタッチ
						local success, new_tab, new_pane, new_window = pcall(function()
							return inner_window:mux_window():spawn_tab({
								args = { "herdr", "--session", id },
								cwd = wezterm.home_dir,
								set_environment_variables = { HERDR_ENV = "0" },
							})
						end)
						if success and new_tab then
							pcall(function() new_tab:set_title(id) end)
						else
							wezterm.log_error("Failed to spawn tab for session: " .. tostring(new_tab))
						end
					end
				end),
				title = "herdr Sessions",
				choices = choices,
			}),
			pane
		)
	end)
end

return M
