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
map("n", "<Tab>", "<Cmd>bnext<CR>", opts)
map("n", "<S-Tab>", "<Cmd>bprevious<CR>", opts)
map("n", "<Leader>bd", "<Cmd>bdelete<CR>", vim.tbl_extend("force", opts, { desc = "Delete buffer" }))

-- インデントを選択状態を保ったまま変更 (Visual モード)
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)

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
map("n", "<Leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))

-- コードアクション (VSCode: Ctrl+. → Quick Fix)
map({ "n", "v" }, "<Leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))

-- 診断 (VSCode: ErrorLens の下線 → diagnostic float)
map("n", "<Leader>d", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Show diagnostic" }))
map("n", "[d", vim.diagnostic.goto_prev, vim.tbl_extend("force", opts, { desc = "Prev diagnostic" }))
map("n", "]d", vim.diagnostic.goto_next, vim.tbl_extend("force", opts, { desc = "Next diagnostic" }))
map("n", "<Leader>dl", vim.diagnostic.setloclist, vim.tbl_extend("force", opts, { desc = "Diagnostic list" }))

-- フォーマット (VSCode: formatOnSave は autocmds.lua, 手動は Alt+Shift+F)
map("n", "<Leader>f", function()
	vim.lsp.buf.format({ async = true })
end, vim.tbl_extend("force", opts, { desc = "Format buffer" }))

map("v", "<Leader>f", function()
	vim.lsp.buf.format({ async = true, range = true })
end, vim.tbl_extend("force", opts, { desc = "Format selection" }))

-- ── ファイルツリー (nvim-tree) ────────────────────────────────────────────────
-- VSCode: Ctrl+Shift+E → ファイルエクスプローラー
map("n", "<Leader>e", "<Cmd>NvimTreeToggle<CR>", vim.tbl_extend("force", opts, { desc = "Toggle file tree" }))
map("n", "<Leader>E", "<Cmd>NvimTreeFindFile<CR>", vim.tbl_extend("force", opts, { desc = "Reveal file in tree" }))

-- ── ファジーファインダー (telescope) ─────────────────────────────────────────
-- VSCode: Ctrl+P → ファイル検索
map("n", "<Leader>ff", "<Cmd>Telescope find_files<CR>", vim.tbl_extend("force", opts, { desc = "Find files" }))
map("n", "<Leader>fg", "<Cmd>Telescope live_grep<CR>", vim.tbl_extend("force", opts, { desc = "Live grep" }))
map("n", "<Leader>fb", "<Cmd>Telescope buffers<CR>", vim.tbl_extend("force", opts, { desc = "Buffers" }))
map("n", "<Leader>fh", "<Cmd>Telescope help_tags<CR>", vim.tbl_extend("force", opts, { desc = "Help tags" }))
map("n", "<Leader>fd", "<Cmd>Telescope diagnostics<CR>", vim.tbl_extend("force", opts, { desc = "Diagnostics" }))
map(
	"n",
	"<Leader>fs",
	"<Cmd>Telescope lsp_document_symbols<CR>",
	vim.tbl_extend("force", opts, { desc = "Document symbols" })
)
map(
	"n",
	"<Leader>fr",
	"<Cmd>Telescope lsp_references<CR>",
	vim.tbl_extend("force", opts, { desc = "References (Telescope)" })
)
-- VSCode: Ctrl+Shift+F → グローバル検索
map("n", "<C-S-f>", "<Cmd>Telescope live_grep<CR>", vim.tbl_extend("force", opts, { desc = "Live grep" }))

-- ── Git ──────────────────────────────────────────────────────────────────────
-- VSCode: git.blame.editorDecoration.enabled → gitsigns blame_line
map("n", "<Leader>gb", "<Cmd>Gitsigns blame_line<CR>", vim.tbl_extend("force", opts, { desc = "Git blame line" }))
map(
	"n",
	"<Leader>gB",
	"<Cmd>Gitsigns toggle_current_line_blame<CR>",
	vim.tbl_extend("force", opts, { desc = "Toggle inline blame" })
)
map("n", "<Leader>gd", "<Cmd>Gitsigns diffthis<CR>", vim.tbl_extend("force", opts, { desc = "Git diff" }))
map("n", "<Leader>gs", "<Cmd>Gitsigns stage_hunk<CR>", vim.tbl_extend("force", opts, { desc = "Stage hunk" }))
map("n", "<Leader>gu", "<Cmd>Gitsigns undo_stage_hunk<CR>", vim.tbl_extend("force", opts, { desc = "Undo stage hunk" }))
map("n", "<Leader>gr", "<Cmd>Gitsigns reset_hunk<CR>", vim.tbl_extend("force", opts, { desc = "Reset hunk" }))
map("n", "<Leader>gp", "<Cmd>Gitsigns preview_hunk<CR>", vim.tbl_extend("force", opts, { desc = "Preview hunk" }))
map("n", "]h", "<Cmd>Gitsigns next_hunk<CR>", vim.tbl_extend("force", opts, { desc = "Next hunk" }))
map("n", "[h", "<Cmd>Gitsigns prev_hunk<CR>", vim.tbl_extend("force", opts, { desc = "Prev hunk" }))

-- ── ターミナル ────────────────────────────────────────────────────────────────
map("n", "<Leader>t", "<Cmd>terminal<CR>", vim.tbl_extend("force", opts, { desc = "Open terminal" }))
map("t", "<Esc>", "<C-\\><C-n>", opts) -- ターミナルモードから抜ける

-- ── コメント (comment.nvim) ───────────────────────────────────────────────────
-- gcc / gc は comment.nvim のデフォルトに任せる (VSCode: Ctrl+/ と同等)
