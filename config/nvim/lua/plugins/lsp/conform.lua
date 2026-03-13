local conform_status, conform = pcall(require, "conform")
if not conform_status then
  return
end

local function available_formatters(bufnr, formatter_names)
  local ready = {}

  for _, formatter_name in ipairs(formatter_names) do
    if conform.get_formatter_info(formatter_name, bufnr).available then
      table.insert(ready, formatter_name)
    end
  end

  return ready
end

conform.setup({
  formatters_by_ft = {
    c = function(bufnr)
      return available_formatters(bufnr, { "clang_format" })
    end,
    cpp = function(bufnr)
      return available_formatters(bufnr, { "clang_format" })
    end,
    go = function(bufnr)
      return available_formatters(bufnr, { "gofumpt" })
    end,
    lua = function(bufnr)
      return available_formatters(bufnr, { "stylua" })
    end,
    python = function(bufnr)
      if conform.get_formatter_info("ruff_format", bufnr).available then
        return { "ruff_format" }
      end

      return available_formatters(bufnr, { "black" })
    end,
    sh = function(bufnr)
      return available_formatters(bufnr, { "shfmt" })
    end,
    bash = function(bufnr)
      return available_formatters(bufnr, { "shfmt" })
    end,
    zsh = function(bufnr)
      return available_formatters(bufnr, { "shfmt" })
    end,
  },
  format_on_save = {
    lsp_format = "fallback",
    timeout_ms = 500,
  },
  notify_no_formatters = false,
})

vim.keymap.set({ "n", "v" }, "<leader>cf", function()
  conform.format({
    async = true,
    lsp_format = "fallback",
  })
end, { desc = "Format Buffer" })
