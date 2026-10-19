"""Install a device-local work identity and guard normal Git commits."""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

from dotfiles_manifest import build_managed_paths

ROOT = Path(__file__).resolve().parent


def state_path(home: Path) -> Path:
    return home / ".config/dotfiles/work.json"


def read_state(home: Path) -> dict[str, str]:
    data = json.loads(state_path(home).read_text(encoding="utf-8"))
    if not isinstance(data, dict) or data.get("profile") != "work":
        raise ValueError("An explicit work profile is required.")
    for key in ("name", "email", "root"):
        if not isinstance(data.get(key), str) or not data[key].strip():
            raise ValueError("Incomplete work profile. Run make install-work again.")
    return data


def quote(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def global_config(home: Path, state: dict[str, str]) -> str:
    return (
        "# Managed by dotfiles work profile. No personal includes.\n"
        f"[include]\n\tpath = {quote(str(ROOT / 'config/git/work.conf'))}\n"
        f"[core]\n\thooksPath = {quote(str(ROOT / 'config/git/hooks'))}\n"
        f"[includeIf {quote('gitdir:' + state['root'] + '/')}]\n"
        f"\tpath = {quote(str(home / '.config/dotfiles/identity.gitconfig'))}\n"
    )


def validate_work_root(home: Path, raw_root: str) -> Path:
    candidate = Path(raw_root).expanduser()
    if (not candidate.is_absolute() or ".." in candidate.parts
            or any(c in raw_root for c in "*?[]\n\r\0")):
        raise ValueError("Work root must be an absolute dedicated directory without globs or parent traversal.")
    for directory in (candidate, *candidate.parents):
        if directory.resolve() == home:
            break
        if directory.is_symlink():
            raise ValueError("Work root must not contain symlinked directories.")
    resolved = candidate.resolve()
    if home not in resolved.parents:
        raise ValueError("Use a dedicated work directory beneath HOME, not HOME itself.")
    return resolved


def check_namespaces(home: Path) -> None:
    targets = [p.target for p in build_managed_paths(ROOT, home, os.environ.get("OSTYPE", "darwin"))]
    targets += [state_path(home), home / ".local/share/work/atuin/history.db",
                home / ".local/state/work/zsh/history", home / ".cache/work/file",
                home / ".local/state/dotfiles/backups/file",
                home / ".config/nvim-work/.dotfiles-check", home / ".config/tmux/.dotfiles-check"]
    for target in targets:
        if target.is_dir() and not target.is_symlink():
            raise ValueError(f"Refusing to replace directory: {target}")
        for parent in target.parents:
            if parent == home:
                break
            if parent.is_symlink():
                raise ValueError(f"Refusing a symlinked configuration directory: {parent}")
    history = home / ".local/state/work/zsh/history"
    atuin = home / ".local/share/work/atuin"
    if history.is_symlink() or any(path.is_symlink() for path in atuin.rglob("*")):
        raise ValueError("Work history state must not contain symlinks to another profile.")
    work_namespaces = [home / path for path in (".local/share/work", ".local/state/work", ".cache/work")]
    for namespace in work_namespaces:
        editor = namespace / "nvim-work"
        if editor.is_symlink():
            raise ValueError("Work editor state must not alias another directory.")
        for path in editor.rglob("*"):
            if path.is_symlink() and not any(path.resolve().is_relative_to(root) for root in work_namespaces):
                raise ValueError("Work editor state must not contain symlinks to another profile.")


def preserve_and_write(home: Path, target: Path, content: str) -> None:
    if target.is_file() and not target.is_symlink() and target.read_text(encoding="utf-8") == content:
        target.chmod(0o600)
        return
    if target.is_dir() and not target.is_symlink():
        raise ValueError(f"Refusing to replace directory: {target}")
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists() or target.is_symlink():
        backups = home / ".local/state/dotfiles/backups"
        backups.mkdir(parents=True, exist_ok=True, mode=0o700)
        backups.chmod(0o700)
        backup_dir = Path(tempfile.mkdtemp(prefix="config-", dir=backups))
        target.rename(backup_dir / target.name)
    fd, temporary = tempfile.mkstemp(dir=target.parent)
    with os.fdopen(fd, "w", encoding="utf-8") as output:
        output.write(content)
    Path(temporary).replace(target)


def preflight(home: Path) -> dict[str, str]:
    # A work namespace must not point back into another profile's directories.
    check_namespaces(home)
    previous = read_state(home) if state_path(home).exists() else {}
    name = os.environ.get("DOTFILES_WORK_GIT_NAME", previous.get("name", "")).strip()
    email = os.environ.get("DOTFILES_WORK_GIT_EMAIL", previous.get("email", "")).strip()
    raw_root = os.environ.get("DOTFILES_WORK_ROOT", previous.get("root", str(home / "Work")))
    if not name or not re.fullmatch(r"[^\s<>@]+@[^\s<>@]+", email):
        raise ValueError("Set DOTFILES_WORK_GIT_NAME and DOTFILES_WORK_GIT_EMAIL to your work identity.")
    if any(c in name + email + raw_root for c in "\n\r\0") or any(c in name for c in "<>"):
        raise ValueError("Work settings must be single-line values.")
    work_root = validate_work_root(home, raw_root)
    # Company hooks can enforce signing or policy. Do not silently replace them.
    for scope in ("--global", "--system"):
        existing = subprocess.run(["git", "config", scope, "--get-all", "core.hooksPath"],
                                  cwd=home, capture_output=True, text=True)
        if existing.returncode not in (0, 1):
            raise ValueError("Unable to inspect existing Git hooks safely.")
        for hook_path in existing.stdout.splitlines():
            if hook_path not in {str(ROOT / "config/git/hooks"), previous.get("guard_path", "")}:
                raise ValueError("Existing global/system Git hooks must be integrated before work installation.")
    # Validation precedes writes. Identity values never enter the repository.
    state = {"profile": "work", "name": name, "email": email, "root": str(work_root),
             "guard_path": str(ROOT / "config/git/hooks")}
    return state


def install(home: Path) -> None:
    state = preflight(home)
    name, email = state["name"], state["email"]
    work_root = Path(state["root"])
    private = home / ".config/dotfiles"
    private.mkdir(parents=True, exist_ok=True, mode=0o700)
    private.chmod(0o700)
    work_root.mkdir(parents=True, exist_ok=True)
    for namespace in (".local/share/work", ".local/state/work", ".cache/work"):
        directory = home / namespace
        directory.mkdir(parents=True, exist_ok=True, mode=0o700)
        directory.chmod(0o700)
    identity = f"[user]\n\tname = {quote(name)}\n\temail = {quote(email)}\n"
    preserve_and_write(home, private / "identity.gitconfig", identity)
    preserve_and_write(home, state_path(home), json.dumps(state, indent=2) + "\n")
    preserve_and_write(home, home / ".gitconfig", global_config(home, state))
    print("Work identity configured locally. Clone work repositories beneath the configured work directory.")


def git(*args: str) -> str:
    return subprocess.check_output(["git", *args], text=True, stderr=subprocess.DEVNULL).strip()


def guard(home: Path, rebase_upstream: str | None = None, rebase_branch: str = "HEAD") -> None:
    state = read_state(home)
    work_root = validate_work_root(home, state["root"])
    repository = Path(git("rev-parse", "--show-toplevel")).resolve()
    if repository != work_root and work_root not in repository.parents:
        raise ValueError("Commit blocked: repository is outside the configured work directory.")
    for role in ("GIT_AUTHOR_IDENT", "GIT_COMMITTER_IDENT"):
        ident = git("var", role)
        match = re.fullmatch(r"(.+) <([^<>]+)> \d+ [+-]\d{4}", ident)
        if not match or (match[1], match[2]) != (state["name"], state["email"]):
            raise ValueError("Commit blocked: author and committer must match the configured work identity.")
    expected_author = state["name"] + "\0" + state["email"]
    # Sequencer commands can preserve an author that git var does not expose.
    for reference in ("CHERRY_PICK_HEAD", "REBASE_HEAD"):
        result = subprocess.run(["git", "rev-parse", "--verify", "--quiet", reference],
                                capture_output=True, text=True)
        if result.returncode == 0:
            if git("show", "-s", "--format=%an%x00%ae", reference) != expected_author:
                raise ValueError("Commit blocked: preserved author must match the configured work identity.")
        elif result.returncode != 1:
            raise ValueError("Unable to inspect the preserved commit author safely.")
    if rebase_upstream is not None:
        branch = git("rev-parse", "--verify", "--end-of-options", rebase_branch + "^{commit}")
        revisions = branch
        if rebase_upstream != "--root":
            upstream = git("rev-parse", "--verify", "--end-of-options", rebase_upstream + "^{commit}")
            revisions = upstream + ".." + branch
        authors = git("log", "--format=%an%x00%ae", revisions)
        if any(author != expected_author for author in authors.splitlines()):
            raise ValueError("Rebase blocked: preserved authors must match the configured work identity.")


def verify(home: Path) -> None:
    check_namespaces(home)
    state = read_state(home)
    validate_work_root(home, state["root"])
    identity = f"[user]\n\tname = {quote(state['name'])}\n\temail = {quote(state['email'])}\n"
    if (home / ".config/dotfiles/identity.gitconfig").read_text(encoding="utf-8") != identity:
        raise ValueError("Private Git identity differs from the selected work identity.")
    if (home / ".gitconfig").read_text(encoding="utf-8") != global_config(home, state):
        raise ValueError("Global Git configuration differs from the work profile.")
    for hook in ("pre-commit", "prepare-commit-msg", "pre-rebase"):
        if not os.access(ROOT / "config/git/hooks" / hook, os.X_OK):
            raise ValueError(f"Work commit guard is not executable: {hook}")
    print("Work profile and commit guards match. Identity checks run on guarded commits.")


def clean(home: Path) -> None:
    check_namespaces(home)
    if state_path(home).exists():
        state = read_state(home)
        target = home / ".gitconfig"
        if target.is_file() and not target.is_symlink() and target.read_text(encoding="utf-8") == global_config(home, state):
            target.unlink()
    print("Private work settings, histories, and backups retained.")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["install", "preflight", "guard", "verify", "clean"])
    parser.add_argument("--expected-home", type=Path)
    parser.add_argument("--rebase-upstream")
    parser.add_argument("--rebase-branch", default="HEAD")
    args = parser.parse_args()
    try:
        home = Path.home().resolve()
        if args.expected_home is not None and args.expected_home.resolve() != home:
            raise ValueError("The selected Nix profile HOME does not match the activating user.")
        {"install": install, "preflight": preflight,
         "guard": lambda selected_home: guard(selected_home, args.rebase_upstream, args.rebase_branch),
         "verify": verify, "clean": clean}[args.command](home)
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f"Work profile: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
