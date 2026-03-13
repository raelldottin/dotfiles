# Repository Settings

## Branches

- `main` is the protected release branch.
- `dev` is the protected integration branch.
- short-lived branches such as `codex/*`, `feat/*`, `fix/*`, and `docs/*` are used for individual changes.

## Merge Policy

- squash merge is the default and preferred merge strategy
- merge commits and rebase merges are disabled
- branches are deleted automatically after merge

## Branch Protection

`main` and `dev` should require:

- pull requests before merge
- conversation resolution
- up-to-date branches before merge
- passing CI checks
- linear history

Required checks:

- `checkmake`
- `shellcheck`
- `luacheck`
- `pyright`
- `tests`

Review expectations:

- `main` requires at least one approval and code owner review
- `dev` requires at least one approval

## Security

Enable these repository features when available:

- Dependabot security updates
- secret scanning
- secret scanning push protection

## Ownership

Use `.github/CODEOWNERS` to make workflow, shell, Neovim, and documentation changes explicit review surfaces.
