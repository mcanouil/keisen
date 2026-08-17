#!/usr/bin/env bash
# Holds the three places a version is written to the same value.
#
# typst.toml is what Typst Universe publishes, CITATION.cff is what a citation
# resolves to, and CHANGELOG.md is what a reader is told changed. Bumping one
# and forgetting another is silent, and permanent once published.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

manifest="$(awk -F'"' '/^version[[:space:]]*=/ { print $2; exit }' typst.toml)"
citation="$(awk '/^version:[[:space:]]*/ { print $2; exit }' CITATION.cff)"

if [[ -z "${manifest}" ]]; then
  echo "version: typst.toml carries no version" >&2
  exit 1
fi

if [[ "${manifest}" != "${citation}" ]]; then
  printf 'version: typst.toml and CITATION.cff disagree\n' >&2
  printf '  typst.toml:   %s\n' "${manifest}" >&2
  printf '  CITATION.cff: %s\n' "${citation:-<none>}" >&2
  exit 1
fi

# Either the version has a dated section of its own, or the changes are still
# being gathered under Unreleased. Neither means the changelog was never
# touched.
#
# The two accepted headings are the grammar docs/_scripts/pre-render.sh reads to
# build the changelog page. It matches `## Unreleased` and `## X.Y.Z (date)`, and
# nothing else, so a heading written any other way reaches the site as loose text
# under no version at all. Checking the same grammar here is what keeps the two
# from disagreeing in silence.
escaped="${manifest//./\\.}"
if ! grep -qE "^## (Unreleased|${escaped} \([0-9]{4}-[0-9]{2}-[0-9]{2}\))$" CHANGELOG.md; then
  printf 'version: CHANGELOG.md holds no dated section for %s and none for Unreleased\n' "${manifest}" >&2
  printf '  expected: "## %s (YYYY-MM-DD)" or "## Unreleased"\n' "${manifest}" >&2
  exit 1
fi

printf 'version:  %s\n' "${manifest}"
