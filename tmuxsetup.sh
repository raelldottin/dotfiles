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
	ln -fn "$TMUX_CONF" "$HOME"/.tmux.conf
else
	echo "$HOME/.tmux.conf is already configured."
fi

if [[ ! -d ~/.tmux/plugins ]]; then
	mkdir -p ~/.tmux/plugins
else
	echo "$HOME/.tmux/plugins already exists."
fi

if [[ -d "$HOME"/.tmux/plugins/tpm ]]; then
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins
	echo "Please use prefix + I in a tmux session to install pending plugins."
fi

echo "Tmux configuration complete."
