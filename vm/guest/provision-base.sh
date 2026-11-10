#!/usr/bin/env bash
# Runs inside the base image build (vm/golden-gate.pkr.hcl) as admin.
#
# Installs the Command Line Tools, which provide Git. Both setup guides expect
# Git before installation, and Nix runs `git` to read a Git checkout; without
# the tools, /usr/bin/git only asks to install them.

# shellcheck source=vm/guest/common.sh
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"

# softwareupdate lists the tools only while this marker exists.
MARKER="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"

reset_dns() {
  local service

  service="$(network_service)"
  if [[ -n "$service" ]]; then
    # Clones start with the gateway's DNS again; run-test.sh re-applies the
    # fallback per test, so host-specific resolvers are not baked in.
    sudo networksetup -setdnsservers "$service" Empty
  fi
}

main() {
  local label=""

  wait_for_network "https://swscan.apple.com"
  trap 'rm -f "$MARKER"; reset_dns' EXIT

  if xcode-select -p >/dev/null 2>&1 && /usr/bin/git --version >/dev/null 2>&1; then
    step "Command Line Tools are already installed"
  else
    step "Installing the Command Line Tools"
    touch "$MARKER"
    local attempt listing=""
    for attempt in 1 2 3; do
      listing="$(softwareupdate --list 2>&1 || true)"
      label="$(sed -n 's/^[[:space:]]*\* Label: \(Command Line Tools.*\)$/\1/p' <<<"$listing" |
        sort -V | tail -n 1)"
      [[ -z "$label" ]] || break
      step "Command Line Tools not listed yet (attempt $attempt)"
      sleep 20
    done
    if [[ -z "$label" ]]; then
      printf '%s\n' "$listing"
      fail "softwareupdate does not offer the Command Line Tools"
    fi
    run sudo softwareupdate --install "$label" --agree-to-license
  fi
  run xcode-select -p
  run /usr/bin/git --version
}

main "$@"
