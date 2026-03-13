#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/dotfiles.sh"

pick_tmux_config() {
  case "${OSTYPE:-}" in
    linux-gnu*)
      printf '%s\n' "linux-gnu_tmux.conf"
      ;;
    darwin*)
      printf '%s\n' "darwin_tmux.conf"
      ;;
    *)
      echo "Error: Unable to determine operating system"
      exit 1
      ;;
  esac
}

REPO_ROOT="$(dotfiles_repo_root)"
TMUX_CONF="$(pick_tmux_config)"
TMUX_CONF_PATH="$HOME/.tmux.conf"
TMUX_PLUGINS_DIR="$HOME/.tmux/plugins"
TPM_DIR="$TMUX_PLUGINS_DIR/tpm"

echo "Setting up tmux configuration file."
dotfiles_link_file "$REPO_ROOT/$TMUX_CONF" "$TMUX_CONF_PATH"

if [[ "${DOTFILES_SKIP_TMUX_PLUGIN_INSTALL:-0}" == "1" ]]; then
  echo "Skipping TPM bootstrap because DOTFILES_SKIP_TMUX_PLUGIN_INSTALL=1."
  echo "Tmux configuration complete."
  exit 0
fi

if ! command -v git >/dev/null 2>&1; then
  echo "Error: Please install git."
  exit 1
fi

mkdir -p "$TMUX_PLUGINS_DIR"

if [[ ! -d "$TPM_DIR" ]]; then
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  echo "Tmux Plugin Manager (TPM) installed."
  echo "Please use prefix + I in a tmux session to install pending plugins."
else
  echo "$TPM_DIR already exists. Skipping TPM installation."
fi

echo "Tmux configuration complete."
