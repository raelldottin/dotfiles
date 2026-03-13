#!/usr/bin/env bash

dotfiles_repo_root() {
  local script_dir
  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
  printf '%s\n' "$script_dir"
}

dotfiles_python() {
  printf '%s\n' "${PYTHON:-python3}"
}

dotfiles_link_file() {
  local source_path="$1"
  local target_path="$2"

  mkdir -p "$(dirname "$target_path")"
  ln -sfn "$source_path" "$target_path"
  printf 'Linked %s -> %s\n' "$target_path" "$source_path"
}

dotfiles_each_nvim_file() {
  local repo_root="$1"

  "$(dotfiles_python)" "$repo_root/dotfiles_manifest.py" nvim-files --repo-root "$repo_root"
}

dotfiles_each_managed_file() {
  local repo_root="$1"

  "$(dotfiles_python)" "$repo_root/dotfiles_manifest.py" managed-files \
    --repo-root "$repo_root" \
    --home "${HOME:?HOME must be set}" \
    --ostype "${OSTYPE:-}"
}

dotfiles_tmux_source() {
  local repo_root="$1"

  while IFS=$'\t' read -r source_path _ category; do
    if [[ "$category" == "tmux" ]]; then
      printf '%s\n' "$source_path"
      return 0
    fi
  done < <(dotfiles_each_managed_file "$repo_root")

  echo "Error: Unable to determine tmux configuration for OSTYPE='${OSTYPE:-}'." >&2
  return 1
}

dotfiles_target_for_repo_file() {
  local repo_root="$1"
  local repo_file="$2"
  local relative_path="${repo_file#"$repo_root/config/nvim/"}"

  printf '%s/.config/nvim/%s\n' "${HOME:?HOME must be set}" "$relative_path"
}

dotfiles_remove_if_managed() {
  local source_path="$1"
  local target_path="$2"

  if [[ -L "$target_path" ]]; then
    local resolved_target
    resolved_target="$(python3 - <<'PY' "$target_path"
from pathlib import Path
import sys

print(Path(sys.argv[1]).resolve())
PY
)"
    if [[ "$resolved_target" == "$source_path" ]]; then
      rm -f "$target_path"
      printf 'Removed %s\n' "$target_path"
      return
    fi
  fi

  if [[ -f "$target_path" ]] && cmp -s "$source_path" "$target_path"; then
    rm -f "$target_path"
    printf 'Removed %s\n' "$target_path"
  fi
}

dotfiles_prune_empty_dirs() {
  local root_path="$1"

  while [[ "$root_path" != "${HOME}" && -d "$root_path" ]]; do
    if find "$root_path" -mindepth 1 -print -quit | grep -q .; then
      break
    fi

    rmdir "$root_path"
    root_path="$(dirname "$root_path")"
  done
}
