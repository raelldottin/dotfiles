from __future__ import annotations

from pathlib import Path
import os
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]


class GitHookIntegrationTests(unittest.TestCase):
    def test_readme_generator_cli_renders_template_and_stages_output(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir_name:
            repo_root = Path(temp_dir_name)
            (repo_root / ".githooks").mkdir()

            shutil.copy2(ROOT / "gitvars.py", repo_root / "gitvars.py")
            shutil.copy2(ROOT / ".githooks" / "replace_by_git_vars.py", repo_root / ".githooks" / "replace_by_git_vars.py")
            (repo_root / "README.template").write_text(
                "# {{ repository.name }}\nBranch: {{ current.branch }}\n",
                encoding="utf-8",
            )

            subprocess.run(["git", "init", "-b", "main"], cwd=repo_root, check=True)
            subprocess.run(["git", "config", "user.name", "Test User"], cwd=repo_root, check=True)
            subprocess.run(["git", "config", "user.email", "test@example.com"], cwd=repo_root, check=True)
            subprocess.run(
                ["git", "remote", "add", "origin", "git@github.com:example/dotfiles.git"],
                cwd=repo_root,
                check=True,
            )
            subprocess.run(["git", "add", "."], cwd=repo_root, check=True)
            subprocess.run(["git", "commit", "-m", "Initial commit"], cwd=repo_root, check=True)

            subprocess.run(
                [sys.executable, ".githooks/replace_by_git_vars.py", "README.template", "README.md"],
                cwd=repo_root,
                check=True,
            )

            readme_text = (repo_root / "README.md").read_text(encoding="utf-8")
            self.assertIn("# example/dotfiles", readme_text)
            self.assertIn("Branch: main", readme_text)


            staged_files = subprocess.run(
                ["git", "diff", "--cached", "--name-only"],
                cwd=repo_root,
                check=True,
                capture_output=True,
                text=True,
            ).stdout.splitlines()
            self.assertIn("README.md", staged_files)

    def test_pre_commit_hook_succeeds_without_optional_package_managers(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir_name:
            repo_root = Path(temp_dir_name)
            hooks_dir = repo_root / ".githooks"
            hooks_dir.mkdir()

            shutil.copy2(ROOT / "gitvars.py", repo_root / "gitvars.py")
            shutil.copy2(ROOT / ".githooks" / "replace_by_git_vars.py", hooks_dir / "replace_by_git_vars.py")
            shutil.copy2(ROOT / ".githooks" / "pre-commit", hooks_dir / "pre-commit")
            (repo_root / "README.template").write_text(
                "# {{ repository.name }} v{{ current.version }}\n",
                encoding="utf-8",
            )

            subprocess.run(["git", "init", "-b", "main"], cwd=repo_root, check=True)
            subprocess.run(
                ["git", "remote", "add", "origin", "git@github.com:example/dotfiles.git"],
                cwd=repo_root,
                check=True,
            )

            shim_dir = repo_root / "bin"
            shim_dir.mkdir()
            for executable_name, executable_path in {
                "git": shutil.which("git"),
                "python3": shutil.which(sys.executable),
            }.items():
                if executable_path is None:
                    self.fail(f"Required executable {executable_name} is not available for the integration test.")

                target_path = shim_dir / executable_name
                target_path.symlink_to(executable_path)

            env = os.environ.copy()
            env["PATH"] = str(shim_dir)

            subprocess.run(["/bin/bash", ".githooks/pre-commit"], cwd=repo_root, env=env, check=True)

            readme_text = (repo_root / "README.md").read_text(encoding="utf-8")
            self.assertIn("# example/dotfiles v0.0.0-local", readme_text)
            self.assertFalse((repo_root / "homebrew_installed_app.txt").exists())
            self.assertFalse((repo_root / "npm_installed_app.txt").exists())


if __name__ == "__main__":
    unittest.main()
