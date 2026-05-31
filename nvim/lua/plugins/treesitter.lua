return {
  {
    "nvim-treesitter/nvim-treesitter",

    build = ":TSUpdate",

    lazy = false,

    priority = 1000,

    config = function()
      require("nvim-treesitter.config").setup({
        ensure_installed = {
          "lua",
          "vim",
          "vimdoc",
          "markdown",
          "markdown_inline",
          "python",
          "cpp",
          "c"
        },

        highlight = {
          enable = true,
        },

        indent = {
          enable = true,
        },
      })
    end,
  },
}
