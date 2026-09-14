-- The pinned line and the bench block below are edited by the `nvimtheme` shell function.
local theme = "nekomi" -- nvimtheme:pinned

return {
  { "LazyVim/LazyVim", opts = { colorscheme = theme } },

  {
    "rose-pine/neovim",
    name = "rose-pine",
    opts = {
      variant = "moon",
      styles = { italic = false },
      highlight_groups = { ["@punctuation"] = { fg = "highlight_lo" } },
    },
  },

  -- nvimtheme:bench -- installed but never loaded; preview them with <leader>uC
  { "catppuccin/nvim", name = "catppuccin", lazy = true },
  { "folke/tokyonight.nvim", lazy = true },
  { "rebelot/kanagawa.nvim", lazy = true },
  { "EdenEast/nightfox.nvim", lazy = true },
  { "scottmckendry/cyberdream.nvim", lazy = true },
  { "kotsuban/nekomi.nvim", lazy = true },
  { "initsyscall/themeInitNvim", lazy = true },
  -- nvimtheme:end
}
