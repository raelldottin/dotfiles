return {
  cmd = "zsh",
  stdin = false,
  args = { "-n" },
  stream = "stderr",
  ignore_exitcode = true,
  parser = function(output)
    local diagnostics = {}
    for line in output:gmatch("[^\r\n]+") do
      local number, message = line:match("^.-:(%d+):%s*(.*)$")
      if number then
        table.insert(diagnostics, {
          lnum = tonumber(number) - 1,
          col = 0,
          message = message,
          severity = vim.diagnostic.severity.ERROR,
          source = "zsh -n",
        })
      end
    end
    return diagnostics
  end,
}
