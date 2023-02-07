#!/bin/bash

if [[ "$OSTYPE" == "linux-gnu" ]]; then
  echo "Hyper is only for macOS"
  exit 0
else
  echo "Setting up Hyper configuration file."
  brew tap homebrew/cask-fonts
  brew install font-hack-nerd-font
  ln hyper.js "$HOME"/.hyper.js
  echo "Hyper configuration complete."
fi
