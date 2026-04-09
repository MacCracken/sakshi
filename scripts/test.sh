#!/bin/sh
set -eu

# Run sakshi test suite (.tcyr files)

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
BUILD_DIR="${BUILD_DIR:-./build}"

echo "=== sakshi test suite ==="

FAIL=0
for tcyr in tests/*.tcyr; do
  name=$(basename "$tcyr" .tcyr)
  echo "--- $name ---"
  "$CYRIUS" build "$tcyr" "$BUILD_DIR/$name"
  if "$BUILD_DIR/$name" 2>&1; then
    echo "PASS: $name"
  else
    echo "FAIL: $name"
    FAIL=1
  fi
  echo ""
done

if [ "$FAIL" -eq 0 ]; then
  echo "=== all tests passed ==="
  exit 0
else
  echo "=== some tests failed ==="
  exit 1
fi
