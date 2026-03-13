#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/dotfiles.sh"

REPO_ROOT="$(dotfiles_repo_root)"

echo "Uninstalling configuration files:"

while IFS= read -r repo_file; do
  dotfiles_remove_if_managed "$repo_file" "$(dotfiles_target_for_repo_file "$REPO_ROOT" "$repo_file")"
done < <(dotfiles_each_nvim_file "$REPO_ROOT")

dotfiles_remove_if_managed "$REPO_ROOT/zshrc" "$HOME/.zshrc"
dotfiles_remove_if_managed "$REPO_ROOT/pylintrc" "$HOME/.pylintrc"

case "${OSTYPE:-}" in
  linux-gnu*)
    dotfiles_remove_if_managed "$REPO_ROOT/linux-gnu_tmux.conf" "$HOME/.tmux.conf"
    ;;
  darwin*)
    dotfiles_remove_if_managed "$REPO_ROOT/darwin_tmux.conf" "$HOME/.tmux.conf"
    ;;
esac

dotfiles_prune_empty_dirs "$HOME/.config/nvim/lua/plugins/lsp"
dotfiles_prune_empty_dirs "$HOME/.config/nvim/lua/plugins"
dotfiles_prune_empty_dirs "$HOME/.config/nvim/lua/core"
dotfiles_prune_empty_dirs "$HOME/.config/nvim/lua"
dotfiles_prune_empty_dirs "$HOME/.config/nvim"

if [[ -d "$HOME/.local/nvim" ]]; then
  echo "If you encounter issues, please delete $HOME/.local/nvim"
fi

echo "Uninstallation complete."
