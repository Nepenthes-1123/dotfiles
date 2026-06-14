-- =============================================================================
-- lua/plugins/snacks.lua  –  snacks.nvim 設定
-- noice.nvim の残機能 (通知フローティング・LSP プログレス) を補完する
-- =============================================================================
-- ui2 が担う機能:
--   ・cmdline のシンタックスハイライト
--   ・「Press ENTER」の廃止
--   ・メッセージのフローティング表示 (ephemeral)
--   ・ページャのバッファ化
--
-- snacks.nvim が補完する機能:
--   ・通知の右上フローティング表示 (notifier) … noice の nvim-notify 統合相当
--   ・LSP プログレスインジケーター (notifier) … noice の lsp.progress 相当
--   ・vim.ui.input() のオーバーライド (input) … noice の cmdline popup 相当
--   ・スクロールアニメーション (scroll)
--   ・カーソル下の単語ハイライト (words)  … vim-illuminate と選択的に使用
-- =============================================================================

local function setup(mod, fn)
    local ok, m = pcall(require, mod)
    if not ok then return end
    fn(m)
end

setup('snacks', function(Snacks)
    Snacks.setup({

        -- ── notifier: 通知のフローティング表示 ──────────────────────────────────
        -- noice.nvim + nvim-notify の組み合わせ相当
        -- vim.notify() を上書きして右上にトースト通知を表示する
        notifier     = {
            enabled  = true,
            timeout  = 3000, -- 自動消去までの時間 (ms)
            width    = { min = 40, max = 0.4 },
            height   = { min = 1, max = 0.6 },
            -- 表示位置: 右上 (noice のデフォルトと同じ)
            position = 'top-right',
            -- アイコン (noice の icons 設定に相当)
            icons    = {
                error = ' ',
                warn  = ' ',
                info  = ' ',
                debug = ' ',
                trace = '✎ ',
            },
            style    = 'compact', -- 'compact' | 'fancy' | 'minimal'
            -- 通知履歴の最大保持件数
            history  = { limit = 100 },
        },

        -- ── input: vim.ui.input() のフローティング化 ─────────────────────────────
        -- noice.nvim の cmdline ポップアップ (rename, 検索入力) 相当
        -- ui2 の cmdline ハイライトと併用することで noice のフル機能に近づく
        input        = {
            enabled = true,
            -- フローティング入力ウィンドウのスタイル
            win = {
                -- winborder は options.lua の vim.o.winborder = 'rounded' を継承
                style    = 'input',
                width    = 60,
                row      = -3, -- カーソル付近に表示
                relative = 'cursor',
            },
        },

        -- ── scroll: スムーズスクロール ────────────────────────────────────────────
        -- noice のアニメーション設定 (animate) 相当
        scroll       = {
            enabled = true,
            animate = {
                duration = { step = 15, total = 150 },
                easing   = 'linear',
            },
            -- スクロールバーの表示
            filter  = function(buf)
                return vim.g.smooth_scroll_enabled ~= false
                    and vim.bo[buf].buftype ~= 'terminal'
            end,
        },

        -- ── words: カーソル下の単語ハイライト ─────────────────────────────────────
        -- vim-illuminate と同等の機能 (plugins/init.lua の vim-illuminate と重複するため
        -- どちらか一方を有効にすること。snacks.words はより軽量)
        -- vim-illuminate を無効化する場合は enabled = true に変更
        words        = {
            enabled = false, -- vim-illuminate を使用しているため無効
        },

        -- ── その他の snacks モジュール (明示的に無効化) ───────────────────────────
        -- plugins/init.lua で別途設定しているものと競合しないよう無効化
        bigfile      = { enabled = false }, -- autocmds.lua で代替済み
        dashboard    = { enabled = false }, -- 使用しない
        explorer     = { enabled = false }, -- nvim-tree を使用
        indent       = { enabled = false }, -- indent-blankline.nvim を使用
        picker       = { enabled = false }, -- telescope.nvim を使用
        statuscolumn = { enabled = false }, -- lualine.nvim を使用
        animate      = { enabled = false },
        dim          = { enabled = false },
        quickfile    = { enabled = false },
        scope        = { enabled = false },
        zen          = { enabled = false },

    })

    -- ── vim.notify のルーティングについて ────────────────────────────────────
    -- notifier.enabled = true により、snacks.setup() が内部で vim.notify を
    -- 自動的に snacks.notifier (フローティング表示) へ差し替える。
    -- 手動で vim.notify = Snacks.notify を代入すると、Snacks.notify はテーブル
    -- (呼び出し可能な関数ではない) のため vim.notify が壊れてエラーになる。
    -- そのため明示的な代入は行わない。

    -- ── LSP プログレス通知 ────────────────────────────────────────────────────
    -- noice.nvim の lsp.progress 相当
    -- LspProgress イベントを snacks.notifier でフローティング表示する
    local progress_handles = {}
    vim.api.nvim_create_autocmd('LspProgress', {
        group    = vim.api.nvim_create_augroup('snacks_lsp_progress', { clear = true }),
        callback = function(ev)
            local client = vim.lsp.get_client_by_id(ev.data.client_id)
            if not client then return end

            local value = ev.data.params.value
            local token = ev.data.params.token or 'default'
            local key   = client.id .. ':' .. token

            if value.kind == 'begin' then
                -- プログレス開始: 通知を作成
                progress_handles[key] = Snacks.notify.info(
                    (value.message or '') ~= '' and value.message or (value.title or 'Loading...'),
                    {
                        id    = key,
                        title = client.name,
                        opts  = function(notif)
                            notif.icon = '◐ '
                            notif.timeout = false -- 完了まで自動消去しない
                        end,
                    }
                )
            elseif value.kind == 'report' and progress_handles[key] then
                -- プログレス更新
                local msg = value.message or ''
                if value.percentage then
                    msg = string.format('%s (%d%%)', msg, value.percentage)
                end
                Snacks.notify.info(msg, {
                    id    = key,
                    title = client.name,
                    opts  = function(notif)
                        notif.icon = '◐ '
                        notif.timeout = false
                    end,
                })
            elseif value.kind == 'end' then
                -- プログレス完了: 通知を更新して短時間で消去
                Snacks.notify.info(value.message or 'Done', {
                    id      = key,
                    title   = client.name,
                    timeout = 1500,
                    opts    = function(notif)
                        notif.icon = ' '
                    end,
                })
                progress_handles[key] = nil
            end
        end,
    })

    -- ── キーマップ ────────────────────────────────────────────────────────────
    local map  = vim.keymap.set
    local opts = { noremap = true, silent = true }

    -- 通知履歴を表示 (noice: <Leader>snh 相当)
    map('n', '<Leader>nh', function() Snacks.notifier.show_history() end,
        vim.tbl_extend('force', opts, { desc = 'Notification history' }))

    -- 全通知を閉じる (noice: <Leader>snd 相当)
    map('n', '<Leader>nd', function() Snacks.notifier.hide() end,
        vim.tbl_extend('force', opts, { desc = 'Dismiss all notifications' }))

    -- which-key グループ登録
    local wk_ok, wk = pcall(require, 'which-key')
    if wk_ok then
        wk.add({ { '<Leader>n', group = 'Notifications' } })
    end
end)
