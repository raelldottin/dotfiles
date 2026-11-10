"""Check the VM test runner's orchestration with stand-in Tart and SSH tools.

These tests do not boot a VM. They check that vm/run-test.sh clones the base
image, passes the tested commit to the right guest script, reports the guest's
status, and always removes the disposable VM unless --keep is given.
"""

from __future__ import annotations

from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import textwrap
import unittest


ROOT = Path(__file__).resolve().parents[2]

FAKE_TART = """\
#!/usr/bin/env bash
set -eu
printf 'tart %s\\n' "$*" >> "$FAKE_LOG"
vms="$FAKE_STATE/vms"
touch "$vms"
case "$1" in
  --version) echo "${FAKE_TART_VERSION:-2.41.1}" ;;
  list) cat "$vms" ;;
  clone) echo "$3" >> "$vms" ;;
  delete) grep -Fxv -- "$2" "$vms" > "$vms.new" || true; mv "$vms.new" "$vms" ;;
  ip) echo 192.0.2.10 ;;
  run | set | stop) ;;
  *) echo "unexpected tart call: $*" >&2; exit 64 ;;
esac
"""

FAKE_SSH = """\
#!/usr/bin/env bash
printf 'ssh %s\\n' "$*" >> "$FAKE_LOG"
case "$*" in
  *test-personal.sh* | *test-work.sh*) echo "guest output"; exit "${FAKE_GUEST_STATUS:-0}" ;;
esac
exit 0
"""

FAKE_SCP = """\
#!/usr/bin/env bash
printf 'scp %s\\n' "$*" >> "$FAKE_LOG"
"""

FAKE_UNAME = """\
#!/usr/bin/env bash
case "${1:-}" in
  -m) echo arm64 ;;
  *) echo Darwin ;;
esac
"""

FAKE_SW_VERS = """\
#!/usr/bin/env bash
echo 27.2
"""

FLAKE_NIX = """\
{
  outputs = _: let
    username = "vmtester";
  in { };
}
"""

FLAKE_LOCK = """\
{"nodes": {"nixpkgs": {"locked": {"rev": "0123456789abcdef0123456789abcdef01234567"}}}}
"""


class VmRunnerTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        root = Path(self.temp.name)
        self.repo = root / "repo"
        self.bin = root / "bin"
        self.state = root / "state"
        self.log = root / "calls.log"
        shutil.copytree(ROOT / "vm", self.repo / "vm")
        (self.repo / "flake.nix").write_text(FLAKE_NIX)
        (self.repo / "flake.lock").write_text(FLAKE_LOCK)
        self.bin.mkdir()
        for name, body in {
            "tart": FAKE_TART,
            "ssh": FAKE_SSH,
            "scp": FAKE_SCP,
            "uname": FAKE_UNAME,
            "sw_vers": FAKE_SW_VERS,
        }.items():
            path = self.bin / name
            path.write_text(body)
            path.chmod(0o755)
        self.state.mkdir()
        (self.state / "vms").write_text("dotfiles-golden-gate-base\n")
        (self.state / "id_ed25519").write_text("fake private key\n")

        self.env = {k: v for k, v in os.environ.items() if not k.startswith(("GIT_", "DOTFILES_"))}
        self.env.update({
            "PATH": f"{self.bin}{os.pathsep}{os.environ['PATH']}",
            "FAKE_LOG": str(self.log),
            "FAKE_STATE": str(self.state),
            "DOTFILES_VM_STATE_DIR": str(self.state),
            "TMPDIR": str(root),
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_CONFIG_GLOBAL": os.devnull,
        })
        git = ["git", "-C", str(self.repo), "-c", "user.name=VM Test", "-c", "user.email=vm@example.test"]
        subprocess.run([*git, "init", "-q"], check=True, env=self.env)
        subprocess.run([*git, "add", "."], check=True, env=self.env)
        subprocess.run([*git, "commit", "-q", "-m", "fixture"], check=True, env=self.env)

    def tearDown(self) -> None:
        self.temp.cleanup()

    def run_test(self, *args: str, **extra_env: str) -> subprocess.CompletedProcess[str]:
        env = {**self.env, **extra_env}
        return subprocess.run(
            ["bash", str(self.repo / "vm/run-test.sh"), *args],
            env=env, text=True, capture_output=True, timeout=60, check=False,
        )

    def calls(self) -> list[str]:
        return self.log.read_text().splitlines() if self.log.exists() else []

    def vms(self) -> list[str]:
        return (self.state / "vms").read_text().split()

    def test_personal_run_clones_tests_and_deletes_the_vm(self) -> None:
        result = self.run_test("personal")

        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.calls()
        clone = next(call for call in calls if call.startswith("tart clone"))
        vm_name = clone.split()[-1]
        self.assertEqual(clone, f"tart clone dotfiles-golden-gate-base {vm_name}")
        self.assertTrue(vm_name.startswith("dotfiles-test-personal-"))
        self.assertIn(f"tart run --no-graphics {vm_name}", calls)
        guest = next(call for call in calls if "test-personal.sh" in call)
        self.assertTrue(guest.endswith(
            "/tmp/dotfiles-vm/dotfiles.bundle 0123456789abcdef0123456789abcdef01234567 vmtester"
        ), guest)
        self.assertIn(f"tart delete {vm_name}", calls)
        self.assertEqual(self.vms(), ["dotfiles-golden-gate-base"])
        log = next((self.state / "logs").glob(f"{vm_name}.log")).read_text()
        self.assertIn("guest output", log)

    def test_work_run_does_not_pass_a_personal_username(self) -> None:
        result = self.run_test("work")

        self.assertEqual(result.returncode, 0, result.stderr)
        guest = next(call for call in self.calls() if "test-work.sh" in call)
        self.assertTrue(guest.endswith(
            "/tmp/dotfiles-vm/dotfiles.bundle 0123456789abcdef0123456789abcdef01234567"
        ), guest)

    def test_guest_failure_is_reported_and_the_vm_is_still_deleted(self) -> None:
        result = self.run_test("work", FAKE_GUEST_STATUS="3")

        self.assertEqual(result.returncode, 3, result.stderr)
        self.assertIn("failed with status 3", result.stderr)
        self.assertEqual(self.vms(), ["dotfiles-golden-gate-base"])

    def test_keep_leaves_the_vm_for_inspection(self) -> None:
        result = self.run_test("--keep", "work")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(any(call.startswith("tart delete") for call in self.calls()))
        self.assertEqual(len(self.vms()), 2)
        self.assertIn("Keeping dotfiles-test-work-", result.stderr)

    def test_unknown_profile_is_rejected_before_any_vm_is_created(self) -> None:
        result = self.run_test("legacy")

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("unknown argument: legacy", result.stderr)
        self.assertFalse(any(call.startswith("tart clone") for call in self.calls()))

    def test_missing_base_image_is_reported(self) -> None:
        (self.state / "vms").write_text("")

        result = self.run_test("personal")

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("vm/build-base.sh", result.stderr)
        self.assertFalse(any(call.startswith("tart clone") for call in self.calls()))

    def test_old_tart_is_rejected(self) -> None:
        result = self.run_test("personal", FAKE_TART_VERSION="2.32.1")

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("older than 2.33.0", result.stderr)
        self.assertFalse(any(call.startswith("tart clone") for call in self.calls()))


class VmVersionTests(unittest.TestCase):
    def check(self, have: str, want: str) -> bool:
        script = textwrap.dedent(f"""\
            . {str(ROOT / 'vm/lib.sh')!r}
            vm_version_at_least {have!r} {want!r}
        """)
        return subprocess.run(["bash", "-c", script], check=False).returncode == 0

    def test_version_comparison_is_numeric(self) -> None:
        self.assertTrue(self.check("2.41.1", "2.33.0"))
        self.assertTrue(self.check("2.33.0", "2.33.0"))
        self.assertTrue(self.check("10.0", "2.33.0"))
        self.assertFalse(self.check("2.32.1", "2.33.0"))
        self.assertFalse(self.check("2.4", "2.33.0"))

    def test_version_suffixes_are_ignored(self) -> None:
        self.assertTrue(self.check("2.41.1-beta", "2.33.0"))
        self.assertFalse(self.check("2.32.9-rc1", "2.33.0"))


if __name__ == "__main__":
    unittest.main()
