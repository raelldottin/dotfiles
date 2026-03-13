# User Guide

## Overview

This repo manages four kinds of files:

- `~/.zshrc`
- `~/.tmux.conf`
- `~/.config/nvim/**`
- `~/.pylintrc`

The install scripts use symlinks so the files in your home directory continue to point back to the repo.

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

Install the managed dotfiles into your current `HOME`:

```bash
make install
```

Verify the installed files:

```bash
make verify-install
```

## Safe Automation Flags

These environment variables are useful for CI and local dry-run style testing:

- `DOTFILES_SKIP_HOMEBREW_SETUP=1` skips Homebrew installation in `pre-install.sh`.
- `DOTFILES_GIT_USER_NAME` and `DOTFILES_GIT_USER_EMAIL` opt into Git identity configuration.
- `DOTFILES_SKIP_OH_MY_ZSH_INSTALL=1` skips downloading Oh My Zsh and plugin repositories.
- `DOTFILES_SKIP_TMUX_PLUGIN_INSTALL=1` skips cloning the tmux plugin manager.

## Updating

Pull the latest repo changes, then rerun:

```bash
make install
make verify-install
```

## Uninstalling

Remove all files managed by this repo:

```bash
make clean
```

## Troubleshooting

- If `make verify-install` fails, rerun `make install` and verify the reported file path still points into this repo.
- If tmux plugins are missing, rerun `make tmux` without `DOTFILES_SKIP_TMUX_PLUGIN_INSTALL=1`.
- If Oh My Zsh or its plugins are missing, rerun `make zsh` without `DOTFILES_SKIP_OH_MY_ZSH_INSTALL=1`.
- If Neovim still behaves unexpectedly after uninstalling, remove `~/.local/nvim`.

