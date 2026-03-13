# Testing Guide

## Philosophy

This repo follows the testing split recommended in *Unit Testing: Principles, Practices, and Patterns*:

- Unit tests cover pure logic with no filesystem, network, or shell-process dependency.
- Integration tests cover installer and hook behavior against temporary, isolated repositories and `HOME` directories.
- Linting stays separate so failures point directly to style/type issues instead of being hidden inside functional tests.

In practice that means the decision-heavy code lives in Python modules such as `gitvars.py` and `dotfiles_manifest.py`, while the shell scripts stay thin and orchestration-focused.

## Commands

Run individual checks:

```bash
make lint
make unit-test
make integration-test
```

Run the full verification pipeline:

```bash
make verify
```

## What Is Covered

- `gitvars.py` is covered by unit tests for placeholder discovery, rendering, staged output behavior, and resilient Git metadata resolution.
- `dotfiles_manifest.py` is covered by unit tests for OS-specific tmux selection and managed-file planning.
- The README hook entrypoint is covered by an integration test that runs the actual CLI inside a temporary Git repository.
- The shared `pre-commit` hook is covered by an integration test that proves the repo still works when optional package managers are missing.
- The install and cleanup shell scripts are covered by integration tests that install into a temporary `HOME`, verify the resulting files, uninstall them, and confirm unmanaged user files are preserved.

## Local Expectations

`make verify` is the closest equivalent to the repository CI contract. A change is ready to merge only after:

- `checkmake` passes
- `shellcheck` passes
- `luacheck` passes
- `pyright` passes
- unit tests pass
- integration tests pass

## CI

GitHub Actions run:

- `checkmake`
- `shellcheck`
- `luacheck`
- `pyright`
- the automated unit and integration test suite

Push-based CI runs on `main`, `dev`, and `codex/*` branches. Pull requests are also validated independently.
