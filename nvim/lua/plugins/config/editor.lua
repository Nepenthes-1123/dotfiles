local setup              = require('plugins.config.utils').setup

-- ── nvim-tree ─────────────────────────────────────────────────────────────────
vim.g.loaded_netrw       = 1
vim.g.loaded_netrwPlugin = 1
setup('nvim-tree', function(m)
    m.setup({
        view                = { width = 30, side = 'left' },
        renderer            = {
            group_empty    = false,
            indent_markers = { enable = true },
        },
        filters             = {
            custom = { '^.git$', '__pycache__', '*.pyc', 'node_modules', '.DS_Store' },
        },
        git                 = { enable = true },
        update_focused_file = { enable = true },
    })
end)

-- ── telescope ─────────────────────────────────────────────────────────────────
setup('telescope', function(m)
    local actions = require('telescope.actions')
    m.setup({
        defaults = {
            prompt_prefix        = '  ',
            selection_caret      = ' ',
            path_display         = { 'truncate' },
            sorting_strategy     = 'ascending',
            layout_config        = {
                horizontal = { prompt_position = 'top', preview_width = 0.55 },
                width = 0.87,
                height = 0.80,
            },
            mappings             = {
                i = {
                    ['<C-j>'] = actions.move_selection_next,
                    ['<C-k>'] = actions.move_selection_previous,
                    ['<Esc>'] = actions.close,
                },
            },
            file_ignore_patterns = {
                'node_modules/', '.git/', '__pycache__/', '%.pyc', '%.DS_Store',
            },
        },
        pickers = { find_files = { hidden = true } },
    })
end)

-- ── gitsigns ──────────────────────────────────────────────────────────────────
setup('gitsigns', function(m)
    m.setup({
        signs = {
            add          = { text = '▎' },
            change       = { text = '▎' },
            delete       = { text = '' },
            topdelete    = { text = '' },
            changedelete = { text = '▎' },
        },
        current_line_blame = true,
        current_line_blame_opts = {
            virt_text     = true,
            virt_text_pos = 'eol',
            delay         = 500,
        },
        current_line_blame_formatter = '  <author>, <author_time:%Y-%m-%d> · <summary>',
        preview_config = { border = 'rounded' },
    })
end)

-- ── rainbow-delimiters ────────────────────────────────────────────────────────
setup('rainbow-delimiters', function(m)
    vim.g.rainbow_delimiters = {
        strategy  = { [''] = m.strategy['global'] },
        query     = { [''] = 'rainbow-delimiters', lua = 'rainbow-blocks' },
        highlight = {
            'RainbowDelimiterRed', 'RainbowDelimiterYellow', 'RainbowDelimiterBlue',
            'RainbowDelimiterOrange', 'RainbowDelimiterGreen', 'RainbowDelimiterViolet',
            'RainbowDelimiterCyan',
        },
    }
end)

-- ── Comment.nvim ─────────────────────────────────────────────────────────────
setup('Comment', function(m)
    m.setup({
        toggler  = { line = 'gcc', block = 'gbc' },
        opleader = { line = 'gc', block = 'gb' },
    })
end)

-- ── nvim-autopairs ────────────────────────────────────────────────────────────
setup('nvim-autopairs', function(m)
    m.setup({
        check_ts         = true,
        disable_filetype = { 'TelescopePrompt' },
    })
end)

-- ── vim-illuminate ────────────────────────────────────────────────────────────
setup('illuminate', function(m)
    m.configure({
        providers          = { 'lsp', 'treesitter', 'regex' },
        delay              = 200,
        filetypes_denylist = { 'NvimTree', 'telescope' },
    })
end)
