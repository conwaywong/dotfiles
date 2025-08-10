return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    adapters = {
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
      },
    },
    opts = {
      log_level = "DEBUG",
    },
  },
}
