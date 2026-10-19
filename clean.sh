#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/dotfiles.sh"

REPO_ROOT="$(dotfiles_repo_root)"

"$(dotfiles_python)" "$REPO_ROOT/workstation.py" clean

echo "Uninstalling configuration files:"

while IFS=$'\t' read -r source_path target_path _; do
  dotfiles_remove_if_managed "$source_path" "$target_path"
done < <(dotfiles_each_managed_file "$REPO_ROOT")

dotfiles_prune_empty_dirs "$HOME/.config/nvim-work/lua/config"
dotfiles_prune_empty_dirs "$HOME/.config/nvim-work/lua/plugins"
dotfiles_prune_empty_dirs "$HOME/.config/nvim-work/lua"
dotfiles_prune_empty_dirs "$HOME/.config/nvim-work"

if [[ -d "$HOME/.local/nvim" ]]; then
  echo "If you encounter issues, please delete $HOME/.local/nvim"
fi

echo "Uninstallation complete."
