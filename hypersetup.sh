#!/bin/bash

if [[ "$OSTYPE" == "linux-gnu" ]]; then
  echo "Hyper is only for macOS"
  exit 0
else
  echo "Setting up Hyper configuration file."
  ln hyper.js "$HOME"/.hyper.js
  echo "Hyper configuration complete."
fi
