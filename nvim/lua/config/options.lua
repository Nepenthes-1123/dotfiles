-- =============================================================================
-- config/options.lua  –  エディタ基本設定 (VSCode settings.json の移植)
-- =============================================================================

local opt = vim.opt

-- ── フォント・表示 ──────────────────────────────────────────────────────────
-- VSCode: "editor.fontSize": 14  →  Neovim は guifont で設定 (GUI 版のみ有効)
if vim.g.neovide or vim.g.fvim_loaded or vim.g.goneovim then
	vim.o.guifont = "JetBrainsMono Nerd Font:h14"
end

-- 予測変換・フロートの透過度設定
opt.pumblend = 40
opt.winblend = 40

-- UI2: 実験的らしいので変更する必要が出てくる可能性がある
pcall(function()
	require("vim._core.ui2").enable({
		enable = true,
		msg = {
			targets = "cmd",
			cmd = {
				height = 0.5,
			},
			dialog = {
				height = 0.5,
			},
			msg = {
				height = 0.5,
				timeout = 4000,
			},
			pager = {
				height = 0.999,
			},
		},
	})
end)
opt.cmdheight = 0
opt.winborder = "rounded"

-- ── インデント ───────────────────────────────────────────────────────────────
-- VSCode: "editor.tabSize": 4, "editor.insertSpaces": true, "editor.detectIndentation": false
opt.tabstop = 4 -- タブ幅 4
opt.shiftwidth = 4 -- インデント幅 4
opt.softtabstop = 4
opt.expandtab = true -- タブをスペースに展開
opt.smartindent = true
opt.autoindent = true

-- ── ファイル ─────────────────────────────────────────────────────────────────
-- VSCode: "files.eol": "\n", "files.insertFinalNewline": true
opt.fileformat = "unix" -- LF 固定
opt.fixendofline = true -- 末尾改行を補完

-- ── 検索 ─────────────────────────────────────────────────────────────────────
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- ── 行番号・カーソル ──────────────────────────────────────────────────────────
opt.number = true
opt.relativenumber = false
opt.cursorline = true -- VSCode: "editor.renderLineHighlight": "all"
opt.cursorcolumn = false

-- ── 空白文字の可視化 ──────────────────────────────────────────────────────────
-- VSCode: "editor.renderWhitespace": "boundary"
opt.list = true
opt.listchars = {
	tab = "→ ",
	trail = "·",
	nbsp = "␣",
	lead = " ",
}

-- ── スクロール ────────────────────────────────────────────────────────────────
opt.scrolloff = 8
opt.sidescrolloff = 8

-- ── ウィンドウ分割 ────────────────────────────────────────────────────────────
opt.splitbelow = true
opt.splitright = true

-- ── 補完 ─────────────────────────────────────────────────────────────────────
opt.completeopt = { "menu", "menuone", "noselect" }
opt.pumheight = 12 -- 補完メニュー最大行数

-- ── クリップボード ────────────────────────────────────────────────────────────
opt.clipboard = "unnamedplus"

-- ── 折り返し ─────────────────────────────────────────────────────────────────
opt.wrap = false
opt.linebreak = true

-- ── バックアップ / スワップ ───────────────────────────────────────────────────
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.undofile = true -- 永続 undo

-- ── タイムアウト ──────────────────────────────────────────────────────────────
opt.timeoutlen = 500
opt.updatetime = 300 -- CursorHold のトリガー間隔 (ホバー表示に影響)

-- ── サインカラム (Git gutter など) ───────────────────────────────────────────
opt.signcolumn = "yes" -- 常に表示 (ガタつき防止)

-- ── 折りたたみ ────────────────────────────────────────────────────────────────
-- Neovim v0.12: treesitter の expr fold が安定
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevelstart = 99 -- 起動時は全展開

-- ── カラー ───────────────────────────────────────────────────────────────────
opt.termguicolors = true -- 24-bit カラー有効
opt.background = "dark"

-- ── マウス ───────────────────────────────────────────────────────────────────
opt.mouse = "a"

-- ── grep ─────────────────────────────────────────────────────────────────────
if vim.fn.executable("rg") == 1 then
	opt.grepprg = "rg --vimgrep --smart-case"
	opt.grepformat = "%f:%l:%c:%m"
end

-- ── メッセージ ────────────────────────────────────────────────────────────────
opt.shortmess:append("c") -- 補完メッセージを抑制

-- ── ブラケットペアハイライト ─────────────────────────────────────────────────
-- Neovim v0.12 では `:h matchparen` (標準プラグイン) が有効
-- VSCode: "editor.bracketPairColorization.independentColorPoolPerBracketType": true
-- → rainbow-delimiters.nvim で再現 (plugins/init.lua 参照)

-- ── タイトル ─────────────────────────────────────────────────────────────────
-- VSCode: "window.title": "${dirty}${activeEditorShort}${separator}${rootName}"
opt.title = true
opt.titlestring = "%{expand('%:t')}%m  ·  %{fnamemodify(getcwd(), ':t')}"

-- ── スペルチェック (markdown のみ有効化は autocmds.lua で制御) ───────────────
opt.spelllang = { "en", "cjk" }

-- シェルのデフォルトオプション-- もし以下のように zsh を指定している場合
vim.opt.shellcmdflag = "-c"
vim.opt.shellquote = ""
vim.opt.shellxquote = ""
