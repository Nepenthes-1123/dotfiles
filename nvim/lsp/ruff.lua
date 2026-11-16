-- =============================================================================
-- lsp/ruff.lua  –  Ruff LSP サーバー設定
-- VSCode: ms-python.black-formatter + ms-python.flake8 + ms-python.isort の統合版
-- =============================================================================
-- VSCode 設定の移植:
--   "flake8.args": ["--ignore=E203,W503,W504", "--max-line-length=88"]
--   "black-formatter.importStrategy": "useBundled"
--   "editor.codeActionsOnSave": { "source.organizeImports": "explicit" }

return {
	cmd = { "ruff", "server" },
	filetypes = { "python" },
	root_markers = {
		"pyproject.toml",
		"ruff.toml",
		".ruff.toml",
		"setup.py",
		".git",
	},
	init_options = {
		settings = {
			-- black 互換の行長 88
			lineLength = 88,
			lint = {
				select = { "E", "F", "W", "I", "N", "UP" },
				-- VSCode: "flake8.args": ["--ignore=E203,W503,W504"] のうち、ruff にある規則だけを残す。
				-- W503 / W504 は ruff に実装が無く、未知の規則を 1 つでも渡すと ruff は
				-- エディタ側の設定 (select・lineLength も含む) をまるごと捨てて既定値で動く
				ignore = { "E203" },
			},
			format = {
				-- black 互換フォーマット
				preview = false,
			},
			-- isort 統合: import の自動整理
			organizeImports = true,
		},
	},
	-- ruff はフォーマットと診断を提供するが型チェックは pyright に任せる。
	--
	-- 保存時の import 整列は conform の ruff_organize_imports (CLI) が担う。
	-- ここで BufWritePre + code_action({ apply = true }) を張らないこと:
	-- code_action は非同期なので書き込みまでに完了せず、編集が書き込み後に
	-- 適用されてバッファが再び modified になる。augroup をバッファごとに
	-- 作る実装だったため増え続ける問題もあった。
}
