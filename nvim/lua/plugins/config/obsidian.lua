-- =============================================================================
-- lua/plugins/obsidian.lua  –  obsidian.nvim 設定
-- VSCode: foam.foam-vscode の代替
-- リポジトリ: https://github.com/obsidian-nvim/obsidian.nvim
-- =============================================================================
--
-- 【Foam テンプレート変数の互換対応】
-- 既存の Foam テンプレートで使われている変数を obsidian.nvim の
-- templates.substitutions でそのまま解決できるようにマッピングしています。
--
-- Foam 変数                    obsidian.nvim での解決方法
-- ─────────────────────────────────────────────────────
-- $FOAM_TITLE                → {{title}}          (組み込み)
-- $FOAM_SLUG                 → {{FOAM_SLUG}}      (カスタム: title をスラッグ化)
-- $FOAM_TITLE_NON_EXT_SAFE   → {{FOAM_TITLE_NON_EXT_SAFE}} (カスタム: 同上)
-- $FOAM_DATE_YEAR            → {{FOAM_DATE_YEAR}} (カスタム: os.date)
-- $FOAM_DATE_MONTH           → {{FOAM_DATE_MONTH}}
-- $FOAM_DATE_DATE            → {{FOAM_DATE_DATE}}
-- $FOAM_DATE_HOUR            → {{FOAM_DATE_HOUR}}
-- $FOAM_DATE_MINUTE          → {{FOAM_DATE_MINUTE}}
-- $FOAM_DATE_SECOND          → {{FOAM_DATE_SECOND}}
-- $FOAM_DATE_SECONDS_UNIX    → {{FOAM_DATE_SECONDS_UNIX}}
-- $FOAM_DATE_WEEK            → {{FOAM_DATE_WEEK}}
-- $FOAM_DATE_DAY_ISO         → {{FOAM_DATE_DAY_ISO}}
-- $FOAM_SELECTED_TEXT        → {{FOAM_SELECTED_TEXT}} (カスタム: 空文字列)
-- $FOAM_CURRENT_DIR          → {{path}} で代替 (組み込み)
-- $TM_FILENAME_BASE          → {{title}} で代替 (組み込み)
--
-- 【テンプレートファイルの書き換えについて】
-- 既存テンプレートの $FOAM_XXX 変数を {{FOAM_XXX}} に置換してください。
-- 例: $FOAM_TITLE → {{title}}
--     $FOAM_DATE_YEAR → {{FOAM_DATE_YEAR}}
-- 一括置換スクリプトを本ファイル末尾に記載しています。
-- =============================================================================

local function setup(mod, fn)
	local ok, m = pcall(require, mod)
	if not ok then
		return
	end
	fn(m)
end

-- ── Foam スラッグ変換ヘルパー ──────────────────────────────────────────────────
-- $FOAM_SLUG: タイトルを GitHub slug 方式でスラッグ化
-- 例: "My Note Title" → "my-note-title"
local function slugify(str)
	return str
		:lower()
		:gsub("[%s_]+", "-") -- 空白・アンダースコアをハイフンに
		:gsub("[^%w%-]", "") -- 英数字とハイフン以外を除去
		:gsub("%-+", "-") -- 連続ハイフンを単一に
		:gsub("^%-+", "") -- 先頭ハイフンを除去
		:gsub("%-+$", "") -- 末尾ハイフンを除去
end

-- ── ノートタイプ別の保存先・テンプレート定義 ────────────────────────────────────
-- Zettelkasten のノートタイプごとに「保存先フォルダ」と「テンプレートファイル名」を
-- 事前に定義しておく。<Leader>oz + キー で各タイプのノートを新規作成できる。
-- フォルダ名は実際の Vault 構成 (PARA/Zettelkasten のフォルダ構造) に
-- 合わせて変更してください。daily(05_Daily) は daily_notes 設定で別途管理。
local note_types = {
	f = { folder = "00_Inbox", template = "fleeting-note.md", desc = "Fleeting Note" },
	l = { folder = "10_Literature", template = "literature-note.md", desc = "Literature Note" },
	p = { folder = "20_Notes", template = "permanent-note.md", desc = "Permanent Note" },
	i = { folder = "30_Index", template = "index-note.md", desc = "Index Note (MOC)" },
}

-- 指定フォルダ + テンプレートでノートを新規作成する
-- タイトルをプロンプトで入力 (空欄でキャンセル)
local function new_note_from_template(folder, template)
	vim.ui.input({ prompt = "Note title: " }, function(title)
		if not title or title == "" then
			return
		end
		local path = folder .. "/" .. title
		-- vim.cmd.Obsidian({ args = {...} }) はタイトル中のスペースを
		-- 分割せず単一の引数として渡せる
		vim.cmd.Obsidian({ args = { "new_from_template", path, template } })
	end)
end

-- ── obsidian.nvim 設定 ────────────────────────────────────────────────────────
setup("obsidian", function(m)
	m.setup({

		-- ── ワークスペース ──────────────────────────────────────────────────────
		-- 既存の Foam リポジトリをそのまま vault として使用する
		-- path は環境に合わせて変更してください
		workspaces = {
			{
				name = "foam-vault",
				-- Foam リポジトリのパスを指定
				-- Windows:  'C:/Users/<username>/path/to/foam-repo'
				-- macOS:    '~/path/to/foam-repo'
				-- Linux:    '~/path/to/foam-repo'
				path = vim.env.OBSIDIAN_VAULT_PATH or "~/Documents/slip-box",
			},
		},

		-- ── ノート ID・ファイル名のデフォルト形式 ─────────────────────────────
		-- Foam はタイトルをファイル名にするスタイルなので合わせる
		note_id_func = function(title)
			if title ~= nil then
				return slugify(title)
			else
				-- タイトルなしの場合はタイムスタンプ
				return tostring(os.time())
			end
		end,

		-- ノートのフルパス生成関数
		note_path_func = function(spec)
			local path = spec.dir / tostring(spec.id)
			return path:with_suffix(".md")
		end,

		-- ── デイリーノート ─────────────────────────────────────────────────────
		-- Foam のデイリーノートと同じフォルダ・形式に合わせる
		-- Foam デフォルト: /daily/YYYY-MM-DD.md
		daily_notes = {
			folder = "05_Daily",
			date_format = "%Y-%m-%d",
			-- デイリーノートに適用するテンプレートファイル名
			-- Foam リポジトリ内の .foam/templates/daily-note.md に相当するファイル名を指定
			template = "daily-note.md",
		},

		-- ── テンプレート ───────────────────────────────────────────────────────
		-- Foam リポジトリのテンプレートフォルダを指定
		-- Foam のデフォルト: .foam/templates/
		templates = {
			folder = "Templates",
			date_format = "%Y-%m-%d",
			time_format = "%H:%M:%S",

			-- ── Foam テンプレート変数の互換 substitutions ─────────────────────
			-- 既存テンプレート内の $FOAM_XXX を {{FOAM_XXX}} に書き換えると
			-- 以下のマッピングで自動解決される
			substitutions = {

				id = function()
					return os.date("%Y%m%d%H%M%S")
				end,

				ymd = function()
					return os.date("%Y%m%d")
				end,

				-- デイリーノートで便利な前日・翌日変数 (Foam にはないが有用)
				yesterday = function()
					return os.date("%Y-%m-%d", os.time() - 86400)
				end,
				tomorrow = function()
					return os.date("%Y-%m-%d", os.time() + 86400)
				end,
			},
		},

		-- ── 新規ノートの保存場所 ───────────────────────────────────────────────
		-- Foam のデフォルト: ワークスペースルートに作成
		new_notes_location = "current_dir",

		-- ── picker (検索UI) ────────────────────────────────────────────────────
		-- telescope.nvim を使用 (plugins/init.lua で設定済み)
		picker = {
			name = "telescope.nvim",
			note_mappings = {
				new = "<C-x>", -- 新規ノートを作成
				insert_link = "<C-l>", -- リンクを挿入
			},
			tag_mappings = {
				tag_note = "<C-x>",
				insert_tag = "<C-l>",
			},
		},

		-- ── UI 設定 ────────────────────────────────────────────────────────────
		ui = {
			enable = false,

			-- [[wikilink]] のハイライト
			hl_groups = {
				ObsidianTodo = { bold = true, fg = "#f78c6c" },
				ObsidianDone = { bold = true, fg = "#89ddff" },
				ObsidianRightArrow = { bold = true, fg = "#f78c6c" },
				ObsidianTilde = { bold = true, fg = "#ff5370" },
				ObsidianImportant = { bold = true, fg = "#d73128" },
				ObsidianBullet = { bold = true, fg = "#89ddff" },
				ObsidianRefText = { underline = true, fg = "#c792ea" },
				ObsidianExtLinkIcon = { fg = "#c792ea" },
				ObsidianTag = { italic = true, fg = "#89ddff" },
				ObsidianBlockID = { italic = true, fg = "#89ddff" },
				ObsidianHighlightText = { bg = "#75662e" },
			},

			bullets = { char = "•", hl_group = "ObsidianBullet" },
			external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
			reference_text = { hl_group = "ObsidianRefText" },
			highlight_text = { hl_group = "ObsidianHighlightText" },
			tags = { hl_group = "ObsidianTag" },
			block_ids = { hl_group = "ObsidianBlockID" },
		},

		-- チェックボックスの表示 (Foam: GFM チェックボックスと同等)
		checkboxes = {
			[" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
			["x"] = { char = "", hl_group = "ObsidianDone" },
			[">"] = { char = "", hl_group = "ObsidianRightArrow" },
			["~"] = { char = "󰰱", hl_group = "ObsidianTilde" },
			["!"] = { char = "", hl_group = "ObsidianImportant" },
		},

		-- ── Obsidian アプリとの共存 ────────────────────────────────────────────
		-- Foam リポジトリを Obsidian アプリとも共有する場合は true
		-- (Obsidian の .obsidian/ フォルダが vault 内に存在していても問題なし)
		open = {
			func = function(uri)
				vim.ui.open(uri)
			end,
		},

		-- 古いPascalCaseコマンドを明示的に消す
		legacy_commands = false,
	})

	-- ── キーマップ (<Leader>o プレフィックス) ────────────────────────────────
	local map = vim.keymap.set
	local opts = { noremap = true, silent = true }

	-- ノート検索 (Foam: "Foam: Open Note")
	map(
		"n",
		"<Leader>of",
		"<Cmd>Obsidian quick_switch<CR>",
		vim.tbl_extend("force", opts, { desc = "Obsidian: Find notes" })
	)

	-- 全文検索 (Foam: "Foam: Search Notes")
	map(
		"n",
		"<Leader>og",
		"<Cmd>Obsidian search<CR>",
		vim.tbl_extend("force", opts, { desc = "Obsidian: Search in notes" })
	)

	-- デイリーノートを開く (Foam: "Foam: Open Daily Note")
	map(
		"n",
		"<Leader>od",
		"<Cmd>Obsidian today<CR>",
		vim.tbl_extend("force", opts, { desc = "Obsidian: Open today note" })
	)

	-- 前日のデイリーノート
	map(
		"n",
		"<Leader>oD",
		"<Cmd>Obsidian yesterday<CR>",
		vim.tbl_extend("force", opts, { desc = "Obsidian: Open yesterday note" })
	)

	-- 新規ノートを作成 (Foam: "Foam: Create New Note")
	map("n", "<Leader>on", "<Cmd>Obsidian new<CR>", vim.tbl_extend("force", opts, { desc = "Obsidian: New note" }))

	-- テンプレートから新規ノートを作成 (Foam: "Foam: Create New Note From Template")
	map(
		"n",
		"<Leader>oN",
		"<Cmd>Obsidian new_from_template<CR>",
		vim.tbl_extend("force", opts, { desc = "Obsidian: New note from template" })
	)

	-- カーソル下のリンクを追う (Foam: Ctrl+Click / "Foam: Follow Link")
	map(
		"n",
		"<Leader>ol",
		"<Cmd>Obsidian follow_link<CR>",
		vim.tbl_extend("force", opts, { desc = "Obsidian: Follow link" })
	)
	-- gf でも追える (Neovim ネイティブな操作感)
	map("n", "gf", "<Cmd>Obsidian follow_link<CR>", vim.tbl_extend("force", opts, { desc = "Follow wikilink" }))

	-- バックリンク一覧 (Foam: "Foam: Show Backlinks")
	map(
		"n",
		"<Leader>ob",
		"<Cmd>Obsidian backlinks<CR>",
		vim.tbl_extend("force", opts, { desc = "Obsidian: Show backlinks" })
	)

	-- タグ一覧 (Foam: "Foam: Show Tags")
	map("n", "<Leader>ot", "<Cmd>Obsidian tags<CR>", vim.tbl_extend("force", opts, { desc = "Obsidian: Show tags" }))

	-- テンプレートを現在のノートに挿入 (Foam: テンプレート挿入コマンド)
	map(
		"n",
		"<Leader>oT",
		"<Cmd>Obsidian template<CR>",
		vim.tbl_extend("force", opts, { desc = "Obsidian: Insert template" })
	)

	-- 目次 (Table of Contents) を表示
	map(
		"n",
		"<Leader>oc",
		"<Cmd>Obsidian toc<CR>",
		vim.tbl_extend("force", opts, { desc = "Obsidian: Table of contents" })
	)

	-- ノートのリネーム (リンクも自動更新)
	map(
		"n",
		"<Leader>or",
		"<Cmd>Obsidian rename<CR>",
		vim.tbl_extend("force", opts, { desc = "Obsidian: Rename note (update links)" })
	)

	-- チェックボックスのトグル (Foam: GFM チェックボックス)
	map(
		"n",
		"<Leader>ox",
		"<Cmd>Obsidian toggle_checkbox<CR>",
		vim.tbl_extend("force", opts, { desc = "Obsidian: Toggle checkbox" })
	)

	-- リンクを挿入 (Foam: [[ で補完)
	map("n", "<Leader>oi", "<Cmd>Obsidian link<CR>", vim.tbl_extend("force", opts, { desc = "Obsidian: Insert link" }))

	-- ワークスペースを切り替え
	map(
		"n",
		"<Leader>ow",
		"<Cmd>Obsidian workspace<CR>",
		vim.tbl_extend("force", opts, { desc = "Obsidian: Switch workspace" })
	)

	-- ── ノートタイプ別の新規作成 (<Leader>oz + キー) ─────────────────────────
	-- 各タイプ専用フォルダにタイトル入力 → 対応テンプレートでノート作成
	for key, nt in pairs(note_types) do
		map("n", "<Leader>oz" .. key, function()
			new_note_from_template(nt.folder, nt.template)
		end, vim.tbl_extend("force", opts, { desc = "Obsidian: New " .. nt.desc }))
	end

	-- which-key グループ登録
	local wk_ok, wk = pcall(require, "which-key")
	if wk_ok then
		wk.add({
			{ "<Leader>o", group = "Obsidian (Foam vault)" },
			{ "<Leader>oz", group = "New note (by type)" },
		})
	end

	-- lualine にステータスを表示 (obsidian.nvim 公式推奨)
	-- plugins/init.lua の lualine 設定は自動で obsidian_status を検知するが
	-- 明示的に追加したい場合は以下を plugins/init.lua の lualine_x セクションに追記:
	-- { 'b:obsidian_status' }
end)
