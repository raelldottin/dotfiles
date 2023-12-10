-- set leader key to space
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
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
  { "bluz71/vim-moonfly-colors", name = "moonfly", lazy = false, priority = 1000 },

  -- tmux navigation
  "christoomey/vim-tmux-navigator", -- tmux & split window navigation

  -- file explorer
  { "nvim-tree/nvim-tree.lua", dependencies = { "kyazdani42/nvim-web-devicons" } },

  -- statusline
  { "nvim-lualine/lualine.nvim", dependencies = { "kyazdani42/nvim-web-devicons" } },

  -- fuzzy finding w/ telescope
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-lua/popup.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && make --build build --config Release && cmake --install build --prefix build",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
    },
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
  },

  -- configuring lsp servers
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim", -- in charge of managing lsp servers, linters & formatters
      "williamboman/mason-lspconfig.nvim", -- bridges gap b/w mason & lspconfig
      "hrsh7th/cmp-nvim-lsp", -- for autocompletion
      "jose-elias-alvarez/typescript.nvim", -- additional functionality for typescript server (e.g. rename file & update imports,
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
  },

  -- formatting & linting
  "jose-elias-alvarez/null-ls.nvim", -- configure formatters & linters
  "jayp0521/mason-null-ls.nvim", -- bridges gap b/w mason & null-ls

  -- treesitter configuration
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = { "nvim-treesitter/nvim-treesitter-context", "nvim-treesitter/nvim-treesitter-textobjects" },
    build = ":TSUpdate",
  },

  -- git integration
  "lewis6991/gitsigns.nvim", -- show line modifications on left hand side

  -- wakatime
  "wakatime/vim-wakatime",
})
