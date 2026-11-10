# VM testing

The VM tests rehearse a fresh-machine installation in a disposable macOS 27
(Golden Gate) virtual machine. They cover what CI and `make verify` cannot:
a real system-level nix-darwin activation with Homebrew casks, and a work
Home Manager installation on a Mac that has never seen this repository.

Every command used for VM testing lives in [`vm/`](../vm) and the Makefile
targets below. Run VM tests through these scripts rather than ad hoc `tart` or
`ssh` commands, and change the scripts when the procedure changes.

| File | Runs on | Purpose |
| --- | --- | --- |
| `vm/install-tools.sh` | host | Installs Tart and Packer |
| `vm/golden-gate.pkr.hcl` | host (Packer) | Defines the base image |
| `vm/build-base.sh` | host | Builds the base image with Packer |
| `vm/run-test.sh` | host | Clones the base image, runs one profile test, deletes the clone |
| `vm/shell.sh` | host | Opens a shell in a test VM kept with `--keep` |
| `vm/guest/test-personal.sh` | guest | Personal nix-darwin activation (`docs/NIX.md`) |
| `vm/guest/test-work.sh` | guest | Work Home Manager activation (`docs/WORK_MAC.md`) |
| `vm/guest/provision-base.sh` | guest (Packer) | Installs the Command Line Tools in the base image |
| `vm/lib.sh`, `vm/guest/common.sh` | both | Shared helpers |

## Requirements

- An Apple Silicon Mac running macOS 27 or later. The guest cannot be newer
  than the host.
- Homebrew, about 30 GB of free disk for the base image, and more for each
  test clone while it runs.
- Network access: the base build downloads Apple's restore image (about 26 GB),
  and each test downloads Nix, packages, and Homebrew casks.
- Apple's license allows at most two macOS VMs running at once. Stop other
  VMs first if `tart run` refuses to start one.

## One-time setup

```sh
make vm-tools
make vm-base
```

`make vm-tools` installs Tart from the `openai/tools` tap and Packer from
`hashicorp/tap`, unless new enough copies are already installed. Tart must be
2.33.0 or later. Homebrew refuses formulae from untrusted taps; the script
prints the `brew trust` command to run yourself instead of trusting a tap for
you. If an old Tart from the abandoned `cirruslabs/cli` tap is installed, the
script replaces it.

`make vm-base` builds `dotfiles-golden-gate-base` from Apple's macOS 27.2
restore image. Tart's first-boot provisioning creates the `admin` account,
automatic login, and SSH, so the build needs no keystrokes. Packer then enables
passwordless sudo, turns off sleep and the screen lock, installs the Command
Line Tools (the guides' Git prerequisite; Nix also runs `git` to read a
checkout) with `vm/guest/provision-base.sh`, and installs a per-host SSH key
from `~/.local/state/dotfiles-vm/id_ed25519`. Tests sign in with that key.
The `admin` password is random for each build, because macOS 27 requires at
least 12 characters with letters and digits; it is saved in
`~/.local/state/dotfiles-vm/admin-password` (mode 600) for unlocking the VM's
screen by hand. Neither the key nor the password is committed. After the
restore image download, the build takes about 10 minutes, most of it the
Command Line Tools download.

Rebuild the image with `vm/build-base.sh --force`. To use another restore
image, set `DOTFILES_VM_IPSW` to its URL or path.

## Run a profile test

```sh
make vm-test-personal
make vm-test-work
```

Or call the runner directly, adding `--keep` to leave the VM for inspection:

```sh
vm/run-test.sh --keep work
```

The runner tests the **committed HEAD** of this checkout. It warns about, and
does not copy, uncommitted changes. Each run:

1. Clones the base image to `dotfiles-test-<profile>-<timestamp>` and gives it
   6 CPUs and 16 GB of memory (`DOTFILES_VM_CPU`, `DOTFILES_VM_MEMORY_MB`).
2. Boots it without a window and waits for SSH.
3. Copies a Git bundle of HEAD and `vm/guest/` into `/tmp/dotfiles-vm`.
4. Runs the profile's guest script and streams its output to the terminal and
   to `~/.local/state/dotfiles-vm/logs/<vm>.log`.
5. Stops and deletes the clone, also on failure or Ctrl-C, unless `--keep`.

The runner exits with the guest script's status.

Both guest scripts install Nix with the Lix installer
(`DOTFILES_VM_NIX_INSTALLER` overrides the URL) and clone the bundle with Git
from the nixpkgs revision pinned in `flake.lock`, so the clone does not depend
on the image's Git.

### Personal profile

`vm/guest/test-personal.sh` creates the account named by `username` in
`flake.nix` with a random password and passwordless sudo, because cask
installers call sudo during activation. As that user it then:

1. Clones the commit to `~/dotfiles` and runs `nix flake check`.
2. Runs the first activation from `docs/NIX.md`:
   `sudo nix run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake .#macbook`.
3. Activates again with the installed `darwin-rebuild`.
4. In fresh login shells, checks that zsh, tmux, Neovim, Atuin, Python, and
   Homebrew resolve. Neovim must come from the Home Manager profile. It also
   starts a tmux server and headless Neovim, and lists the installed casks.
5. Runs `tests/check_pinned_tools.py` with Neovim and Atuin from the user's
   Home Manager profile, which fails on any skipped probe. If the profile has
   no zsh, the probes use zsh from the pinned nixpkgs revision.

### Work profile

`vm/guest/test-work.sh` runs as `admin` with the placeholder identity
`Dotfiles VM Test <dotfiles-vm-test@example.invalid>`. It:

1. Clones the commit to `~/Work/dotfiles`.
2. Checks that activation without the `DOTFILES_WORK_*` settings is refused
   by the account check, not by an unrelated error.
3. Runs the activation command from `docs/WORK_MAC.md` twice.
4. In fresh login shells, runs `dotfiles-work verify`, checks that
   `NVIM_APPNAME` is `nvim-work`, and starts tmux and headless Neovim.
5. Checks that a commit under `~/Work` uses the work identity, that a commit
   outside it has no identity, and that the commit guard rejects it even with
   a local identity.
6. Runs `tests/check_pinned_tools.py` with Neovim and Atuin from
   `~/.nix-profile/bin`. The work profile uses the system's login zsh, so the
   probes take zsh from the pinned nixpkgs revision, as the CI fixture does.

## What a pass establishes

A pass shows that the committed configuration installs and activates on a
clean macOS 27 machine and that its shells, editors, and Git guards work
there. It does not prove behavior on your real Mac, which has existing files,
company provisioning, signed-in accounts, and personal data. It does not test
account sign-in, FileVault, or MDM policies, and it does not test the legacy
`make install-work` fallback.

## Troubleshooting

| Symptom | Next step |
| --- | --- |
| `Tart ... is older than 2.33.0` | Run `make vm-tools` |
| Base image is missing | Run `make vm-base` |
| `tart run` refuses to start | Two macOS VMs are already running; stop one with `tart stop <name>` |
| The guest cannot resolve names | The runner passes the host's resolvers to the guest, which switches to them when the NAT gateway's DNS forwarder does not answer; set `DOTFILES_VM_DNS=server1,server2` to choose others |
| SSH never comes up | Rerun with `--keep`, then open the VM with `tart run <name>` to see its screen |
| Inspect a kept VM | `vm/shell.sh <name>` opens a shell; `vm/shell.sh <name> <command>` runs one command |
| A guest step fails | Read the log path printed at the end, fix the repo, commit, and rerun |
| Leftover test VMs | `tart list`, then `tart delete dotfiles-test-<profile>-<timestamp>` |
