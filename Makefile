SHELL := bash
PYTHON ?= python3
CHECKMAKE ?= checkmake
LUACHECK ?= luacheck
PYRIGHT ?= pyright
SHELLCHECK ?= shellcheck

.PHONY: all install bootstrap dependencies hooks zsh tmux nvim clean uninstall
.PHONY: lint lint-make lint-shell lint-lua lint-python
.PHONY: test unit-test integration-test verify verify-install

# Build all managed dotfiles.
all: install

# Install the managed dotfiles into the current HOME directory.
install: zsh tmux nvim

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
	${SHELLCHECK} --severity=style *.sh .githooks/pre-commit .githooks/post-commit lib/*.sh

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

# Run the full local verification pipeline.
verify: lint test
