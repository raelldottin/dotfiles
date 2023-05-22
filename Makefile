SHELL := bash

#Build all items
.PHONY: all install
all install: dependencies zsh tmux hyper nvim

#Install dependencies
.PHONY: dependencies
dependencies:
	./pre-install.sh

#Setup zsh
.PHONY: zsh
zsh:
	./zshsetup.sh

#Setup tmux
.PHONY: tmux
tmux:
	./tmuxsetup.sh

#Setup hyper
.PHONY: hyper
hyper:
	./hypersetup.sh

#Setup nvim
.PHONY: nvim
nvim:
	./nvimsetup.sh

#Remove all generated files
.PHONY: clean uninstall
clean uninstall:
	./clean.sh

#Run tests
.PHONY: test
test:
	./test.sh
