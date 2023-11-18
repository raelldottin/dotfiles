<!---
This file is auto-generate by a github hook please modify README.template if you don't want to loose your work
-->
# raelldottin/dotfiles v0.2.0-115
[![Makefile Linter](https://github.com/raelldottin/dotfiles/actions/workflows/checkmake.yml/badge.svg)](https://github.com/raelldottin/dotfiles/actions/workflows/checkmake.yml)
[![Shell Script Linter](https://github.com/raelldottin/dotfiles/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/raelldottin/dotfiles/actions/workflows/shellcheck.yml)
[![Lua Linter](https://github.com/raelldottin/dotfiles/actions/workflows/luacheck.yml/badge.svg)](https://github.com/raelldottin/dotfiles/actions/workflows/luacheck.yml)
[![Python Linter](https://github.com/raelldottin/dotfiles/actions/workflows/pyright.yml/badge.svg)](https://github.com/raelldottin/dotfiles/actions/workflows/pyright.yml)

[![ v0.2.0-115 ](https://github.com/raelldottin/dotfiles/blob/main/PNGimage.png)](https://github.com/raelldottin/dotfiles/blob/main/PNGimage.png)

**Table of Contents**

<!-- toc -->

- [About](#about)
- [Installing](#installing)
- [Customizing](#customizing)
- [Uninstalling](#uninstalling)
- [Running tests](#running-tests)

<!-- tocstop -->

## About

My dotfiles; buyers beware!

### Installing
```
# ./homebrewsetup.sh
```

This will automated the homebrew installation.

```
$ make
```

This will create hard links from this repo to your home folder.

### Customizing

Repo file hierarchy

```
.
├── .githooks
│   ├── post-commit
│   ├── pre-commit
│   └── replace_by_git_vars.py
├── .github
│   └── workflows
│       ├── checkmake.yml
│       ├── luacheck.yml
│       ├── pyright.yml
│       └── shellcheck.yml
├── .gitignore
├── Makefile
├── PNGimage.png
├── README.md
├── README.template
├── clean.sh
├── config
│   └── nvim
│       ├── .gitignore
│       ├── .stylua.toml
│       ├── init.lua
│       └── lua
│           ├── core
│           │   ├── colorscheme.lua
│           │   ├── keymaps.lua
│           │   └── options.lua
│           ├── plugins
│           │   ├── gitsigns.lua
│           │   ├── lsp
│           │   │   ├── lspconfig.lua
│           │   │   ├── mason.lua
│           │   │   └── null-ls.lua
│           │   ├── lualine.lua
│           │   ├── mason.lua
│           │   ├── nvim-cmp.lua
│           │   ├── nvim-tree.lua
│           │   ├── telescope.lua
│           │   └── treesitter.lua
│           └── plugins-setup.lua
├── darwin_tmux.conf
├── homebrew_installed_app.txt
├── homebrewsetup.sh
├── index.rst
├── linux-gnu_tmux.conf
├── npm_installed_app.txt
├── nvimsetup.sh
├── pre-install.sh
├── pylintrc
├── test.sh
├── tmuxsetup.sh
├── zshrc
└── zshsetup.sh

10 directories, 43 files
```

### Uninstalling

```
$ make clean
```

### Running tests

```
$ make test
```
