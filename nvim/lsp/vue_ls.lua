-- =============================================================================
-- lsp/vue_ls.lua  –  Vue LSP サーバー設定 (Volar v2)
-- VSCode: vue.volar 拡張
-- =============================================================================

return {
    cmd          = { "vue-language-server", "--stdio" },
    filetypes    = { "vue" },
    root_markers = { "vue.config.js", "vue.config.ts", "nuxt.config.ts", "package.json", ".git" },
    init_options = {
        -- Volar v2: TypeScript サポートを内蔵
        typescript = {
            tsdk = (function()
                -- グローバルインストールの TypeScript を探す
                local tsdk = vim.fn.exepath("tsserver")
                if tsdk ~= "" then
                    return vim.fn.fnamemodify(tsdk, ":h") .. "/../lib"
                end
                -- node_modules 内を探す
                local local_ts = vim.fn.getcwd() .. "/node_modules/typescript/lib"
                if vim.fn.isdirectory(local_ts) == 1 then
                    return local_ts
                end
                return ""
            end)(),
        },
    },
}
