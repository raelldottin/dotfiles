# Neovim Guide

## Layout

The Neovim configuration is stored under `config/nvim` and installed into `~/.config/nvim`.

- `init.lua` loads the plugin bootstrap and the core editor modules.
- `lua/core/options.lua` sets editor behavior such as tabs, clipboard, splits, and search defaults.
- `lua/core/keymaps.lua` contains user-facing keybindings.
- `lua/core/colorscheme.lua` applies the preferred theme.
- `lua/plugins/setup.lua` bootstraps `lazy.nvim` and declares the plugin catalog.
- `lua/plugins/*.lua` configures individual plugins.
- `lua/plugins/lsp/*.lua` groups language-server, formatter, and diagnostics configuration.

## Plugin Stack

The current setup is organized around a few responsibilities:

- navigation and project discovery: `nvim-tree`, `telescope`
- editing ergonomics: `vim-sleuth`, `nvim-cmp`, `LuaSnip`
- language tooling: `mason`, `mason-lspconfig`, native `vim.lsp`, `nvim-lspconfig`
- Python workflow: `pyright` for type checking and `ruff` for linting/formatting, with Ruff hover disabled so `K` stays useful
- formatting: `conform.nvim`
- source-control visibility: `gitsigns`
- presentation: `lualine`, `moonfly`

## Operational Notes

- `make install` links the entire tracked Neovim tree into `~/.config/nvim`.
- `make verify-install` checks the installed files against the repository versions.
- `make clean` removes only repo-managed files and leaves unrelated personal files alone.
- `config/nvim/lazy-lock.json` pins plugin revisions so upstream plugin changes do not unexpectedly change editor behavior.
- `telescope-fzf-native.nvim` is treated as an optional speed-up and only builds when both `cmake` and `make` are available.

## Updating The Configuration

1. Edit files under `config/nvim`.
2. Run `make verify` to catch shell, Lua, Python, and test regressions.
3. If you changed plugin structure or keybindings, update this guide and the user-facing README summary.

## Key Safety Principle

The repository treats Neovim as part of the same managed install surface as shell and tmux. Any change under `config/nvim` should keep these guarantees:

- installation remains idempotent
- cleanup removes only repo-managed paths
- verification can prove the installed state matches the repo
