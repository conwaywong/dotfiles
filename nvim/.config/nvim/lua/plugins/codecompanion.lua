return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  -- only load plugin if the SAIC API token exists
  cond = function()
    return vim.fn.filereadable(vim.fn.expand("$HOME/.config/saic/ai_token"))
  end,
  opts = {
    adapters = {
      opts = {
        show_defaults = false, -- only display defined adapters
      },
      saic = function()
        return require("codecompanion.adapters").extend("openai_compatible", {
          env = {
            url = "https://ai-api.sif.saicdevops.com",
            api_key = "cmd:/usr/bin/cat $HOME/.config/saic/ai_token",
          },
          schema = {
            model = {
              default = "bedrock-claude-v3-7-sonnet",
            },
          },
        })
      end,
    },
    strategies = {
      chat = {
        adapter = "saic",
        keymaps = {
          options = {
            modes = { n = "?" },
            callback = function()
              require("which-key").show({ global = false })
            end,
            description = "Codecompanion Keymaps",
            hide = true,
          },
        },
      },
      inline = {
        adapter = "saic",
      },
      cmd = {
        adapter = "saic",
      },
    },
    opts = {
      log_level = "DEBUG",
    },
  },
}
