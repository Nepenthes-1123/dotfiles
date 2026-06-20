-- =============================================================================
-- lua/plugins/config/octo.lua  –  octo.nvim 設定
-- VSCode: GitHub.vscode-pull-request-github の代替
-- =============================================================================
-- VSCode 拡張の機能と Neovim での対応 (キーマップは <Leader>h プレフィックス):
--   PR/Issue 一覧パネル          → <Leader>hpl / <Leader>hil (Telescope)
--   PR レビュー (diff + コメント) → <Leader>hprs (review start)
--   インラインコメント追加        → レビューバッファ上で <Leader>ca
--   PR のチェックアウト           → <Leader>hpc / Telescope ピッカー上で <C-o>
--   PR のマージ                   → <Leader>hpm / ピッカー上で <C-r>
--   通知一覧                       → <Leader>hn
--
-- 【プレフィックス設計】
-- <Leader>g は gitsigns (Git) が <Leader>gp = preview_hunk など
-- リーフキーとして既に使用しているため、<Leader>gp* をプレフィックスに
-- 持つキーを追加すると which-key 上でグループとして展開できない。
-- そのため octo (GitHub) は <Leader>h (Hub) を新設して衝突を回避する。
--
-- 前提条件:
--   - GitHub CLI (gh) のインストールが必須
--     Windows: winget install GitHub.cli / scoop install gh
--     macOS:   brew install gh
--     Linux:   各ディストリのパッケージマネージャ参照
--   - 初回のみ認証が必要: gh auth login
--   - GitHub Projects (v2) を使う場合は追加スコープが必要:
--       gh auth refresh -s read:project
-- =============================================================================

local setup = require("plugins.config.utils").setup

setup("octo", function(m)
	-- gh コマンドが無い場合は警告のみ表示してセットアップを継続
	-- (octo 自体は読み込まれるが、API 呼び出し時にエラーになる)
	if vim.fn.executable("gh") == 0 then
		vim.notify(
			"octo.nvim: GitHub CLI (gh) が見つかりません。`gh auth login` 後に利用できます。",
			vim.log.levels.WARN
		)
	end

	m.setup({
		-- VSCode 拡張のデフォルトと同様 squash を既定のマージ方法に
		default_merge_method = "squash",
		-- リモートの優先順位 (fork からの PR にも対応)
		default_remote = { "upstream", "origin" },
		-- GitHub Projects (v2) パネル相当
		default_to_projects_v2 = true,

		-- レビュー時に変更ファイルをローカルファイルシステムから表示
		-- (VSCode の "diff" ビューに近い見た目になる)
		use_local_fs = true,

		-- bare `:Octo` 実行時にコマンド一覧を表示
		enable_builtin = true,

		-- 検索・一覧パネルは snacks.picker を使用 (既存構成と統一)
		picker = "snacks",
		picker_config = {
			mappings = {
				open_in_browser = { lhs = "<C-b>", desc = "open issue in browser" },
				copy_url = { lhs = "<C-y>", desc = "copy url to system clipboard" },
				copy_sha = { lhs = "<C-e>", desc = "copy commit SHA to system clipboard" },
				checkout_pr = { lhs = "<C-o>", desc = "checkout pull request" },
				merge_pr = { lhs = "<C-r>", desc = "merge pull request" },
			},
		},

		-- アイコン (VSCode の PR タイムライン装飾相当)
		comment_icon = "▎",
		outdated_icon = "󰅒 ",
		resolved_icon = " ",

		-- ファイルパネル (変更ファイル一覧)
		file_panel = {
			size = 10,
			icons = true,
		},
	})

	-- ── キーマップ ───────────────────────────────────────────────────────────
	-- プレフィックスについて:
	--   <Leader>o は obsidian.nvim が使用
	--   <Leader>g は gitsigns (Git) が <Leader>gp = preview_hunk など
	--              リーフキーとして既に使用しているため、
	--              octo (GitHub) は <Leader>h (Hub) を新設して衝突を回避する
	-- ─────────────────────────────────────────────────────────────────────────
	local map = vim.keymap.set
	local opts = { noremap = true, silent = true }

	-- レビュー開始 (VSCode: "Start Review")
	map(
		"n",
		"<Leader>gprs",
		"<Cmd>Octo review start<CR>",
		vim.tbl_extend("force", opts, { desc = "Octo: Start review" })
	)

	-- レビュー再開 (VSCode: ローカルにキャッシュされた未送信コメントの再開)
	map(
		"n",
		"<Leader>gprr",
		"<Cmd>Octo review resume<CR>",
		vim.tbl_extend("force", opts, { desc = "Octo: Resume review" })
	)

	-- レビュー送信
	map(
		"n",
		"<Leader>gprx",
		"<Cmd>Octo review submit<CR>",
		vim.tbl_extend("force", opts, { desc = "Octo: Submit review" })
	)

	-- PR をマージ (VSCode: "Merge Pull Request")
	map(
		"n",
		"<Leader>gpm",
		"<Cmd>Octo pr merge<CR>",
		vim.tbl_extend("force", opts, { desc = "Octo: Merge pull request" })
	)

	-- PR をチェックアウト (VSCode: "Checkout Pull Request")
	map(
		"n",
		"<Leader>gpc",
		"<Cmd>Octo pr checkout<CR>",
		vim.tbl_extend("force", opts, { desc = "Octo: Checkout pull request" })
	)

	-- レビューの差分内で次/前のコメントへ移動 (quickfix 連携)
	map("n", "]q", "<Cmd>cnext<CR>", vim.tbl_extend("force", opts, { desc = "Octo: Next changed file" }))
	map("n", "[q", "<Cmd>cprev<CR>", vim.tbl_extend("force", opts, { desc = "Octo: Prev changed file" }))

	-- 新規 Issue 作成
	map(
		"n",
		"<Leader>gic",
		"<Cmd>Octo issue create<CR>",
		vim.tbl_extend("force", opts, { desc = "Octo: Create issue" })
	)

	-- 通知一覧 (VSCode: GitHub の通知ベル相当)
	map(
		"n",
		"<Leader>gn",
		"<Cmd>Octo notification list<CR>",
		vim.tbl_extend("force", opts, { desc = "Octo: List notifications" })
	)

	-- リポジトリ一覧
	map(
		"n",
		"<Leader>gR",
		"<Cmd>Octo repo list<CR>",
		vim.tbl_extend("force", opts, { desc = "Octo: List repositories" })
	)

	-- ── レビューバッファ用キーマップ (Octo バッファ内のみ有効) ──────────────────
	-- VSCode: 行コメント追加 (差分の +/- ガター上でクリック)
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "octo",
		callback = function(ev)
			local o = { buffer = ev.buf, noremap = true, silent = true }
			-- コメント追加 (単一/複数行)
			map(
				{ "n", "v" },
				"<Leader>ca",
				"<Cmd>Octo comment add<CR>",
				vim.tbl_extend("force", o, { desc = "Octo: Add comment" })
			)
			-- 提案 (Suggestion) 追加
			map(
				{ "n", "v" },
				"<Leader>sa",
				"<Cmd>Octo review comment suggest<CR>",
				vim.tbl_extend("force", o, { desc = "Octo: Add suggestion" })
			)
			-- コメント/レビューの送信
			map(
				"n",
				"<Leader>rs",
				"<Cmd>Octo review submit<CR>",
				vim.tbl_extend("force", o, { desc = "Octo: Submit review" })
			)
			-- リアクション追加
			map(
				"n",
				"<Leader>ra",
				"<Cmd>Octo reaction add<CR>",
				vim.tbl_extend("force", o, { desc = "Octo: Add reaction" })
			)
		end,
	})

	-- which-key グループ登録
	local wk_ok, wk = pcall(require, "which-key")
	if wk_ok then
		wk.add({
			{ "<Leader>gpr", group = "PR Review " },
		})
	end
end)
