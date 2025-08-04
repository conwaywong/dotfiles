return {
  "saghen/blink.cmp",
  opts = {
    keymap = {
      ["<C-k>"] = { "select_prev", "fallback" },
      ["<C-j>"] = { "select_next", "fallback" },
      ["<ESC>"] = { "cancel", "fallback" },
      ["<C-c>"] = { "cancel", "fallback" },
    },
    sources = {
      providers = {
        path = { score_offset = 3 },
        lsp = { score_offset = 0 },
        snippets = { score_offset = -1 },
        buffer = { score_offset = -3 },
      },
    },
  },
}
