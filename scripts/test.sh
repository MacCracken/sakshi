#!/usr/bin/env bash
set -euo pipefail

# Run sakshi test suite
# Expects: build/cc2 and build/cyrb in PATH or ./build/

CYRB="${CYRB:-./build/cyrb}"
BUILD_DIR="${BUILD_DIR:-./build}"

echo "=== sakshi test suite ==="

# Build test program
"$CYRB" build programs/test_sakshi.cyr "$BUILD_DIR/test_sakshi"
echo "built: $BUILD_DIR/test_sakshi ($(wc -c < "$BUILD_DIR/test_sakshi") bytes)"

# Run and capture output (sakshi logs to stderr)
OUTPUT=$("$BUILD_DIR/test_sakshi" 2>&1) || {
  echo "FAIL: test_sakshi exited non-zero"
  echo "$OUTPUT"
  exit 1
}

echo "$OUTPUT"

# Verify all tests passed
if echo "$OUTPUT" | grep -q "all tests passed"; then
  echo ""
  echo "PASS: all tests"
  exit 0
else
  echo ""
  echo "FAIL: 'all tests passed' not found in output"
  exit 1
fi
