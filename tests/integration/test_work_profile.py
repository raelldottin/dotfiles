from __future__ import annotations

import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class WorkProfileTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.home = Path(self.temporary.name).resolve() / "home"
        self.home.mkdir()
        self.env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
        self.env.update({
            "HOME": str(self.home), "OSTYPE": "darwin",
            "XDG_CONFIG_HOME": str(self.home / ".config"),
            "XDG_DATA_HOME": str(self.home / ".local/share"),
            "XDG_STATE_HOME": str(self.home / ".local/state"),
            "XDG_CACHE_HOME": str(self.home / ".cache"),
            "ATUIN_CONFIG_DIR": str(self.home / ".config/atuin-work"),
            "GIT_CONFIG_NOSYSTEM": "1",
            "DOTFILES_WORK_GIT_NAME": "Work Test",
            "DOTFILES_WORK_GIT_EMAIL": "work@example.test",
            "DOTFILES_SKIP_TMUX_PLUGIN_INSTALL": "1",
        })
        self.env.pop("DOTFILES_WORK_ROOT", None)

    def run_command(self, *args: str, cwd: Path | None = None,
                    env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
        return subprocess.run(args, cwd=cwd or ROOT, env=env or self.env,
                              capture_output=True, text=True, timeout=30)

    def install(self) -> None:
        result = self.run_command("bash", str(ROOT / "zshsetup.sh"), cwd=self.home)
        self.assertEqual(result.returncode, 0, result.stderr)

    def repository(self, directory: Path) -> Path:
        directory.mkdir(parents=True)
        result = self.run_command("git", "init", "-q", str(directory))
        self.assertEqual(result.returncode, 0, result.stderr)
        return directory

    def test_identity_is_required_before_any_file_is_changed(self) -> None:
        self.env.pop("DOTFILES_WORK_GIT_NAME")
        self.env.pop("DOTFILES_WORK_GIT_EMAIL")
        original = self.home / ".zshrc"
        original.write_text("personal shell\n")
        result = self.run_command("bash", str(ROOT / "zshsetup.sh"))
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(original.read_text(), "personal shell\n")
        self.assertFalse((self.home / ".gitconfig").exists())
        self.assertFalse((self.home / ".config").exists())

    def test_backups_reinstall_and_personal_data_preservation(self) -> None:
        (self.home / ".zshrc").write_text("personal shell\n")
        (self.home / ".gitconfig").write_text("[user]\n email = personal@example.test\n")
        personal = self.home / ".config/nvim/init.lua"
        personal.parent.mkdir(parents=True)
        personal.write_text("-- personal editor\n")
        history = self.home / ".local/share/atuin/history.db"
        history.parent.mkdir(parents=True)
        history.write_bytes(b"personal history sentinel")
        self.install()
        backups = self.home / ".local/state/dotfiles/backups"
        before = sorted(str(p) for p in backups.rglob("*"))
        self.install()
        self.assertEqual(before, sorted(str(p) for p in backups.rglob("*")))
        self.assertIn("personal shell\n", [p.read_text() for p in backups.rglob(".zshrc")])
        result = self.run_command("bash", str(ROOT / "nvimsetup.sh"))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(personal.read_text(), "-- personal editor\n")
        self.assertEqual(history.read_bytes(), b"personal history sentinel")
        self.assertTrue((self.home / ".config/nvim-work/init.lua").is_symlink())
        self.assertEqual((self.home / ".config/dotfiles/work.json").stat().st_mode & 0o777, 0o600)
        self.assertNotIn("personal@example.test", (self.home / ".gitconfig").read_text())

    def test_work_commit_succeeds_and_personal_overrides_are_rejected(self) -> None:
        self.install()
        repo = self.repository(self.home / "Work/project")
        good = self.run_command("git", "commit", "--allow-empty", "-m", "work", cwd=repo)
        self.assertEqual(good.returncode, 0, good.stderr)
        for variable in ("GIT_AUTHOR_EMAIL", "GIT_COMMITTER_EMAIL"):
            env = {**self.env, variable: "personal@example.test"}
            result = self.run_command("git", "commit", "--allow-empty", "--no-verify", "-m", "blocked",
                                      cwd=repo, env=env)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("configured work identity", result.stderr)
        self.run_command("git", "config", "user.email", "personal@example.test", cwd=repo)
        result = self.run_command("git", "commit", "--allow-empty", "-m", "blocked", cwd=repo)
        self.assertNotEqual(result.returncode, 0)

    def test_commits_outside_work_root_are_blocked_even_with_local_identity(self) -> None:
        self.install()
        repo = self.repository(self.home / "Personal/project")
        self.run_command("git", "config", "user.name", "Work Test", cwd=repo)
        self.run_command("git", "config", "user.email", "work@example.test", cwd=repo)
        result = self.run_command("git", "commit", "--allow-empty", "-m", "blocked", cwd=repo)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("outside the configured work directory", result.stderr)

    def test_symlinked_work_namespace_and_external_work_root_are_rejected(self) -> None:
        (self.home / ".config").mkdir()
        (self.home / ".config/nvim-work").symlink_to(self.home / "personal-editor", target_is_directory=True)
        result = self.run_command("bash", str(ROOT / "zshsetup.sh"))
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.home / ".gitconfig").exists())
        (self.home / ".config/nvim-work").unlink()
        self.env["DOTFILES_WORK_ROOT"] = str(self.home.parent / "outside")
        result = self.run_command("bash", str(ROOT / "zshsetup.sh"))
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.home / ".gitconfig").exists())

    def test_work_root_cannot_alias_a_personal_directory(self) -> None:
        personal = self.home / "Personal"
        personal.mkdir()
        (self.home / "Work").symlink_to(personal, target_is_directory=True)
        result = self.run_command("bash", str(ROOT / "zshsetup.sh"))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("symlinked directories", result.stderr)
        self.assertFalse((self.home / ".gitconfig").exists())

    def test_retargeted_work_root_blocks_commits_inside_and_outside_home(self) -> None:
        self.install()
        work = self.home / "Work"
        work.rmdir()
        for target in (self.home / "Personal", self.home.parent / "outside"):
            with self.subTest(target=target.name):
                target.mkdir()
                work.symlink_to(target, target_is_directory=True)
                repo = self.repository(target / "project")
                self.run_command("git", "config", "user.name", "Work Test", cwd=repo)
                self.run_command("git", "config", "user.email", "work@example.test", cwd=repo)
                result = self.run_command("git", "commit", "--allow-empty", "-m", "blocked", cwd=repo)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("symlinked directories", result.stderr)
                result = self.run_command(sys.executable, str(ROOT / "workstation.py"), "verify")
                self.assertNotEqual(result.returncode, 0)
                work.unlink()

    def test_redirected_backups_are_refused_by_all_install_entry_points(self) -> None:
        shared = self.home.parent / "shared"
        shared.mkdir()
        backup = self.home / ".local/state/dotfiles/backups"
        backup.parent.mkdir(parents=True)
        backup.symlink_to(shared, target_is_directory=True)
        original = self.home / ".zshrc"
        original.write_text("fixture original\n")
        for script in ("zshsetup.sh", "nvimsetup.sh", "tmuxsetup.sh"):
            with self.subTest(script=script):
                result = self.run_command("bash", str(ROOT / script))
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(original.read_text(), "fixture original\n")
                self.assertFalse(any(shared.iterdir()))
        self.assertFalse((self.home / ".gitconfig").exists())

    def test_standalone_editor_install_and_cleanup_cannot_follow_a_personal_alias(self) -> None:
        personal = self.home / ".config/nvim"
        personal.mkdir(parents=True)
        original = personal / "init.lua"
        original.write_text("-- personal editor\n")
        (self.home / ".config/nvim-work").symlink_to(personal, target_is_directory=True)
        for script in ("nvimsetup.sh", "clean.sh"):
            with self.subTest(script=script):
                result = self.run_command("bash", str(ROOT / script))
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(original.read_text(), "-- personal editor\n")
                self.assertFalse(original.is_symlink())

    def test_linked_history_state_is_rejected_on_reinstall_and_verification(self) -> None:
        self.install()
        personal = self.home / "personal-state"
        personal.write_text("fixture private state\n")
        for target in (self.home / ".local/share/work/atuin/key",
                       self.home / ".local/state/work/zsh/history"):
            with self.subTest(target=target.name):
                target.parent.mkdir(parents=True, exist_ok=True)
                target.symlink_to(personal)
                for command in ("install", "verify"):
                    result = self.run_command(sys.executable, str(ROOT / "workstation.py"), command)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn("Work history state", result.stderr)
                self.assertEqual(personal.read_text(), "fixture private state\n")
                target.unlink()

    def test_work_root_with_spaces_and_modified_gitconfig_cleanup(self) -> None:
        self.env["DOTFILES_WORK_ROOT"] = str(self.home / "Work Projects")
        self.install()
        repo = self.repository(self.home / "Work Projects/project")
        result = self.run_command("git", "commit", "--allow-empty", "-m", "work", cwd=repo)
        self.assertEqual(result.returncode, 0, result.stderr)
        config = self.home / ".gitconfig"
        config.write_text(config.read_text() + "\n# local addition\n")
        result = self.run_command(sys.executable, str(ROOT / "workstation.py"), "clean")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(config.exists())

    def test_nix_preflight_is_read_only_and_rejects_a_different_home(self) -> None:
        result = self.run_command(sys.executable, str(ROOT / "workstation.py"), "preflight",
                                  "--expected-home", str(self.home))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(any(self.home.iterdir()))
        result = self.run_command(sys.executable, str(ROOT / "workstation.py"), "install",
                                  "--expected-home", str(self.home.parent / "other-user"))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("does not match", result.stderr)
        self.assertFalse(any(self.home.iterdir()))

    def test_guard_package_upgrade_preserves_identity_and_updates_hooks(self) -> None:
        self.install()
        package = self.home.parent / "new-package"
        for relative in ("workstation.py", "dotfiles_manifest.py", "config/git/work.conf",
                         "config/git/hooks/pre-commit", "config/git/hooks/prepare-commit-msg"):
            target = package / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / relative, target)
        result = self.run_command(sys.executable, str(package / "workstation.py"), "install")
        self.assertEqual(result.returncode, 0, result.stderr)
        result = self.run_command(sys.executable, str(package / "workstation.py"), "verify")
        self.assertEqual(result.returncode, 0, result.stderr)
        repo = self.repository(self.home / "Work/project")
        result = self.run_command("git", "commit", "--allow-empty", "-m", "work", cwd=repo)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(str(package), (self.home / ".gitconfig").read_text())

    def test_company_git_hooks_are_not_silently_replaced(self) -> None:
        config = self.home / ".gitconfig"
        original = '[core]\n hooksPath = /company/required-hooks\n'
        config.write_text(original)
        result = self.run_command("bash", str(ROOT / "zshsetup.sh"))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("hooks must be integrated", result.stderr)
        self.assertEqual(config.read_text(), original)
        self.assertFalse((self.home / ".zshrc").exists())

    def test_existing_directory_fails_before_any_configuration_write(self) -> None:
        (self.home / ".zshrc").mkdir()
        result = self.run_command("bash", str(ROOT / "zshsetup.sh"))
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.home / ".gitconfig").exists())
        self.assertFalse((self.home / ".config").exists())

    def test_system_personal_identity_cannot_be_used_as_a_fallback(self) -> None:
        system = self.home / "system.gitconfig"
        system.write_text('[user]\n name = Personal\n email = personal@example.test\n')
        self.env.pop("GIT_CONFIG_NOSYSTEM")
        self.env["GIT_CONFIG_SYSTEM"] = str(system)
        self.install()
        repo = self.repository(self.home / "Outside")
        result = self.run_command("git", "var", "GIT_COMMITTER_IDENT", cwd=repo)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("personal@example.test", result.stdout)
        repo = self.repository(self.home / "Work/project")
        result = self.run_command("git", "commit", "--allow-empty", "-m", "work", cwd=repo)
        self.assertEqual(result.returncode, 0, result.stderr)

    @unittest.skipUnless(shutil.which("nvim"), "Neovim is required for the offline config smoke check")
    def test_current_editor_config_loads_offline_with_pinned_lazyvim_spec(self) -> None:
        # Exercise the actual migrated config while prohibiting bootstrap downloads.
        lazy_data = self.home / "editor-data/nvim/lazy/lazy.nvim"
        lazy_data.mkdir(parents=True)
        script = self.home / "editor-check.lua"
        script.write_text(
            'vim.fn.system = function() error("unexpected external command") end\n'
            'local spec\n'
            'package.preload["lazy"] = function() return {setup=function(s) spec=s end} end\n'
            'local root = vim.env.CONFIG_ROOT\n'
            'for _, file in ipairs(vim.fn.glob(root .. "/**/*.lua", false, true)) do assert(loadfile(file)) end\n'
            'dofile(root .. "/lua/config/lazy.lua")\n'
            'assert(spec.spec[1][1] == "LazyVim/LazyVim")\n'
            'assert(spec.checker.enabled == false)\n'
            'local line = dofile(root .. "/lua/plugins/lualine.lua")\n'
            'local opts = {sections={lualine_z={}}}; line[1].opts(nil, opts)\n'
            'assert(opts.sections.lualine_z[1][1] == "datetime")\n'
            'vim.cmd("qa!")\n'
        )
        env = {**self.env, "XDG_DATA_HOME": str(self.home / "editor-data"),
               "CONFIG_ROOT": str(ROOT / "config/nvim"), "NVIM_APPNAME": "nvim"}
        result = self.run_command("nvim", "--headless", "--clean", "-u", "NONE", "-l", str(script), env=env)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    @unittest.skipUnless(shutil.which("zsh"), "zsh is required")
    def test_shell_reasserts_work_state_without_startup_updates(self) -> None:
        self.install()
        shim = self.home / "bin"
        shim.mkdir()
        calls = self.home / "calls"
        for tool in ("brew", "npm", "gh", "atuin"):
            script = shim / tool
            script.write_text('#!/bin/sh\nprintf "%s %s\\n" "${0##*/}" "$*" >>"$CALLS"\n')
            script.chmod(0o700)
        local = self.home / ".config/dotfiles/work.local.zsh"
        local.write_text('export NVIM_APPNAME=nvim-personal\nexport ATUIN_CONFIG_DIR="$HOME/personal"\n'
                         'export XDG_CONFIG_HOME="$HOME/personal-config"\n'
                         'export GIT_CONFIG_GLOBAL="$HOME/personal.gitconfig"\n'
                         'export GIT_AUTHOR_EMAIL=personal@example.test\n')
        env = {**self.env, "PATH": str(shim) + os.pathsep + self.env["PATH"], "CALLS": str(calls),
               "XDG_DATA_HOME": str(self.home / "personal-data"), "TERM": "dumb"}
        result = self.run_command("zsh", "-dfi", "-c",
                                  'source "$HOME/.zshrc"; print -r -- "$NVIM_APPNAME|$ATUIN_CONFIG_DIR|$HISTFILE|$XDG_DATA_HOME|$GIT_CONFIG_GLOBAL|${GIT_AUTHOR_EMAIL-unset}|$PURE_GIT_PULL|$XDG_CONFIG_HOME"',
                                  cwd=self.home, env=env)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("nvim-work|" + str(self.home / ".config/atuin-work"), result.stdout)
        self.assertIn(str(self.home / ".local/state/work/zsh/history"), result.stdout)
        self.assertIn(str(self.home / ".local/share/work"), result.stdout)
        self.assertIn(str(self.home / ".gitconfig") + "|unset|0|" + str(self.home / ".config"), result.stdout)
        self.assertEqual(calls.read_text().strip(), "atuin init zsh")

    def test_verification_detects_a_changed_private_identity(self) -> None:
        self.install()
        result = self.run_command(sys.executable, str(ROOT / "workstation.py"), "verify")
        self.assertEqual(result.returncode, 0, result.stderr)
        identity = self.home / ".config/dotfiles/identity.gitconfig"
        identity.write_text('[user]\n name = Personal\n email = personal@example.test\n')
        result = self.run_command(sys.executable, str(ROOT / "workstation.py"), "verify")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Private Git identity differs", result.stderr)

    def test_existing_brew_uses_manifest_from_any_directory_without_global_identity_changes(self) -> None:
        shim = self.home / "bin"
        shim.mkdir()
        brew = shim / "brew"
        brew.write_text('#!/bin/sh\nprintf "%s\\n" "$@" >"$CALLS"\n')
        brew.chmod(0o700)
        calls = self.home / "brew-calls"
        env = {**self.env, "PATH": str(shim) + os.pathsep + self.env["PATH"], "CALLS": str(calls)}
        result = self.run_command("bash", str(ROOT / "pre-install.sh"), cwd=self.home, env=env)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls.read_text().splitlines(), ["bundle", "install", "--no-upgrade", "--file=" + str(ROOT / "Brewfile")])
        self.assertFalse((self.home / ".gitconfig").exists())

    @unittest.skipUnless(shutil.which("atuin"), "Atuin path probe requires the installed CLI")
    def test_real_atuin_resolves_work_database_and_metadata_paths(self) -> None:
        self.install()
        env = {**self.env, "ATUIN_CONFIG_DIR": str(self.home / ".config/atuin-work"),
               "XDG_DATA_HOME": str(self.home / ".local/share/work")}
        result = self.run_command("atuin", "info", env=env)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(str(self.home / ".local/share/work/atuin/history.db"), result.stdout)
        self.assertIn(str(self.home / ".local/share/work/atuin/key"), result.stdout)
        self.assertIn(str(self.home / ".local/share/work/atuin/meta.db"), result.stdout)


if __name__ == "__main__":
    unittest.main()
