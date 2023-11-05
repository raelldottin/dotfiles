-- import null-ls plugin safely
local setup, null_ls = pcall(require, "null-ls")
if not setup then
	return
end

-- code action sources
-- local code_actions = null_ls.builtins.diagnostics

-- diagnostic sources
local diagnostics = null_ls.builtins.diagnostics -- to setup linters

--  formatting sources
local formatting = null_ls.builtins.formatting -- to setup formatters

-- hover sources
--local hover = null_ls.builtins.hover

-- completion sources
--local completion = null_ls.builtins.completion

-- to setup format on save
local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

-- configure null_ls
null_ls.setup({
	-- setup formatters & linters
	sources = {
		--  to disable file types use
		--  "formatting.prettier.with({disabled_filetypes: {}})" (see null-ls docs)
		diagnostics.cpplint,
		formatting.clang_format,
		diagnostics.hadolint,
		diagnostics.gitlint,
		formatting.gofumpt,
		diagnostics.alex,
		formatting.black,
		diagnostics.shellcheck,
		diagnostics.pylint,
		formatting.shfmt,
		formatting.stylua, -- lua formatter
	},
	-- configure format on save
	on_attach = function(current_client, bufnr)
		if current_client.supports_method("textDocument/formatting") then
			vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
			vim.api.nvim_create_autocmd("BufWritePre", {
				group = augroup,
				buffer = bufnr,
				callback = function()
					vim.lsp.buf.format({
						filter = function(client)
							--  only use null-ls for formatting instead of lsp server
							return client.name == "null-ls"
						end,
						bufnr = bufnr,
					})
				end,
			})
		end
	end,
})
