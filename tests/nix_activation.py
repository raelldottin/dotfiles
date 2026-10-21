"""Private-profile helpers shared by the real Nix activation CI rehearsals."""

from __future__ import annotations

import hashlib
import os
from pathlib import Path
import pwd
import subprocess

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


def guard_global_profiles() -> tuple[Path, dict[str, str]]:
    username = pwd.getpwuid(os.getuid()).pw_name
    nix_state = Path(os.environ.get("NIX_STATE_DIR", "/nix/var/nix"))
    profiles = nix_state / "profiles/per-user" / username
    # Home Manager may migrate/delete legacy generations outside HOME.
    legacy_root = nix_state / "gcroots/per-user" / username / "current-home"
    if list(profiles.glob("home-manager*")) or legacy_root.exists() or legacy_root.is_symlink():
        raise RuntimeError("The runner already has legacy Home Manager state; refusing activation.")
    return profiles, profile_snapshot(profiles)


def clean_environment() -> dict[str, str]:
    return {key: value for key, value in os.environ.items()
            if not key.startswith(("GIT_", "DOTFILES_", "HOME_MANAGER_"))
            and key not in {"NIX_PROFILE", "DRY_RUN_CMD", "DRY_RUN", "ZDOTDIR", "SSH_CONNECTION"}}


def private_environment(home: Path, activation: Path, env: dict[str, str],
                        namespace: str = "") -> dict[str, str]:
    username = pwd.getpwuid(os.getuid()).pw_name
    state = home / ".local/state" / namespace
    profiles = state / "nix/profiles"
    profiles.mkdir(parents=True)
    profile = profiles / "profile"
    isolated = {**env, "HOME": str(home), "USER": username, "LOGNAME": username,
                "XDG_CONFIG_HOME": str(home / ".config"),
                "XDG_DATA_HOME": str(home / ".local/share" / namespace),
                "XDG_STATE_HOME": str(state), "XDG_CACHE_HOME": str(home / ".cache" / namespace),
                "GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": str(home / ".gitconfig"),
                "HOME_MANAGER_BACKUP_EXT": "hm-backup"}
    # Seed a valid private profile and both legacy/XDG default aliases before
    # activation, so nix-env cannot initialize a global per-user profile.
    run(["nix-env", "--profile", str(profile), "--set", str(activation / "home-path")], isolated)
    (home / ".nix-profile").symlink_to(profile)
    (state / "nix/profile").symlink_to(profile)
    isolated["PATH"] = str(home / ".nix-profile/bin") + os.pathsep + os.environ["PATH"]
    return isolated
