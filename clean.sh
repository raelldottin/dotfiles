#!/bin/bash

runclean() {
	local_file="$1"
	if rm -f "$local_file"; then
		echo "Successfully deleted $local_file"
	fi
}
echo "Uninstalling configuration files:"
runclean "$HOME/.config/nvim/init.lua"
runclean "$HOME/.config/nvim/lua/core/colorscheme.lua"
runclean "$HOME/.config/nvim/lua/core/keymaps.lua"
runclean "$HOME/.config/nvim/lua/core/options.lua"
runclean "$HOME/.config/nvim/lua/plugins/autopairs.lua"
runclean "$HOME/.config/nvim/lua/plugins/ts-autotag.lua"
runclean "$HOME/.config/nvim/lua/plugins/comment.lua"
runclean "$HOME/.config/nvim/lua/plugins/gitsigns.lua"
runclean "$HOME/.config/nvim/lua/plugins/lsp/lspconfig.lua"
runclean "$HOME/.config/nvim/lua/plugins/lsp/mason.lua"
runclean "$HOME/.config/nvim/lua/plugins/lsp/null-ls.lua"
runclean "$HOME/.config/nvim/lua/plugins/lualine.lua"
runclean "$HOME/.config/nvim/lua/plugins/mason.lua"
runclean "$HOME/.config/nvim/lua/plugins/nvim-cmp.lua"
runclean "$HOME/.config/nvim/lua/plugins/nvim-tree.lua"
runclean "$HOME/.config/nvim/lua/plugins/telescope.lua"
runclean "$HOME/.config/nvim/lua/plugins/treesitter.lua"
runclean "$HOME/.config/nvim/lua/plugins-setup.lua"
runclean "$HOME/.hyper.js"
runclean "$HOME/.tmux.conf"
runclean "$HOME/.zshrc"
if [[ -d ~/.local ]]; then
	echo "If you encounter issues, please delete the respective files in $HOME/.local"
fi

echo "Uninstallation complete."
