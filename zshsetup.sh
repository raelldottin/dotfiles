#!/bin/bash

echo "Setting up Zsh configuration file."
ln -fn zshrc "$HOME"/.zshrc

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    download_script() {
        local download_command
        if command -v curl &> /dev/null; then
            download_command="curl -fsSL"
        elif command -v wget &> /dev/null; then
            download_command="wget -O-"
        elif command -v fetch &> /dev/null; then
            download_command="fetch -o -"
        else
            echo "Error: No utility found to perform download."
            exit 1
        fi
        $download_command "$1" | sh
    }

    download_script "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
fi

if command -v git &> /dev/null; then
    clone_repo() {
        local repo_url="$1"
        local target_directory="$2"
        if [[ ! -d "$target_directory" ]]; then
            git clone --depth=1 "$repo_url" "$target_directory"
        fi
    }

    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    clone_repo "https://github.com/romkatv/powerlevel10k.git" "$ZSH_CUSTOM/themes/powerlevel10k"
    clone_repo "https://github.com/zsh-users/zsh-autosuggestions" "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    clone_repo "https://github.com/zdharma-continuum/fast-syntax-highlighting.git" "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"
else
    echo "Error: Please install git."
    exit 1
fi

echo "Zsh configuration complete."
