#!/bin/bash

# Function to check if Homebrew is installed
check_homebrew() {
	if ! command -v brew &>/dev/null; then
		echo "Homebrew not found. Installing Homebrew..."
		/bin/bash ./homebrewsetup.sh
	else
		echo "Homebrew is already installed."
	fi
}

# Function for Git configuration
configure_git() {
	git config --global user.email "raell.dottin@gmail.com"
	git config --global user.name "Raell Dottin"
	echo "Git configuration completed."
}

# Check and install Homebrew
check_homebrew

# Run Homebrew setup script

# Configure Git
configure_git
