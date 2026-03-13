-- import cmp-nvim-lsp plugin safely
local cmp_nvim_lsp_status, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if not cmp_nvim_lsp_status then
  return
end

local capabilities = cmp_nvim_lsp.default_capabilities()

vim.diagnostic.config({
  severity_sort = true,
  underline = true,
  update_in_insert = false,
  virtual_text = false,
})

local diagnostic_keymap_options = { noremap = true, silent = true }
vim.keymap.set("n", "<leader>ld", vim.diagnostic.open_float, diagnostic_keymap_options)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, diagnostic_keymap_options)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, diagnostic_keymap_options)
vim.keymap.set("n", "<leader>lq", vim.diagnostic.setloclist, diagnostic_keymap_options)

-- Change the diagnostic symbols in the sign column (gutter).
local signs = { Error = " ", Warn = " ", Hint = "ﴞ ", Info = " " }
for severity, icon in pairs(signs) do
  local highlight = "DiagnosticSign" .. severity
  vim.fn.sign_define(highlight, { text = icon, texthl = highlight, numhl = "" })
end

local function on_attach(client, bufnr)
  local buffer_options = { noremap = true, silent = true, buffer = bufnr }

  if client.name == "ruff" then
    client.server_capabilities.hoverProvider = false
  end

  vim.keymap.set("n", "gD", vim.lsp.buf.declaration, buffer_options)
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, buffer_options)
  vim.keymap.set("n", "K", vim.lsp.buf.hover, buffer_options)
  vim.keymap.set("n", "gi", vim.lsp.buf.implementation, buffer_options)
  vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, buffer_options)
  vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, buffer_options)
  vim.keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, buffer_options)
  vim.keymap.set("n", "<leader>wl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, buffer_options)
  vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, buffer_options)
  vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, buffer_options)
  vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, buffer_options)
  vim.keymap.set("n", "gr", vim.lsp.buf.references, buffer_options)
end

local function with_defaults(extra_options)
  return vim.tbl_deep_extend("force", {
    capabilities = capabilities,
    on_attach = on_attach,
  }, extra_options or {})
end

local server_names = {
  "bashls",
  "clangd",
  "dockerls",
  "golangci_lint_ls",
  "jsonls",
  "lua_ls",
  "marksman",
  "pyright",
  "ruff",
  "taplo",
  "terraformls",
  "tflint",
  "ts_ls",
  "yamlls",
}

local server_settings = {
  golangci_lint_ls = {
    filetypes = { "go" },
  },
  lua_ls = {
    settings = {
      Lua = {
        runtime = {
          version = "LuaJIT",
        },
        diagnostics = {
          globals = { "vim" },
        },
        workspace = {
          checkThirdParty = false,
          library = vim.api.nvim_get_runtime_file("", true),
        },
      },
    },
  },
  pyright = {
    settings = {
      python = {
        analysis = {
          autoSearchPaths = true,
          diagnosticMode = "openFilesOnly",
          typeCheckingMode = "basic",
          useLibraryCodeForTypes = true,
        },
      },
    },
  },
}

if vim.lsp.config ~= nil and vim.lsp.enable ~= nil then
  for _, server_name in ipairs(server_names) do
    vim.lsp.config(server_name, with_defaults(server_settings[server_name]))
  end

  vim.lsp.enable(server_names)
  return
end

-- Fallback for older Neovim releases.
local lspconfig_status, lspconfig = pcall(require, "lspconfig")
if not lspconfig_status then
  return
end

for _, server_name in ipairs(server_names) do
  local server = lspconfig[server_name]
  if server ~= nil then
    server.setup(with_defaults(server_settings[server_name]))
  end
end
