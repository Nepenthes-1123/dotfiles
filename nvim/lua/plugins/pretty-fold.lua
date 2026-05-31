return {
	{
		"anuvyklack/pretty-fold.nvim",
		-- ファイルを開いたタイミングで読み込む
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			sections = {
				left = {
					"content",
				},
				right = {
					" ",
					"number_of_folded_lines",
					": ",
					"percentage",
					" ",
					function(config)
						return config.fill_char:rep(3)
					end,
				},
			},
			fill_char = "•", -- 折りたたまれた部分を埋める文字（例: •, ─,  などお好みで）
			remove_fold_markers = true, -- {{{ などのマーカーを非表示にする
			keep_indentation = true, -- 折りたたんだ行のインデントを維持する

			-- コメント記号の処理
			-- "delete" (削除) / "spaces" (スペースに置換) / false (何もしない)
			process_comment_signs = "spaces",

			-- 対応する括弧などを考慮して折りたたみを綺麗に見せる
			matchup_patterns = {
				{ "{", "}" },
				{ "%(", ")" }, -- % はLuaのパターンエスケープ文字
				{ "%[", "]" },
			},

			-- このプラグインを無効化するファイルタイプ
			ft_ignore = { "neorg", "markdown" },
		},
	},
}
