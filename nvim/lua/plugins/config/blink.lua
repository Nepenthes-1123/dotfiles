local setup = require("plugins.config.utils").setup

-- ── 補完プラグイン: blink.cmp───────────────────────────────────────────
setup("blink.cmp", function(m)
	m.setup({
		-- キーマップの設定 (Enterで確定、Tab/Shift-Tabで候補移動)
		keymap = {
			preset = "enter",
			["<Tab>"] = { "select_next", "fallback" },
			["<S-Tab>"] = { "select_prev", "fallback" },
		},
		appearance = {
			use_nvim_cmp_as_default = true,
			nerd_font_variant = "mono",
		},
		-- 補完ソース指定
		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
		},
		-- シグネチャーヘルプ(関数の引数ヒント)を有効化
		signature = { enabled = true },
	})
end)
