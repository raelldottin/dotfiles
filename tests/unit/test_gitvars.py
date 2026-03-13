from __future__ import annotations

from pathlib import Path
import unittest

import gitvars


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


if __name__ == "__main__":
    unittest.main()
