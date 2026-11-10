#!/usr/bin/env bash
# Install the host tools that build and run the dotfiles test VMs:
# Tart (Apple Virtualization VMs) and Packer (base image builds).
set -euo pipefail

# shellcheck source=vm/lib.sh
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# Tart releases moved from the cirruslabs/cli tap (frozen at 2.32.1) to
# openai/tools. Packer comes from HashiCorp's tap.
TART_FORMULA="openai/tools/tart"
LEGACY_TART_FORMULAE=(cirruslabs/cli/tart cirruslabs/cli/softnet)
PACKER_FORMULA="hashicorp/tap/packer"

vm_require_apple_silicon
vm_require brew

brew_has() {
  brew list --formula --full-name 2>/dev/null | grep -Fxq -- "$1"
}

# Homebrew refuses formulae from taps the user has not trusted. Trusting a tap
# is the user's own decision, so print the command instead of running it.
require_trusted() {
  local formula trusted
  local -a untrusted=()

  trusted="$(brew trust --json=v1 2>/dev/null || true)"
  for formula in "$@"; do
    # Trusting the formula's whole tap also counts.
    grep -Fq -e "\"$formula\"" -e "\"${formula%/*}\"" <<<"$trusted" || untrusted+=("$formula")
  done
  if (( ${#untrusted[@]} > 0 )); then
    printf 'Homebrew must trust these formulae before they can be installed:\n' >&2
    printf '  brew trust --formula %s\n' "${untrusted[@]}" >&2
    exit 1
  fi
}

install_tart() {
  local version

  if command -v tart >/dev/null 2>&1; then
    version="$(vm_tart_version)"
    if vm_version_at_least "$version" "$VM_MIN_TART_VERSION"; then
      vm_log "Tart $version is already installed at $(command -v tart)"
      return
    fi
    vm_log "Tart $version is older than $VM_MIN_TART_VERSION"
  fi

  for formula in "${LEGACY_TART_FORMULAE[@]}"; do
    if brew_has "$formula"; then
      vm_log "Removing $formula from the abandoned cirruslabs/cli tap"
      brew uninstall --ignore-dependencies "$formula"
    fi
  done
  if brew tap | grep -Fxq cirruslabs/cli &&
    ! brew list --formula --full-name | grep -q '^cirruslabs/cli/'; then
    brew untap cirruslabs/cli
  fi

  require_trusted "$TART_FORMULA" openai/tools/softnet
  brew install "$TART_FORMULA"
}

install_packer() {
  if command -v packer >/dev/null 2>&1; then
    vm_log "$(packer version | head -n 1) is already installed at $(command -v packer)"
    return
  fi
  require_trusted "$PACKER_FORMULA"
  brew install "$PACKER_FORMULA"
}

install_tart
install_packer
vm_require_tart
vm_log "VM tools are ready: Tart $(vm_tart_version), $(packer version | head -n 1)"
