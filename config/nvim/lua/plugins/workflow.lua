return {
  {
    "christoomey/vim-tmux-navigator",
    event = "VeryLazy",
    cmd = { "TmuxNavigateLeft", "TmuxNavigateDown", "TmuxNavigateUp", "TmuxNavigateRight", "TmuxNavigatePrevious" },
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Left window or tmux pane" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Lower window or tmux pane" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Upper window or tmux pane" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Right window or tmux pane" },
      { "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Previous window or tmux pane" },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "python", "swift", "rust", "bash", "toml" })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- The Nix profiles and Brewfile supply these tools; avoid duplicate installs.
        pyright = { mason = false },
        ruff = {
          mason = false,
          on_attach = function(client)
            client.server_capabilities.hoverProvider = false
          end,
        },
        rust_analyzer = { mason = false },
        bashls = { mason = false, filetypes = { "sh", "bash" } },
        sourcekit = {
          mason = false,
          cmd = vim.fn.has("macunix") == 1 and { "xcrun", "sourcekit-lsp" } or { "sourcekit-lsp" },
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      local formatters = { python = "ruff_format", swift = "swift", rust = "rustfmt", sh = "shfmt", bash = "shfmt" }
      for ft, formatter in pairs(formatters) do
        opts.formatters_by_ft[ft] = { formatter }
      end
      -- shfmt does not parse Zsh. Keep Zsh syntax checking separate.
      opts.formatters_by_ft.zsh = {}
      if vim.fn.has("macunix") == 1 then
        opts.formatters = opts.formatters or {}
        opts.formatters.swift = { command = "xcrun", prepend_args = { "swift" } }
      end
    end,
  },
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.sh = { "shellcheck" }
      opts.linters_by_ft.bash = { "shellcheck" }
      opts.linters_by_ft.zsh = { "zsh_syntax" }
      opts.linters = opts.linters or {}
      opts.linters.zsh_syntax = require("config.zsh_lint")
    end,
  },
}
