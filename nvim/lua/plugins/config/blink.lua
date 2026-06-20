local setup = require("plugins.config.utils").setup

-- ── カラースキーム: Rosé Pine Moon ───────────────────────────────────────────
setup("blink.cmp", function(m)
	m.setup({
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
	})

	function m.get_capabilities()
		local ok, blink = pcall(require, "blink.cmp")
		if ok then
			return blink.get_lsp_capabilities()
		end
		-- プラグインが読み取れなかった場合のフォールバック
		return vim.lsp.protocol.make_client_capabilities()
	end
end)
