"""Run offline editor/history probes with tools from the activated Nix profile."""

from __future__ import annotations

import argparse
from pathlib import Path
import shutil
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

PROBES = (
    "tests.integration.test_nvim_workflow",
    "tests.integration.test_work_profile.WorkProfileTests."
    "test_current_editor_config_loads_offline_with_pinned_lazyvim_spec",
    "tests.integration.test_work_profile.WorkProfileTests."
    "test_editor_uses_a_writable_lockfile_seeded_from_read_only_config",
    "tests.integration.test_work_profile.WorkProfileTests."
    "test_real_atuin_resolves_work_database_and_metadata_paths",
)


def run_probes(binary_directory: Path) -> None:
    # Check PATH before importing tests whose optional decorators inspect it.
    for name in ("nvim", "atuin", "zsh"):
        selected = shutil.which(name)
        expected = binary_directory / name
        if selected is None or not expected.is_file() or not Path(selected).samefile(expected):
            raise RuntimeError(f"{name} must resolve to the activated profile: {expected}")
        print(f"Pinned tool: {name} -> {Path(selected).resolve()}", flush=True)
    suite = unittest.defaultTestLoader.loadTestsFromNames(PROBES)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    if not result.wasSuccessful() or result.skipped or result.testsRun == 0:
        raise RuntimeError("Pinned tool probes must pass without any skips.")
    print(f"Pinned editor/history tool probes: {result.testsRun} passed; no skips.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("binary_directory", type=Path)
    run_probes(parser.parse_args().binary_directory)
