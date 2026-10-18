#!/usr/bin/env bash
# Compatibility entry point; provisioning Homebrew is owned by the company.
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec bash "$SCRIPT_DIR/pre-install.sh"
