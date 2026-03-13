#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/dotfiles.sh"

REPO_ROOT="$(dotfiles_repo_root)"
CONFIG_DIR="$HOME/.config"

echo "Setting up Neovim configuration files."
mkdir -p "$CONFIG_DIR"

while IFS= read -r repo_file; do
  dotfiles_link_file "$repo_file" "$(dotfiles_target_for_repo_file "$REPO_ROOT" "$repo_file")"
done < <(dotfiles_each_nvim_file "$REPO_ROOT")

dotfiles_link_file "$REPO_ROOT/pylintrc" "$HOME/.pylintrc"

echo "Setup complete."
