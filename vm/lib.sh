# shellcheck shell=bash
# Shared host-side helpers for the Tart VM test scripts. Source this file.
# shellcheck disable=SC2034 # The settings below are used by the sourcing scripts.

VM_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
VM_REPO_ROOT="$(cd -- "$VM_DIR/.." && pwd)"

# Every name and path can be overridden so tests and parallel checkouts can
# use their own images and state.
VM_BASE_IMAGE="${DOTFILES_VM_BASE:-dotfiles-golden-gate-base}"
VM_STATE_DIR="${DOTFILES_VM_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-vm}"
VM_SSH_KEY="$VM_STATE_DIR/id_ed25519"
VM_ADMIN_PASSWORD_FILE="$VM_STATE_DIR/admin-password"
VM_GUEST_USER="admin"
VM_MIN_TART_VERSION="2.33.0"

# The guests are disposable, NAT-only VMs whose host keys change on every
# clone, so host keys are neither checked nor recorded.
VM_SSH_OPTS=(
  -i "$VM_SSH_KEY"
  -o IdentitiesOnly=yes
  -o BatchMode=yes
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
  -o LogLevel=ERROR
  -o ConnectTimeout=5
  -o ServerAliveInterval=30
)

vm_log() {
  printf '==> %s\n' "$*" >&2
}

vm_die() {
  printf 'vm: %s\n' "$*" >&2
  exit 1
}

vm_require() {
  local command_name

  for command_name in "$@"; do
    command -v "$command_name" >/dev/null 2>&1 ||
      vm_die "$command_name is not installed; run vm/install-tools.sh first."
  done
}

vm_require_apple_silicon() {
  [[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "arm64" ]] ||
    vm_die "macOS guests need an Apple Silicon Mac host."
}

# Succeeds when version $1 is at least version $2 (dotted numeric versions).
vm_version_at_least() {
  local IFS=.
  local -a have want
  local index

  read -r -a have <<<"$1"
  read -r -a want <<<"$2"
  for index in 0 1 2; do
    # Keep only the leading digits of each part, so 2.41.1-beta compares as 2.41.1.
    have[index]="$(printf '%s' "${have[index]:-0}" | sed 's/[^0-9].*//')"
    want[index]="$(printf '%s' "${want[index]:-0}" | sed 's/[^0-9].*//')"
    if (( 10#${have[index]:-0} > 10#${want[index]:-0} )); then
      return 0
    fi
    if (( 10#${have[index]:-0} < 10#${want[index]:-0} )); then
      return 1
    fi
  done
  return 0
}

vm_tart_version() {
  tart --version 2>/dev/null | head -n 1
}

vm_require_tart() {
  local version

  vm_require tart
  version="$(vm_tart_version)"
  vm_version_at_least "$version" "$VM_MIN_TART_VERSION" ||
    vm_die "Tart $version is older than $VM_MIN_TART_VERSION; run vm/install-tools.sh."
}

vm_ensure_state_dir() {
  mkdir -p "$VM_STATE_DIR/logs"
  chmod 700 "$VM_STATE_DIR"
}

# The key only opens the local test VMs; it is created per host and is never
# committed.
vm_ensure_ssh_key() {
  vm_ensure_state_dir
  if [[ ! -f "$VM_SSH_KEY" ]]; then
    vm_log "Creating the VM test SSH key at $VM_SSH_KEY"
    ssh-keygen -q -t ed25519 -N '' -C dotfiles-vm-test -f "$VM_SSH_KEY"
  fi
}

# The guests fall back to the host's resolvers when the DNS forwarder on
# Tart's NAT gateway does not answer. DOTFILES_VM_DNS overrides them.
vm_host_dns() {
  if [[ -n "${DOTFILES_VM_DNS:-}" ]]; then
    printf '%s\n' "$DOTFILES_VM_DNS"
  elif command -v scutil >/dev/null 2>&1; then
    scutil --dns |
      awk '/^resolver #1$/{found=1; next} found && /nameserver\[/{print $3} found && /^$/{exit}' |
      paste -sd, -
  fi
}

vm_exists() {
  tart list --quiet 2>/dev/null | grep -Fxq -- "$1"
}

vm_ssh() {
  local address="$1"
  shift
  # shellcheck disable=SC2029 # Callers pass commands for the guest shell.
  ssh "${VM_SSH_OPTS[@]}" "$VM_GUEST_USER@$address" "$@"
}

vm_wait_for_ssh() {
  local address="$1"
  local timeout="$2"
  local waited=0

  until vm_ssh "$address" true >/dev/null 2>&1; do
    if (( waited >= timeout )); then
      return 1
    fi
    sleep 5
    waited=$((waited + 5))
  done
}
