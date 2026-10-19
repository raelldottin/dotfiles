# Neovim guide

The configuration is the LazyVim setup captured from the current Mac on
October 18, 2026. It retains the live Lua configuration, 34-plugin lockfile,
LazyVim metadata, and the status-line date customization. The inactive example
plugin file and the personal plugin caches and sessions are not imported.
The upstream starter license is retained in `config/nvim/LICENSE`.

Both Nix profiles share the captured portable editor preferences. The personal
profile retains its existing `~/.config/nvim` location. The company profile
places files in `~/.config/nvim-work`. The managed Zsh config
exports `NVIM_APPNAME=nvim-work` and work XDG data/cache/state paths. Use
`nvim` from a new work terminal so Neovim uses that namespace. A graphical
launcher must receive equivalent environment settings if used.

The first launch bootstraps lazy.nvim and the configured plugins over the
network. Run `:Lazy restore` to restore `lazy-lock.json` revisions. Periodic
plugin update checking is disabled; choose updates deliberately.

`lua/config/lazy.lua` loads LazyVim and `lua/plugins`. The current active
override adds the date to lualine. Other config modules retain the current
Mac's starter defaults. Keymaps and language support now come from the
captured LazyVim revision, rather than the repo's older standalone plugin set.

The automated offline smoke check compiles the actual Lua modules and evaluates
the lazy.nvim specification and lualine override with a local stub. It does not
download or boot the complete plugin set. First-launch plugin installation,
language servers, and interactive behavior require verification on the company Mac.
