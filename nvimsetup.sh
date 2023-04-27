#!/bin/bash

createdirectory() {
	local_directory="$1"
	if [[ ! -d "$local_directory" ]]; then
		echo "Creating $local_directory"
		mkdir -p "$local_directory"
	fi
}

linkfile() {
	repo_file="$1"
	local_directory="$2"
	if ln -fn "$repo_file" "$local_directory"; then
		echo "Successfully linked $repo_file to $local_directory"
	fi
}
echo "Setting up Nvim configuration files and folders."

createdirectory "$HOME/.config"
createdirectory "$HOME/.nvim"
createdirectory "$HOME/.config/nvim/lua"
createdirectory "$HOME/.config/nvim/lua"
createdirectory "$HOME/.config/nvim/lua/core"
createdirectory "$HOME/.config/nvim/lua/plugins"
createdirectory "$HOME/.config/nvim/lua/plugins/lsp"

linkfile "config/nvim/init.lua" \
	"$HOME/.config/nvim"
linkfile "config/nvim/lua/core/colorscheme.lua" \
	"$HOME/.config/nvim/lua/core"
linkfile "config/nvim/lua/core/keymaps.lua" \
	"$HOME/.config/nvim/lua/core"
linkfile "config/nvim/lua/core/options.lua" \
	"$HOME/.config/nvim/lua/core"
linkfile "config/nvim/lua/plugins/autopairs.lua" \
	"$HOME/.config/nvim/lua/plugins"
linkfile "config/nvim/lua/plugins/ts-autotag.lua" \
	"$HOME/.config/nvim/lua/plugins"
linkfile "config/nvim/lua/plugins/comment.lua" \
	"$HOME/.config/nvim/lua/plugins"
linkfile "config/nvim/lua/plugins/gitsigns.lua" \
	"$HOME/.config/nvim/lua/plugins"
linkfile "config/nvim/lua/plugins/lsp/lspconfig.lua" \
	"$HOME/.config/nvim/lua/plugins/lsp"
linkfile "config/nvim/lua/plugins/lsp/mason.lua" \
	"$HOME/.config/nvim/lua/plugins/lsp"
linkfile "config/nvim/lua/plugins/lsp/null-ls.lua" \
	"$HOME/.config/nvim/lua/plugins/lsp"
linkfile "config/nvim/lua/plugins/lualine.lua" \
	"$HOME/.config/nvim/lua/plugins"
linkfile "config/nvim/lua/plugins/tabline.lua" \
	"$HOME/.config/nvim/lua/plugins"
linkfile "config/nvim/lua/plugins/mason.lua" \
	"$HOME/.config/nvim/lua/plugins"
linkfile "config/nvim/lua/plugins/nvim-cmp.lua" \
	"$HOME/.config/nvim/lua/plugins"
linkfile "config/nvim/lua/plugins/nvim-tree.lua" \
	"$HOME/.config/nvim/lua/plugins"
linkfile "config/nvim/lua/plugins/telescope.lua" \
	"$HOME/.config/nvim/lua/plugins"
linkfile "config/nvim/lua/plugins/treesitter.lua" \
	"$HOME/.config/nvim/lua/plugins"
linkfile "config/nvim/lua/plugins-setup.lua" \
	"$HOME/.config/nvim/lua"

echo "Setup complete."
