-- =============================================================================
-- config/autocmds.lua  –  自動コマンド群
-- VSCode の "formatOnSave", "trimTrailingWhitespace", 言語別設定 etc. を再現
-- =============================================================================

local aug        = vim.api.nvim_create_augroup
local au         = vim.api.nvim_create_autocmd

-- ── 末尾空白の自動削除 (trimTrailingWhitespace) ───────────────────────────────
-- VSCode: "files.trimTrailingWhitespace": true
-- markdown は除外 (VSCode: "[markdown]": { "files.trimTrailingWhitespace": false })
local trim_group = aug("TrimTrailingWhitespace", { clear = true })
au("BufWritePre", {
    group    = trim_group,
    pattern  = "*",
    callback = function()
        if vim.bo.filetype == "markdown" then return end
        -- 現在のカーソル位置を保持して末尾空白を削除
        local view = vim.fn.winsaveview()
        vim.cmd([[silent! %s/\s\+$//e]])
        vim.fn.winrestview(view)
    end,
})

-- ── 言語別インデント設定 ─────────────────────────────────────────────────────
-- VSCode: "[tex]": { "editor.tabSize": 2 }, "[latex]": { "editor.tabSize": 2 }
local indent_group = aug("FiletypeIndent", { clear = true })
au("FileType", {
    group    = indent_group,
    pattern  = { "tex", "latex", "bib", "plaintex", "markdown", "json", "jsonc", "yaml", "html", "css" },
    callback = function()
        vim.bo.tabstop    = 2
        vim.bo.shiftwidth = 2
    end,
})

-- ── ターミナルでは行番号を非表示 ─────────────────────────────────────────────
local term_group = aug("TerminalSettings", { clear = true })
au("TermOpen", {
    group    = term_group,
    pattern  = "*",
    callback = function()
        vim.wo.number         = false
        vim.wo.relativenumber = false
        vim.cmd("startinsert")
    end,
})

-- ── Yank ハイライト (視認性向上) ──────────────────────────────────────────────
local yank_group = aug("YankHighlight", { clear = true })
au("TextYankPost", {
    group    = yank_group,
    pattern  = "*",
    callback = function()
        vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
    end,
})

-- ── ファイルタイプ別 spell (markdown のみ有効) ────────────────────────────────
local spell_group = aug("SpellSettings", { clear = true })
au("FileType", {
    group    = spell_group,
    pattern  = { "markdown", "gitcommit" },
    callback = function()
        vim.wo.spell = true
    end,
})

-- ── LSP attach 共通処理 ───────────────────────────────────────────────────────
-- attach 時に inlay hints を有効化 (Neovim v0.10+)
local lsp_group = aug("LspAttachSettings", { clear = true })
au("LspAttach", {
    group    = lsp_group,
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if not client then return end

        -- インレイヒント (VSCode Pylance の型ヒントと同等)
        if client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
        end

        -- フォーマット機能が無い LSP を除外してフォーマット競合を防ぐ
        -- (例: tsserver は prettier に任せる)
        if client.name == "ts_ls" or client.name == "vue_ls" then
            client.server_capabilities.documentFormattingProvider = false
        end
    end,
})

-- ── 大文字ファイル読み込み時のパフォーマンス最適化 ───────────────────────────
local bigfile_group = aug("BigFileSettings", { clear = true })
au("BufReadPre", {
    group    = bigfile_group,
    pattern  = "*",
    callback = function()
        local max_filesize = 1024 * 1024 -- 1 MB
        local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(0))
        if ok and stats and stats.size > max_filesize then
            vim.bo.swapfile   = false
            vim.bo.undofile   = false
            vim.wo.foldmethod = "manual"
        end
    end,
})

-- ── quickfix を自動で開く ─────────────────────────────────────────────────────
local qf_group = aug("QuickFixOpen", { clear = true })
au("QuickFixCmdPost", {
    group   = qf_group,
    pattern = "[^l]*",
    command = "cwindow",
})
