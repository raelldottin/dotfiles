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
	if ln "$repo_file" "$local_directory"; then 
		echo "Successfully linked $repo_file to $local_directory"
	fi
}
echo "Setting up Nvim configuration files and folders."; \

createdirectory "$HOME/.config"
createdirectory "$HOME/.nvim"
createdirectory "$HOME/.config/nvim/lua"
createdirectory "$HOME/.config/nvim/lua/r2e"
createdirectory "$HOME/.config/nvim/lua/r2e/core"
createdirectory "$HOME/.config/nvim/lua/r2e/plugins"
createdirectory "$HOME/.config/nvim/lua/r2e/plugins/lsp"

linkfile "config/nvim/init.lua" \
  "$HOME/.config/nvim"
linkfile "config/nvim/lua/r2e/core/colorscheme.lua" \
  "$HOME/.config/nvim/lua/r2e/core"
linkfile "config/nvim/lua/r2e/core/keymaps.lua" \
  "$HOME/.config/nvim/lua/r2e/core"
linkfile "config/nvim/lua/r2e/core/options.lua" \
  "$HOME/.config/nvim/lua/r2e/core"
linkfile "config/nvim/lua/r2e/plugins/autopairs.lua" \
  "$HOME/.config/nvim/lua/r2e/plugins"
linkfile "config/nvim/lua/r2e/plugins/comment.lua" \
  "$HOME/.config/nvim/lua/r2e/plugins"
linkfile "config/nvim/lua/r2e/plugins/gitsigns.lua" \
  "$HOME/.config/nvim/lua/r2e/plugins"
linkfile "config/nvim/lua/r2e/plugins/lsp/lspconfig.lua" \
  "$HOME/.config/nvim/lua/r2e/plugins/lsp"
linkfile "config/nvim/lua/r2e/plugins/lsp/mason.lua" \
  "$HOME/.config/nvim/lua/r2e/plugins/lsp"
linkfile "config/nvim/lua/r2e/plugins/lsp/null-ls.lua" \
  "$HOME/.config/nvim/lua/r2e/plugins/lsp"
linkfile "config/nvim/lua/r2e/plugins/lualine.lua" \
  "$HOME/.config/nvim/lua/r2e/plugins"
linkfile "config/nvim/lua/r2e/plugins/mason.lua" \
  "$HOME/.config/nvim/lua/r2e/plugins"
linkfile "config/nvim/lua/r2e/plugins/nvim-cmp.lua" \
  "$HOME/.config/nvim/lua/r2e/plugins"
linkfile "config/nvim/lua/r2e/plugins/nvim-tree.lua" \
  "$HOME/.config/nvim/lua/r2e/plugins"
linkfile "config/nvim/lua/r2e/plugins/telescope.lua" \
  "$HOME/.config/nvim/lua/r2e/plugins"
linkfile "config/nvim/lua/r2e/plugins/treesitter.lua" \
  "$HOME/.config/nvim/lua/r2e/plugins"
linkfile "config/nvim/lua/r2e/plugins-setup.lua" \
  "$HOME/.config/nvim/lua/r2e"

echo "Setup complete."
