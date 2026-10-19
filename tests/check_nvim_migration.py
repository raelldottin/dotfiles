"""Exercise the actual personal Home Manager file definition in a disposable HOME."""
from __future__ import annotations

import os
from pathlib import Path
import pwd
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def run(command: list[str], env: dict[str, str]) -> str:
    result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True, text=True, timeout=600)
    if result.returncode:
        raise RuntimeError(f"{command[0]} failed:\n{result.stdout}\n{result.stderr}")
    return result.stdout.strip()


def main() -> None:
    with tempfile.TemporaryDirectory(prefix="nvim-migration-") as temporary:
        home = Path(temporary) / "home"
        plugins = home / ".config/nvim/lua/plugins"
        plugins.mkdir(parents=True)
        obsolete = plugins / "gitsigns.lua"
        former_source = Path(temporary) / "legacy/config/nvim/lua/plugins/gitsigns.lua"
        obsolete.symlink_to(former_source)
        custom = home / ".config/nvim/user-note.txt"
        custom.write_text("preserve my existing configuration\n")
        env = {**os.environ, "DOTFILES_NVIM_TEST_HOME": str(home),
               "DOTFILES_NVIM_TEST_USER": pwd.getpwuid(os.getuid()).pw_name}
        command = ["nix", "build", "--impure", "--no-write-lock-file", "--no-link",
                   "--print-out-paths", "--file", "tests/nix/nvim-migration.nix"]
        activation = run([*command, "activation"], env)
        tools = run([*command, "tools"], env)
        isolated = {**env, "HOME": str(home), "NVIM_APPNAME": "nvim",
                    "XDG_CONFIG_HOME": str(home / ".config"),
                    "XDG_DATA_HOME": str(home / ".local/share"),
                    "XDG_STATE_HOME": str(home / ".local/state"),
                    "XDG_CACHE_HOME": str(home / ".cache"),
                    "HOME_MANAGER_BACKUP_EXT": "hm-backup"}
        backup = home / ".config/nvim.hm-backup"
        backup.mkdir()
        (backup / "earlier.txt").write_text("retain the earlier backup\n")
        conflict = subprocess.run([str(Path(activation) / "activate")], cwd=ROOT, env=isolated,
                                  capture_output=True, text=True, timeout=120)
        if conflict.returncode == 0 or not obsolete.is_symlink() or not custom.exists():
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
            if not (home / ".config/nvim").is_symlink() or obsolete.is_symlink():
                raise AssertionError("Obsolete plugin links remain in the active Neovim configuration")
            if (backup / "user-note.txt").read_text() != "preserve my existing configuration\n":
                raise AssertionError("The previous configuration was not preserved")
            if (backup / "lua/plugins/gitsigns.lua").readlink() != former_source:
                raise AssertionError("The previous plugin link was not preserved")
            run([str(Path(tools) / "bin/nvim"), "--headless", "-u", "NONE", "-i", "NONE",
                 "-l", str(probe)], isolated)
        isolated["PATH"] = str(Path(tools) / "bin") + os.pathsep + os.environ["PATH"]
        run([sys.executable, "-m", "unittest", "tests.integration.test_nvim_workflow"], isolated)
        print("Personal Neovim migration: backup preserved, obsolete imports excluded, second activation clean.")
        print("Offline language, tmux keymap, and Zsh diagnostics checks passed with pinned Neovim.")


if __name__ == "__main__":
    main()
