-- import lualine plugin safely
local status, lualine = pcall(require, "lualine")
if not status then
  return
end

-- get lualine moonfly theme
local theme_status, lualine_moonfly = pcall(require, "lualine.themes.moonfly")
if not theme_status then
  lualine_moonfly = "auto"
end

-- configure lualine with modified theme
lualine.setup({
  options = {
    theme = lualine_moonfly,
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch", "diff", "diagnostics" },
    lualine_c = { "filename" },
    lualine_x = { "location" },
    lualine_y = { "encoding", "fileformat", "filetype" },
    lualine_z = { "progress" },
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { "filename" },
    lualine_x = { "location" },
    lualine_y = {},
    lualine_z = {},
  },
})
