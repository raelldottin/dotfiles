SHELL := bash
PYTHON ?= python3
CHECKMAKE ?= checkmake
LUACHECK ?= luacheck
PYRIGHT ?= pyright
SHELLCHECK ?= shellcheck

.PHONY: all install install-work bootstrap dependencies hooks zsh tmux nvim clean uninstall snapshot
.PHONY: lint lint-make lint-shell lint-lua lint-python
.PHONY: test unit-test integration-test verify verify-install
.PHONY: vm-tools vm-base vm-test-personal vm-test-work

# Build all managed dotfiles.
all: install

# Install the managed dotfiles into the current HOME directory.
install: install-work

# Apply only on the company Mac with an explicitly supplied work identity.
install-work:
	${SHELL} ./zshsetup.sh
	${SHELL} ./tmuxsetup.sh
	${SHELL} ./nvimsetup.sh

# Refresh observational package inventories only when explicitly requested.
snapshot:
	${SHELL} ./snapshot.sh

# Bootstrap workstation dependencies explicitly.
bootstrap dependencies:
	${SHELL} ./pre-install.sh

# Configure the shared repository git hooks.
hooks:
	git config core.hooksPath .githooks

# Setup zsh.
zsh:
	${SHELL} ./zshsetup.sh

# Setup tmux.
tmux:
	${SHELL} ./tmuxsetup.sh

# Setup nvim.
nvim:
	${SHELL} ./nvimsetup.sh

# Remove all managed files.
clean:
	${SHELL} ./clean.sh

uninstall: clean

# Run every linter used by this repo.
lint: lint-make lint-shell lint-lua lint-python

lint-make:
	${CHECKMAKE} Makefile

lint-shell:
	${SHELLCHECK} --severity=style *.sh .githooks/pre-commit .githooks/prepare-commit-msg .githooks/pre-rebase .githooks/post-commit lib/*.sh vm/*.sh vm/guest/*.sh

lint-lua:
	${LUACHECK} config/nvim

lint-python:
	${PYRIGHT}

# Run all automated tests.
test: unit-test integration-test

unit-test:
	${PYTHON} -m unittest discover -s tests/unit -t .

integration-test:
	${PYTHON} -m unittest discover -s tests/integration -t .

# Verify an already-installed HOME directory matches this repo.
verify-install:
	${SHELL} ./test.sh
	${PYTHON} ./workstation.py verify

# Run the full local verification pipeline.
verify: lint test

# Install Tart and Packer for the VM tests (docs/VM_TESTING.md).
vm-tools:
	${SHELL} ./vm/install-tools.sh

# Build the macOS base image that the VM tests clone.
vm-base:
	${SHELL} ./vm/build-base.sh

# Rehearse the personal nix-darwin activation in a disposable VM.
vm-test-personal:
	${SHELL} ./vm/run-test.sh personal

# Rehearse the work Home Manager activation in a disposable VM.
vm-test-work:
	${SHELL} ./vm/run-test.sh work
