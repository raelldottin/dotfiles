"""Rehearse the full personal Linux module and editor migration in a CI HOME."""
from __future__ import annotations

import os
from pathlib import Path
import pwd
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tests.nix_activation import clean_environment, guard_global_profiles, private_environment, profile_snapshot, run


def main() -> None:
    if sys.platform != "linux" or os.environ.get("GITHUB_ACTIONS") != "true":
        raise RuntimeError("Run this rehearsal only on a disposable Linux GitHub Actions runner.")
    global_profiles, before_global = guard_global_profiles()
    with tempfile.TemporaryDirectory(prefix="nvim-migration-") as temporary:
        home = Path(temporary).resolve() / "home"
        plugins = home / ".config/nvim/lua/plugins"
        plugins.mkdir(parents=True)
        obsolete = plugins / "gitsigns.lua"
        former_source = Path(temporary) / "legacy/config/nvim/lua/plugins/gitsigns.lua"
        obsolete.symlink_to(former_source)
        custom = home / ".config/nvim/user-note.txt"
        custom.write_text("preserve my existing configuration\n")
        env = {**clean_environment(), "DOTFILES_NVIM_TEST_HOME": str(home),
               "DOTFILES_NVIM_TEST_USER": pwd.getpwuid(os.getuid()).pw_name}
        command = ["nix", "build", "--impure", "--no-write-lock-file", "--no-link",
                   "--print-out-paths", "--file", "tests/nix/nvim-migration.nix"]
        activation = Path(run([*command, "activation"], env, timeout=900))
        tools = activation / "home-path"
        isolated = {**private_environment(home, activation, env), "NVIM_APPNAME": "nvim",
                    "TERM": "xterm-256color"}
        originals = {home / ".zshrc": "# original shell\n", home / ".pylintrc": "# original pylint\n"}
        for path, content in originals.items():
            path.write_text(content)
        backup = home / ".config/nvim.hm-backup"
        backup.mkdir()
        (backup / "earlier.txt").write_text("retain the earlier backup\n")
        run([str(activation / "activate")], isolated, error="would be clobbered")
        if not obsolete.is_symlink() or not custom.exists():
            raise AssertionError("An existing backup conflict did not stop migration before file changes")
        if (backup / "earlier.txt").read_text() != "retain the earlier backup\n":
            raise AssertionError("The earlier backup was overwritten")
        backup.rename(home / "earlier-backup-preserved")
        probe = Path(temporary) / "check.lua"
        probe.write_text(
            'local root = vim.fn.stdpath("config") .. "/lua/plugins"\n'
            'local count = 0\n'
            'for name in vim.fs.dir(root) do\n'
            '  if name:match("%.lua$") then assert(loadfile(root .. "/" .. name)); count = count + 1 end\n'
            'end\n'
            'assert(count > 0)\n'
            'vim.cmd("qa!")\n'
        )
        for _ in range(2):
            run([str(Path(activation) / "activate")], isolated)
            for path, content in originals.items():
                if path.with_name(path.name + ".hm-backup").read_text() != content or not path.is_symlink():
                    raise AssertionError(f"Managed file or original backup missing: {path}")
            if not (home / ".config/nvim").is_symlink() or obsolete.is_symlink():
                raise AssertionError("Obsolete plugin links remain in the active Neovim configuration")
            if (backup / "user-note.txt").read_text() != "preserve my existing configuration\n":
                raise AssertionError("The previous configuration was not preserved")
            if (backup / "lua/plugins/gitsigns.lua").readlink() != former_source:
                raise AssertionError("The previous plugin link was not preserved")
            run([str(Path(tools) / "bin/nvim"), "--headless", "-u", "NONE", "-i", "NONE",
                 "-l", str(probe)], isolated)
            if profile_snapshot(global_profiles) != before_global:
                raise AssertionError("Activation changed the runner's global Nix profiles")
        run([str(tools / "bin/zsh"), "-lic",
             '[[ "$EDITOR" == nvim ]] && [[ "$(alias vi)" == "vi=nvim" ]] && '
             'command -v nvim >/dev/null'], isolated)
        socket = str(Path(temporary) / "tmux.sock")
        try:
            run([str(tools / "bin/tmux"), "-S", socket, "-f", str(home / ".tmux.conf"),
                 "new-session", "-d", "-s", "fixture"], isolated)
            prefix = run([str(tools / "bin/tmux"), "-S", socket, "show-options", "-gv", "prefix"], isolated)
            if prefix != "C-z":
                raise AssertionError(f"Managed tmux prefix did not load: {prefix}")
        finally:
            # Cleanup must not replace a useful startup/configuration failure.
            subprocess.run([str(tools / "bin/tmux"), "-S", socket, "kill-server"],
                           env=isolated, capture_output=True, timeout=30, check=False)
        isolated["PATH"] = str(Path(tools) / "bin") + os.pathsep + os.environ["PATH"]
        probe_output = run([sys.executable, "tests/check_pinned_tools.py", str(tools / "bin")], isolated)
        if profile_snapshot(global_profiles) != before_global:
            raise AssertionError("Tool probes changed the runner's global Nix profiles")
        print(probe_output, flush=True)
        print("Personal Neovim migration: backup preserved, obsolete imports excluded, second activation clean.")
        print("Offline language, tmux keymap, and Zsh diagnostics checks passed with pinned Neovim.")
        print("Pinned work editor and Atuin probes passed with no skips.")
        print("Full personal Linux module: two activations, shell/tmux smoke checks, managed backups and private profiles passed.")


if __name__ == "__main__":
    main()
