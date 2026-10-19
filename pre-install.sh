#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ "${DOTFILES_SKIP_HOMEBREW_SETUP:-0}" == "1" ]]; then
  echo "Skipping optional dependency installation."
  exit 0
fi
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is missing. Use your company's approved provisioning method, then retry." >&2
  exit 1
fi
HOMEBREW_NO_AUTO_UPDATE=1 brew bundle install --no-upgrade --file="$SCRIPT_DIR/Brewfile"
