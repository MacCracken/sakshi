#!/bin/sh
set -eu

# Run sakshi test suite via cyrius test (auto-discovers .tcyr files)

if [ -n "${CYRIUS:-}" ]; then
  CYRIUS="$CYRIUS"
elif command -v cyrius >/dev/null 2>&1; then
  CYRIUS="cyrius"
elif [ -x "$HOME/.cyrius/bin/cyrius" ]; then
  CYRIUS="$HOME/.cyrius/bin/cyrius"
elif [ -x "./build/cyrius" ]; then
  CYRIUS="./build/cyrius"
else
  echo "error: cyrius not found" >&2; exit 1
fi

echo "=== sakshi test suite ==="
"$CYRIUS" test
