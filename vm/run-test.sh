#!/usr/bin/env bash
# Rehearse a fresh-machine installation of one profile in a disposable VM.
#
#   vm/run-test.sh [--keep] personal|work
#
# Clones the base image, boots it headless, copies the committed HEAD of this
# checkout into it, and runs vm/guest/test-<profile>.sh there. The VM is
# deleted afterwards unless --keep is given. Uncommitted changes are not tested.
set -euo pipefail

# shellcheck source=vm/lib.sh
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
  sed -n '2,8s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"
}

keep=0
profile=""
while (( $# > 0 )); do
  case "$1" in
    --keep) keep=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    personal | work)
      [[ -z "$profile" ]] || vm_die "choose one profile"
      profile="$1"
      ;;
    *)
      usage >&2
      vm_die "unknown argument: $1"
      ;;
  esac
  shift
done
[[ -n "$profile" ]] || {
  usage >&2
  vm_die "choose a profile: personal or work"
}

vm_require_apple_silicon
vm_require_tart
vm_require git python3 ssh scp
[[ -f "$VM_SSH_KEY" ]] || vm_die "no VM test key at $VM_SSH_KEY; run vm/build-base.sh first."
vm_exists "$VM_BASE_IMAGE" || vm_die "base image $VM_BASE_IMAGE is missing; run vm/build-base.sh first."

if [[ -n "$(git -C "$VM_REPO_ROOT" status --porcelain)" ]]; then
  vm_log "Warning: uncommitted changes are not copied into the VM; testing HEAD only."
fi
head="$(git -C "$VM_REPO_ROOT" rev-parse HEAD)"
# The guest has no Git until Nix is installed; it fetches Git from the
# nixpkgs revision this commit pins.
nixpkgs_rev="$(git -C "$VM_REPO_ROOT" show HEAD:flake.lock |
  python3 -c 'import json, sys; print(json.load(sys.stdin)["nodes"]["nixpkgs"]["locked"]["rev"])')"
guest_args=(/tmp/dotfiles-vm/dotfiles.bundle "$nixpkgs_rev")
if [[ "$profile" == personal ]]; then
  # The personal outputs fix their account name in flake.nix.
  personal_user="$(git -C "$VM_REPO_ROOT" show HEAD:flake.nix |
    sed -n 's/^ *username = "\([a-z_][a-z0-9_-]*\)";$/\1/p' | head -n 1)"
  [[ -n "$personal_user" ]] || vm_die "could not read the personal username from flake.nix"
  guest_args+=("$personal_user")
fi

host_dns="$(vm_host_dns)"

vm_ensure_state_dir
vm_name="dotfiles-test-$profile-$(date +%Y%m%d-%H%M%S)-$$"
log="$VM_STATE_DIR/logs/$vm_name.log"
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-vm.XXXXXX")"
tart_pid=""

# shellcheck disable=SC2317,SC2329 # Invoked by the EXIT trap.
cleanup() {
  local status=$?

  trap - EXIT INT TERM
  if (( keep == 1 )); then
    vm_log "Keeping $vm_name; remove it with: tart stop $vm_name; tart delete $vm_name"
  elif vm_exists "$vm_name"; then
    tart stop --timeout 30 "$vm_name" >/dev/null 2>&1 || true
    if [[ -n "$tart_pid" ]]; then
      wait "$tart_pid" 2>/dev/null || true
    fi
    tart delete "$vm_name" || vm_log "Could not delete $vm_name"
  fi
  rm -rf "$work_dir"
  vm_log "Log: $log"
  exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT TERM
trap 'exit 129' HUP

{
  printf 'profile: %s\ncommit: %s\nbase image: %s\nvm: %s\nhost: %s, Tart %s\n' \
    "$profile" "$head" "$VM_BASE_IMAGE" "$vm_name" "$(sw_vers -productVersion)" "$(vm_tart_version)"
} | tee "$log" >&2

vm_log "Cloning $VM_BASE_IMAGE to $vm_name"
tart clone "$VM_BASE_IMAGE" "$vm_name"
tart set "$vm_name" --cpu "${DOTFILES_VM_CPU:-6}" --memory "${DOTFILES_VM_MEMORY_MB:-16384}"

vm_log "Booting $vm_name"
tart run --no-graphics "$vm_name" >"$work_dir/tart-run.log" 2>&1 &
tart_pid=$!

address="$(tart ip --wait 300 "$vm_name")" ||
  vm_die "$vm_name did not get an IP address: $(cat "$work_dir/tart-run.log")"
vm_wait_for_ssh "$address" 300 || vm_die "SSH to $vm_name at $address did not come up."

vm_log "Copying commit ${head:0:12} into $vm_name"
git -C "$VM_REPO_ROOT" bundle create -q "$work_dir/dotfiles.bundle" HEAD
vm_ssh "$address" 'rm -rf /tmp/dotfiles-vm && mkdir -p /tmp/dotfiles-vm'
scp -q -r "${VM_SSH_OPTS[@]}" "$VM_DIR/guest" "$work_dir/dotfiles.bundle" \
  "$VM_GUEST_USER@$address:/tmp/dotfiles-vm/"
vm_ssh "$address" 'chmod -R a+rX /tmp/dotfiles-vm'

vm_log "Running the $profile profile test in $vm_name"
set +e
vm_ssh "$address" env "DOTFILES_VM_DNS=$host_dns" \
  /bin/bash /tmp/dotfiles-vm/guest/test-"$profile".sh \
  "${guest_args[@]}" 2>&1 | tee -a "$log"
status=${PIPESTATUS[0]}
set -e

if (( status == 0 )); then
  vm_log "The $profile profile test passed for ${head:0:12}"
else
  vm_log "The $profile profile test failed with status $status"
fi
exit "$status"
