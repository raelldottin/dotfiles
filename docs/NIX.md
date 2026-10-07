# Nix migration

This repository is moving from custom shell/Python installers to a declarative
workstation model built from three layers:

1. **Home Manager** owns user packages and dotfiles on macOS and Linux.
2. **nix-darwin** owns macOS system integration.
3. **nix-homebrew** adopts the existing Apple Silicon Homebrew installation and
   keeps Homebrew available for GUI casks.

The legacy installer remains in the repository during the first migration pass
so the existing workstation can be restored without reconstructing the old
setup.

## Why Nix instead of chezmoi

Chezmoi would be a cleaner replacement for the current symlink/install scripts,
but this repository also tracks package inventories and platform-specific
workstation setup. Nix can make those part of the same evaluated configuration,
pin package inputs in `flake.lock`, and provide rollback generations.

Homebrew is intentionally retained for GUI casks. Command-line and development
packages move to nixpkgs over time.

## macOS bootstrap

The macOS output is named `macbook` and targets Apple Silicon.

Install a Nix implementation first. nix-darwin currently recommends an
installer with a reliable uninstaller; Lix is compatible and the configuration
selects `pkgs.lix` after activation.

From a clone of this repository:

```bash
nix flake check
sudo nix run nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
  switch --flake .#macbook
```

Subsequent updates:

```bash
nix flake update
sudo darwin-rebuild switch --flake .#macbook
```

During the first activation Home Manager backs up conflicting managed files with
the `.hm-backup` suffix.

## Linux bootstrap

Two standalone Home Manager outputs are provided.

x86_64:

```bash
nix run home-manager/release-26.05 -- \
  switch -b hm-backup --flake .#linux-x86_64
```

aarch64:

```bash
nix run home-manager/release-26.05 -- \
  switch -b hm-backup --flake .#linux-aarch64
```

## Ownership during migration

| Area | New owner | Legacy source kept for rollback |
| --- | --- | --- |
| zsh + Oh My Zsh + Powerlevel10k | Home Manager | `zshrc`, `zshsetup.sh` |
| tmux + plugins | Home Manager | `*_tmux.conf`, `tmuxsetup.sh` |
| Neovim files | Home Manager | `config/nvim/**`, `nvimsetup.sh` |
| Python lint config | Home Manager | `pylintrc` |
| CLI/dev packages | nixpkgs/Home Manager | `homebrew_installed_app.txt` |
| GUI apps | nix-darwin Homebrew module | existing Homebrew install |
| Homebrew installation | nix-homebrew | `homebrewsetup.sh` |

The first pass deliberately uses `homebrew.onActivation.cleanup = "none"`.
That means Homebrew packages not yet represented in Nix are preserved. Once the
Nix configuration has been exercised on the workstation, the remaining package
inventory can be classified and the legacy installer can be removed.

## Validation

CI evaluates both the Linux Home Manager and Apple Silicon nix-darwin outputs.
The existing repository checks remain in place while branch protection still
requires their status contexts.

Useful local commands:

```bash
nix flake check
nix fmt
nix flake update
```

To inspect the exact derivation without activating it:

```bash
nix eval --raw .#darwinConfigurations.macbook.config.system.build.toplevel.drvPath
```
