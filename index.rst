dotfiles
========

This repository manages shell, tmux, and Neovim configuration as a reproducible dotfiles setup.

Documentation
-------------

* ``README.md`` for the quick-start workflow.
* ``docs/USER_GUIDE.md`` for installation, managed files, and troubleshooting.
* ``docs/TESTING.md`` for the unit/integration testing strategy and verification commands.

Automation
----------

The repository exposes a single local verification entrypoint:

.. code-block:: bash

   make verify

That command runs all linters plus the unit and integration test suites.
