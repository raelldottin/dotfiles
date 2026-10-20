# First-time setup

## Choose the profile before installing

| Machine | Setup path | Prerequisites |
| --- | --- | --- |
| Company Mac, Apple Silicon or Intel | [Company Mac with Home Manager](WORK_MAC.md#install-on-the-company-mac) | Company provisioning complete, approved Nix installation with flakes, work Git name/email |
| Company Mac where Nix is unavailable | [Legacy fallback](WORK_MAC.md#legacy-fallback-when-nix-is-unavailable) | Company approval, Git, Python 3.10+, Homebrew, and `make` |
| Personal Apple Silicon Mac | [Personal macOS bootstrap](NIX.md#macos-bootstrap) | Git, Nix with flakes, account/configuration review, administrator access for nix-darwin |
| Personal Linux, x86_64 or aarch64 | [Linux bootstrap](NIX.md#linux-bootstrap) | Git, Nix with flakes, account/configuration review |

The personal outputs use the `username` in `flake.nix`, currently `raelldottin`,
and derive the home directory from it. Review that value and `nix/home.nix`
before using them for another account. For a personal Mac, also review
`nix/darwin.nix`, including its Homebrew applications and system settings.

`make install` selects the company fallback; it is not the personal Nix setup.
Use one installation path per machine. Keep existing managed settings and
backups until the new installation has been checked on that device.

## Clone a stable checkout

Git must already be available. On a company Mac, use the company's approved
developer-tool provisioning method first. Choose a permanent parent directory;
company work repositories belong under `~/Work` by default. On a company Mac,
create and enter that directory first:

```sh
mkdir -p "$HOME/Work"
cd "$HOME/Work"
```

From your chosen parent directory, clone the stable branch:

```sh
git clone --branch main https://github.com/raelldottin/dotfiles.git dotfiles
cd dotfiles
git status --short --branch
uname -s
uname -m
```

HTTPS cloning of this public repository does not require setting up SSH keys.
Keep the checkout in place: the legacy fallback links installed files to it.
Use `main` for installation; contributors start changes from `dev` as described
in the [contributor workflow](CONTRIBUTING.md).

## Install through the selected guide

Open the matching setup path above and follow its activation steps. For Nix,
check `nix --version` and enable `nix-command` and `flakes` if your approved
installation has not enabled them. The first package and plugin downloads need
network access. Begin with the committed `flake.lock`; input updates are a
separate maintenance step.

If a command fails, resolve its reported error before continuing with the next
installation step.

For the company profile, supply the current device's account and work identity
locally. Do not copy personal history, agent state, credentials, or account
sessions to the company device. The setup guide provides separate, complete
commands for Nix and the fallback.

## Verify the first login

Open a new login terminal after installation, then check the selected path:

| Installation | Check | What success establishes |
| --- | --- | --- |
| Company Home Manager | `dotfiles-work verify` | Private work identity and commit-guard configuration match |
| Company fallback, from the checkout | `make verify-install` | Managed links and work Git configuration match |
| Personal Nix | Start a fresh shell, tmux session, and Neovim | The affected tools launch on this device; complete the [device checklist](../README.md#migration-completion-criteria) |

On a company Mac, confirm `NVIM_APPNAME` is `nvim-work` in the new terminal.
Launch `nvim` and `tmux`, and allow the first approved plugin downloads to
finish. In a work repository under the configured work root, inspect
`git config --show-origin --get user.email` and confirm it is the intended work
identity before making a commit. Tool startup and identity checks do not
authenticate company accounts; verify access separately with the approved
services.

`make verify` is the repository's lint and isolated-test pipeline. It needs the
development tools listed in the [testing guide](TESTING.md) and does not prove
that this machine has been activated successfully.

## If setup stops

| Symptom | Next step |
| --- | --- |
| `nix` is missing or flakes are disabled | Complete the approved Nix setup before activation; use the company fallback only when permitted |
| Work name/email is missing, or the selected HOME differs | Use the work guide's identity prompts and the current device's username/HOME; do not reuse another machine's values |
| Homebrew is missing during `make dependencies` | Provision it through the approved method; the fallback deliberately does not bootstrap it |
| A conflicting file or symlink is rejected | Inspect the reported path and preserve its contents before retrying; do not delete private history or editor state to bypass the check |
| Work editor starts in the personal namespace | Open a new login terminal and check `NVIM_APPNAME`; graphical launchers need equivalent environment settings |

## Company profile after installation

Use [Company Mac setup](WORK_MAC.md) for installation, identity configuration,
separation boundaries, updates, and removal. Apply this repo on the company
device after provisioning; do not run the work installer on the personal Mac
to export its settings.

The installer requires a locally supplied work identity and defaults to
`~/Work` for repositories. The preferred company profile uses standalone Home Manager and a minimal Nix
package set. The legacy fallback uses a curated Brewfile rather than replaying
the personal machine's inventories. Shell and editor state use work-specific
directories, and existing replaced files are preserved in backups.

`make verify` checks source and isolated behavior. `dotfiles-work verify` checks the Nix profile's private identity;
`make verify-install` checks the legacy fallback installation; first installation and account access still
need checking on the company Mac. See [Testing Guide](TESTING.md).

After installation, open a new login terminal. Use `nvim` from that terminal
for the work editor namespace. Machine-only settings go in
`~/.config/dotfiles/work.local.zsh`, which is never imported from this repo.
Work namespace and Git environment settings are reapplied after that file.

For the legacy fallback, `make clean` leaves private work state and backups
intact. Review a backup
before manually restoring it; restoring the personal configuration would undo
the intended work separation.
