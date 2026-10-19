#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/dotfiles.sh"
REPO_ROOT="$(dotfiles_repo_root)"

# Validate identity and the work boundary before changing shell files.
"$(dotfiles_python)" "$REPO_ROOT/workstation.py" install
while IFS=$'\t' read -r source_path target_path category; do
  case "$category" in
    zsh|atuin|git) dotfiles_link_file "$source_path" "$target_path" ;;
    *) ;;
  esac
done < <(dotfiles_each_managed_file "$REPO_ROOT")
echo "Work shell installed. Optional tools are installed with make dependencies."
