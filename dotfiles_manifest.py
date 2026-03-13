from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import argparse


@dataclass(frozen=True)
class ManagedPath:
    source: Path
    target: Path
    category: str


def resolve_tmux_config_name(ostype: str) -> str:
    if ostype.startswith("linux-gnu"):
        return "linux-gnu_tmux.conf"
    if ostype.startswith("darwin"):
        return "darwin_tmux.conf"
    raise ValueError(f"Unsupported OSTYPE: {ostype}")


def iter_nvim_repo_files(repo_root: Path) -> list[Path]:
    nvim_root = repo_root / "config" / "nvim"
    return sorted(path for path in nvim_root.rglob("*") if path.is_file())


def build_managed_paths(repo_root: Path, home: Path, ostype: str) -> list[ManagedPath]:
    managed_paths = [
        ManagedPath(repo_root / "zshrc", home / ".zshrc", "zsh"),
        ManagedPath(repo_root / resolve_tmux_config_name(ostype), home / ".tmux.conf", "tmux"),
        ManagedPath(repo_root / "pylintrc", home / ".pylintrc", "python"),
    ]

    for repo_file in iter_nvim_repo_files(repo_root):
        relative_path = repo_file.relative_to(repo_root / "config" / "nvim")
        managed_paths.append(
            ManagedPath(
                repo_file,
                home / ".config" / "nvim" / relative_path,
                "nvim",
            )
        )

    return managed_paths


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Inspect the managed dotfiles install manifest.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    nvim_files_parser = subparsers.add_parser("nvim-files")
    nvim_files_parser.add_argument("--repo-root", type=Path, required=True)

    managed_files_parser = subparsers.add_parser("managed-files")
    managed_files_parser.add_argument("--repo-root", type=Path, required=True)
    managed_files_parser.add_argument("--home", type=Path, required=True)
    managed_files_parser.add_argument("--ostype", required=True)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if args.command == "nvim-files":
        for repo_file in iter_nvim_repo_files(args.repo_root.resolve()):
            print(repo_file)
        return 0

    if args.command == "managed-files":
        try:
            managed_paths = build_managed_paths(
                repo_root=args.repo_root.resolve(),
                home=args.home.resolve(),
                ostype=args.ostype,
            )
        except ValueError as error:
            parser.error(str(error))

        for managed_path in managed_paths:
            print(f"{managed_path.source}\t{managed_path.target}\t{managed_path.category}")
        return 0

    parser.error(f"Unsupported command: {args.command}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
