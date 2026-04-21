#!/bin/sh
set -eu

# Bump version across all files
NEW_VERSION="${1:?Usage: $0 <new-version>}"

# VERSION file (source of truth)
echo "$NEW_VERSION" > VERSION

# cyrius.cyml
sed -i "s/^version = \".*\"/version = \"$NEW_VERSION\"/" cyrius.cyml

# CHANGELOG.md — add section header if missing
if ! grep -q "## \[$NEW_VERSION\]" CHANGELOG.md; then
  sed -i "/^## \[/i ## [$NEW_VERSION] - Unreleased\n" CHANGELOG.md
fi

echo "Bumped to $NEW_VERSION"
echo ""
echo "Updated: VERSION, cyrius.cyml, CHANGELOG.md"
echo ""
echo "Next steps:"
echo "  git add VERSION cyrius.cyml CHANGELOG.md"
echo "  git commit -m 'release: $NEW_VERSION'"
echo "  git tag $NEW_VERSION"
echo "  git push origin main --tags"
