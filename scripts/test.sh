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

# The raw-include test again, built with NO auto-prepend: `cyrius test` supplies
# the [deps] stdlib, which masks a bundle missing its requires block. See the
# header of tests/tcyr/raw_include.tcyr. Matches CI.
echo "=== raw include of dist/sakshi.cyr (no auto-prepend) ==="
mkdir -p build
"$CYRIUS" build --no-deps tests/tcyr/raw_include.tcyr build/raw_include
./build/raw_include
echo "raw include: ok"
