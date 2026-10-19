# Apply this configuration to the company Mac

The repo now carries portable preferences from the current Mac: Pure prompt
styling, shell aliases and editor selection, explicit Homebrew maintenance,
Atuin integration, and the current LazyVim configuration with its plugin lockfile
and date in the status line. Tmux retains the repo's existing configuration;
there was no live `~/.tmux.conf` to import.

Personal Hermes/swarm functions, personal agent profiles, account settings,
credentials, SSH keys, shell history, Atuin databases, and editor sessions are
not imported. This is a company-device setup. Do not run its installer on the
personal Mac merely to export settings.

## Install on the company Mac

Finish company provisioning first. Use an approved Nix installation. The
company outputs use **standalone Home Manager**; they do not import the personal
`nix/darwin.nix` settings or install its personal GUI applications. Do not run
the personal `macbook` nix-darwin activation on the company Mac.

Clone this branch to a stable location on the **company Mac**. Supply work Git
identity locally, then activate the correct architecture:

```sh
printf 'Work Git name: '; IFS= read -r DOTFILES_WORK_GIT_NAME
printf 'Work Git email: '; IFS= read -r DOTFILES_WORK_GIT_EMAIL
export DOTFILES_WORK_GIT_NAME DOTFILES_WORK_GIT_EMAIL
export DOTFILES_WORK_USER="$(id -un)"
export DOTFILES_WORK_HOME="$HOME"
work_system="$(nix eval --impure --raw --expr builtins.currentSystem)"
nix run --no-write-lock-file .#work-home-manager -- switch \
  --flake ".#work-${work_system}" --impure -b hm-backup
unset DOTFILES_WORK_GIT_NAME DOTFILES_WORK_GIT_EMAIL
unset DOTFILES_WORK_USER DOTFILES_WORK_HOME work_system
```

The `work-aarch64-darwin` and `work-x86_64-darwin` outputs support Apple Silicon
and Intel Macs. Username and HOME must be supplied explicitly; they never fall
back to the repo's personal username. Activation checks the selected HOME against
the actual user before Home Manager's write boundary. Git name/email are read
only during activation and saved in private device-local files, not the Nix store.
Pure evaluation uses a non-activatable placeholder so generic flake checks can
run without a real account. The helper refuses that placeholder and requires
the explicit variables with `--impure` for activation.

The work repository directory defaults to `~/Work`. Set `DOTFILES_WORK_ROOT`
to choose another dedicated directory beneath HOME. The installer rejects HOME
itself, external paths, parent traversal, and linked work/config/history/backup
directories. Commit guards also reject a work root redirected after installation.
Existing global/system Git hooks must be integrated before installation.

Home Manager preserves conflicting configuration with `.hm-backup`; generated
Git files use the private dotfiles backups directory. A pre-existing backup
conflict should be reviewed rather than deleted automatically. Nix-managed
configuration is read-only: change the repo and activate again. A pinned guard
package is used for Git hooks, and an upgrade updates its path without importing
a previous global configuration.

Open a new login terminal. Clone company repositories beneath the selected work
root, and run `dotfiles-work verify`. It checks the private identity and global
Git guard configuration. Home Manager owns the shell/editor file generations.

### Legacy fallback when Nix is unavailable

Use the shell installer only if the company permits this alternative. Do not
apply it over a Home Manager-owned installation. Provision Git, Python 3.10+ and
Homebrew using company-approved methods. Optionally run `make dependencies`
for the curated Brewfile, supply the same work Git variables above, and run
`make install-work`. `make install` selects that same work profile.

The fallback does not install Homebrew, run `sudo`, or replay either personal
package inventory. It backs up replaced files and uses the same work identity
checks. Verify it with `make verify-install`. Unlike the Nix profile, its hooks
and configuration links refer to the checkout path; reinstall after moving it.

## Separation enforced by the configuration

| Area | Work behavior |
| --- | --- |
| Git identity | Required during installation. Global default identity is empty; the selected work identity applies beneath the work root. |
| Commits | Global pre-commit and prepare-commit-msg hooks reject repositories outside the work root and author/committer identities that differ from the selected work identity. Preserved cherry-pick authors are checked explicitly; pre-rebase checks the selected source history before rewriting it. The prepare-commit-msg hook also runs with `git commit --no-verify`. |
| Inherited Git settings | The shell selects this Mac's managed global config and clears inherited author/committer identity and injected Git command configuration variables. |
| Atuin | Configuration is `~/.config/atuin-work/config.toml`; history, key, and metadata use the work data namespace. Automatic sync and update checks are disabled. No account session is copied. |
| Shell history | `~/.local/state/work/zsh/history`; existing personal shell history is not sourced or imported. |
| Neovim | `NVIM_APPNAME=nvim-work`; configuration is `~/.config/nvim-work`, with separate editor data, caches, and sessions. Existing `~/.config/nvim` is left alone. |
| Other shell tool state | XDG data/state/cache directories are `~/.local/share/work`, `~/.local/state/work`, and `~/.cache/work`. Tools that honor these variables use work-specific storage. |
| Machine overrides | Only `~/.config/dotfiles/work.local.zsh` is loaded. Work namespaces and Git environment safeguards are reapplied afterward. No personal override is loaded. |
| Updates | Terminal startup performs no package upgrades or remote status queries. `bup` explicitly updates/upgrades Homebrew and runs its health check. |

Identity values live in private files under `~/.config/dotfiles`, outside the
repo. The generated `~/.gitconfig` does not include the previous personal/global
configuration. Existing files replaced by installation are preserved beneath
`~/.local/state/dotfiles/backups`; review them locally rather than restoring an
old personal configuration over the work setup.

Authenticate company accounts separately on the company Mac. In particular,
do not import the personal Atuin database or sign into its personal sync
account. Keep sync disabled unless the employer supplies an approved work
destination. Agent CLIs and cloud tools are optional additions; they are not
in the baseline Brewfile.

These guards prevent accidental mixing in the configured shell and guarded Git
commits. They are not an operating-system sandbox: a repository can replace
`core.hooksPath`, a tool can ignore XDG paths, and application/browser logins
must still use work accounts. Check existing repositories' hook configuration
before use; preserve and integrate company-required hooks rather than silently
overriding them. A person deliberately changing config or using Git's hook-bypass
options can bypass local guards.
Both author and committer must match the selected identity; importing a commit
with another author through cherry-pick or rebase is intentionally rejected by
this strict default and needs a reviewed company workflow.

Pure's background Git fetching is disabled as well; prompt rendering does not
automatically contact a remote repository.

## Editor and package maintenance

Use `nvim` from the new terminal so it inherits `NVIM_APPNAME=nvim-work`.
First launch downloads LazyVim plugins. Run `:Lazy restore` to restore the
captured lockfile revisions. Periodic plugin update checking is disabled;
updates should be deliberate. No personal plugin cache or session was copied.

LazyVim writes its runtime lockfile to
`~/.local/state/work/nvim-work/lazy-lock.json`, so the Nix-managed configuration
can remain read-only. It is seeded from the repo's captured lockfile and refreshed
when those captured revisions change. Ordinary restarts preserve deliberate
runtime updates. To capture updated pins, copy that runtime lockfile into
`config/nvim/lazy-lock.json` in the checkout, review it, and activate the updated
configuration. Editor storage directories and history files cannot alias another
profile. Tool links within the work namespaces remain valid, and editor data
may link to installed executable runtimes, as Python virtual environments do.
Editor state and cache links cannot escape the work namespaces.

`make snapshot` is an explicit inventory maintenance command. Ordinary commits
no longer rewrite the Homebrew/npm inventories. These inventories remain
observations of the personal machine, not the company installation manifest.

## Verification and removal

`make verify` runs linters plus isolated tests for installation, preservation,
Git identity rejection, work-directory boundaries, shell startup, and dependency
invocation. Where Atuin is available, a read-only CLI probe checks the actual
work database/key/metadata paths. Tests do not authenticate accounts or install
Homebrew packages.

`make verify-install` checks installed files and the managed work Git config.
It cannot certify company account selection or overridden hooks in every repo.
Fresh company-Mac installation and first plugin downloads still need checking
on that device.

For the legacy fallback, `make clean` removes matching managed links and the unchanged generated global
Git config. It keeps private work settings, history, sessions, and backups.
It does not automatically restore the previous Git config or personal files.

## Verification recorded October 18, 2026

All repository linters and **43 tests** passed: 12 unit tests and 31 integration
tests, with no skips on this Mac. The actual Atuin path probe and offline
Neovim configuration check ran. Regression tests cover linked work roots, redirected backups, standalone
installer aliases, work history aliases, expected-HOME checks, and guard-package
upgrades. Additional regressions cover preserved cherry-pick authors, both rebase
backends, root and explicitly selected branches, editor state aliases, internal
tool links, and writable lockfile seeding from read-only configuration.
Nix evaluation and a macOS activation-package build are checked in CI;
no Nix activation has been performed on the company device.

The original checkout and its uncommitted Homebrew/npm inventory edits were
preserved. This delivery is based on the current Nix migration on `dev`. The
personal Atuin audit is not included in the transferable repo. No installer was
applied to this Mac's real HOME. Company-Mac provisioning, complete plugin
installation, and work account access remain unverified.
