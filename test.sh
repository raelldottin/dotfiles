#!/bin/bash

runtest() {
  repo_file="$1"
  local_file="$2"
  if [[ -r "$repo_file" ]]; then
    if [[ ! -e "$local_file" ]]; then
      if [[ $(diff "$repo_file" "$local_file") ]]; then 
        echo "$local_file is out of sync with repo."
      fi
    fi
  else
    echo "$repo_file doesn't exists."
  fi
}
	echo "Runnings tests on configuration files:"; \
	runtest "config/nvim/init.lua" \
    "$HOME/.config/nvim/init.lua"
  runtest "config/nvim/lua/r2e/core/colorscheme.lua" \
    "$HOME/.config/nvim/lua/r2e/core/colorscheme.lua"
	runtest "config/nvim/lua/r2e/core/keymaps.lua" \
    "$HOME/.config/nvim/lua/r2e/core/keymaps.lua"
  runtest "config/nvim/lua/r2e/core/options.lua" \
    "$HOME/.config/nvim/lua/r2e/core/options.lua"
  runtest "config/nvim/lua/r2e/core/options.lua" \
    "$HOME/.config/nvim/lua/r2e/core/options.lua"
  runtest "config/nvim/lua/r2e/plugins/autopairs.lua" \
    "$HOME/.config/nvim/lua/r2e/plugins/autopairs.lua"
  runtest "config/nvim/lua/r2e/plugins/comment.lua" \
    "$HOME/.config/nvim/lua/r2e/plugins/comment.lua"
  runtest "config/nvim/lua/r2e/plugins/gitsigns.lua" \
    "$HOME/.config/nvim/lua/r2e/plugins/gitsigns.lua"
  runtest "config/nvim/lua/r2e/plugins/lsp/lspconfig.lua" \
    "$HOME/.config/nvim/lua/r2e/plugins/lsp/lspconfig.lua"
  runtest "config/nvim/lua/r2e/plugins/lsp/mason.lua" \
    "$HOME/.config/nvim/lua/r2e/plugins/lsp/mason.lua"
  runtest "config/nvim/lua/r2e/plugins/lsp/null-ls.lua" \
    "$HOME/.config/nvim/lua/r2e/plugins/lsp/null-ls.lua"
  runtest "config/nvim/lua/r2e/plugins/lualine.lua" \
    "$HOME/.config/nvim/lua/r2e/plugins/lualine.lua"
  runtest "config/nvim/lua/r2e/plugins/mason.lua" \
    "$HOME/.config/nvim/lua/r2e/plugins/mason.lua"
  runtest "config/nvim/lua/r2e/plugins/nvim-cmp.lua" \
    "$HOME/.config/nvim/lua/r2e/plugins/nvim-cmp.lua"
  runtest "config/nvim/lua/r2e/plugins/nvim-tree.lua" \
    "$HOME/.config/nvim/lua/r2e/plugins/nvim-tree.lua"
  runtest "config/nvim/lua/r2e/plugins/telescope.lua" \
    "$HOME/.config/nvim/lua/r2e/plugins/telescope.lua"
  runtest "config/nvim/lua/r2e/plugins/treesitter.lua" \
    "$HOME/.config/nvim/lua/r2e/plugins/treesitter.lua"
  runtest "config/nvim/lua/r2e/plugins-setup.lua" \
    "$HOME/.config/nvim/lua/r2e/plugins-setup.lua"
  runtest "hyper.js" "$HOME/.hyper.js"
  case "$OSTYPE" in
    linux-gnu)
      tmux_conf="linux-gnu_tmux.conf"
      ;;
    darwin*)
      tmux_conf="darwin_tmux.conf"
      ;;
    *)
      echo "Unable to determine operating system"
      ;;
esac
  runtest "$tmux_conf" "$HOME/.tmux.conf"
  runtest "zshrc" "$HOME/.zshrc"
  if [[ "$(brew list > homebrew_installed_app.txt)" == "$(cat homebrew_installed_app.txt)" ]]; then
    echo "homebrew_installed_app.txt is out of sync with repo."
  fi
	echo "Tests complete."
