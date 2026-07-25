-- =============================================================================
-- after/ftplugin/tex.lua  –  LaTeX ファイルタイプ固有設定
-- VSCode: "[latex]", "[tex]", "[bibtex]" セクションの設定を移植
-- =============================================================================

-- インデント設定 (VSCode: "[tex]": { "editor.tabSize": 2 })
vim.bo.tabstop = 2
vim.bo.shiftwidth = 2
vim.bo.expandtab = true

-- スペルチェック有効 (論文執筆環境として)
vim.wo.spell = true
vim.bo.spelllang = "en"

-- ソフト折り返し (長い数式行を見やすく)
vim.wo.wrap = true
vim.wo.linebreak = true

-- テキスト幅 (LaTeX は長い行が多いので広めに)
vim.bo.textwidth = 0

-- conceal (数式記号を見やすく表示: \alpha → α)
vim.wo.conceallevel = 2

-- LaTeX ビルドコマンド (VSCode: latexmk レシピの再現)
-- :make で latexmk を実行
vim.bo.makeprg = "latexmk -file-line-error -interaction=nonstopmode -synctex=1 -outdir=out %"
vim.bo.errorformat = "%f:%l: %m"

-- キーマップ: latexmk でビルド
vim.keymap.set("n", "<LocalLeader>b", "<Cmd>make<CR>", { buffer = true, desc = "Build LaTeX" })

-- キーマップ: out/ ディレクトリの PDF を開く (システムのデフォルトビューワー)
vim.keymap.set("n", "<LocalLeader>v", function()
	local pdf = vim.fn.expand("%:r") .. ".pdf"
	-- out/ ディレクトリに出力される場合
	local out_pdf = "out/" .. vim.fn.expand("%:t:r") .. ".pdf"
	local target = vim.fn.filereadable(out_pdf) == 1 and out_pdf or pdf
	if vim.fn.filereadable(target) == 1 then
		-- OS ごとにファイルを開くコマンドを変更する
		local open_cmd
		if vim.fn.has("win32") == 1 then
			open_cmd = { "cmd", "/c", "start", "", target }
		elseif vim.fn.has("macunix") == 1 then
			open_cmd = { "open", target }
		else
			open_cmd = { "xdg-open", target }
		end
		vim.fn.jobstart(open_cmd, { detach = true })
	else
		vim.notify("PDF not found: " .. target, vim.log.levels.WARN)
	end
end, { buffer = true, desc = "View PDF" })
