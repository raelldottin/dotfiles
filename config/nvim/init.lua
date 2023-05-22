--Plugins setup
require("plugins-setup")

--Core configuration
require("core.options")
require("core.keymaps")
require("core.colorscheme")

--Plugins
require("plugins.autopairs")
require("plugins.ts-autotag")
require("plugins.comment")
require("plugins.gitsigns")
require("plugins.lualine")
require("plugins.mason")
require("plugins.nvim-cmp")
require("plugins.nvim-tree")
require("plugins.tabline")
require("plugins.telescope")
require("plugins.treesitter")

--LSPs
require("plugins.lsp.mason")
require("plugins.lsp.lspconfig")
require("plugins.lsp.null-ls")
