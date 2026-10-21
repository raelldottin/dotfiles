"""Rehearse real work Home Manager activation in a disposable macOS CI HOME."""

from __future__ import annotations

import hashlib
import os
from pathlib import Path
import pwd
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def run(command: list[str], env: dict[str, str], cwd: Path = ROOT,
        timeout: int = 180, error: str | None = None) -> str:
    result = subprocess.run(command, cwd=cwd, env=env, capture_output=True,
                            text=True, timeout=timeout)
    output = result.stdout + result.stderr
    if error is not None:
        if result.returncode == 0 or error not in output:
            raise AssertionError(f"Expected rejection containing {error!r}:\n{output}")
    elif result.returncode:
        raise RuntimeError(f"{command[0]} failed:\n{output}")
    return result.stdout.strip()


def profile_snapshot(directory: Path) -> dict[str, str]:
    if not directory.exists():
        return {}
    return {path.name: str(path.readlink()) if path.is_symlink()
            else hashlib.sha256(path.read_bytes()).hexdigest()
            for path in directory.iterdir() if path.is_symlink() or path.is_file()}


def main() -> None:
    # This test is for an ephemeral runner, never a workstation setup command.
    if sys.platform != "darwin" or os.environ.get("GITHUB_ACTIONS") != "true":
        raise RuntimeError("Run this rehearsal only on a disposable macOS GitHub Actions runner.")
    username = pwd.getpwuid(os.getuid()).pw_name
    nix_state = Path(os.environ.get("NIX_STATE_DIR", "/nix/var/nix"))
    global_profiles = nix_state / "profiles/per-user" / username
    # Home Manager can migrate/remove legacy generations outside HOME. Refuse
    # such a runner before activation rather than exercising that migration.
    legacy_root = nix_state / "gcroots/per-user" / username / "current-home"
    if list(global_profiles.glob("home-manager*")) or legacy_root.exists() or legacy_root.is_symlink():
        raise RuntimeError("The runner already has legacy Home Manager state; refusing activation.")
    before_global = profile_snapshot(global_profiles)

    with tempfile.TemporaryDirectory(prefix="work-activation-") as temporary:
        home = Path(temporary).resolve() / "home"
        home.mkdir()
        env = {key: value for key, value in os.environ.items()
               if not key.startswith(("GIT_", "DOTFILES_", "HOME_MANAGER_"))
               and key not in {"NIX_PROFILE", "DRY_RUN_CMD", "DRY_RUN"}}
        env.update({"DOTFILES_WORK_USER": username, "DOTFILES_WORK_HOME": str(home)})
        system = run(["nix", "eval", "--impure", "--raw", "--expr", "builtins.currentSystem"], env)
        activation = Path(run([
            "nix", "build", "--impure", "--no-write-lock-file", "--no-link",
            "--print-out-paths", f".#homeConfigurations.work-{system}.activationPackage",
        ], env, timeout=900))

        state = home / ".local/state/work"
        profiles = state / "nix/profiles"
        profiles.mkdir(parents=True)
        profile = profiles / "profile"
        isolated = {**env, "HOME": str(home), "USER": username, "LOGNAME": username,
                    "XDG_CONFIG_HOME": str(home / ".config"),
                    "XDG_DATA_HOME": str(home / ".local/share/work"),
                    "XDG_STATE_HOME": str(state), "XDG_CACHE_HOME": str(home / ".cache/work"),
                    "GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": str(home / ".gitconfig"),
                    "HOME_MANAGER_BACKUP_EXT": "hm-backup"}
        # Both default-profile aliases resolve to an explicit private profile.
        # Otherwise nix-env may initialize a global per-user profile.
        run(["nix-env", "--profile", str(profile), "--set", str(activation / "home-path")], isolated)
        (home / ".nix-profile").symlink_to(profile)
        (state / "nix/profile").symlink_to(profile)
        isolated["PATH"] = str(home / ".nix-profile/bin") + os.pathsep + os.environ["PATH"]

        personal = {
            home / ".config/nvim/init.lua": b"-- personal editor sentinel\n",
            home / ".local/share/atuin/history.db": b"personal history sentinel",
        }
        for path, content in personal.items():
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(content)
        original_shell = "# original shell sentinel\n"
        original_git = "[user]\n name = Personal Fixture\n email = personal@example.test\n"
        (home / ".zshrc").write_text(original_shell)
        (home / ".gitconfig").write_text(original_git)
        activate = [str(activation / "activate")]
        run(activate, isolated, error="Set DOTFILES_WORK_GIT_NAME and DOTFILES_WORK_GIT_EMAIL")
        if ((home / ".zshrc").read_text() != original_shell
                or (home / ".gitconfig").read_text() != original_git
                or (home / ".config/dotfiles/work.json").exists()
                or (home / ".zshrc.hm-backup").exists()):
            raise AssertionError("Missing identity changed managed files before the write boundary")

        selected = {**isolated, "DOTFILES_WORK_GIT_NAME": "Work Fixture",
                    "DOTFILES_WORK_GIT_EMAIL": "work@example.test"}
        previous_backups: dict[str, bytes] | None = None
        for _ in range(2):
            run(activate, selected)
            run([str(home / ".nix-profile/bin/dotfiles-work"), "verify"], selected)
            for path, content in personal.items():
                if path.read_bytes() != content:
                    raise AssertionError(f"Personal fixture changed: {path}")
            for relative in (".zshrc", ".config/nvim-work/init.lua", ".config/atuin-work/config.toml"):
                if not (home / relative).is_symlink():
                    raise AssertionError(f"Activation did not install {relative}")
            if (home / ".zshrc.hm-backup").read_text() != original_shell:
                raise AssertionError("Original shell was not preserved")
            for relative, mode in ((".config/dotfiles", 0o700),
                                   (".config/dotfiles/work.json", 0o600),
                                   (".config/dotfiles/identity.gitconfig", 0o600)):
                if (home / relative).stat().st_mode & 0o777 != mode:
                    raise AssertionError(f"Incorrect private permissions: {relative}")
            backups = {str(path.relative_to(home)): path.read_bytes()
                       for path in (home / ".local/state/dotfiles/backups").rglob("*") if path.is_file()}
            if original_git.encode() not in backups.values():
                raise AssertionError("Previous Git config was not preserved")
            if previous_backups is not None and backups != previous_backups:
                raise AssertionError("Repeat activation changed backups")
            previous_backups = backups
            if profile_snapshot(global_profiles) != before_global:
                raise AssertionError("Activation changed the runner's global Nix profiles")

        work = home / "Work/project"
        run(["git", "init", "-q", str(work)], selected)
        run(["git", "commit", "--allow-empty", "-m", "work fixture"], selected, cwd=work)
        head = run(["git", "rev-parse", "HEAD"], selected, cwd=work)
        run(["git", "commit", "--allow-empty", "--no-verify", "-m", "blocked fixture"],
            {**selected, "GIT_COMMITTER_EMAIL": "personal@example.test"}, cwd=work,
            error="configured work identity")
        if run(["git", "rev-parse", "HEAD"], selected, cwd=work) != head:
            raise AssertionError("Rejected identity advanced Git history")
        outside = home / "Personal/project"
        run(["git", "init", "-q", str(outside)], selected)
        run(["git", "-c", "user.name=Work Fixture", "-c", "user.email=work@example.test",
             "commit", "--allow-empty", "-m", "blocked outside"], selected, cwd=outside,
            error="outside the configured work directory")
        print("Work activation: missing identity rejected; two activations passed; personal files and backups preserved.")
        print("Packaged Git guards: work commit passed; wrong identity and outside-root commits rejected.")
        print("Disposable HOME/profile only; runner global Nix profiles unchanged.")


if __name__ == "__main__":
    main()
