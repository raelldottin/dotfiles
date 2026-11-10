# shellcheck shell=bash
# Helpers shared by the scripts that run inside a test VM. Source this file.

set -euo pipefail

NIX_DAEMON_PROFILE="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
NIX_FLAGS=(--extra-experimental-features "nix-command flakes")

step() {
  printf '\n==> [guest] %s\n' "$*"
}

fail() {
  printf '\nFAIL: %s\n' "$*" >&2
  exit 1
}

# Echo each test command before running it so the log shows what ran.
run() {
  printf '+ %s\n' "$*"
  "$@"
}

load_nix() {
  [[ -r "$NIX_DAEMON_PROFILE" ]] || fail "Nix is not installed"
  set +u
  # shellcheck disable=SC1090
  . "$NIX_DAEMON_PROFILE"
  set -u
}

# Any HTTP response, including an error status, means the network works.
can_reach() {
  curl --proto '=https' -sSI --max-time 10 -o /dev/null "$1" 2>/dev/null
}

# Point the guest at the host's own resolvers. Some hosts block the DNS
# forwarder on Tart's NAT gateway while direct DNS to their resolvers works.
network_service() {
  networksetup -listnetworkserviceorder |
    awk '/^\([0-9]+\) /{sub(/^\([0-9]+\) /, ""); name=$0} /Device: en0\)/{print name; exit}'
}

use_host_dns() {
  local servers="${DOTFILES_VM_DNS:-}"
  local service

  [[ -n "$servers" ]] || return 1
  service="$(network_service)"
  [[ -n "$service" ]] || return 1
  step "The NAT gateway's DNS is not answering; using the host's resolvers ${servers//,/ } on $service"
  # shellcheck disable=SC2086 # One argument per server.
  sudo networksetup -setdnsservers "$service" ${servers//,/ }
}

# SSH can come up before a freshly booted guest can resolve names.
wait_for_network() {
  local url="$1"
  local waited=0
  local switched=0

  until can_reach "$url"; do
    if (( waited >= 30 && switched == 0 )); then
      switched=1
      use_host_dns || true
    fi
    if (( waited >= 180 )); then
      curl --proto '=https' -sSI --max-time 10 -o /dev/null "$url" || true
      fail "the guest could not reach $url within 180 seconds"
    fi
    sleep 5
    waited=$((waited + 5))
  done
  if (( waited > 0 )); then
    step "Network ready after ${waited}s"
  fi
}

# Fresh-machine Nix install. nix-darwin recommends an installer with a
# reliable uninstaller; the Lix installer is one and the personal profile runs
# Lix after activation.
install_nix() {
  local installer="${DOTFILES_VM_NIX_INSTALLER:-https://install.lix.systems/lix}"

  wait_for_network "$installer"
  if [[ -e /nix/var/nix/profiles/default/bin/nix ]]; then
    step "Nix is already installed"
  else
    step "Installing Nix from $installer"
    curl --proto '=https' --tlsv1.2 -sSfL "$installer" | sh -s -- install --no-confirm
  fi
  load_nix
  run nix --version
}

# Fresh macOS has no Git until the Command Line Tools are installed, so use
# Git from the nixpkgs revision that the tested commit pins.
clone_bundle() {
  local bundle="$1"
  local destination="$2"
  local nixpkgs_rev="$3"

  run nix "${NIX_FLAGS[@]}" shell "github:NixOS/nixpkgs/$nixpkgs_rev#git" --command \
    git -c advice.detachedHead=false clone --quiet "$bundle" "$destination"
  run nix "${NIX_FLAGS[@]}" shell "github:NixOS/nixpkgs/$nixpkgs_rev#git" --command \
    git -C "$destination" log -1 --format='Testing %H %s'
}

# Fail unless every named tool resolves in a fresh login shell; print each path.
require_tools() {
  login_shell "for tool in $*; do tool_path=\"\$(command -v \"\$tool\")\" || { echo \"missing: \$tool\"; exit 1; }; printf '%s -> %s\\n' \"\$tool\" \"\$tool_path\"; done"
}

# Run a command in a fresh login shell, as a new terminal would.
login_shell() {
  printf '+ zsh -lc %q\n' "$1"
  /bin/zsh -lc "$1"
}

# Run tests/check_pinned_tools.py with the activated profile's Neovim and
# Atuin. A profile that relies on the system's zsh gets zsh from the pinned
# nixpkgs revision instead, as the CI fixture does.
run_pinned_probes() {
  local checkout="$1"
  local profile_bin="$2"
  local nixpkgs_rev="$3"
  local tools
  local zsh_bin="$profile_bin/zsh"

  tools="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-vm-tools.XXXXXX")"
  ln -s "$profile_bin/nvim" "$tools/nvim"
  ln -s "$profile_bin/atuin" "$tools/atuin"
  if [[ ! -x "$zsh_bin" ]]; then
    zsh_bin="$(nix "${NIX_FLAGS[@]}" build --no-link --print-out-paths \
      "github:NixOS/nixpkgs/$nixpkgs_rev#zsh")/bin/zsh"
  fi
  ln -s "$zsh_bin" "$tools/zsh"
  printf 'Probe tools: nvim, atuin from %s; zsh from %s\n' "$profile_bin" "$zsh_bin"
  login_shell "cd $(printf '%q' "$checkout") && PATH=$(printf '%q' "$tools"):\$PATH python3 tests/check_pinned_tools.py $(printf '%q' "$tools")"
}
