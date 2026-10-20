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
- `agent-review/main` on `main`, or `agent-review/dev` on `dev`

Review expectations:

- `main` and `dev` require zero mandatory human approvals and no mandatory
  code-owner approval; pull requests remain required.
- Both branches require their target-specific agent-review status on the exact reviewed commit,
  alongside all existing CI checks. It links to a published agent review.
- A new commit requires a new agent review. This is an operator-attested review
  gate, not an independent GitHub approval. See [Agent Review](AGENT_REVIEW.md).

## Security

Enable these repository features when available:

- Dependabot security updates
- secret scanning
- secret scanning push protection

## Ownership

Use `.github/CODEOWNERS` to make workflow, shell, Neovim, and documentation changes explicit review surfaces.
