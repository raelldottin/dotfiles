#!/usr/bin/env bash
# Open a shell, or run one command, in a running test VM as its admin user.
#
#   vm/shell.sh VM [COMMAND...]
#
# Use it with VMs kept by `vm/run-test.sh --keep`; `tart list` shows names.
set -euo pipefail

# shellcheck source=vm/lib.sh
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

case "${1:-}" in
  "" | -h | --help)
    sed -n '2,6s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"
    [[ -n "${1:-}" ]] || exit 1
    exit 0
    ;;
esac

vm_require_tart
vm_name="$1"
shift
vm_exists "$vm_name" || vm_die "no VM named $vm_name"
address="$(tart ip "$vm_name")" || vm_die "$vm_name is not running"
if (( $# == 0 )); then
  exec ssh -t "${VM_SSH_OPTS[@]}" "$VM_GUEST_USER@$address"
fi
vm_ssh "$address" "$@"
