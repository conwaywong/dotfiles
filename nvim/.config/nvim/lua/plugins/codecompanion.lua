return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "j-hui/fidget.nvim",
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
      tenjin = function()
        return require("codecompanion.adapters").extend("openai_compatible", {
          name = "tenjin",
          formatted_name = "Tenjin",
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
        adapter = "tenjin",
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
        adapter = "tenjin",
      },
      cmd = {
        adapter = "tenjin",
      },
    },
    opts = {
      log_level = "DEBUG",
    },
  },
  init = function()
    require("plugins.codecompanion.fidget-spinner"):init()
  end,
}
