local opt = vim.opt

-- 文字コード設定
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"

-- 行番号表示
opt.number = true
opt.relativenumber = true
opt.cursorline = true

-- タブとインデント設定
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true
opt.smartindent = true

-- 検索設定
opt.ignorecase = true
opt.smartcase = true

-- appearance
opt.termguicolors = true
opt.signcolumn = "yes"

-- split
opt.splitright = true
opt.splitbelow = true

-- clipboard
opt.clipboard = "unnamedplus"

-- undo
opt.undofile = true

-- swap
opt.swapfile = false
opt.backup = false
opt.writebackup = false

-- mouse
opt.mouse = "a"

-- markdown / obsidian
opt.conceallevel = 2
opt.concealcursor = "nc"

-- grep
opt.grepprg = "rg --vimgrep"
opt.grepformat = "%f:%l:%c:%m"

--file format
opt.fileformats = { "unix", "dos" }

--better completion
opt.completeopt = { "menu", "menuone", "noselect" }

-- lua/config/options.lua への追記例
-- 折りたたみの設定 (Treesitterを使用)
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
-- ファイルを開いたときは、折りたたみをすべて開いた状態にする (99は深くネストされた意味)
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true
