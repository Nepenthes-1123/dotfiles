-- =============================================================================
-- init.lua  –  Neovim v0.12 設定 (VSCode dotfiles 移植版)
-- =============================================================================
-- 読み込み順:
--   1. options   … エディタ基本オプション
--   2. keymaps   … グローバルキーマップ
--   3. autocmds  … 自動コマンド (formatOnSave, trimTrailingWhitespace など)
--   4. lsp       … LSP サーバー有効化 & 共通キーマップ
--   5. plugins   … packpath 経由プラグイン設定
-- =============================================================================

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lsp")
require("plugins.init")
