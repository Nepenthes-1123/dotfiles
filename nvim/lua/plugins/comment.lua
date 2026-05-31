return {
	{
		"numToStr/Comment.nvim",
		-- ファイルを開いたタイミングで遅延読み込み（起動速度を落とさないため）
		event = { "BufReadPre", "BufNewFile" },

		-- lazy.nvimの仕組みを使い、setup()の中身をここにまとめます
		opts = {
			---コメントとコードの間にスペースを空ける (例: // comment)
			padding = true,
			---コメントアウトした際にカーソルの位置を固定する
			sticky = true,
			---無視する行のパターン (nil = なし)
			ignore = nil,

			---ノーマルモード時のトグル（切り替え）ショートカット
			toggler = {
				---行コメント (gcc でその行をコメントアウト)
				line = "gcc",
				---ブロックコメント (gbc でその行をブロックコメントアウト)
				block = "gbc",
			},

			---ビジュアルモードなどで範囲選択している時のショートカット
			opleader = {
				---行コメント
				line = "gc",
				---ブロックコメント
				block = "gb",
			},

			---その他の便利なショートカット
			extra = {
				---現在の行の上にコメント行を追加
				above = "gcO",
				---現在の行の下にコメント行を追加
				below = "gco",
				---現在の行の行末にコメントを追加
				eol = "gcA",
			},

			---キーバインドを有効化する設定
			mappings = {
				basic = true,
				extra = true,
			},

			pre_hook = nil,
			post_hook = nil,
		},
	},
}
