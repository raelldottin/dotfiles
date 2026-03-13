from __future__ import annotations

from pathlib import Path
import subprocess
import tempfile
import unittest

import gitvars


class ParseArgsTests(unittest.TestCase):
    def test_parse_args_supports_verbose_mode(self) -> None:
        arguments = gitvars.parse_args(["replace_by_git_vars.py", "README.template", "README.md", "-v"])

        self.assertEqual(
            arguments,
            gitvars.Arguments(
                input_path=Path("README.template").resolve(),
                output_path=Path("README.md").resolve(),
                verbose=True,
            ),
        )


class FindGitVariablesTests(unittest.TestCase):
    def test_extracts_unique_variables_in_order(self) -> None:
        template_text = """
        # {{ repository.name }}
        Branch: {{ current.branch }}
        Branch again: {{ current.branch }}
        """

        self.assertEqual(
            gitvars.find_git_variables(template_text),
            ["repository.name", "current.branch"],
        )

    def test_render_template_replaces_known_variables(self) -> None:
        template_text = "Hello {{ repository.name }} on {{ current.branch }}"

        rendered = gitvars.render_template(
            template_text,
            {"repository.name": "dotfiles", "current.branch": "dev"},
        )

        self.assertEqual(rendered, "Hello dotfiles on dev")


class BuildGitVariablesTests(unittest.TestCase):
    def test_build_git_variables_uses_known_values_and_git_config_fallbacks(self) -> None:
        template_text = """
        # {{ repository.name }}
        URL: {{ remote.origin.url }}
        Branch: {{ current.branch }}
        Author: {{ custom.author }}
        """

        outputs = {
            ("config", "--get", "remote.origin.url"): "git@github.com:example/dotfiles.git",
            ("symbolic-ref", "--short", "HEAD"): "dev",
            ("rev-parse", "--abbrev-ref", "HEAD"): "dev",
            ("rev-parse", "HEAD"): "abc123",
            ("tag", "--list"): "v1.0.0",
            ("config", "custom.author"): "Raell Dottin",
        }

        def fake_runner(args: gitvars.Sequence[str], _: Path) -> str:
            return outputs[tuple(args)]

        result = gitvars.build_git_variables(template_text, Path.cwd(), fake_runner)

        self.assertEqual(result["repository.name"], "example/dotfiles")
        self.assertEqual(result["remote.origin.url"], "git@github.com:example/dotfiles.git")
        self.assertEqual(result["current.branch"], "dev")
        self.assertEqual(result["custom.author"], "Raell Dottin")

    def test_build_git_variables_only_requests_variables_present_in_the_template(self) -> None:
        observed_calls: list[tuple[str, ...]] = []

        def fake_runner(args: gitvars.Sequence[str], _: Path) -> str:
            observed_calls.append(tuple(args))
            if tuple(args) == ("config", "--get", "remote.origin.url"):
                return "git@github.com:example/dotfiles.git"
            raise AssertionError(f"Unexpected git invocation: {args}")

        result = gitvars.build_git_variables("# {{ repository.name }}", Path.cwd(), fake_runner)

        self.assertEqual(result, {"repository.name": "example/dotfiles"})
        self.assertEqual(observed_calls, [("config", "--get", "remote.origin.url")])

    def test_build_git_variables_derives_current_version_without_git_config(self) -> None:
        def fake_runner(args: gitvars.Sequence[str], _: Path) -> str:
            command = tuple(args)
            if command == ("describe", "--tags", "--long", "--always"):
                return "v0.4.1-7-gabcdef"
            if command == ("diff", "--cached", "--name-only"):
                return ""
            raise AssertionError(f"Unexpected git invocation: {args}")

        result = gitvars.build_git_variables("Version: {{ current.version }}", Path.cwd(), fake_runner)

        self.assertEqual(result["current.version"], "0.4.1-7")

    def test_build_git_variables_advances_current_version_for_staged_changes(self) -> None:
        def fake_runner(args: gitvars.Sequence[str], _: Path) -> str:
            command = tuple(args)
            if command == ("describe", "--tags", "--long", "--always"):
                return "v0.4.1-7-gabcdef"
            if command == ("diff", "--cached", "--name-only"):
                return "README.template\n"
            raise AssertionError(f"Unexpected git invocation: {args}")

        result = gitvars.build_git_variables("Version: {{ current.version }}", Path.cwd(), fake_runner)

        self.assertEqual(result["current.version"], "0.4.1-8")

    def test_build_git_variables_falls_back_to_repo_directory_name_without_remote(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir_name:
            repo_root = Path(temp_dir_name)

            def fake_runner(args: gitvars.Sequence[str], _: Path) -> str:
                raise subprocess.CalledProcessError(returncode=1, cmd=list(args))

            result = gitvars.build_git_variables("# {{ repository.name }}", repo_root, fake_runner)

            self.assertEqual(result["repository.name"], repo_root.name)


class StageOutputFileTests(unittest.TestCase):
    def test_stage_output_file_uses_repo_relative_path(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir_name:
            repo_root = Path(temp_dir_name)
            output_path = repo_root / "docs" / "README.md"
            output_path.parent.mkdir()
            output_path.touch()
            staged_commands: list[tuple[str, ...]] = []

            def fake_runner(args: gitvars.Sequence[str], _: Path) -> str:
                staged_commands.append(tuple(args))
                return ""

            gitvars.stage_output_file(output_path, repo_root, fake_runner)

            self.assertEqual(staged_commands, [("add", "docs/README.md")])


if __name__ == "__main__":
    unittest.main()
