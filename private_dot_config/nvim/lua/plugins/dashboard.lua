return {
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = { enabled = false },
    },
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    init = function()
      vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("OpenNeoTreeOnEmptyStart", { clear = true }),
        callback = function()
          if vim.fn.argc() == 0 then
            require("neo-tree.command").execute({ dir = vim.uv.cwd() })
          end
        end,
      })
    end,
  },
}
