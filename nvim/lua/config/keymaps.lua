local keymap = vim.keymap

vim.g.mapleader = " "

keymap.set("n", "<leader>w", "<cmd>w<cr>")
keymap.set({ "i", "n" }, "<C-s>", "<cmd>w<cr>", { desc = "Save file" })
keymap.set("n", "<leader>q", "<cmd>q<cr>")
keymap.set({ "i", "n" }, "<C-z>", "u", { desc = "Undo" })

keymap.set("n", "<Esc>", "<cmd>noh<cr>")

keymap.set("t", "<Esc>", [[<C-\><C-n>]])

-- タブ操作ショートカット
-- Tabで次のタブへ移動
keymap.set("n", "<Tab>", "<cmd>tabnext<cr>", { desc = "Next tab" })

-- Shift + Tab で前のタブへ移動
keymap.set("n", "<S-Tab>", "<cmd>tabprevious<cr>", { desc = "previous tab" })
