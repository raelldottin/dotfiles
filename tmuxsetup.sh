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
    echo "Unable to determine operating system"
    exit 1
    ;;
esac
if [[ ! -f "$HOME"/.tmux.conf ]]; then
  ln "$TMUX_CONF" "$HOME"/.tmux.conf
fi
if [[ ! -d ~/.tmux/plugins/tpm ]]; then
  mkdir -p ~/.tmux/plugins/tpm
fi
if [[ -d "$HOME"/.tmux/plugins/tpm ]]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

  echo "Please use prefix + I in a tmux session to install pending plugins."
fi
echo "Tmux configuration complete."

