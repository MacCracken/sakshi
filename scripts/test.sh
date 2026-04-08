#!/usr/bin/env bash
set -euo pipefail

# Run sakshi test suite (.tcyr files)
# Expects: build/cc2 and build/cyrb available

CYRB="${CYRB:-./build/cyrb}"
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
