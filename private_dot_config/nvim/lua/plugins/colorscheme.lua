local config = function()
  require("rose-pine").setup({
    variant = "moon",
    disable_italics = true,
    groups = {
      punctuation = "highlight_lo",
    },
  })
  vim.cmd("colorscheme rose-pine")
end

return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    config = config,
  },
}
--return {
--  {
--    "catppuccin/nvim",
--    name = "catppuccin",
--    priority = 1000,
--    opts = {
--      flavour = "mocha", -- latte, frappe, macchiato, mocha
--      integrations = {
--        cmp = true,
--        gitsigns = true,
--        neotree = true,
--        treesitter = true,
--        notify = true,
--        mini = true,
--        which_key = true,
--      },
--    },
--  },
--
--  {
--    "LazyVim/LazyVim",
--    opts = {
--      colorscheme = "catppuccin",
--    },
--  },
--}
