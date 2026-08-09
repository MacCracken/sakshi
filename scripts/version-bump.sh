#!/bin/sh
set -eu

# Bump version across all files
NEW_VERSION="${1:?Usage: $0 <new-version>}"

# VERSION file (source of truth)
echo "$NEW_VERSION" > VERSION

# cyrius.cyml derives its version from VERSION via `version = "${file:VERSION}"`,
# so there is nothing to rewrite here — touching it would clobber the template
# with a stale literal.

# CHANGELOG.md — add section header if missing.
#
# ⚠ DATE THE HEADING WHEN YOU TAG. The awk below strips every
# "## [X] - Unreleased" stub, so a released-but-still-"Unreleased" heading is
# DELETED by the next bump and its notes silently fold into the new version.
# That is exactly what happened to 2.4.8 (tagged 2026-08-05, heading left as
# Unreleased) and was caught during the 2.4.9 bump.
# `sed -i "/PATTERN/i ..."` inserts before EVERY matching line, not just the
# first, so we use awk to insert exactly once before the first ^## [ heading.
# Also strips any pre-existing "## [X] - Unreleased" stubs (left over from the
# pre-v2.2.0 version of this script — see CHANGELOG v2.2.0 Fixed).
if ! grep -q "## \[$NEW_VERSION\]" CHANGELOG.md; then
  awk -v ver="$NEW_VERSION" '
    !inserted && /^## \[/ {
      print "## [" ver "] - Unreleased"
      print ""
      inserted = 1
    }
    !/^## \[.*\] - Unreleased$/ { print }
  ' CHANGELOG.md > CHANGELOG.md.tmp && mv CHANGELOG.md.tmp CHANGELOG.md
fi

echo "Bumped to $NEW_VERSION"
echo ""
echo "Updated: VERSION, CHANGELOG.md (cyrius.cyml tracks VERSION automatically)"
echo ""
echo "Next steps:"
echo "  git add VERSION CHANGELOG.md"
echo "  git commit -m 'release: $NEW_VERSION'"
echo "  git tag $NEW_VERSION"
echo "  git push origin main --tags"
