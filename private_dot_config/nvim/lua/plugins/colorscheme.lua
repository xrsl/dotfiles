-- The pinned line and the bench block below are edited by the `nvimtheme` shell function.
local theme = "catppuccin-mocha" -- nvimtheme:pinned

return {
  { "LazyVim/LazyVim", opts = { colorscheme = theme } },

  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      flavour = "mocha", -- same palette ghostty and herdr already draw; base is #1e1e2e in both
      no_italic = true,
      term_colors = true, -- :terminal buffers inherit the same 16 colors
      color_overrides = {
        -- stock mocha comments (overlay0 #6c7086) read muddy on #1e1e2e; one step up.
        mocha = { overlay0 = "#7f849c" },
      },
    },
  },

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
  { "folke/tokyonight.nvim", lazy = true },
  { "rebelot/kanagawa.nvim", lazy = true },
  { "EdenEast/nightfox.nvim", lazy = true },
  { "scottmckendry/cyberdream.nvim", lazy = true },
  { "kotsuban/nekomi.nvim", lazy = true },
  { "initsyscall/themeInitNvim", lazy = true },
  -- nvimtheme:end
}
