# Neovim workflow

The recommended baseline is the captured LazyVim configuration, with focused
support for Python, Swift, Rust, Bash/POSIX shell, Zsh, and tmux navigation.
It preserves the existing LazyVim key conventions, completion, picker, explorer,
Git signs, sessions, and date in the status line. The plugin lockfile pins all
plugins, including the added vim-tmux-navigator bridge.

## Why this configuration

| History | What it provides | Decision |
| --- | --- | --- |
| Custom configuration through `caea484` | Individually maintained LSP, completion, Telescope, file-tree, and formatter modules | Useful history, but it carries modules removed by the current migration. |
| `602738c`, March 13, 2026 | A modernization of that custom stack, including Conform and revised LSP setup | Keep its preference for maintained formatters rather than restoring the entire alternative stack. |
| Captured LazyVim in `e7c4269` / `44f688b` | The active configuration and plugin pins match the installed Mac's editor | Use this as the base and add only the requested workflow support. |

The installed example plugin file returns an empty specification. Its sample
language/plugin additions are inactive and are not requirements to copy.
The upstream starter license remains in `config/nvim/LICENSE`.

## Languages

| Files | Language support | Formatting / checking |
| --- | --- | --- |
| Python | Pyright plus Ruff diagnostics; Ruff hover yields to Pyright | Ruff format |
| Swift | SourceKit-LSP through the selected Xcode toolchain on macOS | Official Swift 6+ formatter through `xcrun swift format` |
| Rust | rust-analyzer and Cargo tooling | rustfmt, using the project's Cargo edition |
| Bash / POSIX shell | bash-language-server and ShellCheck | shfmt |
| Zsh | Native Zsh syntax highlighting and real `zsh -n` diagnostics | No Bash formatter or Bash language server is applied to Zsh |

The Nix profiles and curated Brewfile provide the Python, Rust, and shell tools.
The declared servers use those executables rather than installing duplicates
with Mason. Swift requires an approved Xcode/Swift toolchain; use
`xcode-select` to select the intended toolchain. On Linux, Swift support uses a
separately provisioned `sourcekit-lsp` and Swift 6+ toolchain.

## Navigation

The tmux prefix remains **Ctrl-z**. **Ctrl-h/j/k/l** selects a neighboring
Neovim window and crosses to the neighboring tmux pane at the edge.
**Ctrl-\\** selects the previous window or pane. The Neovim bridge is pinned
and complements the existing tmux-side navigator plugin. LazyVim's normal
leader-key workflow remains available; no wholesale legacy keymap import is
performed.

## Safe migration and state

The personal Nix profile owns `~/.config/nvim` as one directory link.
On first activation, the existing directory is preserved as
`~/.config/nvim.hm-backup`. This retains custom files and old links while
keeping obsolete plugin modules out of the active import path. An existing
backup conflict stops activation for review; it is not silently overwritten.

The work profile uses `~/.config/nvim-work`, with `NVIM_APPNAME=nvim-work`
and separate XDG state/data/cache directories. Use `nvim` from the managed
work shell; a graphical launcher needs the same environment. Personal caches
and sessions are not imported into work state.

Both profiles keep the runtime Lazy lockfile in Neovim's writable state
directory, seeded from the captured lockfile. A changed captured lockfile
refreshes that seed; deliberate runtime updates survive ordinary restarts.
First launch downloads missing pinned plugins. Use `:Lazy restore` to restore
the selected runtime pins. Automatic update checking remains disabled.

## Verification

The offline tests exercise language/formatter selection, navigation command
dispatch, and actual Zsh diagnostics without executing the checked script.
A private tmux/Neovim runtime check confirmed navigation within Neovim and
across pane boundaries with the pinned bridge.

The Nix workflow runs `tests/check_nvim_migration.py` against the actual
personal file definition in a disposable HOME. It verifies full-directory
backup, exclusion of obsolete plugin links, and a clean second activation.
This does not activate the profile on the real Mac or certify every language
server's project-specific behavior.
