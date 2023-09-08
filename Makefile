SHELL := bash

#Build all items
.PHONY: all install
all install: dependencies zsh tmux hyper nvim

#Install dependencies
.PHONY: dependencies
dependencies:
	${SHELL} ./pre-install.sh

#Setup zsh
.PHONY: zsh
zsh:
	${SHELL} ./zshsetup.sh

#Setup tmux
.PHONY: tmux
tmux:
	${SHELL} ./tmuxsetup.sh

#Setup hyper
.PHONY: hyper
hyper:
	${SHELL} ./hypersetup.sh

#Setup nvim
.PHONY: nvim
nvim:
	${SHELL} ./nvimsetup.sh

#Remove all generated files
.PHONY: clean uninstall
clean uninstall:
	${SHELL} ./clean.sh

#Run tests
.PHONY: test
test:
	${SHELL} ./test.sh
