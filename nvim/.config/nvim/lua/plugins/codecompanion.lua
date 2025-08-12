return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "j-hui/fidget.nvim",
    "nvim-lua/plenary.nvim",
    {
      "nvim-treesitter/nvim-treesitter",
      lazy = false,
      dependencies = { --https://github.com/OXY2DEV/markview.nvim?tab=readme-ov-file#-installation
        "OXY2DEV/markview.nvim",
        lazy = false,
        opts = {
          preview = {
            filetypes = { "markdown", "codecompanion" },
            ignore_buftypes = {},
          },
        },
      },
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
  enabled = function()
    return vim.fn.filereadable(vim.fn.expand("~/.config/saic/ai_token")) == 1
  end,
  opts = {
    adapters = {
      opts = {
        show_defaults = false, -- only display defined adapters
        show_model_choices = true,
      },
      saicgpt = function()
        return require("codecompanion.adapters").extend("openai_compatible", {
          name = "saicgpt",
          formatted_name = "SAICGPT",
          env = {
            url = "https://ai-api.sif.saicdevops.com",
            api_key = "cmd:/usr/bin/cat $HOME/.config/saic/ai_token",
          },
          raw = {
            "--connect-timeout",
            "20",
          },
          schema = {
            model = {
              default = "bedrock-claude-4-sonnet",
            },
          },
        })
      end,
    },
    strategies = {
      chat = {
        adapter = "saicgpt",
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
        adapter = "saicgpt",
      },
      cmd = {
        adapter = "saicgpt",
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
