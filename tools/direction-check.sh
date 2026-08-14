#!/usr/bin/env bash
# Holds a formatted number to reading the same way in both writing directions.
#
# Decimal alignment pads each number with six boxes, and Typst lays inline
# boxes out along the writing direction, so a number inherits the paragraph's
# and comes out backwards in right-to-left text: 1256.75 renders as 75.256 1.
# The number run is pinned to ltr for that reason.
#
# Asserting the pin from inside a document is not possible: a set rule leaves
# an opaque `styles` value, so a test can see that some rule wraps the run but
# not which. This reads the render instead. The same document is compiled in
# both directions, every glyph on the page is ordered by its horizontal
# position, and the two sequences must match.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

OUT_DIR="${OUT_DIR:-/tmp/keisen-check}"
mkdir -p "${OUT_DIR}"

# The glyph identifiers are content hashes, so the same glyph carries the same
# identifier in both renders whatever font resolved.
glyph_order() {
  grep -o '<use xlink:href="#g[0-9A-F]*" x="[-0-9.]*"' "$1" |
    sed -E 's/.*#(g[0-9A-F]*)" x="([-0-9.]*)".*/\2 \1/' |
    sort -n |
    awk '{ print $2 }'
}

failures=0

for fixture in tests/direction/*.typ; do
  name="$(basename "${fixture%.typ}")"

  for direction in ltr rtl; do
    typst compile "${fixture}" --root "${REPO_ROOT}" \
      --input "direction=${direction}" \
      --format svg "${OUT_DIR}/direction-${name}-${direction}.svg" 2>/dev/null
  done

  glyph_order "${OUT_DIR}/direction-${name}-ltr.svg" >"${OUT_DIR}/direction-${name}-ltr.order"
  glyph_order "${OUT_DIR}/direction-${name}-rtl.svg" >"${OUT_DIR}/direction-${name}-rtl.order"

  # A render carrying no glyphs would compare equal to another one, and report
  # that the thing under test holds.
  if [[ ! -s "${OUT_DIR}/direction-${name}-ltr.order" ]]; then
    printf '  FAIL  direction  %s  rendered no glyphs\n' "${fixture}" >&2
    failures=$((failures + 1))
    continue
  fi

  if ! diff -q "${OUT_DIR}/direction-${name}-ltr.order" "${OUT_DIR}/direction-${name}-rtl.order" >/dev/null; then
    printf '  FAIL  direction  %s  reads differently in right-to-left text\n' "${fixture}" >&2
    printf '        the glyphs come out in another order; a number is not pinned to ltr\n' >&2
    failures=$((failures + 1))
  fi
done

if [[ ${failures} -gt 0 ]]; then
  exit 1
fi

printf 'direction: ok\n'
