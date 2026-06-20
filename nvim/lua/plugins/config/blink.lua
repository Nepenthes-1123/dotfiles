local setup = require("plugins.config.utils").setup

-- ── 補完プラグイン: blink.cmp───────────────────────────────────────────
setup("blink.cmp", function(m)
	m.setup({
		-- キーマップのプリセット
		keymap = { preset = "enter" },
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
