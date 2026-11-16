local setup = require("plugins.utils").setup

-- ── nvim-treesitter ───────────────────────────────────────────────────────────
-- main ブランチはパーサとクエリの導入だけを担い、ハイライト・インデントの有効化は
-- 利用側に任せる (master の highlight = { enable = true } に当たるオプションは無い)。
-- パーサのビルドに tree-sitter CLI が要る (mise で導入)。
local parsers = {
	"python",
	"lua",
	"c",
	"cpp",
	"vim",
	"vimdoc",
	"javascript",
	"typescript",
	"vue",
	"json",
	"markdown",
	"markdown_inline",
	"bash",
	"zsh",
	"yaml",
	"toml",
	"html",
	"css",
	"pug",
	"scss",
}

setup("nvim-treesitter", function(m)
	m.install(parsers)

	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("treesitter-start", { clear = true }),
		callback = function(ev)
			local lang = vim.treesitter.language.get_lang(ev.match)
			-- パーサが無い filetype は多いため、エラーにせず正規表現のハイライトのままにする
			if not lang or not vim.treesitter.language.add(lang) then
				return
			end
			vim.treesitter.start(ev.buf, lang)
			-- インデントのクエリが無い言語で indentexpr を差し替えると、既定の字下げより悪くなる
			if vim.treesitter.query.get(lang, "indents") then
				vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
			end
		end,
	})
end)

-- master の incremental_selection の代わりに、Neovim 0.12 組み込みのノード選択 (v_an / v_in) を使う
vim.keymap.set("n", "<C-Space>", "van", { remap = true, desc = "Select treesitter node" })
vim.keymap.set("x", "<C-Space>", "an", { remap = true, desc = "Expand selection to parent node" })
vim.keymap.set("x", "<BS>", "in", { remap = true, desc = "Shrink selection to child node" })

-- ── nvim-treesitter-context ──────────────────────────────────────────────────
setup("treesitter-context", function(m)
	m.setup({
		enable = true,
		max_lines = 3,
		min_window_height = 0,
		line_numbers = true,
		multiline_threshold = 20,
		trim_scope = "outer",
		mode = "topline",
		separator = "▔",
		zindex = 10,
		multiwindow = true,
	})

	vim.api.nvim_set_hl(0, "TreesitterContextSeparator", { link = "DiagnosticInfo" })
end)
