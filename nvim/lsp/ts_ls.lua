-- =============================================================================
-- lsp/ts_ls.lua  –  TypeScript / JavaScript LSP サーバー設定
-- VSCode: dbaeumer.vscode-eslint + esbenp.prettier-vscode と連携
-- =============================================================================
-- フォーマットは prettier (conform.nvim 経由) に任せるため、
-- ts_ls のドキュメントフォーマット機能は無効化する
-- (config/autocmds.lua の LspAttach で client.server_capabilities を落としている)

return {
  cmd          = { "typescript-language-server", "--stdio" },
  filetypes    = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
  init_options = {
    hostInfo = "neovim",
    preferences = {
      -- 未使用インポートの自動削除 (VSCode: source.organizeImports と同等)
      includeCompletionsForModuleExports    = true,
      includeCompletionsWithInsertText      = true,
      importModuleSpecifierPreference       = "shortest",
      -- インレイヒント (VSCode Pylance 風の型表示)
      includeInlayParameterNameHints        = "all",
      includeInlayParameterNameHintsWhenArgumentMatchesName = false,
      includeInlayFunctionParameterTypeHints = true,
      includeInlayVariableTypeHints         = true,
      includeInlayPropertyDeclarationTypeHints = true,
      includeInlayFunctionLikeReturnTypeHints  = true,
      includeInlayEnumMemberValueHints         = true,
    },
  },
  settings = {
    typescript = {
      inlayHints = {
        includeInlayParameterNameHints              = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints      = true,
        includeInlayVariableTypeHints               = true,
        includeInlayPropertyDeclarationTypeHints    = true,
        includeInlayFunctionLikeReturnTypeHints     = true,
        includeInlayEnumMemberValueHints            = true,
      },
    },
    javascript = {
      inlayHints = {
        includeInlayParameterNameHints              = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints      = true,
        includeInlayVariableTypeHints               = true,
        includeInlayPropertyDeclarationTypeHints    = true,
        includeInlayFunctionLikeReturnTypeHints     = true,
        includeInlayEnumMemberValueHints            = true,
      },
    },
  },
}
