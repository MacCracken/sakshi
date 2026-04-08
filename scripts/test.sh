#!/bin/sh
set -eu

# Run sakshi test suite (.tcyr files)
# Expects: build/cc2 and build/cyrb available

if [ -n "${CYRB:-}" ]; then
  CYRB="$CYRB"
elif command -v cyrb >/dev/null 2>&1; then
  CYRB="cyrb"
elif [ -x "$HOME/.cyrius/bin/cyrb" ]; then
  CYRB="$HOME/.cyrius/bin/cyrb"
elif [ -x "./build/cyrb" ]; then
  CYRB="./build/cyrb"
else
  echo "error: cyrb not found" >&2; exit 1
fi
BUILD_DIR="${BUILD_DIR:-./build}"

echo "=== sakshi test suite ==="

FAIL=0
for tcyr in tests/*.tcyr; do
  name=$(basename "$tcyr" .tcyr)
  echo "--- $name ---"
  "$CYRB" build "$tcyr" "$BUILD_DIR/$name"
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
