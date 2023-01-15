SHELL := bash

.PHONY: all
all: zsh tmux hyper nvim

.PHONY: zsh
zsh:
	echo "Setting up Zsh configuration file."; \
	ln zshrc "$HOME"/.zshrc; \
	echo "Zsh configuration complete."

.PHONY: tmux
tmux:
	echo "Setting up tmux configuration file."; \
	ln tmux.conf "$HOME"/.tmux.conf; \
	echo "Tmux configuration complete."

hyper:
	echo "Setting up Hyper configuration file."; \
	ln hyper.js "$HOME"/.hyper.js; \
	echo "Hyper configuration complete."

.PHONY: nvim
nvim:
	./nvimsetup.sh

.PHONY: clean
clean:
	./clean.sh

.PHONY: test
test:
	./test.sh
