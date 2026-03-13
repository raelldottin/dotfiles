from __future__ import annotations

from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]


class InstallScriptsIntegrationTests(unittest.TestCase):
    def test_install_verify_and_clean_cycle_succeeds_in_temporary_home(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir_name:
            temp_root = Path(temp_dir_name)
            repo_root = temp_root / "repo"
            home_root = temp_root / "home"

            shutil.copytree(
                ROOT,
                repo_root,
                ignore=shutil.ignore_patterns(".git", "__pycache__", ".DS_Store", ".pytest_cache"),
            )
            home_root.mkdir()
            (home_root / ".oh-my-zsh").mkdir()

            env = os.environ.copy()
            env["HOME"] = str(home_root)
            env["OSTYPE"] = "linux-gnu"
            env["DOTFILES_SKIP_HOMEBREW_SETUP"] = "1"
            env["DOTFILES_SKIP_OH_MY_ZSH_INSTALL"] = "1"
            env["DOTFILES_SKIP_TMUX_PLUGIN_INSTALL"] = "1"

            for script_name in ("pre-install.sh", "zshsetup.sh", "tmuxsetup.sh", "nvimsetup.sh", "test.sh"):
                subprocess.run(["bash", script_name], cwd=repo_root, env=env, check=True)

            self.assertTrue((home_root / ".zshrc").exists())
            self.assertTrue((home_root / ".tmux.conf").exists())
            self.assertTrue((home_root / ".config" / "nvim" / "init.lua").exists())
            self.assertTrue((home_root / ".pylintrc").exists())

            subprocess.run(["bash", "clean.sh"], cwd=repo_root, env=env, check=True)

            self.assertFalse((home_root / ".zshrc").exists())
            self.assertFalse((home_root / ".tmux.conf").exists())
            self.assertFalse((home_root / ".pylintrc").exists())


if __name__ == "__main__":
    unittest.main()
