<!---
This file is auto-generate by a github hook please modify readme.template if you don't want to loose your work
-->
# raelldottin/dotfiles v0.0.1-21

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
$ make
```

This will create hard links from this repo to your home folder.

### Customizing

Repo file structure

```
.
├── .config
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
│       │       │   ├── fidget.nvim.lua
│       │       │   ├── gitsigns.lua
│       │       │   ├── lsp
│       │       │   │   ├── lspconfig.lua
│       │       │   │   ├── lspsaga.lua
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
├── .githooks
│   ├── post-commit
│   ├── pre-commit
│   └── replace_by_git_vars.py
├── .github
│   └── workflows
│       ├── checkmake.yml
│       └── shellcheck.yml
├── .gitignore
├── .hyper.js
├── .tmux.conf
├── .zprofile
├── .zshenv
├── .zshrc
├── Makefile
├── homebrew_installed_app.txt
├── readme.md
└── readme.template

13 directories, 37 files
```

### Uninstalling

```
$ make uninstall
```

### Running tests

```
$ make test
```

[![Makefile testing](https://github.com/raelldottin/dotfiles/actions/workflows/checkmake.yml/badge.svg)](https://github.com/raelldottin/dotfiles/actions/workflows/checkmake.yml)
[![Shell Script testing](https://github.com/raelldottin/dotfiles/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/raelldottin/dotfiles/actions/workflows/shellcheck.yml)
