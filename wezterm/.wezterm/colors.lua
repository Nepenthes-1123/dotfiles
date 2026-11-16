-- タブバー・ステータス・タイトルバーで使う配色

local M = {}

-- ステータスのセルの背景。左 (モード表示) から右へ明るくなる
M.fade = {
	"#8a3375",
	"#9f377e",
	"#b33c86",
	"#c54390",
	"#d64b9f",
	"#e55ea8",
	"#f071b5",
}

M.text = "#fee6ee"

M.titlebar = {
	active = "#442845",
	inactive = "#221622",
}

M.tab = {
	inactive = { bg = M.titlebar.active, fg = "#dcc4cc" },
	hover = { bg = M.fade[1], fg = "#edd5dd" },
	active = { bg = M.fade[3], fg = M.text },
}

M.mode = {
	NORMAL = "#cbb6ff",
	RESIZE = "#f59574",
	LEADER = "#f59574",
	COPY = "#f41d99",
	SEARCH = "#22e529",
}

return M
