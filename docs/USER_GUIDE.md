# User Guide

## Overview

This repo manages four kinds of files through symlinks:

- `~/.zshrc`
- `~/.tmux.conf`
- `~/.config/nvim/**`
- `~/.pylintrc`

The install scripts never copy the tracked files into your home directory. They link back to the repo so updates stay centralized and `make verify-install` can confirm the live install still matches source control.

## Prerequisites

- `bash`
- `git`
- `make`
- `python3`
- Optional: `brew` if you want to use `make dependencies`

## Installation

Install optional workstation dependencies:

```bash
make dependencies
```

Enable the shared Git hooks:

```bash
make hooks
```

Install the managed dotfiles into your current `HOME`:

```bash
make install
```

Verify the installed files:

```bash
make verify-install
```

## Managed Neovim Configuration

All Neovim config lives under `config/nvim` in this repository and is installed into `~/.config/nvim`.

- `init.lua` boots the plugin layer and core settings.
- `lua/core` contains editor defaults such as options, keymaps, and colors.
- `lua/plugins` contains plugin registrations and plugin-specific configuration.
- `lua/plugins/lsp` contains language-server and formatter wiring.

See [docs/NVIM.md](NVIM.md) for the module layout, plugin responsibilities, and update workflow.

## Safe Automation Flags

These environment variables are useful for CI and local dry-run style testing:

- `DOTFILES_SKIP_HOMEBREW_SETUP=1` skips Homebrew installation in `pre-install.sh`.
- `DOTFILES_GIT_USER_NAME` and `DOTFILES_GIT_USER_EMAIL` opt into Git identity configuration.
- `DOTFILES_SKIP_OH_MY_ZSH_INSTALL=1` skips downloading Oh My Zsh and plugin repositories.
- `DOTFILES_SKIP_TMUX_PLUGIN_INSTALL=1` skips cloning the tmux plugin manager.

## Day-to-Day Operations

Reinstall links after pulling updates:

```bash
make install
make verify-install
```

Run the full local quality gate before pushing:

```bash
make verify
```

## Updating

Pull the latest repo changes, then rerun:

```bash
make install
make verify-install
```

## Hooks

The repository hook path lives in `.githooks`.

- `pre-commit` regenerates `README.md` from `README.template`.
- `pre-commit` records Homebrew and global npm snapshots only when those tools are installed.
- `post-commit` refreshes the Git-backed version metadata used in the generated README.

## Uninstalling

Remove all files managed by this repo:

```bash
make clean
```

## Troubleshooting

- If `make verify-install` fails, rerun `make install` and verify the reported file path still points into this repo.
- If tmux plugins are missing, rerun `make tmux` without `DOTFILES_SKIP_TMUX_PLUGIN_INSTALL=1`.
- If Oh My Zsh or its plugins are missing, rerun `make zsh` without `DOTFILES_SKIP_OH_MY_ZSH_INSTALL=1`.
- If `make hooks` was never run, generated files such as `README.md` will not stay in sync automatically.
- If Neovim still behaves unexpectedly after uninstalling, remove `~/.local/nvim`.
