local setup = require("plugins.config.utils").setup

-- ── tiny-cmdline ──────────────────────────────────────────────────────────────
setup("tiny-cmdline", function(m)
	m.setup({
		-- 画面中央に表示 (デフォルト)
		-- `/` (検索) や `:` (コマンド) が自動的にここで入力できるようになります
		native_types = {},
	})
end)
