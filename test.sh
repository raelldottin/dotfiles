#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/dotfiles.sh"

REPO_ROOT="$(dotfiles_repo_root)"
FAILURES=0

record_failure() {
  local message="$1"

  echo "$message"
  FAILURES=$((FAILURES + 1))
}

assert_installed_file_matches() {
  local source_path="$1"
  local target_path="$2"

  if [[ ! -r "$source_path" ]]; then
    record_failure "$source_path is not readable."
    return
  fi

  if [[ ! -r "$target_path" ]]; then
    record_failure "$target_path is not readable."
    return
  fi

  if ! diff "$source_path" "$target_path" >/dev/null; then
    record_failure "$source_path and $target_path are out of sync."
  fi
}

echo "Running tests on configuration files:"

while IFS=$'\t' read -r source_path target_path _; do
  assert_installed_file_matches "$source_path" "$target_path"
done < <(dotfiles_each_managed_file "$REPO_ROOT")

if (( FAILURES > 0 )); then
  echo "Tests complete with $FAILURES failure(s)."
  exit 1
fi

echo "Tests complete."
