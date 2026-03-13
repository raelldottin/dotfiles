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

while IFS= read -r repo_file; do
  assert_installed_file_matches "$repo_file" "$(dotfiles_target_for_repo_file "$REPO_ROOT" "$repo_file")"
done < <(dotfiles_each_nvim_file "$REPO_ROOT")

assert_installed_file_matches "$REPO_ROOT/zshrc" "$HOME/.zshrc"
assert_installed_file_matches "$REPO_ROOT/pylintrc" "$HOME/.pylintrc"

case "${OSTYPE:-}" in
  linux-gnu*)
    assert_installed_file_matches "$REPO_ROOT/linux-gnu_tmux.conf" "$HOME/.tmux.conf"
    ;;
  darwin*)
    assert_installed_file_matches "$REPO_ROOT/darwin_tmux.conf" "$HOME/.tmux.conf"
    ;;
  *)
    record_failure "Unable to determine operating system."
    ;;
esac

if (( FAILURES > 0 )); then
  echo "Tests complete with $FAILURES failure(s)."
  exit 1
fi

echo "Tests complete."
