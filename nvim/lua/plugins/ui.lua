return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
  },

  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    opts = {},
  },

  {
    "projekt0N/github-nvim-theme",
    lazy = false,
    priority = 1000,
    config = function()
      require("github-theme").setup({})
      vim.cmd("colorscheme github_dark")
    end,
  }
}
