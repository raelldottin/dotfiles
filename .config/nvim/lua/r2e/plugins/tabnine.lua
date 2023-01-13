-- import tabnine plugin safely
local status, tabnine = pcall(require, "tabnine")
if not status then
  return
end

tabnine.setup({
  disable_auto_comment = true,
  accept_keymap = "<Tab>",
  dismiss_keymap = "<C-]>",
  debounce_ms = 300,
  suggestion_color = { gui = "#808080", cterm = 244 },
  execlude_filetypes = { "TelescopePrompt" },
})
