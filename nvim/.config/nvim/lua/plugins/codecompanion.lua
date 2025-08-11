return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "j-hui/fidget.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    {
      "MeanderingProgrammer/render-markdown.nvim",
      ft = { "markdown", "codecompanion" },
    },
    {
      "echasnovski/mini.diff",
      config = function()
        local diff = require("mini.diff")
        diff.setup({
          -- Disabled by default
          source = diff.gen_source.none(),
        })
      end,
    },
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
          close = {
            modes = { n = { "<C-c>", "<esc>" }, i = {} }, --disable <C-c> in insert mode
            callback = function() --https://github.com/olimorris/codecompanion.nvim/discussions/139#discussioncomment-10577399
              require("codecompanion").toggle()
            end,
            description = "Toggle Chat",
          },
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
      require("which-key").add({ "<leader>a", group = "ai" }), --only add which-key group if this plugin is loaded
      log_level = "DEBUG",
    },
  },
  keys = {
    { "<leader>aa", "<cmd>CodeCompanionChat Toggle<cr>", desc = "Toggle (AI Chat)", mode = { "n", "v" } },
    { "<leader>ao", "<cmd>CodeCompanionActions<cr>", desc = "Actions (AI Chat)", mode = { "n", "v" } },
    { "<leader>av", "<cmd>CodeCompanionChat Add<cr>", desc = "Add (AI Chat)", mode = { "v" } },
  },
  init = function()
    require("plugins.codecompanion.fidget-spinner"):init()
  end,
}
