#!/usr/bin/env bash
# Runs inside a disposable VM: install Nix, then activate the personal
# nix-darwin `macbook` system as the flake's user, following docs/NIX.md.
#
#   test-personal.sh BUNDLE NIXPKGS_REV USER
#
# USER is the `username` fixed in flake.nix.
# Runs as the image's admin account, creates the flake's personal user,
# and re-runs itself as that user for the activation steps.

# Commands passed to login_shell expand in the guest's login shell.
# shellcheck disable=SC2016

# shellcheck source=vm/guest/common.sh
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"

as_user() {
  local bundle="$1"
  local nixpkgs_rev="$2"
  local checkout="$HOME/dotfiles"
  local tools="/etc/profiles/per-user/$USER/bin"

  cd /
  load_nix
  step "Cloning the tested commit to $checkout as $USER"
  clone_bundle "$bundle" "$checkout" "$nixpkgs_rev"
  cd "$checkout"

  step "Checking the flake (docs/NIX.md)"
  run nix "${NIX_FLAGS[@]}" flake check --no-write-lock-file

  step "First nix-darwin activation (docs/NIX.md)"
  run sudo "$(command -v nix)" "${NIX_FLAGS[@]}" run nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
    switch --flake .#macbook --no-write-lock-file

  step "Second activation with the installed darwin-rebuild"
  run sudo /run/current-system/sw/bin/darwin-rebuild switch --flake .#macbook --no-write-lock-file

  step "Fresh login shell, tmux, and Neovim"
  login_shell 'for tool in zsh tmux nvim atuin python3 brew; do printf "%s -> %s\n" "$tool" "$(command -v "$tool")"; done'
  login_shell '[[ "$(command -v nvim)" == /etc/profiles/per-user/* ]]' ||
    fail "nvim does not come from the Home Manager profile"
  login_shell 'tmux -L dotfiles-vm new-session -d "sleep 30" && tmux -L dotfiles-vm has-session && tmux -L dotfiles-vm kill-server'
  login_shell 'nvim --headless "+lua io.stdout:write(vim.version().major .. \".\" .. vim.version().minor .. \"\\n\")" +qa'
  [[ -d "$HOME/.config/nvim" ]] || fail "$HOME/.config/nvim was not installed"

  step "Homebrew casks from nix/darwin.nix"
  login_shell 'brew list --cask'

  step "Pinned editor/history probes with the activated tools"
  login_shell "cd $(printf '%q' "$checkout") && python3 tests/check_pinned_tools.py $(printf '%q' "$tools")"

  step "Personal profile test passed"
}

main() {
  local bundle="$1"
  local nixpkgs_rev="$2"
  local user="$3"
  local password

  [[ "$user" =~ ^[a-z_][a-z0-9_-]*$ ]] || fail "invalid personal username: $user"

  install_nix

  if ! id "$user" >/dev/null 2>&1; then
    step "Creating the personal user $user"
    # A throwaway password: the account is only reached through sudo here.
    password="$(openssl rand -base64 24)"
    sudo sysadminctl -addUser "$user" -fullName "Dotfiles VM Personal" \
      -password "$password" -home "/Users/$user" -shell /bin/zsh -admin
    sudo createhomedir -c -u "$user" >/dev/null
  fi
  # Homebrew casks that install packages call sudo during activation.
  printf '%s ALL=(ALL) NOPASSWD: ALL\n' "$user" |
    sudo EDITOR=tee visudo -f "/etc/sudoers.d/$user-nopasswd" >/dev/null

  sudo -H -u "$user" /bin/bash "${BASH_SOURCE[0]}" --as-user "$bundle" "$nixpkgs_rev"
}

if [[ "${1:-}" == "--as-user" ]]; then
  shift
  as_user "$@"
else
  main "$@"
fi
