from __future__ import annotations

from pathlib import Path
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


if __name__ == "__main__":
    unittest.main()
