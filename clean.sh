#!/bin/bash

runclean() {
  local_file="$1"
  if rm -f "$local_file"; then
    echo "Successfully deleted $local_file"
  fi
}
	echo "Uninstalling configuration files:"
	runclean "$HOME/.config/nvim/init.lua"
  runclean "$HOME/.config/nvim/lua/r2e/core/colorscheme.lua"
	runclean "$HOME/.config/nvim/lua/r2e/core/keymaps.lua"
  runclean "$HOME/.config/nvim/lua/r2e/core/options.lua"
  runclean "$HOME/.config/nvim/lua/r2e/plugins/autopairs.lua"
  runclean "$HOME/.config/nvim/lua/r2e/plugins/comment.lua"
  runclean "$HOME/.config/nvim/lua/r2e/plugins/gitsigns.lua"
  runclean "$HOME/.config/nvim/lua/r2e/plugins/lsp/lspconfig.lua"
  runclean "$HOME/.config/nvim/lua/r2e/plugins/lsp/mason.lua"
  runclean "$HOME/.config/nvim/lua/r2e/plugins/lsp/null-ls.lua"
  runclean "$HOME/.config/nvim/lua/r2e/plugins/lualine.lua"
  runclean "$HOME/.config/nvim/lua/r2e/plugins/mason.lua"
  runclean "$HOME/.config/nvim/lua/r2e/plugins/nvim-cmp.lua"
  runclean "$HOME/.config/nvim/lua/r2e/plugins/nvim-tree.lua"
  runclean "$HOME/.config/nvim/lua/r2e/plugins/telescope.lua"
  runclean "$HOME/.config/nvim/lua/r2e/plugins/treesitter.lua"
  runclean "$HOME/.config/nvim/lua/r2e/plugins-setup.lua"
  runclean "$HOME/.hyper.js"
  runclean "$HOME/.tmux.conf"
  runclean "$HOME/.zshrc"
	if [[ -d ~/.local ]]; then
		echo "If you encounter issues, please delete the respective files in $HOME/.local"
	fi;

	echo "Uninstallation complete."
