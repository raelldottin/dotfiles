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

setup_nvim() {
  echo "Setting up Nvim configuration files and folders."

  directories=(
    "$HOME/.config/nvim"
    "$HOME/.config/nvim/lua"
    "$HOME/.config/nvim/lua/core"
    "$HOME/.config/nvim/lua/plugins"
    "$HOME/.config/nvim/lua/plugins/lsp"
  )

  files=(
    "config/nvim/init.lua"
    "config/nvim/lua/core/colorscheme.lua"
    "config/nvim/lua/core/keymaps.lua"
    "config/nvim/lua/core/options.lua"
    "config/nvim/lua/plugins/autopairs.lua"
    "config/nvim/lua/plugins/ts-autotag.lua"
    "config/nvim/lua/plugins/comment.lua"
    "config/nvim/lua/plugins/gitsigns.lua"
    "config/nvim/lua/plugins/lsp/lspconfig.lua"
    "config/nvim/lua/plugins/lsp/mason.lua"
    "config/nvim/lua/plugins/lsp/null-ls.lua"
    "config/nvim/lua/plugins/lualine.lua"
    "config/nvim/lua/plugins/tabline.lua"
    "config/nvim/lua/plugins/mason.lua"
    "config/nvim/lua/plugins/nvim-cmp.lua"
    "config/nvim/lua/plugins/nvim-tree.lua"
    "config/nvim/lua/plugins/telescope.lua"
    "config/nvim/lua/plugins/treesitter.lua"
    "config/nvim/lua/plugins-setup.lua"
    "pylintrc"
  )

  for dir in "${directories[@]}"; do
    createdirectory "$dir"
  done

  for file in "${files[@]}"; do
    linkfile "$file" "$HOME/.config/nvim/lua/plugins"
  done

  echo "Setup complete."
}

# Run the setup function
setup_nvim
