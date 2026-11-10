#!/usr/bin/env bash
# Build the macOS 27 base image that every VM test clones.
#
#   vm/build-base.sh [--force]
#
# --force deletes and rebuilds an existing base image.
# DOTFILES_VM_IPSW selects another restore image URL or local path.
# DOTFILES_VM_KEEP_FAILED=1 leaves a failed build VM for vm/shell.sh.
set -euo pipefail

# shellcheck source=vm/lib.sh
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

force=0
while (( $# > 0 )); do
  case "$1" in
    --force) force=1 ;;
    -h | --help)
      sed -n '2,8s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *) vm_die "unknown argument: $1" ;;
  esac
  shift
done

vm_require_apple_silicon
vm_require_tart
vm_require packer ssh-keygen openssl
vm_ensure_ssh_key

if vm_exists "$VM_BASE_IMAGE"; then
  if (( force == 0 )); then
    vm_log "$VM_BASE_IMAGE already exists; pass --force to rebuild it."
    exit 0
  fi
  vm_log "Deleting the existing $VM_BASE_IMAGE"
  tart delete "$VM_BASE_IMAGE"
fi

# macOS 27 requires 12+ characters with letters and digits. Tests sign in with
# the SSH key; the password is kept only for opening the VM's screen by hand.
password="dotfiles1-$(openssl rand -hex 12)"
(umask 077 && printf '%s\n' "$password" >"$VM_ADMIN_PASSWORD_FILE")

template="$VM_DIR/golden-gate.pkr.hcl"
packer_args=(
  -var "vm_name=$VM_BASE_IMAGE"
  -var "ssh_public_key=$(<"$VM_SSH_KEY.pub")"
  -var "dns_servers=$(vm_host_dns)"
)
# Pass the password through the environment so Packer masks it in its logs.
export PKR_VAR_password="$password"
if [[ -n "${DOTFILES_VM_IPSW:-}" ]]; then
  packer_args+=(-var "ipsw=$DOTFILES_VM_IPSW")
fi

log="$VM_STATE_DIR/logs/build-$VM_BASE_IMAGE-$(date +%Y%m%d-%H%M%S).log"
vm_log "Building $VM_BASE_IMAGE (log: $log)"
packer init "$template"
packer validate "${packer_args[@]}" "$template"
build_args=()
if [[ "${DOTFILES_VM_KEEP_FAILED:-0}" == 1 ]]; then
  build_args+=(-on-error=abort)
fi
PACKER_LOG=1 PACKER_LOG_PATH="$log" packer build "${build_args[@]}" "${packer_args[@]}" "$template"
vm_log "Built $VM_BASE_IMAGE"
