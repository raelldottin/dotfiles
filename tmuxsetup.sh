#!/bin/bash

echo "Setting up tmux configuration file."

case "$OSTYPE" in
  linux-gnu)
    TMUX_CONF="linux-gnu_tmux.conf"
    ;;
  darwin*)
    TMUX_CONF="darwin_tmux.conf"
    ;;
  *)
    echo "Error: Unable to determine operating system"
    exit 1
    ;;
esac

TMUX_CONF_PATH="$HOME/.tmux.conf"

if [[ ! -f "$TMUX_CONF_PATH" ]]; then
  ln -fn "$TMUX_CONF" "$TMUX_CONF_PATH"
  echo "$TMUX_CONF_PATH linked to $TMUX_CONF"
else
  echo "$TMUX_CONF_PATH is already configured."
fi

TMUX_PLUGINS_DIR="$HOME/.tmux/plugins"
TPM_DIR="$TMUX_PLUGINS_DIR/tpm"

if [[ ! -d "$TMUX_PLUGINS_DIR" ]]; then
  mkdir -p "$TMUX_PLUGINS_DIR"
  echo "Created $TMUX_PLUGINS_DIR directory."
else
  echo "$TMUX_PLUGINS_DIR already exists."
fi

if [[ ! -d "$TPM_DIR" ]]; then
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  echo "Tmux Plugin Manager (TPM) installed."
  echo "Please use prefix + I in a tmux session to install pending plugins."
else
  echo "$TPM_DIR already exists. Skipping TPM installation."
fi

echo "Tmux configuration complete."
