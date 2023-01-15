SHELL := bash

.PHONY: all
all: zsh tmux hyper nvim

.PHONY: zsh
zsh:
	./zshsetup.sh

.PHONY: tmux
tmux:
	./tmuxsetup.sh

.PHONY: hyper
hyper:
	./hypersetup.sh

.PHONY: nvim
nvim:
	./nvimsetup.sh

.PHONY: clean
clean:
	./clean.sh

.PHONY: test
test:
	./test.sh
