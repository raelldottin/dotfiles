-- set leader key to space
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local uv = vim.uv or vim.loop

if not uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- configure plugins
require("lazy").setup({
  "tpope/vim-sleuth", -- detect tabstop and shiftwidth automatically

  -- colorscheme
  {
    "bluz71/vim-moonfly-colors",
    name = "moonfly",
    lazy = false,
    priority = 1000,
    config = function()
      require("core.colorscheme")
    end,
  },

  -- tmux navigation
  "christoomey/vim-tmux-navigator", -- tmux & split window navigation

  -- file explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("plugins.nvim-tree")
    end,
  },

  -- statusline
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("plugins.lualine")
    end,
  },

  -- fuzzy finding w/ telescope
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-lua/popup.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release"
          .. " && make --build build --config Release"
          .. " && cmake --install build --prefix build",
        cond = function()
          return vim.fn.executable("cmake") == 1 and vim.fn.executable("make") == 1
        end,
      },
    },
    config = function()
      require("plugins.telescope")
    end,
  },

  -- autocompletion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-nvim-lsp",
      "L3MON4D3/LuaSnip",
      "rafamadriz/friendly-snippets",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      require("plugins.nvim-cmp")
    end,
  },

  -- configuring lsp servers
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason-org/mason.nvim", -- manage language servers
      "mason-org/mason-lspconfig.nvim", -- bridge mason and nvim-lspconfig
      "hrsh7th/cmp-nvim-lsp", -- for autocompletion
      "onsails/lspkind.nvim", -- vs-code like icons for autocompletion
      {
        "glepnir/lspsaga.nvim",
        branch = "main",
        config = function()
          require("lspsaga").setup({})
        end,
      },
      { "j-hui/fidget.nvim", opts = {} },
    },
    config = function()
      require("plugins.lsp.mason")
      require("plugins.lsp.lspconfig")
    end,
  },

  -- formatting
  {
    "stevearc/conform.nvim",
    config = function()
      require("plugins.lsp.conform")
    end,
  },

  -- treesitter configuration
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-context",
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    build = ":TSUpdate",
    config = function()
      require("plugins.treesitter")
    end,
  },

  -- git integration
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("plugins.gitsigns")
    end,
  },

  -- wakatime
  "wakatime/vim-wakatime",
})
