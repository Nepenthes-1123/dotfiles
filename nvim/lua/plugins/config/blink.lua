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
		-- 補完メニューの見た目カスタマイズ
		completion = {
			menu = {
				draw = {
					-- カラムレイアウト: アイコン | ラベル(gap=1で説明表示) || 右端にソース名
					columns = { { "kind_icon" }, { "label", "label_description", gap = 1 }, { "source_name" } },
					components = {
						source_name = {
							width = { max = 30 },
							text = function(ctx)
								-- 表示名を見やすく略記 (例: [LSP], [Buf], [Path], [Snip])
								local name_map = {
									lsp = "LSP",
									buffer = "Buf",
									path = "Path",
									snippets = "Snip",
								}
								local disp_name = name_map[ctx.source_name] or ctx.source_name
								return "[" .. disp_name .. "]"
							end,
							highlight = "BlinkCmpMenu",
						},
					},
				},
			},
		},
		-- 補完ソース指定
		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
		},
		-- シグネチャーヘルプ(関数の引数ヒント)を有効化
		signature = { enabled = true },
	})
end)
