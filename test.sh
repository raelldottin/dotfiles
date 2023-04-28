#!/bin/bash

runtest() {
	repo_file="$1"
	local_file="$2"
	if [[ -r "$repo_file" ]]; then
		if [[ -r "$local_file" ]]; then
			#if diff "$repo_file" "$local_file" > /dev/null; then
			#  echo "$repo_file" and "$local_file" are in sync.
			#else
			if ! diff "$repo_file" "$local_file" >/dev/null; then
				echo "$repo_file" and "$local_file" are out of sync.
			fi
			if [[ $(stat -f "%l" "$local_file") -eq 1 ]]; then
				echo "$local_file" is not a hardlink.
			fi
		else
			echo "$local_file" is not readable.
		fi
	else
		echo "$repo_file" is not readable.
	fi
}
echo "Runnings tests on configuration files:"
runtest "config/nvim/init.lua" \
	"$HOME/.config/nvim/init.lua"
runtest "config/nvim/lua/core/colorscheme.lua" \
	"$HOME/.config/nvim/lua/core/colorscheme.lua"
runtest "config/nvim/lua/core/keymaps.lua" \
	"$HOME/.config/nvim/lua/core/keymaps.lua"
runtest "config/nvim/lua/core/options.lua" \
	"$HOME/.config/nvim/lua/core/options.lua"
runtest "config/nvim/lua/core/options.lua" \
	"$HOME/.config/nvim/lua/core/options.lua"
runtest "config/nvim/lua/plugins/autopairs.lua" \
	"$HOME/.config/nvim/lua/plugins/autopairs.lua"
runtest "config/nvim/lua/plugins/ts-autotag.lua" \
	"$HOME/.config/nvim/lua/plugins/ts-autotag.lua"
runtest "config/nvim/lua/plugins/comment.lua" \
	"$HOME/.config/nvim/lua/plugins/comment.lua"
runtest "config/nvim/lua/plugins/gitsigns.lua" \
	"$HOME/.config/nvim/lua/plugins/gitsigns.lua"
runtest "config/nvim/lua/plugins/lsp/lspconfig.lua" \
	"$HOME/.config/nvim/lua/plugins/lsp/lspconfig.lua"
runtest "config/nvim/lua/plugins/lsp/mason.lua" \
	"$HOME/.config/nvim/lua/plugins/lsp/mason.lua"
runtest "config/nvim/lua/plugins/lsp/null-ls.lua" \
	"$HOME/.config/nvim/lua/plugins/lsp/null-ls.lua"
runtest "config/nvim/lua/plugins/lualine.lua" \
	"$HOME/.config/nvim/lua/plugins/lualine.lua"
runtest "config/nvim/lua/plugins/tabline.lua" \
	"$HOME/.config/nvim/lua/plugins/tabline.lua"
runtest "config/nvim/lua/plugins/mason.lua" \
	"$HOME/.config/nvim/lua/plugins/mason.lua"
runtest "config/nvim/lua/plugins/nvim-cmp.lua" \
	"$HOME/.config/nvim/lua/plugins/nvim-cmp.lua"
runtest "config/nvim/lua/plugins/nvim-tree.lua" \
	"$HOME/.config/nvim/lua/plugins/nvim-tree.lua"
runtest "config/nvim/lua/plugins/telescope.lua" \
	"$HOME/.config/nvim/lua/plugins/telescope.lua"
runtest "config/nvim/lua/plugins/treesitter.lua" \
	"$HOME/.config/nvim/lua/plugins/treesitter.lua"
runtest "config/nvim/lua/plugins-setup.lua" \
	"$HOME/.config/nvim/lua/plugins-setup.lua"
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
runtest "pylintrc" "$HOME/.pylintrc"
if which brew >/dev/null; then
	if [[ -r homebrew_installed_app.txt && "$(brew list)" == "$(cat homebrew_installed_app.txt)" ]]; then
		echo "homebrew_installed_app.txt is out of sync with repo."
	fi
fi
if which npm >/dev/null; then
	if [[ -r npm_installed_app.txt && "$(npm list -g)" == "$(cat npm_installed_app.txt)" ]]; then
		echo "npm_installed_app.txt is out of sync with repo."
	fi
fi
echo "Tests complete."
