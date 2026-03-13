#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/dotfiles.sh"

download_script() {
  local script_url="$1"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$script_url" | sh
    return
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -O- "$script_url" | sh
    return
  fi

  if command -v fetch >/dev/null 2>&1; then
    fetch -o - "$script_url" | sh
    return
  fi

  echo "Error: No utility found to perform download."
  exit 1
}

clone_repo() {
  local repo_url="$1"
  local target_directory="$2"

  if [[ ! -d "$target_directory" ]]; then
    git clone --depth=1 "$repo_url" "$target_directory"
  fi
}

REPO_ROOT="$(dotfiles_repo_root)"

echo "Setting up Zsh configuration file."
dotfiles_link_file "$REPO_ROOT/zshrc" "$HOME/.zshrc"

if [[ "${DOTFILES_SKIP_OH_MY_ZSH_INSTALL:-0}" == "1" ]]; then
  echo "Skipping Oh My Zsh bootstrap because DOTFILES_SKIP_OH_MY_ZSH_INSTALL=1."
  echo "Zsh configuration complete."
  exit 0
fi

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  download_script "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
fi

if ! command -v git >/dev/null 2>&1; then
  echo "Error: Please install git."
  exit 1
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

clone_repo "https://github.com/romkatv/powerlevel10k.git" "$ZSH_CUSTOM/themes/powerlevel10k"
clone_repo "https://github.com/zsh-users/zsh-autosuggestions" "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_repo "https://github.com/zdharma-continuum/fast-syntax-highlighting.git" \
  "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"

echo "Zsh configuration complete."
