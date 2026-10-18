#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
if command -v brew >/dev/null 2>&1; then
  brew list >homebrew_installed_app.txt
fi
if command -v npm >/dev/null 2>&1; then
  npm list -g >npm_installed_app.txt
fi
