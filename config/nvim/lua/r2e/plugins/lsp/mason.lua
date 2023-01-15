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
    "awk_ls",
    "asm_lsp",
    "bashls",
    "clangd",
    "dockerls",
    "golangci_lint_ls",
    "gopls",
    "jsonls",
    "sumneko_lua",
    "prosemd_lsp",
    "marksman",
    "prosemd_lsp",
    "remark_ls",
    "zk",
    "powershell_es",
    "puppet",
    "pyright",
    "solargraph",
    "sqls",
    "salt_ls",
    "taplo",
    "terraformls",
    "tflint",
    "lemminx",
    "yamlls",
  },
  -- auto-install configured servers (with lspconfig)
  automatic_installation = true, -- not the same as ensure_installed
})

mason_null_ls.setup({
  -- list of formatters & linters for mason to install
  ensure_installed = {
    "cpplint",
    "hadolint",
    "gitlint",
    "gofumpt",
    "goimports",
    "goimports_reviser",
    "golangci_lint_ls",
    "golines",
    "revive",
    "staticcheck",
    "luacheck",
    "stylua",
    "alex",
    "markdownlint",
    "write_good",
    "autopep8",
    "black",
    "shellcheck",
    "shellharden",
    "shfmt",
    "jq",
    "stylua", -- lua formatter
  },
  -- auto-install configured formatters & linters (with null-ls)
  automatic_setup = true,
})