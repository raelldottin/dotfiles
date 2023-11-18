--Plugins setup
require("plugins-setup")

--Core configuration
require("core.options")
require("core.keymaps")
require("core.colorscheme")

--Plugins
require("plugins.gitsigns")
require("plugins.lualine")
require("plugins.mason")
require("plugins.nvim-cmp")
require("plugins.nvim-tree")
require("plugins.telescope")
require("plugins.treesitter")

--LSPs
require("plugins.lsp.lspconfig")
require("plugins.lsp.null-ls")
require("plugins.lsp.mason")
