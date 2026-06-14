-- =============================================================================
-- lua/plugins/docker.lua  –  Docker / Dev Container 対応
-- VSCode: docker.docker, ms-azuretools.vscode-containers,
--         ms-vscode-remote.remote-containers
-- =============================================================================
-- VSCode 拡張機能と Neovim での対応:
--   docker.docker (Docker Explorer UI)        → dockerls LSP + lazydocker (TUI)
--   ms-azuretools.vscode-containers           → dockerls LSP + docker-compose LSP
--   ms-vscode-remote.remote-containers        → nvim-dev-container
-- =============================================================================


-- ── LSP: Dockerfile + docker-compose ─────────────────────────────────────────
-- mason-lspconfig の ensure_installed に追記するサーバーを有効化
-- (mason-lspconfig が lsp/dockerls.lua と lsp/docker_compose_language_service.lua
--  を自動で読み込む)
--
-- mason でのパッケージ名:
--   dockerls                         → Dockerfile LSP
--   docker-compose-language-service  → docker-compose.yml LSP

-- ── nvim-dev-container ────────────────────────────────────────────────────────
local function setup(mod, fn)
    local ok, m = pcall(require, mod)
    if not ok then return end
    fn(m)
end

setup('devcontainer', function(m)
    m.setup({
        -- コンテナ管理ツール: docker または podman
        -- システムに応じて自動検出
        container_runtime   = (function()
            if vim.fn.executable('docker') == 1 then return 'docker' end
            if vim.fn.executable('podman') == 1 then return 'podman' end
            return 'docker'
        end)(),

        -- docker-compose も使用する場合
        compose_command     = (function()
            -- docker compose (v2) を優先、なければ docker-compose (v1) にフォールバック
            if vim.fn.executable('docker') == 1 then
                local result = vim.fn.system('docker compose version 2>/dev/null')
                if vim.v.shell_error == 0 then return 'docker compose' end
            end
            return 'docker-compose'
        end)(),

        -- .devcontainer.json の検索起点
        config_search_start = function()
            return vim.loop.cwd()
        end,

        -- Neovim をコンテナ内にインストールするか
        -- true にすると初回起動時に時間がかかる
        always_pull         = false,
        nvim_installation   = 'static', -- 'static' | 'system' | 'skip'

        -- ローカルの Neovim 設定をコンテナにマウントするか
        -- (VSCode: "remoteUser" dotfiles 相当)
        nvim_config_mounts  = {
            enabled       = true,
            dotfiles_path = vim.fn.stdpath('config'),
        },

        -- コンテナ起動後に自動 attach するか
        autostart           = false,

        -- ログレベル
        log_level           = "info"
    })

    -- ── キーマップ (<Leader>dc プレフィックス) ───────────────────────────────
    local map  = vim.keymap.set
    local opts = { noremap = true, silent = true }

    -- コンテナをビルドして起動 (VSCode: "Dev Containers: Rebuild and Reopen in Container")
    map('n', '<Leader>dcu', '<Cmd>DevcontainerUp<CR>',
        vim.tbl_extend('force', opts, { desc = 'DevContainer: Up (build & start)' }))

    -- コンテナにアタッチ (VSCode: "Dev Containers: Attach to Running Container")
    map('n', '<Leader>dca', '<Cmd>DevcontainerAttach<CR>',
        vim.tbl_extend('force', opts, { desc = 'DevContainer: Attach' }))

    -- コンテナを停止
    map('n', '<Leader>dcs', '<Cmd>DevcontainerStop<CR>',
        vim.tbl_extend('force', opts, { desc = 'DevContainer: Stop' }))

    -- コンテナを削除
    map('n', '<Leader>dcd', '<Cmd>DevcontainerRemove<CR>',
        vim.tbl_extend('force', opts, { desc = 'DevContainer: Remove' }))

    -- コンテナ内でコマンドを実行
    map('n', '<Leader>dce', '<Cmd>DevcontainerExec<CR>',
        vim.tbl_extend('force', opts, { desc = 'DevContainer: Exec command' }))

    -- which-key グループ登録
    local wk_ok, wk = pcall(require, 'which-key')
    if wk_ok then
        wk.add({
            { '<Leader>d',  group = 'Docker / DevContainer' },
            { '<Leader>dc', group = 'DevContainer' },
        })
    end
end)

-- ── lazydocker (Docker UI TUI) ────────────────────────────────────────────────
-- VSCode: docker.docker の Docker Explorer パネル相当
-- lazydocker がインストールされている場合のみ有効化
-- インストール: https://github.com/jesseduffield/lazydocker
--   Windows: scoop install lazydocker / winget install lazydocker
--   macOS:   brew install lazydocker
--   Linux:   curl -s https://api.github.com/repos/jesseduffield/lazydocker/releases/latest ...
if vim.fn.executable('lazydocker') == 1 then
    vim.keymap.set('n', '<Leader>dk', function()
        -- フローティングターミナルで lazydocker を起動
        local buf    = vim.api.nvim_create_buf(false, true)
        local width  = math.floor(vim.o.columns * 0.9)
        local height = math.floor(vim.o.lines * 0.85)
        vim.api.nvim_open_win(buf, true, {
            relative  = 'editor',
            width     = width,
            height    = height,
            row       = math.floor((vim.o.lines - height) / 2),
            col       = math.floor((vim.o.columns - width) / 2),
            style     = 'minimal',
            border    = 'rounded',
            title     = ' lazydocker ',
            title_pos = 'center',
        })
        vim.fn.termopen('lazydocker', {
            on_exit = function()
                pcall(vim.api.nvim_buf_delete, buf, { force = true })
            end,
        })
        vim.cmd('startinsert')
    end, { noremap = true, silent = true, desc = 'Docker: Open lazydocker' })
end
