local wezterm = require("wezterm")
local act = wezterm.action

local herdr = require("herdr")
local conditional_action = herdr.conditional_action
local conditional_raw_action = herdr.conditional_raw_action
local conditional_resize_action = herdr.conditional_resize_action

return {
	leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 2000 },
	keys = {
		{ key = "Tab", mods = "CTRL", action = conditional_action(act.ActivateTabRelative(1), "n") },
		{ key = "Tab", mods = "SHIFT|CTRL", action = conditional_action(act.ActivateTabRelative(-1), "p") },
		{ key = "Enter", mods = "ALT", action = act.ToggleFullScreen },
		{ key = "<", mods = "CTRL|SHIFT", action = act.DecreaseFontSize },
		{ key = ">", mods = "CTRL|SHIFT", action = act.IncreaseFontSize },
		{ key = "0", mods = "CTRL", action = act.ResetFontSize },
		{ key = "C", mods = "SHIFT|CTRL", action = act.CopyTo("Clipboard") },
		{ key = "c", mods = "SUPER", action = act.CopyTo("Clipboard") },
		{ key = "F", mods = "SHIFT|CTRL", action = act.Search("CurrentSelectionOrEmptyString") },
		{ key = "f", mods = "SUPER", action = act.Search("CurrentSelectionOrEmptyString") },
		{ key = "B", mods = "SHIFT|CTRL", action = act.ClearScrollback("ScrollbackAndViewport") },
		{ key = "b", mods = "SUPER", action = act.ClearScrollback("ScrollbackAndViewport") },
		{ key = "D", mods = "SHIFT|CTRL", action = act.ShowDebugOverlay },
		{ key = "d", mods = "SUPER", action = act.ShowDebugOverlay },
		{ key = "M", mods = "SHIFT|CTRL", action = act.Hide },
		{ key = "m", mods = "SUPER", action = act.Hide },
		{ key = "N", mods = "SHIFT|CTRL", action = act.SpawnWindow },
		{ key = "n", mods = "SUPER", action = act.SpawnWindow },
		{ key = "P", mods = "SHIFT|CTRL", action = act.ActivateCommandPalette },
		{ key = "p", mods = "SUPER", action = act.ActivateCommandPalette },
		{ key = "R", mods = "SHIFT|CTRL", action = act.ReloadConfiguration },
		{ key = "r", mods = "SUPER", action = act.ReloadConfiguration },
		{ key = "T", mods = "SHIFT|CTRL", action = conditional_action(act.SpawnTab("CurrentPaneDomain"), "c") },
		{ key = "t", mods = "SUPER", action = conditional_action(act.SpawnTab("CurrentPaneDomain"), "c") },
		{
			key = "U",
			mods = "SHIFT|CTRL",
			action = act.CharSelect({ copy_on_select = true, copy_to = "ClipboardAndPrimarySelection" }),
		},
		{
			key = "u",
			mods = "SHIFT|CTRL",
			action = act.CharSelect({ copy_on_select = true, copy_to = "ClipboardAndPrimarySelection" }),
		},
		{ key = "V", mods = "SHIFT|CTRL", action = act.PasteFrom("Clipboard") },
		{ key = "v", mods = "SUPER", action = act.PasteFrom("Clipboard") },
		{
			key = "W",
			mods = "SHIFT|CTRL",
			action = conditional_action(act.CloseCurrentTab({ confirm = true }), "X", "SHIFT"),
		},
		{
			key = "w",
			mods = "SUPER",
			action = conditional_action(act.CloseCurrentTab({ confirm = true }), "X", "SHIFT"),
		},
		{ key = "X", mods = "SHIFT|CTRL", action = act.ActivateCopyMode },
		{ key = "x", mods = "SUPER", action = act.ActivateCopyMode },
		{ key = "Z", mods = "SHIFT|CTRL", action = conditional_action(act.TogglePaneZoomState, "z") },
		{ key = "z", mods = "SUPER", action = conditional_action(act.TogglePaneZoomState, "z") },
		{ key = "phys:Space", mods = "SHIFT|CTRL", action = act.QuickSelect },
		{ key = "PageUp", mods = "SHIFT", action = act.ScrollByPage(-1) },
		{ key = "PageUp", mods = "SHIFT|CTRL", action = act.MoveTabRelative(-1) },
		{ key = "PageDown", mods = "SHIFT", action = act.ScrollByPage(1) },
		{ key = "PageDown", mods = "SHIFT|CTRL", action = act.MoveTabRelative(1) },
		{ key = "LeftArrow", mods = "SHIFT|CTRL", action = conditional_action(act.ActivatePaneDirection("Left"), "h") },
		{
			key = "RightArrow",
			mods = "SHIFT|CTRL",
			action = conditional_action(act.ActivatePaneDirection("Right"), "l"),
		},
		{ key = "UpArrow", mods = "SHIFT|CTRL", action = conditional_action(act.ActivatePaneDirection("Up"), "k") },
		{ key = "DownArrow", mods = "SHIFT|CTRL", action = conditional_action(act.ActivatePaneDirection("Down"), "j") },
		{
			key = "LeftArrow",
			mods = "SHIFT|ALT|CTRL",
			action = conditional_resize_action(act.AdjustPaneSize({ "Left", 1 }), "h"),
		},
		{
			key = "RightArrow",
			mods = "SHIFT|ALT|CTRL",
			action = conditional_resize_action(act.AdjustPaneSize({ "Right", 1 }), "l"),
		},
		{
			key = "UpArrow",
			mods = "SHIFT|ALT|CTRL",
			action = conditional_resize_action(act.AdjustPaneSize({ "Up", 1 }), "k"),
		},
		{
			key = "DownArrow",
			mods = "SHIFT|ALT|CTRL",
			action = conditional_resize_action(act.AdjustPaneSize({ "Down", 1 }), "j"),
		},
		-- hjklでのペーン移動 (SHIFT|CTRL)
		{ key = "H", mods = "SHIFT|CTRL", action = conditional_action(act.ActivatePaneDirection("Left"), "h") },
		{ key = "J", mods = "SHIFT|CTRL", action = conditional_action(act.ActivatePaneDirection("Down"), "j") },
		{ key = "K", mods = "SHIFT|CTRL", action = conditional_action(act.ActivatePaneDirection("Up"), "k") },
		{ key = "L", mods = "SHIFT|CTRL", action = conditional_action(act.ActivatePaneDirection("Right"), "l") },
		-- hjklでのペーン移動 (SUPER)
		{ key = "h", mods = "SUPER", action = conditional_action(act.ActivatePaneDirection("Left"), "h") },
		{ key = "j", mods = "SUPER", action = conditional_action(act.ActivatePaneDirection("Down"), "j") },
		{ key = "k", mods = "SUPER", action = conditional_action(act.ActivatePaneDirection("Up"), "k") },
		{ key = "l", mods = "SUPER", action = conditional_action(act.ActivatePaneDirection("Right"), "l") },
		-- hjklでのペーンサイズ変更 (SHIFT|ALT|CTRL)
		{
			key = "H",
			mods = "SHIFT|ALT|CTRL",
			action = conditional_resize_action(act.AdjustPaneSize({ "Left", 1 }), "h"),
		},
		{
			key = "J",
			mods = "SHIFT|ALT|CTRL",
			action = conditional_resize_action(act.AdjustPaneSize({ "Down", 1 }), "j"),
		},
		{
			key = "K",
			mods = "SHIFT|ALT|CTRL",
			action = conditional_resize_action(act.AdjustPaneSize({ "Up", 1 }), "k"),
		},
		{
			key = "L",
			mods = "SHIFT|ALT|CTRL",
			action = conditional_resize_action(act.AdjustPaneSize({ "Right", 1 }), "l"),
		},
		{ key = "Insert", mods = "SHIFT", action = act.PasteFrom("PrimarySelection") },
		{ key = "Insert", mods = "CTRL", action = act.CopyTo("PrimarySelection") },
		{ key = "Copy", mods = "NONE", action = act.CopyTo("Clipboard") },
		{ key = "Paste", mods = "NONE", action = act.PasteFrom("Clipboard") },
		-- Ctrl+左矢印でカーソルを前の単語に移動
		{
			key = "LeftArrow",
			mods = "CTRL",
			action = act.SendKey({
				key = "b",
				mods = "META",
			}),
		},
		-- Ctrl+右矢印でカーソルを次の単語に移動
		{
			key = "RightArrow",
			mods = "CTRL",
			action = act.SendKey({
				key = "f",
				mods = "META",
			}),
		},
		-- Ctrl+Backspaceで前の単語を削除
		{
			key = "Backspace",
			mods = "CTRL",
			action = act.SendKey({
				key = "w",
				mods = "CTRL",
			}),
		},
		-- Ctrl+数字でtab移動
		{ key = "1", mods = "CTRL", action = conditional_action(act.ActivateTab(0), "1") },
		{ key = "2", mods = "CTRL", action = conditional_action(act.ActivateTab(1), "2") },
		{ key = "3", mods = "CTRL", action = conditional_action(act.ActivateTab(2), "3") },
		{ key = "4", mods = "CTRL", action = conditional_action(act.ActivateTab(3), "4") },
		{ key = "5", mods = "CTRL", action = conditional_action(act.ActivateTab(4), "5") },
		{ key = "6", mods = "CTRL", action = conditional_action(act.ActivateTab(5), "6") },
		{ key = "7", mods = "CTRL", action = conditional_action(act.ActivateTab(6), "7") },
		{ key = "8", mods = "CTRL", action = conditional_action(act.ActivateTab(7), "8") },
		{ key = "9", mods = "CTRL", action = conditional_action(act.ActivateTab(-1), "9") },
		-- Ctrl+Shift+数字でWezTermのtab移動
		{ key = "phys:1", mods = "SHIFT|CTRL", action = act.ActivateTab(0) },
		{ key = "phys:2", mods = "SHIFT|CTRL", action = act.ActivateTab(1) },
		{ key = "phys:3", mods = "SHIFT|CTRL", action = act.ActivateTab(2) },
		{ key = "phys:4", mods = "SHIFT|CTRL", action = act.ActivateTab(3) },
		{ key = "phys:5", mods = "SHIFT|CTRL", action = act.ActivateTab(4) },
		{ key = "phys:6", mods = "SHIFT|CTRL", action = act.ActivateTab(5) },
		{ key = "phys:7", mods = "SHIFT|CTRL", action = act.ActivateTab(6) },
		{ key = "phys:8", mods = "SHIFT|CTRL", action = act.ActivateTab(7) },
		{ key = "phys:9", mods = "SHIFT|CTRL", action = act.ActivateTab(-1) },
		-- ¥でバックスラッシュ・ALT + ¥で¥
		{ key = "¥", action = act.SendKey({ key = "\\" }) },
		{ key = "¥", mods = "ALT", action = act.SendKey({ key = "¥" }) },
		-- ctrl+,で下にpane ctrl+.で右にpane
		{
			key = ",",
			mods = "CTRL",
			action = conditional_action(act.SplitVertical({ domain = "CurrentPaneDomain" }), "-"),
		},
		{
			key = ".",
			mods = "CTRL",
			action = conditional_action(act.SplitHorizontal({ domain = "CurrentPaneDomain" }), "v"),
		},
		-- leader + q で Pane を閉じる
		{
			key = "Q",
			mods = "CTRL|SHIFT",
			action = conditional_action(act({ CloseCurrentPane = { confirm = true } }), "x"),
		},
		{ key = "q", mods = "SUPER", action = conditional_action(act({ CloseCurrentPane = { confirm = true } }), "x") },
		-- LEADERの後にsでワークスペース切り替え
		{
			mods = "LEADER",
			key = "s",
			action = conditional_action(
				act.ShowLauncherArgs({ flags = "WORKSPACES", title = "Select workspace" }),
				"g"
			),
		},
		-- LEADER+SHFIT+sでワークスペース作成
		{
			mods = "LEADER|SHIFT",
			key = "S",
			action = conditional_action(
				act.PromptInputLine({
					description = "(wezterm) Create new workspace:",
					action = wezterm.action_callback(function(window, pane, line)
						if line then
							window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
						end
					end),
				}),
				"N",
				"SHIFT"
			),
		},
		-- LEADER+SHIFT+$でワークスペース名変更
		{
			mods = "LEADER|SHIFT",
			key = "$",
			action = conditional_action(
				act.PromptInputLine({
					description = "(wezterm) Set workspace title:",
					action = wezterm.action_callback(function(win, pane, line)
						if line then
							wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
						end
					end),
				}),
				"W",
				"SHIFT"
			),
		},
		-- ペーンリサイズモード (LEADER + r)
		{
			mods = "LEADER",
			key = "r",
			action = conditional_action(act.ActivateKeyTable({ name = "resize_pane", one_shot = false }), "r"),
		},
		-- herdr: セッションデタッチ (LEADER + d -> prefix+q)
		{
			mods = "LEADER",
			key = "d",
			action = conditional_action(act.DetachDomain("CurrentPaneDomain"), "q"),
		},
		-- herdr: サイドバートグル (LEADER + e -> prefix+b)
		{
			mods = "LEADER",
			key = "e",
			action = conditional_action(nil, "b"),
		},

		-- herdr: GUIセッションセレクターの起動 (LEADER + t)
		{
			mods = "LEADER",
			key = "t",
			action = herdr.session_selector_action(),
		},
	},

	key_tables = {
		resize_pane = {
			{ key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 1 }) },
			{ key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },
			{ key = "RightArrow", action = act.AdjustPaneSize({ "Right", 1 }) },
			{ key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },
			{ key = "UpArrow", action = act.AdjustPaneSize({ "Up", 1 }) },
			{ key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },
			{ key = "DownArrow", action = act.AdjustPaneSize({ "Down", 1 }) },
			{ key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },
			{ key = "Escape", action = "PopKeyTable" },
			{ key = "Enter", action = "PopKeyTable" },
			{ key = "c", mods = "CTRL", action = "PopKeyTable" },
		},
		copy_mode = {
			{ key = "Tab", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
			{ key = "Tab", mods = "SHIFT", action = act.CopyMode("MoveBackwardWord") },
			{ key = "Enter", mods = "NONE", action = act.CopyMode("MoveToStartOfNextLine") },
			{ key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
			{ key = "Space", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
			{ key = "$", mods = "NONE", action = act.CopyMode("MoveToEndOfLineContent") },
			{ key = "$", mods = "SHIFT", action = act.CopyMode("MoveToEndOfLineContent") },
			{ key = ",", mods = "NONE", action = act.CopyMode("JumpReverse") },
			{ key = "0", mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
			{ key = ";", mods = "NONE", action = act.CopyMode("JumpAgain") },
			{ key = "F", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = false } }) },
			{ key = "F", mods = "SHIFT", action = act.CopyMode({ JumpBackward = { prev_char = false } }) },
			{ key = "G", mods = "NONE", action = act.CopyMode("MoveToScrollbackBottom") },
			{ key = "G", mods = "SHIFT", action = act.CopyMode("MoveToScrollbackBottom") },
			{ key = "H", mods = "NONE", action = act.CopyMode("MoveToViewportTop") },
			{ key = "H", mods = "SHIFT", action = act.CopyMode("MoveToViewportTop") },
			{ key = "L", mods = "NONE", action = act.CopyMode("MoveToViewportBottom") },
			{ key = "L", mods = "SHIFT", action = act.CopyMode("MoveToViewportBottom") },
			{ key = "M", mods = "NONE", action = act.CopyMode("MoveToViewportMiddle") },
			{ key = "M", mods = "SHIFT", action = act.CopyMode("MoveToViewportMiddle") },
			{ key = "O", mods = "NONE", action = act.CopyMode("MoveToSelectionOtherEndHoriz") },
			{ key = "O", mods = "SHIFT", action = act.CopyMode("MoveToSelectionOtherEndHoriz") },
			{ key = "T", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = true } }) },
			{ key = "T", mods = "SHIFT", action = act.CopyMode({ JumpBackward = { prev_char = true } }) },
			{ key = "V", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Line" }) },
			{ key = "V", mods = "SHIFT", action = act.CopyMode({ SetSelectionMode = "Line" }) },
			{ key = "^", mods = "NONE", action = act.CopyMode("MoveToStartOfLineContent") },
			{ key = "^", mods = "SHIFT", action = act.CopyMode("MoveToStartOfLineContent") },
			{ key = "b", mods = "NONE", action = act.CopyMode("MoveBackwardWord") },
			{ key = "b", mods = "ALT", action = act.CopyMode("MoveBackwardWord") },
			{ key = "b", mods = "CTRL", action = act.CopyMode("PageUp") },
			{ key = "c", mods = "CTRL", action = act.CopyMode("Close") },
			{ key = "d", mods = "CTRL", action = act.CopyMode({ MoveByPage = 0.5 }) },
			{ key = "e", mods = "NONE", action = act.CopyMode("MoveForwardWordEnd") },
			{ key = "f", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = false } }) },
			{ key = "f", mods = "ALT", action = act.CopyMode("MoveForwardWord") },
			{ key = "f", mods = "CTRL", action = act.CopyMode("PageDown") },
			{ key = "g", mods = "NONE", action = act.CopyMode("MoveToScrollbackTop") },
			{ key = "g", mods = "CTRL", action = act.CopyMode("Close") },
			{ key = "h", mods = "NONE", action = act.CopyMode("MoveLeft") },
			{ key = "j", mods = "NONE", action = act.CopyMode("MoveDown") },
			{ key = "k", mods = "NONE", action = act.CopyMode("MoveUp") },
			{ key = "l", mods = "NONE", action = act.CopyMode("MoveRight") },
			{ key = "m", mods = "ALT", action = act.CopyMode("MoveToStartOfLineContent") },
			{ key = "o", mods = "NONE", action = act.CopyMode("MoveToSelectionOtherEnd") },
			{ key = "q", mods = "NONE", action = act.CopyMode("Close") },
			{ key = "t", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = true } }) },
			{ key = "u", mods = "CTRL", action = act.CopyMode({ MoveByPage = -0.5 }) },
			{ key = "v", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
			{ key = "v", mods = "CTRL", action = act.CopyMode({ SetSelectionMode = "Block" }) },
			{ key = "w", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
			{
				key = "y",
				mods = "NONE",
				action = act.Multiple({ { CopyTo = "ClipboardAndPrimarySelection" }, { CopyMode = "Close" } }),
			},
			{ key = "PageUp", mods = "NONE", action = act.CopyMode("PageUp") },
			{ key = "PageDown", mods = "NONE", action = act.CopyMode("PageDown") },
			{ key = "End", mods = "NONE", action = act.CopyMode("MoveToEndOfLineContent") },
			{ key = "Home", mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
			{ key = "LeftArrow", mods = "NONE", action = act.CopyMode("MoveLeft") },
			{ key = "LeftArrow", mods = "ALT", action = act.CopyMode("MoveBackwardWord") },
			{ key = "RightArrow", mods = "NONE", action = act.CopyMode("MoveRight") },
			{ key = "RightArrow", mods = "ALT", action = act.CopyMode("MoveForwardWord") },
			{ key = "UpArrow", mods = "NONE", action = act.CopyMode("MoveUp") },
			{ key = "DownArrow", mods = "NONE", action = act.CopyMode("MoveDown") },
		},

		search_mode = {
			{ key = "Enter", mods = "NONE", action = act.CopyMode("PriorMatch") },
			{ key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
			{ key = "n", mods = "CTRL", action = act.CopyMode("NextMatch") },
			{ key = "p", mods = "CTRL", action = act.CopyMode("PriorMatch") },
			{ key = "r", mods = "CTRL", action = act.CopyMode("CycleMatchType") },
			{ key = "u", mods = "CTRL", action = act.CopyMode("ClearPattern") },
			{ key = "PageUp", mods = "NONE", action = act.CopyMode("PriorMatchPage") },
			{ key = "PageDown", mods = "NONE", action = act.CopyMode("NextMatchPage") },
			{ key = "UpArrow", mods = "NONE", action = act.CopyMode("PriorMatch") },
			{ key = "DownArrow", mods = "NONE", action = act.CopyMode("NextMatch") },
		},
	},
}
