-- =============================================================================
-- lsp/texlab.lua  –  LaTeX LSP サーバー設定
-- VSCode: James-Yu.latex-workshop 拡張の再現
-- =============================================================================
-- VSCode 設定の移植:
--   "latex-workshop.latex.autoBuild.run": "onSave"
--   "latex-workshop.latex.outDir": "out"
--   "latex-workshop.bibtex-format.sort.enabled": true
--   latexmk コマンド: "-file-line-error -interaction=nonstopmode -synctex=1 -outdir=%OUTDIR%"

return {
  cmd          = { "texlab" },
  filetypes    = { "tex", "plaintex", "bib" },
  root_markers = { ".latexmkrc", "latexmkrc", ".texlabroot", ".git" },
  settings = {
    texlab = {
      auxDirectory    = "out",   -- VSCode: "latex-workshop.latex.outDir": "out"
      bibtexFormatter = "texlab",
      build = {
        -- VSCode: latexmk レシピを再現
        executable   = "latexmk",
        args = {
          "-file-line-error",
          "-interaction=nonstopmode",
          "-synctex=1",
          "-outdir=out",    -- VSCode: "latex-workshop.latex.outDir": "out"
          "%f",
        },
        -- VSCode: "latex-workshop.latex.autoBuild.run": "onSave"
        onSave       = true,
        forwardSearchAfter = false,
      },
      chktex = {
        onOpenAndSave = false,
        onEdit        = false,
      },
      -- BibTeX ソート (VSCode: "latex-workshop.bibtex-format.sort.enabled": true)
      bibtexFormatter = "texlab",
      formatterLineLength = 80,
      latexFormatter      = "latexindent",
      latexindent = {
        modifyLineBreaks = false,
      },
    },
  },
}
