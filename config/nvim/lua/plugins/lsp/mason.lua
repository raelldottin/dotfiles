local mason_status, mason = pcall(require, "mason")
if not mason_status then
  return
end

-- import mason-lspconfig plugin safely
local mason_lspconfig_status, mason_lspconfig = pcall(require, "mason-lspconfig")
if not mason_lspconfig_status then
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
  -- Install the language servers most aligned with this repo's day-to-day work.
  ensure_installed = {
    "bashls", -- bash language server
    "clangd",
    "dockerls",
    "golangci_lint_ls",
    "jsonls",
    "lua_ls",
    "marksman",
    "pyright",
    "ruff",
    "terraformls",
    "tflint",
    "ts_ls",
    "yamlls",
    "taplo",
  },
  automatic_enable = false,
})
