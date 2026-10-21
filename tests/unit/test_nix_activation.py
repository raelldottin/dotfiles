from __future__ import annotations

import os
from pathlib import Path
import pwd
import subprocess
import tempfile
import unittest
from unittest.mock import patch

from tests import check_nvim_migration, check_work_activation, nix_activation


class NixActivationSafetyTests(unittest.TestCase):
    def test_drivers_refuse_non_ci_and_wrong_platform_before_nix_access(self) -> None:
        for driver, platform in [(check_nvim_migration, "linux"),
                                 (check_work_activation, "darwin")]:
            for actual, ci in [("unsupported", "true"), (platform, "false"),
                               (platform, "")]:
                with self.subTest(driver=driver.__name__, platform=actual, ci=ci):
                    with patch.object(driver.sys, "platform", actual), \
                         patch.dict(os.environ, {"GITHUB_ACTIONS": ci}, clear=True), \
                         patch.object(driver, "guard_global_profiles") as profiles, \
                         patch("tests.nix_activation.subprocess.run") as command:
                        with self.assertRaisesRegex(RuntimeError, "disposable.*runner"):
                            driver.main()
                        profiles.assert_not_called()
                        command.assert_not_called()

    def test_clean_environment_removes_activation_and_git_overrides(self) -> None:
        trusted = {"PATH": "/fixture/bin", "GITHUB_ACTIONS": "true",
                   "NIX_STATE_DIR": "/fixture/nix-state"}
        inherited = {"GIT_DIR": "/personal/repo", "GIT_CONFIG_COUNT": "1",
                     "GIT_CONFIG_KEY_0": "user.email", "GIT_CONFIG_VALUE_0": "personal@example.test",
                     "DOTFILES_WORK_HOME": "/personal/home", "HOME_MANAGER_BACKUP_EXT": "old",
                     "NIX_PROFILE": "/global/profile", "DRY_RUN_CMD": "echo",
                     "DRY_RUN": "1", "ZDOTDIR": "/personal/zsh", "SSH_CONNECTION": "fixture"}
        with patch.dict(os.environ, {**trusted, **inherited}, clear=True):
            self.assertEqual(nix_activation.clean_environment(), trusted)

    def test_legacy_profiles_and_gc_roots_are_rejected_including_broken_links(self) -> None:
        username = pwd.getpwuid(os.getuid()).pw_name
        for relative in [f"profiles/per-user/{username}/home-manager",
                         f"profiles/per-user/{username}/home-manager-7-link",
                         f"gcroots/per-user/{username}/current-home"]:
            for broken in [False, True]:
                with self.subTest(path=relative, broken=broken):
                    with tempfile.TemporaryDirectory() as temporary:
                        root = Path(temporary)
                        target = root / "generation"
                        if not broken:
                            target.mkdir()
                        legacy = root / relative
                        legacy.parent.mkdir(parents=True)
                        legacy.symlink_to(target)
                        before = legacy.readlink()
                        with patch.dict(os.environ, {"NIX_STATE_DIR": str(root)}):
                            with self.assertRaisesRegex(RuntimeError, "legacy Home Manager state"):
                                nix_activation.guard_global_profiles()
                        self.assertTrue(legacy.is_symlink())
                        self.assertEqual(legacy.readlink(), before)

    def test_global_profile_guard_observes_existing_profiles_without_writing(self) -> None:
        username = pwd.getpwuid(os.getuid()).pw_name
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            profiles = root / "profiles/per-user" / username
            with patch.dict(os.environ, {"NIX_STATE_DIR": str(root)}):
                self.assertEqual(nix_activation.guard_global_profiles(), (profiles, {}))
                self.assertFalse(profiles.exists())
                profiles.mkdir(parents=True)
                (profiles / "profile").symlink_to(root / "missing-generation")
                (profiles / "metadata").write_text("before", encoding="utf-8")
                observed, before = nix_activation.guard_global_profiles()
                self.assertEqual(observed, profiles)
                self.assertEqual(before["profile"], str(root / "missing-generation"))
                self.assertEqual(set(before), {"profile", "metadata"})
                self.assertEqual(nix_activation.profile_snapshot(profiles), before)
                (profiles / "metadata").write_text("after", encoding="utf-8")
                self.assertNotEqual(nix_activation.profile_snapshot(profiles), before)
                (profiles / "profile").unlink()
                (profiles / "profile").symlink_to(root / "another-generation")
                self.assertNotEqual(nix_activation.profile_snapshot(profiles)["profile"],
                                    before["profile"])

    def test_private_profiles_and_environment_stay_inside_disposable_home(self) -> None:
        for namespace in ["", "work"]:
            with self.subTest(namespace=namespace), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                home = root / "disposable home"
                home.mkdir()
                activation = root / "activation"
                inherited = {"PATH": "/fixture/bin", "HOME": "/personal/home",
                             "XDG_CONFIG_HOME": "/personal/config", "XDG_DATA_HOME": "/personal/data",
                             "XDG_STATE_HOME": "/personal/state", "XDG_CACHE_HOME": "/personal/cache",
                             "USER": "untrusted", "LOGNAME": "untrusted"}
                with patch.dict(os.environ, inherited, clear=True), \
                     patch("tests.nix_activation.subprocess.run") as command:
                    command.return_value = subprocess.CompletedProcess([], 0, "", "")
                    selected = nix_activation.private_environment(
                        home, activation, nix_activation.clean_environment(), namespace)
                state = home / ".local/state" / namespace
                profile = state / "nix/profiles/profile"
                self.assertEqual((home / ".nix-profile").readlink(), profile)
                self.assertEqual((state / "nix/profile").readlink(), profile)
                self.assertTrue(profile.parent.is_dir())
                self.assertEqual(selected["HOME"], str(home))
                self.assertEqual(selected["USER"], pwd.getpwuid(os.getuid()).pw_name)
                self.assertEqual(selected["LOGNAME"], selected["USER"])
                for key, expected in {
                    "XDG_CONFIG_HOME": home / ".config",
                    "XDG_DATA_HOME": home / ".local/share" / namespace,
                    "XDG_STATE_HOME": state, "XDG_CACHE_HOME": home / ".cache" / namespace,
                    "GIT_CONFIG_GLOBAL": home / ".gitconfig",
                }.items():
                    self.assertEqual(selected[key], str(expected), key)
                self.assertEqual(selected["GIT_CONFIG_NOSYSTEM"], "1")
                self.assertEqual(selected["HOME_MANAGER_BACKUP_EXT"], "hm-backup")
                self.assertEqual(selected["PATH"].split(os.pathsep),
                                 [str(home / ".nix-profile/bin"), "/fixture/bin"])
                command.assert_called_once()
                arguments = command.call_args.args[0]
                self.assertEqual(arguments, ["nix-env", "--profile", str(profile),
                                             "--set", str(activation / "home-path")])
                self.assertEqual(command.call_args.kwargs["env"]["HOME"], str(home))

    def test_failed_profile_seed_aborts_before_default_profile_aliases(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary)
            with patch("tests.nix_activation.subprocess.run") as command:
                command.return_value = subprocess.CompletedProcess([], 1, "", "seed failed")
                with self.assertRaisesRegex(RuntimeError, "seed failed"):
                    nix_activation.private_environment(home, home / "activation", {})
            self.assertFalse(os.path.lexists(home / ".nix-profile"))
            self.assertFalse(os.path.lexists(home / ".local/state/nix/profile"))

    def test_expected_rejections_require_failure_and_matching_diagnostic(self) -> None:
        for code, diagnostic, rejected in [(0, "blocked", True), (1, "unrelated", True),
                                            (1, "blocked", False)]:
            with self.subTest(code=code, diagnostic=diagnostic):
                with patch("tests.nix_activation.subprocess.run") as command:
                    command.return_value = subprocess.CompletedProcess([], code, "", diagnostic)
                    if rejected:
                        with self.assertRaisesRegex(AssertionError, "Expected rejection"):
                            nix_activation.run(["fixture"], {}, error="blocked")
                    else:
                        nix_activation.run(["fixture"], {}, error="blocked")
