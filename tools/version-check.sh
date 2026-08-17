#!/usr/bin/env bash
# Holds every place a version is written to the same value.
#
# typst.toml is what Typst Universe publishes, CITATION.cff is what a citation
# resolves to, and CHANGELOG.md is what a reader is told changed. Bumping one
# and forgetting another is silent, and permanent once published.
#
# The import lines the README and the documentation show are the fourth place,
# and the only one a reader copies.

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

# The import line is what a reader copies, and it carries the version by hand.
# README.md reaches furthest: tools/stage-readme.sh keeps its quick look for the
# packaged README, which Typst Universe renders on the package page, so a stale
# import there is published alongside the release it misnames.
#
# The documentation's listings are compiled against an installed copy by
# tools/dry-release.sh, which catches a stale one as a Typst compile error. That
# is the release rehearsal; tools/check.sh runs before every commit and runs
# this script instead, so without this check the first report comes late and
# names a missing package rather than a version.
#
# Tracked files are scanned rather than listed, so a page written after this was
# is covered on the day it is written.
#
# A placeholder is not a version. ARCHITECTURE.md writes `x.y.z` and
# CONTRIBUTING.md writes `<version>`, and a semantic version matches neither.
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "version: not a git checkout, so the import lines cannot be read" >&2
  exit 1
fi

# git grep reads the tracked files, skips the binary ones, and carries a path
# with a space in it through unharmed.
stale="$(git grep -nEo '@preview/keisen:[0-9]+\.[0-9]+\.[0-9]+' |
  awk -F'@preview/keisen:' -v want="${manifest}" '$2 != want' || true)"

if [[ -n "${stale}" ]]; then
  printf 'version: an import names a version the manifest does not\n' >&2
  printf '  typst.toml: %s\n' "${manifest}" >&2
  # Every offender, rather than the first: a bump is then one pass over the
  # repository instead of one run of this script per file.
  printf '%s\n' "${stale}" |
    awk -F'@preview/keisen:' '{ sub(/:$/, "", $1); printf "  %s names %s\n", $1, $2 }' >&2
  exit 1
fi

printf 'version:  %s\n' "${manifest}"
