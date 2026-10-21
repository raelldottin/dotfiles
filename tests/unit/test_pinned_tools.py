from __future__ import annotations

from contextlib import redirect_stderr, redirect_stdout
import io
import os
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest.mock import patch

from tests.check_pinned_tools import run_probes


class PinnedToolProbeTests(unittest.TestCase):
    def setUp(self) -> None:
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.bin = Path(temporary.name) / "profile/bin"
        self.bin.mkdir(parents=True)
        for name in ("nvim", "atuin", "zsh"):
            tool = self.bin / name
            tool.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
            tool.chmod(0o700)
        environment = patch.dict(os.environ, {"PATH": str(self.bin)})
        environment.start()
        self.addCleanup(environment.stop)

    def run_fixture(self, outcome: str) -> str:
        class Probe(unittest.TestCase):
            def runTest(self) -> None:
                if outcome == "skip":
                    self.skipTest("optional tool unavailable")
                if outcome == "failure":
                    self.fail("fixture failure")

        suite = unittest.TestSuite([] if outcome == "empty" else [Probe()])
        output = io.StringIO()
        with patch("tests.check_pinned_tools.unittest.defaultTestLoader.loadTestsFromNames",
                   return_value=suite), redirect_stderr(output), redirect_stdout(output):
            run_probes(self.bin)
        return output.getvalue()

    def test_successful_probes_emit_completion_evidence(self) -> None:
        self.assertIn("Pinned editor/history tool probes: 1 passed; no skips.",
                      self.run_fixture("pass"))

    def test_skipped_probes_fail_the_gate(self) -> None:
        with self.assertRaisesRegex(RuntimeError, "without any skips"):
            self.run_fixture("skip")

    def test_failed_probes_fail_the_gate(self) -> None:
        with self.assertRaisesRegex(RuntimeError, "without any skips"):
            self.run_fixture("failure")

    def test_empty_probe_suite_fails_the_gate(self) -> None:
        with self.assertRaisesRegex(RuntimeError, "without any skips"):
            self.run_fixture("empty")

    def test_missing_or_unpinned_tools_fail_before_test_loading(self) -> None:
        outside = self.bin.parent / "unselected-tool"
        outside.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
        outside.chmod(0o700)
        for name in ("nvim", "atuin", "zsh"):
            for selected in (None, str(outside)):
                with self.subTest(name=name, selected=selected):
                    real_which = shutil.which
                    with patch("tests.check_pinned_tools.shutil.which",
                               side_effect=lambda tool: selected if tool == name else real_which(tool)), \
                         patch("tests.check_pinned_tools.unittest.defaultTestLoader.loadTestsFromNames") as load, \
                         redirect_stdout(io.StringIO()):
                        with self.assertRaisesRegex(RuntimeError, "must resolve to the activated profile"):
                            run_probes(self.bin)
                        load.assert_not_called()
