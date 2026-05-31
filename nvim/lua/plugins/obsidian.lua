local vault_path = vim.fn.expand(vim.env.OBSIDIAN_VAULT_PATH or "~/Documents/slip-box"):gsub("\\", "/")

return {
	"epwalsh/obsidian.nvim",
	version = "*", -- recommended, use latest release instead of latest commit
	lazy = true,

	event = {
		"BufReadPre *.md",
		"BufNewFile *.md",
	},
	-- Markdownファイルを開いていなくても、
	-- 以下のコマンドが打ち込まれたら即座にプラグインをロードする
	cmd = {
		"ObsidianOpen",
		"ObsidianNew",
		"ObsidianNewFromTemplate",
		"ObsidianQuickSwitch",
		"ObsidianFollowLink",
		"ObsidianBacklinks",
		"ObsidianTags",
		"ObsidianToday",
		"ObsidianYesterday",
		"ObsidianTomorrow",
		"ObsidianDailies",
		"ObsidianTemplate",
		"ObsidianSearch",
		"ObsidianLink",
		"ObsidianLinkNew",
	},

	keys = {
		{ "<leader>os", "<cmd>ObsidianSearch<CR>", desc = "Obsidian: 全文検索" },
		{ "<leader>ot", "<cmd>ObsidianTags<CR>", desc = "Obsidian: タグ検索" },
		{ "<leader>ob", "<cmd>ObsidianBacklinks<CR>", desc = "Obsidian: バックリンク表示" },
		{ "<leader>on", "<cmd>ObsidianNew<CR>", desc = "Obsidian: 新規ノート作成" },
		{
			"<leader>ont",
			"<cmd>ObsidianNewFromTemplate<CR>",
			desc = "Obsidian: テンプレートから新規ノート",
		},
		{ "<leader>od", "<cmd>ObsidianToday<CR>", desc = "Obsidian: 今日のデイリーノート" },
	},

	dependencies = {
		-- Required.
		"nvim-lua/plenary.nvim",

		-- see below for full list of optional dependencies 👇
		"hrsh7th/nvim-cmp",
		"nvim-telescope/telescope.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	opts = {
		workspaces = {
			{
				name = "slip-box",
				path = vault_path,
			},
		},

		-- see below for full list of options 👇
		notes_subdir = "00_Inbox",

		daily_notes = {
			folder = "05_Daily",
			date_format = "%Y%m%d",
			alias_format = "%Y-%m-%d",
			template = "daily-note.md",
		},

		-- リンクのオートコンプリート
		completion = {
			nvim_cmp = true,
			min_chars = 2,
		},

		-- キーマッピング
		mappings = {
			["gf"] = {
				action = function()
					return require("obsidian").util.gf_passthrough()
				end,
				opts = { noremap = false, expr = true, buffer = true },
			},
			["<CR>"] = {
				action = function()
					local line = vim.api.nvim_get_current_line()
					if line:match("^%s*%- %[[ x]%]") then
						require("obsidian").util.toggle_checkbox()
					elseif line:match("%[%[.*%]%]") or line:match("%[.*%]%(.*%)") then
						vim.cmd("ObsidianFollowLink")
					else
						vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, true, true), "n", true)
					end
				end,
				opts = { buffer = true, expr = false },
			},
		},

		-- テンプレートフォルダ指定
		templates = {
			folder = "templates",
			date_format = "%Y-%m-%d",
			time_format = "%H:%M",
		},

		-- エディタ上のUI (チェックボックスなど)
		ui = {
			enable = false,
		},

		-- ==========================================
		-- 【ひとつ前の状態を完全復元】 ファイル名 = %Y%m%d-aliases
		-- ==========================================
		note_id_func = function(title)
			local uid = os.date("%Y%m%d%H%M%S")
			if title ~= nil and title ~= "" then
				return uid .. "-" .. title
			else
				return uid
			end
		end,

		-- ==========================================
		-- 【ひとつ前の状態を完全復元】 メタデータの自動抽出
		-- ==========================================
		note_frontmatter_func = function(note)
			local out = {
				id = note.id,
				aliases = note.aliases or {},
				tags = note.tags or {},
				date = os.date("%Y-%m-%d"),
			}

			local filename_id = tostring(note.id)
			local alias_name = filename_id:match("^%d+%-(.+)$") or filename_id

			local has_alias = false
			for _, alias in ipairs(out.aliases) do
				if alias == alias_name then
					has_alias = true
					break
				end
			end
			if not has_alias and alias_name ~= "" then
				table.insert(out.aliases, alias_name)
			end

			-- 既存のテンプレート由来のメタデータ等を結合
			if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
				for k, v in pairs(note.metadata) do
					if k ~= "id" and k ~= "aliases" and k ~= "tags" and k ~= "date" then
						out[k] = v
					end
				end
			end

			return out
		end,

		-- ==========================================
		-- markdown中で使うバックリンク = [[aliases]]
		-- ==========================================
		wiki_link_func = function(opts)
			local alias_name = opts.label

			if not alias_name or alias_name == "" then
				local identifier = ""
				if opts.path then
					identifier = vim.fin.fnamemodify(tostring(opts.path), ":t:r")
				else
					identifier = tostring(opts.id)
				end
				alias_name = identifier:match("^%d*%-(.+)$") or identifier
			end

			return string.format("[[%s|%s]]", opts.id, alias_name)
		end,
	},
	config = function(_, opts)
		-- プラグインのセットアップを実行
		require("obsidian").setup(opts)
		vim.api.nvim_create_autocmd("BufWritePost", {
			pattern = "*.md",
			callback = function(args)
				local current_path = args.file:gsub("\\", "/")
				local workspace_root = vault_path

				if not current_path:lower():find(workspace_root:lower(), 1, true) then
					return
				end

				local lines = vim.api.nvim_buf_get_lines(args.buf, 0, -1, false)
				local note_type = nil
				for i = 1, math.min(#lines, 20) do
					local match = lines[i]:match("^type:%s*(.*)$")
					if match then
						note_type = match:gsub('"', ""):gsub("'", ""):gsub("^%s*", ""):gsub("%s*$", "")
						break
					end
				end

				if not note_type then
					return
				end

				local folder_map = {
					daily = "05_Daily",
					fleeting = "00_Inbox",
					index = "00_Inbox",
					literature = "10_Literature",
					permanent = "20_Notes",
				}

				local target_folder = folder_map[note_type]
				if not target_folder then
					return
				end

				local filename = vim.fn.fnamemodify(current_path, ":t")
				local target_path = workspace_root .. "/" .. target_folder .. "/" .. filename

				if current_path:lower() == target_path:lower() then
					return
				end

				vim.schedule(function()
					vim.fn.mkdir(workspace_root .. "/" .. target_folder, "p")

					local success, err = vim.fn.rename(current_path, target_path)
					if success == 0 then
						vim.api.nvim_buf_set_name(args.buf, target_path)
						vim.api.nvim_buf_call(args.buf, function()
							vim.cmd("silent! noautocmd write")
							vim.cmd("edit!")
						end)
						vim.notify(
							"📁 " .. target_folder .. "へノートを自動移動しました",
							vim.log.levels.INFO
						)
					else
						vim.notify("自動移動に失敗しました: " .. tostring(err), vim.log.levels.ERROR)
					end
				end)
			end,
		})
		-- ビジュアルモード(選択時)の Enter でリンク化する
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "markdown",
			callback = function(args)
				-- "v" = ビジュアルモード, "<CR>" = Enterキー
				-- プラグインを使わずvimの標準機能で選択範囲をヤンクする
				vim.keymap.set("v", "<CR>", function()
					vim.cmd('noau normal! "zy')
					local text = vim.fn.getreg("z")

					text = text:gsub("^%s*", ""):gsub("%s*$", "")
					if text == "" then
						return
					end
					-- エディタ上の選択文字を一旦削除
					vim.cmd('normal! gv"_d')

					-- 抽出したテキストをコマンド引数として渡す
					vim.cmd("ObsidianLinkNew " .. text)
				end, { buffer = args.buf, silent = true })
			end,
		})
	end,
}
