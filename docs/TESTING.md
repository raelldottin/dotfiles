# Testing Guide

## Philosophy

This repo follows the testing split recommended in *Unit Testing: Principles, Practices, and Patterns*:

- Unit tests cover pure logic with no filesystem or process dependency.
- Integration tests cover installer behavior against a temporary, isolated `HOME`.
- Linting stays separate so failures point directly to style/type issues instead of being hidden inside functional tests.

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

- `gitvars.py` is covered by unit tests for placeholder discovery, rendering, and Git metadata resolution.
- The README hook entrypoint is covered by an integration test that runs the actual CLI inside a temporary Git repository.
- The install and cleanup shell scripts are covered by an integration test that installs into a temporary `HOME`, verifies the resulting files, and then uninstalls them.

## CI

GitHub Actions run:

- `checkmake`
- `shellcheck`
- `luacheck`
- `pyright`
- the automated unit and integration test suite

