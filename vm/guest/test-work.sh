#!/usr/bin/env bash
# Runs inside a disposable VM: install Nix, then activate the work Home
# Manager profile with a test identity, following docs/WORK_MAC.md.
#
#   test-work.sh BUNDLE NIXPKGS_REV

# Commands passed to login_shell expand in the guest's login shell.
# shellcheck disable=SC2016

# shellcheck source=vm/guest/common.sh
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# Placeholder identity; example.invalid can never receive mail.
TEST_NAME="Dotfiles VM Test"
TEST_EMAIL="dotfiles-vm-test@example.invalid"

activate_work_profile() {
  local work_system

  export DOTFILES_WORK_GIT_NAME="$TEST_NAME"
  export DOTFILES_WORK_GIT_EMAIL="$TEST_EMAIL"
  DOTFILES_WORK_USER="$(id -un)"
  export DOTFILES_WORK_USER
  export DOTFILES_WORK_HOME="$HOME"
  work_system="$(nix "${NIX_FLAGS[@]}" eval --impure --raw --expr builtins.currentSystem)"
  run nix "${NIX_FLAGS[@]}" run --no-write-lock-file .#work-home-manager -- switch \
    --flake ".#work-${work_system}" --impure -b hm-backup
  unset DOTFILES_WORK_GIT_NAME DOTFILES_WORK_GIT_EMAIL DOTFILES_WORK_USER DOTFILES_WORK_HOME
}

main() {
  local bundle="$1"
  local nixpkgs_rev="$2"
  local checkout="$HOME/Work/dotfiles"
  local email

  install_nix

  step "Cloning the tested commit to $checkout"
  mkdir -p "$HOME/Work"
  clone_bundle "$bundle" "$checkout" "$nixpkgs_rev"
  cd "$checkout"

  step "Activation without the account settings must be refused"
  if nix "${NIX_FLAGS[@]}" run --no-write-lock-file .#work-home-manager -- switch \
    --flake ".#work-$(nix "${NIX_FLAGS[@]}" eval --impure --raw --expr builtins.currentSystem)" \
    --impure -b hm-backup >/tmp/dotfiles-vm/unconfigured.log 2>&1; then
    fail "activation succeeded without DOTFILES_WORK_* settings"
  fi
  tail -n 5 /tmp/dotfiles-vm/unconfigured.log
  # Fail for the intended reason: Home Manager's account check or the
  # profile's own preflight, not an unrelated build or fetch error.
  grep -Eq 'but we expect "work-profile-unconfigured"|Set DOTFILES_WORK_USER and DOTFILES_WORK_HOME' \
    /tmp/dotfiles-vm/unconfigured.log || fail "activation failed for an unexpected reason"

  step "First work activation (docs/WORK_MAC.md)"
  activate_work_profile
  step "Second work activation"
  activate_work_profile

  step "Fresh login shell checks"
  login_shell 'dotfiles-work verify'
  login_shell '[[ "$NVIM_APPNAME" == nvim-work ]]' || fail "NVIM_APPNAME is not nvim-work"
  login_shell 'for tool in git nvim tmux atuin python3; do printf "%s -> %s\n" "$tool" "$(command -v "$tool")"; done'
  login_shell 'tmux -L dotfiles-vm new-session -d "sleep 30" && tmux -L dotfiles-vm has-session && tmux -L dotfiles-vm kill-server'
  login_shell 'nvim --headless +qa'

  step "A commit inside the work root uses the work identity"
  email="$(login_shell 'set -e
    mkdir -p ~/Work/vm-sample && cd ~/Work/vm-sample
    git init -q && printf "sample\n" > sample.txt && git add sample.txt
    git commit -q -m "VM sample commit" && git log -1 --format=%ae')"
  printf '%s\n' "$email"
  [[ "${email##*$'\n'}" == "$TEST_EMAIL" ]] || fail "the commit did not use the work identity"

  step "A commit outside the work root is rejected"
  if login_shell 'set -e
    mkdir -p ~/outside-work && cd ~/outside-work
    git init -q && printf "sample\n" > sample.txt && git add sample.txt
    git commit -q -m "must be rejected"'; then
    fail "a commit outside the work root was accepted"
  fi

  step "Pinned editor/history probes with the activated tools"
  login_shell "cd $(printf '%q' "$checkout") && python3 tests/check_pinned_tools.py \"\$HOME/.nix-profile/bin\""

  step "Work profile test passed"
}

main "$@"
