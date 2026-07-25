-- =============================================================================
-- config/keymaps.lua  –  グローバルキーマップ
-- =============================================================================
-- 凡例:  <Leader> = スペースキー

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- ── 基本操作 ─────────────────────────────────────────────────────────────────
-- 保存 / 終了
map("n", "<Leader>w", "<Cmd>w<CR>", vim.tbl_extend("force", opts, { desc = "Save" }))
map("n", "<Leader>q", "<Cmd>q<CR>", vim.tbl_extend("force", opts, { desc = "Quit" }))
map("n", "<Leader>Q", "<Cmd>qa!<CR>", vim.tbl_extend("force", opts, { desc = "Force quit all" }))

-- ESC でハイライトをクリア (VSCode: Escape でハイライト消去と同等)
map("n", "<Esc>", "<Cmd>nohlsearch<CR>", opts)

-- ウィンドウ移動 (Ctrl+hjkl)
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

-- ウィンドウサイズ変更
map("n", "<C-Up>", "<Cmd>resize +2<CR>", opts)
map("n", "<C-Down>", "<Cmd>resize -2<CR>", opts)
map("n", "<C-Left>", "<Cmd>vertical resize -2<CR>", opts)
map("n", "<C-Right>", "<Cmd>vertical resize +2<CR>", opts)

-- バッファ移動
map("n", "<Tab>", "<Cmd>BufferLineCycleNext<CR>", opts)
map("n", "<S-Tab>", "<Cmd>BufferLineCyclePrev<CR>", opts)
map("n", "<Leader>bd", "<Cmd>bdelete<CR>", vim.tbl_extend("force", opts, { desc = "Delete buffer" }))
map("n", "]b", "<Cmd>bnext<CR>", vim.tbl_extend("force", opts, { desc = "Next buffer" }))
map("n", "[b", "<Cmd>bprevious<CR>", vim.tbl_extend("force", opts, { desc = "Previous buffer" }))

-- インデントを選択状態を保ったまま変更 (Visual モード)
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)

-- インサートモードからノーマルモードに変更
map("i", "jj", "<Esc>", opts)

-- ── LSP コードナビゲーション ─────────────────────────────────────────────────
-- VSCode: F12 → 定義ジャンプ, Shift+F12 → 参照
-- Neovim 標準 LSP キーマップ (LspAttach autocmd で上書きも可)
map("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
map("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "Go to declaration" }))
map("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "Go to references" }))
map("n", "gi", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "Go to implementation" }))
map("n", "gy", vim.lsp.buf.type_definition, vim.tbl_extend("force", opts, { desc = "Go to type definition" }))

-- ホバー表示 (VSCode: マウスホバー → K キー)
map("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover documentation" }))

-- シグネチャヘルプ (関数引数のヒント)
map("n", "<C-s>", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "Signature help" }))
map("i", "<C-s>", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "Signature help" }))

-- リネーム (VSCode: F2)
map("n", "<F2>", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))
map("n", "<Leader>cr", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))

-- コードアクション (VSCode: Ctrl+. → Quick Fix)
map({ "n", "v" }, "<Leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))

-- 診断 (VSCode: ErrorLens の下線 → diagnostic float)
map("n", "<Leader>d", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Show diagnostic" }))
map("n", "[d", function()
	vim.diagnostic.jump({ count = -1 })
end, vim.tbl_extend("force", opts, { desc = "Prev diagnostic" }))

map("n", "]d", function()
	vim.diagnostic.jump({ count = 1 })
end, vim.tbl_extend("force", opts, { desc = "Next diagnostic" }))

-- フォーマット (VSCode: formatOnSave は autocmds.lua, 手動は Alt+Shift+F)
map("n", "<Leader>cf", function()
	vim.lsp.buf.format({ async = true })
end, vim.tbl_extend("force", opts, { desc = "Format buffer" }))

map("v", "<Leader>cf", function()
	vim.lsp.buf.format({ async = true })
end, vim.tbl_extend("force", opts, { desc = "Format selection" }))

-- ── ファジーファインダー (blink) ─────────────────────────────────────────
-- VSCode: Ctrl+P → ファイル検索

-- ── コメント (comment.nvim) ───────────────────────────────────────────────────
-- gcc / gc は comment.nvim のデフォルトに任せる (VSCode: Ctrl+/ と同等)

-- ── インサートモードの挙動をVScode風に変更 ─────────────────────────────────────────────────────────────────
map("i", "<C-s>", "<Cmd>w<CR>", vim.tbl_extend("force", opts, { desc = "Save file" }))
map("i", "<C-z>", "<Cmd>undo<CR>", vim.tbl_extend("force", opts, { desc = "Undo" }))
map("i", "<C-v>", "<C-r>+", vim.tbl_extend("force", opts, { desc = "Pasete from Clipblard" }))
map({ "i", "v" }, "<C-a>", "<Esc>ggVG", vim.tbl_extend("force", opts, { desc = "Select All" }))
map("n", "<C-a>", "ggVG", vim.tbl_extend("force", opts, { desc = "Select All" }))
