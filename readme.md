<!---
This file is auto-generate by a github hook please modify readme.template if you don't want to loose your work
-->
# raelldottin/dotfiles v0.0.1-36
[![Makefile testing](https://github.com/raelldottin/dotfiles/actions/workflows/checkmake.yml/badge.svg)](https://github.com/raelldottin/dotfiles/actions/workflows/checkmake.yml)
[![Shell Script testing](https://github.com/raelldottin/dotfiles/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/raelldottin/dotfiles/actions/workflows/shellcheck.yml)

[![ v0.0.1-36 ](https://github.com/raelldottin/dotfiles/blob/main/PNGimage.png)](https://github.com/raelldottin/dotfiles/blob/main/PNGimage.png)

**Table of Contents**

<!-- toc -->

- [About](#about)
  * [Installing](#installing)
  * [Customizing](#customizing)
  * [Uninstalling](#uninstalling)
  * [Running tests](#running-tests)

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

Repo file structure

```
.
├── .githooks
│   ├── post-commit
│   ├── pre-commit
│   └── replace_by_git_vars.py
├── .github
│   └── workflows
│       ├── checkmake.yml
│       └── shellcheck.yml
├── .gitignore
├── Makefile
├── clean.sh
├── config
│   └── nvim
│       ├── .gitignore
│       ├── .stylua.toml
│       ├── init.lua
│       ├── lua
│       │   └── r2e
│       │       ├── core
│       │       │   ├── colorscheme.lua
│       │       │   ├── keymaps.lua
│       │       │   └── options.lua
│       │       ├── plugins
│       │       │   ├── autopairs.lua
│       │       │   ├── comment.lua
│       │       │   ├── dap
│       │       │   ├── gitsigns.lua
│       │       │   ├── lsp
│       │       │   │   ├── lspconfig.lua
│       │       │   │   ├── mason.lua
│       │       │   │   └── null-ls.lua
│       │       │   ├── lualine.lua
│       │       │   ├── mason.lua
│       │       │   ├── nvim-cmp.lua
│       │       │   ├── nvim-tree.lua
│       │       │   ├── tabnine.lua
│       │       │   ├── telescope.lua
│       │       │   └── treesitter.lua
│       │       └── plugins-setup.lua
│       └── plugin
├── homebrew_installed_app.txt
├── homebrewsetup.sh
├── hyper.js
├── hypersetup.sh
├── nvimsetup.sh
├── readme.md
├── readme.template
├── test.sh
├── tmux.conf
├── tmuxsetup.sh
├── zshrc
└── zshsetup.sh

13 directories, 40 files
```

### Uninstalling

```
$ make clean
```

### Running tests

```
$ make test
```
