from __future__ import annotations

from pathlib import Path
import tempfile
import unittest

import dotfiles_manifest


class ResolveTmuxConfigNameTests(unittest.TestCase):
    def test_selects_linux_tmux_config(self) -> None:
        self.assertEqual(dotfiles_manifest.resolve_tmux_config_name("linux-gnu"), "linux-gnu_tmux.conf")

    def test_selects_macos_tmux_config(self) -> None:
        self.assertEqual(dotfiles_manifest.resolve_tmux_config_name("darwin24"), "darwin_tmux.conf")

    def test_rejects_unknown_operating_systems(self) -> None:
        with self.assertRaisesRegex(ValueError, "Unsupported OSTYPE"):
            dotfiles_manifest.resolve_tmux_config_name("freebsd")


class BuildManagedPathsTests(unittest.TestCase):
    def test_build_managed_paths_includes_shell_tmux_python_and_nvim_files(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir_name:
            repo_root = Path(temp_dir_name)
            (repo_root / "config" / "nvim" / "lua" / "core").mkdir(parents=True)
            (repo_root / "config" / "nvim" / "init.lua").write_text("-- init\n", encoding="utf-8")
            (repo_root / "config" / "nvim" / "lua" / "core" / "options.lua").write_text(
                "-- options\n",
                encoding="utf-8",
            )
            for file_name in ("zshrc", "linux-gnu_tmux.conf", "pylintrc"):
                (repo_root / file_name).write_text("", encoding="utf-8")

            home = repo_root / "home"
            managed_paths = dotfiles_manifest.build_managed_paths(repo_root, home, "linux-gnu")

            self.assertEqual(
                [(path.source.relative_to(repo_root).as_posix(), path.target.relative_to(home).as_posix(), path.category) for path in managed_paths],
                [
                    ("zshrc", ".zshrc", "zsh"),
                    ("linux-gnu_tmux.conf", ".tmux.conf", "tmux"),
                    ("pylintrc", ".pylintrc", "python"),
                    ("config/nvim/init.lua", ".config/nvim/init.lua", "nvim"),
                    ("config/nvim/lua/core/options.lua", ".config/nvim/lua/core/options.lua", "nvim"),
                ],
            )


if __name__ == "__main__":
    unittest.main()
