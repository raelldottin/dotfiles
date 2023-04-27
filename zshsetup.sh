#!/bin/bash

echo "Setting up Zsh configuration file."
ln -fn zshrc "$HOME"/.zshrc

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
	if which curl >/dev/null; then
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	elif which wget >/dev/null; then
		sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	elif which fetch >/dev/null; then
		sh -c "$(fetch -o - https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	else
		echo "No utility found to perform download."
	fi
fi

if which git >/dev/null; then
	if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/themes/powerlevel10k ]]; then
		git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/themes/powerlevel10k
	fi
	if [[ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"/plugins/zsh-autosuggestions ]]; then
		git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"/plugins/zsh-autosuggestions
	fi
	if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/fast-syntax-highlighting ]]; then
		git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/fast-syntax-highlighting
	fi
else
	echo "Please install git."
fi

echo "Zsh configuration complete."
