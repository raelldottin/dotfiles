#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

check_homebrew() {
  if [[ "${DOTFILES_SKIP_HOMEBREW_SETUP:-0}" == "1" ]]; then
    echo "Skipping Homebrew bootstrap because DOTFILES_SKIP_HOMEBREW_SETUP=1."
    return
  fi

  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found. Installing Homebrew..."
    sudo /bin/bash "$SCRIPT_DIR/homebrewsetup.sh"
  else
    echo "Homebrew is already installed."
  fi
}

configure_git() {
  local git_user_name="${DOTFILES_GIT_USER_NAME:-}"
  local git_user_email="${DOTFILES_GIT_USER_EMAIL:-}"

  if [[ -z "$git_user_name" || -z "$git_user_email" ]]; then
    echo "Skipping Git configuration. Set DOTFILES_GIT_USER_NAME and DOTFILES_GIT_USER_EMAIL to opt in."
    return
  fi

  git config --global user.email "$git_user_email"
  git config --global user.name "$git_user_name"
  echo "Git configuration completed."
}

check_homebrew
configure_git
