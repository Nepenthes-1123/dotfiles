-- =============================================================================
-- after/ftplugin/json.lua  –  JSON ファイルタイプ固有設定
-- VSCode: "[json]", "[jsonc]" セクションの設定を移植
-- =============================================================================

-- インデント設定 (一般的な JSON は 2 スペース)
vim.bo.tabstop    = 2
vim.bo.shiftwidth = 2
vim.bo.expandtab  = true

-- VSCode: "editor.quickSuggestions": { "strings": true }
-- jsonls が文字列内補完を提供するため、Neovim 側では特別な設定不要

-- JSON の折りたたみ (オブジェクト・配列を折りたためる)
vim.wo.foldmethod = "expr"
vim.wo.foldexpr   = "v:lua.vim.treesitter.foldexpr()"
vim.wo.foldlevel  = 99  -- 起動時は全展開

-- jq による整形 (フォーマッタが動かない場合のフォールバック)
vim.keymap.set("n", "<LocalLeader>j", function()
  if vim.fn.executable("jq") == 1 then
    vim.cmd("%!jq .")
  else
    vim.notify("jq not found.", vim.log.levels.WARN)
  end
end, { buffer = true, desc = "Format with jq" })
