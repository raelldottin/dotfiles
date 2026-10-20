# Testing guide

Run `make verify` before review. It executes checkmake, shellcheck, luacheck,
pyright, and the unit/integration suites.

Unit tests cover README rendering, Git metadata handling, and the managed-file
manifest. Integration tests use temporary HOME directories and repositories.
They cover:

- Installation, verification, cleanup, and preservation of unmanaged files.
- Required work identity before shell changes and private file permissions.
- Backups and repeat installation without importing personal editor/history data.
- Successful work commits and rejection of personal author/committer overrides,
  commits outside the work directory, and a wrong identity with `--no-verify`.
- Refusal to replace company Git hooks or symlinked configuration directories.
- Work roots containing spaces and preservation of locally edited Git config.
- Zsh startup that reasserts work namespaces without package upgrades.
- Explicit Brewfile invocation from a different working directory.
- An offline Lua configuration smoke check where Neovim is available.
- Read-only Atuin path resolution where the Atuin CLI is available.

CI installs Zsh so its startup test runs. Optional Neovim and Atuin probes are
skipped where those tools are unavailable; local results must say whether they ran.

No test authenticates accounts or installs Homebrew packages. Plugin download,
fresh-machine installation, employer configuration, and work account access are
separate checks on the company Mac. `make verify-install` validates installed
files and the generated work Git configuration; it does not certify every
repository's hook overrides or application account choices.

Nix CI also evaluates both personal Linux architectures (`x86_64` and `aarch64`),
the personal macOS output, and both work Mac architectures. It then builds the
work activation package on a macOS runner without
activating it. The work profile keeps Git identity out of Nix evaluation and tests
its preflight HOME gate and guard-package upgrade behavior locally.

The workflow runs when Nix definitions, their managed configuration sources
(including `pylintrc`), or the Neovim migration driver/integration checks change.
The migration check uses the pinned Nix Neovim in a disposable HOME; changing its
Python checks must not skip that runtime validation. `workflow_dispatch` allows
the same validation to run on demand. Evaluation and activation-package builds
do not establish successful activation on the company device.
