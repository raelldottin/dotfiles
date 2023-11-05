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

-- set leader key to space
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("lazy").setup({
	"nvim-lua/plenary.nvim", -- lua functions for many other plugins

	"bluz71/vim-nightfly-guicolors", -- preferred colorscheme

	"christoomey/vim-tmux-navigator", -- tmux & split window navigation

	"szw/vim-maximizer", -- maximizes and restores current window

	-- essential plugins
	"tpope/vim-surround", -- add, delete, change surroundings (it's awesome,
	"inkarkat/vim-ReplaceWithRegister", -- replace with register contents using motion (gr + motion,

	-- commenting with gc
	--	"numToStr/Comment.nvim",

	-- file explorer
	"nvim-tree/nvim-tree.lua",

	-- statusline
	"nvim-lualine/lualine.nvim",
	{
		"kdheepak/tabline.nvim",
		config = function()
			vim.cmd([[
        set guioptions-=e " Use showtabline in gui vim
        set sessionoptions+=tabpages,globals " store tabpages and globals in session
      ]])
		end,
		dependencies = { "nvim-lualine/lualine.nvim", "kyazdani42/nvim-web-devicons" },
	},

	-- fuzzy finding w/ telescope
	{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" }, -- dependency for better sorting performance
	{ "nvim-telescope/telescope.nvim", branch = "0.1.x" }, -- fuzzy finder
	"nvim-lua/popup.nvim",

	-- autocompletion
	"hrsh7th/nvim-cmp", -- completion plugin
	"hrsh7th/cmp-buffer", -- source for text in buffer
	"hrsh7th/cmp-path", -- source for file system paths

	-- snippets
	"L3MON4D3/LuaSnip", -- snippet engine
	"saadparwaiz1/cmp_luasnip", -- for autocompletion
	--"rafamadriz/friendly-snippets", -- useful snippets

	-- managing & installing lsp servers, linters & formatters
	"williamboman/mason.nvim", -- in charge of managing lsp servers, linters & formatters
	"williamboman/mason-lspconfig.nvim", -- bridges gap b/w mason & lspconfig

	-- configuring lsp servers
	"neovim/nvim-lspconfig", -- easily configure language servers
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

	-- formatting & linting
	"jose-elias-alvarez/null-ls.nvim", -- configure formatters & linters
	"jayp0521/mason-null-ls.nvim", -- bridges gap b/w mason & null-ls

	-- dap
	"mfussenegger/nvim-dap",
	"mfussenegger/nvim-dap-python",
	"rcarriga/nvim-dap-ui",
	"theHamsta/nvim-dap-virtual-text",
	"nvim-telescope/telescope-dap.nvim",

	-- treesitter configuration
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		dependencies = {
			"windwp/nvim-autopairs",
			--		"windwp/nvim-ts-autotag",
		},
	},
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {}, -- this is equalent to setup({}) function
	},
	"nvim-treesitter/nvim-treesitter-context",

	-- git integration
	"lewis6991/gitsigns.nvim", -- show line modifications on left hand side

	-- wakatime
	"wakatime/vim-wakatime",

	-- hard time
	--{
	--	"m4xshen/hardtime.nvim",
	--	dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
	--	opts = {}
	--},
	-- "madox2/vim-ai",
})
