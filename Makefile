SHEL := bash

.PHONY: all
all: zsh tmux iterm nvim

.PHONY: zsh
zsh:
	echo "Setting up Zsh configuration file."; \
	rm -f ~/.zshrc; \
	ln .zshrc ~/.zshrc; \
	echo "Zsh configuration complete."

.PHONY: tmux
tmux:
	echo "Setting up tmux configuration file."; \
	rm -f ~/.tmux.conf; \
	ln .tmux.conf ~/.tmux.conf; \
	echo "Tmux configuration complete."

.PHONY: iterm
iterm:
	echo "Setting up iTerm colorscheme configuration file."; \
	open coolnight.itermcolors; \
	echo "iTerm configuration complete."

.PHONY: nvim
nvim:
	echo "Setting up Nvim configuration files and folders."; \
	if [[ -d ~/.local ]]; then \
		echo "Deleting ~/.local"; \
		rm -fr ~/.local; \
	fi; \
	if [[ ! -d ~/.config ]]; then \
		echo "Creating ~/.config"; \
		mkdir ~/.config; \
	fi; \
	if [[ ! -d ~/.config/nvim ]]; then \
		echo "Creating ~/.config/nvim"; \
		mkdir ~/.config/nvim; \
	fi; \
	if [[ ! -d ~/.config/nvim/lua ]]; then \
		echo "Creating ~/.config/nvim/lua"; \
		mkdir ~/.config/nvim/lua; \
	fi; \
	if [[ ! -d ~/.config/nvim/lua/r2e ]]; then \
		echo "Creating ~/.config/nvim/lua/r2e"; \
		mkdir ~/.config/nvim/lua/r2e; \
	fi; \
	if [[ ! -d ~/.config/nvim/lua/r2e/core ]]; then \
		echo "Creating ~/.config/nvim/lua/r2e/core"; \
		mkdir ~/.config/nvim/lua/r2e/core; \
	fi; \
	if [[ ! -d ~/.config/nvim/lua/r2e/plugins ]]; then \
		echo "Creating ~/.config/nvim/lua/r2e/plugins"; \
		mkdir ~/.config/nvim/lua/r2e/plugins; \
	fi; \
	if [[ -f ~/.config/nvim/init.lua ]]; then \
		echo "Deleting ~/.config/nvim/init.lua"; \
		rm -f ~/.config/nvim/init.lua; \
	fi; \
	echo "Linking .config/nvim/init.lua to ~/.config/nvim"; \
	ln .config/nvim/init.lua ~/.config/nvim; \
	echo "Updating ~/.config/nvim/init.lua"; \
	sed "s/josean/r2e/g" ~/.config/nvim/init.lua > ~/.config/nvim/init.lua.new && mv ~/.config/nvim/init.lua.new ~/.config/nvim/init.lua; \
	if [[ -f ~/.config/nvim/lua/r2e/core/colorscheme.lua ]]; then \
		echo "Deleting ~/.config/nvim/lua/r2e/core/colorscheme.lua"; \
		rm -f ~/.config/nvim/lua/r2e/core/colorscheme.lua; \
	fi; \
	echo "Linking .config/nvim/lua/josean/core/colorscheme.lua to .config/nvim/lua/r2e/core"; \
	ln .config/nvim/lua/josean/core/colorscheme.lua ~/.config/nvim/lua/r2e/core; \
	if [[ -f ~/.config/nvim/ljua/r2e/core/keymaps.lua ]]; then \
		echo "Deleting ~/.config/nvim/lua/r2e/core/keymaps.lua"; \
		rm -f ~/.config/nvim/lua/r2e/core/keymaps.lua; \
	fi; \
	echo "Linking .config/nvim/lua/josean/core/keymaps.lua to ~/.config/nvim/lua/r2e/core"; \
	ln .config/nvim/lua/josean/core/keymaps.lua ~/.config/nvim/lua/r2e/core; \
	if [[ -f ~/.config/nvim/lua/r2e/core/options.lua ]]; then \
		echo "Deleting ~/.config/nvim/lua/r2e/core/options.lua"; \
		rm -f ~/.config/nvim/lua/r2e/core/options.lua; \
	fi; \
	#echo "Linking .config/nvim/lua/josean/core/options.lua to ~/.config/nvim/lua/r2e/core"; \
	if [[ -f ~/.config/nvim/.stylua.toml ]]; then \
		echo "Deleting ~/.config/nvim/.stylua.toml"; \
		rm -f ~/.config/nvim/.stylua.toml; \
	fi; \ 
	echo "Linking .config/nvim/.stylua.toml to ~/.config/nvim"; \
	ln .config/nvim/.stylua.toml ~/.config/nvim; \
	if [[ -f ~/.config/nvim/lua/r2e/plugins-setup.lua ]]; then \
		rm -f ~/.config/nvim/lua/r2e/plugins-setup.lua; \
	fi; \
	ln .config/nvim/lua/josean/core/options.lua ~/.config/nvim/lua/r2e/core; \
	echo "Linking .config/nvim/lua/josean/plugins-setup.lua to ~/.config/nvim/lua/r2e"; \
	ln .config/nvim/lua/josean/plugins-setup.lua ~/.config/nvim/lua/r2e; \
	echo "Copying the plugins."
	while IFS=  read -r -d $'\n'; do \
		ls -l "~/$REPLY"; \
	done < <(ls ~/); \
	echo "Nvim configuration complete."

.PHONY: clean
clean:
	echo "Removing configuration files and folders"; \
	rm -f ~/.zshrc; \
	rm -f ~/.tmux.conf; \
	rm -fr ~/.config/nvim; \
	echo "Configuration files and folders removal complete."

.PHONY: test
test:
	echo "Checking if configuration files and folders setup"; \
	echo "Tests complete."
