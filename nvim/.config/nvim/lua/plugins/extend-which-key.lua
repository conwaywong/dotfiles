return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    -- Disable automatic comment insertion
    vim.api.nvim_create_autocmd("BufEnter", {
      callback = function()
        vim.opt.formatoptions:remove({ "c", "r", "o" })
      end,
      desc = "Disable New Line Comment",
    })
  end,
  opts = {
    icons = {
      mappings = false,
    },
  },
}
