SHELL := bash

#Build all items
.PHONY: all install
all install: dependencies zsh tmux hyper nvim

#Install dependencies
.PHONY: dependencies
dependencies:
	/bin/bash ./pre-install.sh

#Setup zsh
.PHONY: zsh
zsh:
	/bin/bash ./zshsetup.sh

#Setup tmux
.PHONY: tmux
tmux:
	/bin/bash ./tmuxsetup.sh

#Setup hyper
.PHONY: hyper
hyper:
	/bin/bash ./hypersetup.sh

#Setup nvim
.PHONY: nvim
nvim:
	/bin/bash ./nvimsetup.sh

#Remove all generated files
.PHONY: clean uninstall
clean uninstall:
	/bin/bash ./clean.sh

#Run tests
.PHONY: test
test:
	/bin/bash ./test.sh
