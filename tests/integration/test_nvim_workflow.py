from __future__ import annotations

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


@unittest.skipUnless(shutil.which("nvim"), "Neovim is required for workflow checks")
class NeovimWorkflowTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.home = Path(self.temporary.name)

    def run_lua(self, code: str) -> None:
        script = self.home / "check.lua"
        script.write_text('vim.opt.rtp:prepend(vim.env.CONFIG_ROOT)\n' + code + '\nvim.cmd("qa!")\n')
        env = {**os.environ, "HOME": str(self.home), "CONFIG_ROOT": str(ROOT / "config/nvim"),
               "XDG_CONFIG_HOME": str(self.home / "config"),
               "XDG_DATA_HOME": str(self.home / "data"),
               "XDG_STATE_HOME": str(self.home / "state"),
               "XDG_CACHE_HOME": str(self.home / "cache"), "NVIM_APPNAME": "nvim-fixture"}
        result = subprocess.run(["nvim", "--headless", "--clean", "-u", "NONE", "-i", "NONE", "-l", str(script)],
                                env=env, capture_output=True, text=True, timeout=20)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_requested_languages_have_tools_without_formatting_zsh_as_bash(self) -> None:
        self.run_lua(r'''
local specs = dofile(vim.env.CONFIG_ROOT .. "/lua/plugins/workflow.lua")
local by_name = {}
for _, spec in ipairs(specs) do by_name[spec[1]] = spec end
local servers = by_name["neovim/nvim-lspconfig"].opts.servers
for _, name in ipairs({ "pyright", "ruff", "sourcekit", "rust_analyzer", "bashls" }) do
  assert(servers[name] and servers[name].mason == false)
end
assert(not vim.tbl_contains(servers.bashls.filetypes, "zsh"))
local options = {formatters_by_ft={zsh={"shfmt"}}}
by_name["stevearc/conform.nvim"].opts(nil, options)
for filename, formatter in pairs({["app.py"]="ruff_format", ["App.swift"]="swift", ["main.rs"]="rustfmt", ["script.sh"]="shfmt"}) do
  local ft = vim.filetype.match({filename=filename})
  assert(options.formatters_by_ft[ft][1] == formatter)
end
assert(vim.filetype.match({filename=".zshrc"}) == "zsh")
assert(#options.formatters_by_ft.zsh == 0)
local client = {server_capabilities={hoverProvider=true}}
servers.ruff.on_attach(client)
assert(client.server_capabilities.hoverProvider == false)
''')

    def test_tmux_keys_dispatch_the_expected_navigation_commands(self) -> None:
        self.run_lua(r'''
local spec = dofile(vim.env.CONFIG_ROOT .. "/lua/plugins/workflow.lua")[1]
local last
for _, name in ipairs(spec.cmd) do
  vim.api.nvim_create_user_command(name, function() last = name end, {})
end
for _, mapping in ipairs(spec.keys) do vim.keymap.set("n", mapping[1], mapping[2]) end
for key, name in pairs({["<C-h>"]="Left", ["<C-j>"]="Down", ["<C-k>"]="Up", ["<C-l>"]="Right", ["<C-\\>"]="Previous"}) do
  last = nil
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, false, true), "xt", false)
  assert(last == "TmuxNavigate" .. name, key)
end
''')

    @unittest.skipUnless(shutil.which("zsh"), "Zsh is required for real syntax diagnostics")
    def test_zsh_linter_uses_real_syntax_diagnostics_without_running_the_script(self) -> None:
        script = self.home / "fixture.zsh"
        marker = self.home / "must-not-run"
        script.write_text(f'touch "{marker}"\nprint )\n')
        self.run_lua(r'''
local spec = require("config.zsh_lint")
local filename = vim.env.HOME .. "/fixture.zsh"
local result = vim.system({spec.cmd, spec.args[1], filename}, {text=true}):wait()
assert(result.code ~= 0)
local diagnostics = spec.parser(result.stderr)
assert(#diagnostics > 0 and diagnostics[1].lnum == 1)
assert(diagnostics[1].severity == vim.diagnostic.severity.ERROR)
''')
        self.assertFalse(marker.exists())


if __name__ == "__main__":
    unittest.main()
