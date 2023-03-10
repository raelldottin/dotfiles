-- import lspconfig plugin safely
local lspconfig_status, lspconfig = pcall(require, "lspconfig")
if not lspconfig_status then
	return
end

-- import cmp-nvim-lsp plugin safely
local cmp_nvim_lsp_status, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if not cmp_nvim_lsp_status then
	return
end

-- import typescript plugin safely
local typescript_setup, typescript = pcall(require, "typescript")
if not typescript_setup then
	return
end

local keymap = vim.keymap -- for conciseness

-- enable keybinds only for when lsp server available
local on_attach = function(client, bufnr)
	-- keybind options
	local opts = { noremap = true, silent = true, buffer = bufnr }

	-- set keybinds
	-- keymaps for ALE
	keymap.set("n", "<leader>agd", "<cmd>:ALEGoToDefinition<CR>")
	keymap.set("n", "<leader>agf", "<cmd>:ALEFindReferences<CR>")
	keymap.set("n", "<leader>ak", "<cmd>:ALEFindReferences<CR>")
	keymap.set("n", "<leader>as", "<cmd>:ALESymbolSearch<CR>")

	-- LSP finder - Find the symbol's definition
	-- If there is no definition, it will instead be hidden
	-- When you use an action in finder like "open vsplit",
	-- you can use <C-t> to jump back
	keymap.set("n", "gh", "<cmd>Lspsaga lsp_finder<CR>")

	-- Code action
	keymap.set({ "n", "v" }, "<leader>ca", "<cmd>Lspsaga code_action<CR>")

	-- Rename all occurrences of the hovered word for the entire file
	keymap.set("n", "gr", "<cmd>Lspsaga rename<CR>")

	-- Rename all occurrences of the hovered word for the selected files
	keymap.set("n", "gr", "<cmd>Lspsaga rename ++project<CR>")

	-- Peek definition
	-- You can edit the file containing the definition in the floating window
	-- It also supports open/vsplit/etc operations, do refer to "definition_action_keys"
	-- It also supports tagstack
	-- Use <C-t> to jump back
	keymap.set("n", "gD", "<cmd>Lspsaga peek_definition<CR>")

	-- Go to definition
	keymap.set("n", "gd", "<cmd>Lspsaga goto_definition<CR>")

	-- Show line diagnostics
	-- You can pass argument ++unfocus to
	-- unfocus the show_line_diagnostics floating window
	keymap.set("n", "<leader>sl", "<cmd>Lspsaga show_line_diagnostics<CR>")

	-- Show cursor diagnostics
	-- Like show_line_diagnostics, it supports passing the ++unfocus argument
	keymap.set("n", "<leader>sc", "<cmd>Lspsaga show_cursor_diagnostics<CR>")

	-- Show buffer diagnostics
	keymap.set("n", "<leader>sb", "<cmd>Lspsaga show_buf_diagnostics<CR>")

	-- Diagnostic jump
	-- You can use <C-o> to jump back to your previous location
	keymap.set("n", "[e", "<cmd>Lspsaga diagnostic_jump_prev<CR>")
	keymap.set("n", "]e", "<cmd>Lspsaga diagnostic_jump_next<CR>")

	-- Diagnostic jump with filters such as only jumping to an error
	keymap.set("n", "[E", function()
		require("lspsaga.diagnostic"):goto_prev({ severity = vim.diagnostic.severity.ERROR })
	end)
	keymap.set("n", "]E", function()
		require("lspsaga.diagnostic"):goto_next({ severity = vim.diagnostic.severity.ERROR })
	end)

	-- Toggle outline
	keymap.set("n", "<leader>o", "<cmd>Lspsaga outline<CR>")

	-- Hover Doc
	-- If there is no hover doc,
	-- there will be a notification stating that
	-- there is no information available.
	-- To disable it just use ":Lspsaga hover_doc ++quiet"
	-- Pressing the key twice will enter the hover window
	keymap.set("n", "K", "<cmd>Lspsaga hover_doc<CR>")

	-- If you want to keep the hover window in the top right hand corner,
	-- you can pass the ++keep argument
	-- Note that if you use hover with ++keep, pressing this key again will
	-- close the hover window. If you want to jump to the hover window
	-- you should use the wincmd command "<C-w>w"
	keymap.set("n", "K", "<cmd>Lspsaga hover_doc ++keep<CR>")

	-- Call hierarchy
	keymap.set("n", "<Leader>ci", "<cmd>Lspsaga incoming_calls<CR>")
	keymap.set("n", "<Leader>co", "<cmd>Lspsaga outgoing_calls<CR>")

	-- Floating terminal
	keymap.set({ "n", "t" }, "<A-d>", "<cmd>Lspsaga term_toggle<CR>")

	-- typescript specific keymaps (e.g. rename file and update imports)
	if client.name == "tsserver" then
		keymap.set("n", "<leader>rf", ":TypescriptRenameFile<CR>") -- rename file and update imports
		keymap.set("n", "<leader>oi", ":TypescriptOrganizeImports<CR>") -- organize imports (not in youtube nvim video)
		keymap.set("n", "<leader>ru", ":TypescriptRemoveUnused<CR>") -- remove unused variables (not in youtube nvim video)
	end
end

-- used to enable autocompletion (assign to every lsp server config)
local capabilities = cmp_nvim_lsp.default_capabilities()

-- Change the Diagnostic symbols in the sign column (gutter)
-- (not in youtube nvim video)
local signs = { Error = "??? ", Warn = "??? ", Hint = "??? ", Info = "??? " }
for type, icon in pairs(signs) do
	local hl = "DiagnosticSign" .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

-- configure bashls
lspconfig["bashls"].setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

-- configure clangd
lspconfig["clangd"].setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

-- configure dockerls
lspconfig["dockerls"].setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

-- configure golangci_linit_ls
lspconfig["golangci_lint_ls"].setup({
	capabilities = capabilities,
	on_attach = on_attach,
	filetypes = { "go" },
})

-- configure gopls
lspconfig["gopls"].setup({
	capabilities = capabilities,
	on_attach = on_attach,
	filetypes = { "go" },
})

-- configure jsonls
lspconfig["jsonls"].setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

-- configure lua server (with special settings)
lspconfig["sumneko_lua"].setup({
	capabilities = capabilities,
	on_attach = on_attach,
	settings = { -- custom settings for lua
		Lua = {
			-- make the language server recognize "vim" global
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				-- make language server aware of runtime files
				library = {
					[vim.fn.expand("$VIMRUNTIME/lua")] = true,
					[vim.fn.stdpath("config") .. "/lua"] = true,
				},
			},
		},
	},
})

-- configure prosemd_lsp
lspconfig["prosemd_lsp"].setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

-- configure pyright
lspconfig["pyright"].setup({
	on_attach = on_attach,
	settings = {
		pyright = { autoImportCompletion = true },
		python = {
			analysis = {
				autoSearchPaths = true,
				diagnosticMode = "workspace",
				venvpath = "venv",
				useLibraryCodeForTypes = true,
			},
		},
	},
})

-- configure marksman
lspconfig["marksman"].setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

-- configure powershell_es
lspconfig["powershell_es"].setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

-- configure terraformls
lspconfig["terraformls"].setup({
	capabilities = capabilities,
	on_attach = on_attach,
})

-- configure powershell_es
lspconfig["tflint"].setup({
	capabilities = capabilities,
	on_attach = on_attach,
})
