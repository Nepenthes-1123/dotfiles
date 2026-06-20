return {
	cmp = {
		-- キーマップのプリセット
		keymap = { preset = "default" },
		appearance = {
			use_nvim_cmp_as_default = true,
			nerd_font_variant = "mono",
		},
		-- 補完ソース指定
		source = {
			default = { "lsp", "path", "snippets", "buffer" },
		},
		-- シグネチャーヘルプ(関数の引数ヒント)を有効化
		signature = { enabled = true },
	},
}
