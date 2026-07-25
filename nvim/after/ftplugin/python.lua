-- =============================================================================
-- after/ftplugin/python.lua  –  Python ファイルタイプ固有設定
-- VSCode: "[python]" セクションの設定を移植
-- =============================================================================

-- インデント設定 (Python はスペース 4 が標準)
vim.bo.tabstop = 4
vim.bo.shiftwidth = 4
vim.bo.expandtab = true

-- テキスト幅 (black のデフォルト 88 に合わせた折り返し目安)
vim.bo.textwidth = 88

-- カラム参照線 (VSCode のルーラー相当)
vim.wo.colorcolumn = "88"

-- インレイヒント (Pylance の型ヒント相当) は config/autocmds.lua の LspAttach で有効化済み

-- docstring 挿入コマンド (VSCode: njpwerner.autodocstring の簡易代替)
-- カーソル行が関数/クラス定義なら """ を挿入するシンプルな補助
vim.keymap.set("n", "<LocalLeader>d", function()
	local line = vim.api.nvim_get_current_line()
	if line:match("^%s*def ") or line:match("^%s*class ") then
		local row = vim.api.nvim_win_get_cursor(0)[1]
		local indent = line:match("^(%s*)") .. "    "
		vim.api.nvim_buf_set_lines(0, row, row, false, {
			indent .. '"""',
			indent .. "",
			indent .. '"""',
		})
		vim.api.nvim_win_set_cursor(0, { row + 2, #indent })
		vim.cmd("startinsert!")
	end
end, { buffer = true, desc = "Insert docstring" })
