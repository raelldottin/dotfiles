local mason_status, mason = pcall(require, "mason")
if not mason_status then
  return
end

-- import mason-lspconfig plugin safely
local mason_lspconfig_status, mason_lspconfig = pcall(require, "mason-lspconfig")
if not mason_lspconfig_status then
  return
end

-- import mason-null-ls plugin safely
local mason_null_ls_status, mason_null_ls = pcall(require, "mason-null-ls")
if not mason_null_ls_status then
  return
end

-- enable mason
mason.setup({
  ui = {
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗",
    },
  },
})

mason_lspconfig.setup({
  -- list of servers for mason to install
  ensure_installed = {
    "bashls", -- bash language server
    "clangd",
    "dockerls",
    "golangci_lint_ls",
    "jsonls",
    "lua_ls",
    "prosemd_lsp",
    "marksman",
    "terraformls",
    "tflint",
    "ruff_lsp",
  },
  -- auto-install configured servers (with lspconfig)
  automatic_installation = true, -- not the same as ensure_installed
})

mason_null_ls.setup({
  -- list of formatters & linters for mason to install
  ensure_installed = {
    "cpplint",
    "clang_format",
    "hadolint",
    "gitlint",
    "gofumpt",
    "stylua",
    "alex",
    "ruff",
    "shellcheck",
    "shfmt",
    "stylua", -- lua formatter
  },
  -- auto-install configured formatters & linters (with null-ls)
  automatic_setup = true,
})
