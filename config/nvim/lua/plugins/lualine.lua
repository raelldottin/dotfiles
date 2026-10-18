return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      table.insert(opts.sections.lualine_z, 1, { "datetime", style = "%a %b %d" })
    end,
  },
}
