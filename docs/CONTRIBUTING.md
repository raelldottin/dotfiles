# Contributor Workflow

## Branch Strategy

This repository follows a lightweight enterprise-style branching model:

- `main` is the stable branch.
- `dev` is the integration branch for changes ready to combine.
- short-lived feature branches are created from `dev`.
- Codex-created branches use the `codex/` prefix so they are easy to identify and so CI runs on push.

Avoid committing directly to `main` when the change can move through `dev` or a feature branch first.

## Standard Change Flow

1. Start from the latest `dev`.
2. Create a feature branch such as `codex/update-nvim-docs`.
3. Run `make hooks` once per clone so generated files stay current.
4. Make the change.
5. Run `make verify`.
6. Push the feature branch and open a pull request into `dev`.
7. Merge `dev` into `main` only when the integration branch is ready for release.

## Quality Gate

Every branch should satisfy the same baseline before review:

- `make lint`
- `make test`
- `make verify-install` when installer behavior changed

## Pull Requests and Ownership

- GitHub pull requests should use the repository PR template so risk, validation, and rollback notes stay consistent.
- `CODEOWNERS` marks install scripts, workflow changes, Neovim configuration, and documentation as owned review surfaces.
- `main` and `dev` are expected to stay protected; merge through pull requests instead of direct pushes.

## GitHub Settings

The repository-level protection and merge policy are documented in `docs/REPOSITORY_SETTINGS.md`.

## Generated Files

- `README.md` is generated from `README.template`.
- the pre-commit hook updates environment snapshots only when the underlying commands are installed.

Do not edit generated files by hand unless you also update the source template or automation that owns them.
