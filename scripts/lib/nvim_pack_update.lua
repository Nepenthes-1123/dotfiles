-- dot.sh update から nvim --headless で読み込み、vim.pack のプラグインを更新する。
-- force = true の vim.pack.update はプラグインごとの失敗 (fetch の失敗など) を例外にも通知にもせず
-- nvim-pack.log に書くだけで、headless の nvim は Lua のエラーでも終了コード 0 で終わる。
-- 失敗を呼び出し元に伝えるため、例外と、今回ログに追記された Error の節の両方を見て cquit する

local log = vim.fn.stdpath("log") .. "/nvim-pack.log"
local function read_log()
	return vim.fn.filereadable(log) == 1 and vim.fn.readfile(log) or {}
end

local before = #read_log()
local ok, err = pcall(vim.pack.update, nil, { force = true })
if not ok then
	io.stderr:write(tostring(err) .. "\n")
	vim.cmd.cquit(1)
end

local added = vim.list_slice(read_log(), before + 1)
for _, line in ipairs(added) do
	if line:find("^# Error") then
		io.stderr:write(table.concat(added, "\n") .. "\n")
		vim.cmd.cquit(1)
	end
end
