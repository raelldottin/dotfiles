raelldottin/dotfiles v0.1.1-38
==============================

.. image:: https://github.com/raelldottin/dotfiles/actions/workflows/checkmake.yml/badge.svg
   :alt: Makefile linter
   :target: https://github.com/raelldottin/dotfiles/actions/workflows/checkmake.yml


.. image:: https://github.com/raelldottin/dotfiles/actions/workflows/shellcheck.yml/badge.svg
   :alt: Shell Script linter
   :target: https://github.com/raelldottin/dotfiles/actions/workflows/shellcheck.yml

.. image:: https://github.com/raelldottin/dotfiles/actions/workflows/luacheck.yml/badge.svg
   :alt: Lua linter
   :target: https://github.com/raelldottin/dotfiles/actions/workflows/luacheck.yml

.. image:: https://github.com/raelldottin/dotfiles/actions/workflows/pyright.yml/badge.svg
   :alt: Python linter
   :target: https://github.com/raelldottin/dotfiles/actions/workflows/pyright.yml


.. figure:: https://github.com/raelldottin/dotfiles/blob/main/PNGimage.png
   :align: center
   :alt: v0.1.1-38


Table of Contents
=================


* About :ref:`About <about>`
* Installing :ref:`Installing<installing>`
* Customizing :ref:`Customizing<customizing>`
* Uninstalling :ref:`Uninstalling<uninstalling>`
* Running tests :ref:`Running-tests<running-tests>`


.. _about:
About
=====

My dotfiles; buyers beware!

.. _installing:
Installing
==========

This will automated the homebrew installation.

.. code-block:: bash
   sudo ./homebrewsetup.sh


This will create hard links from this repo to your home folder.

.. code-block:: bash
   make


.. _customizing:
Customizing
===========

File hierarchy of the repository.

.. code-block::
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
│       │       │   ├── telescope.lua
│       │       │   └── treesitter.lua
│       │       └── plugins-setup.lua
│       └── plugin
├── darwin_tmux.conf
├── homebrew_installed_app.txt
├── homebrewsetup.sh
├── hyper.js
├── hypersetup.sh
├── linux-gnu_tmux.conf
├── nvimsetup.sh
├── test.sh
├── tmuxsetup.sh
├── zshrc
└── zshsetup.sh

13 directories, 43 files

.. _uninstalling:

Uninstalling
============

Removing dotfiles

.. code-block:: bash
       make clean

.. _running-tests:

Running tests
=============

Running tests

.. code-block:: bash
       make test
