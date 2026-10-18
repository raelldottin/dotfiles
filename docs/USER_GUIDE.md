# User guide

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

`make clean` leaves private work state and backups intact. Review a backup
before manually restoring it; restoring the personal configuration would undo
the intended work separation.
