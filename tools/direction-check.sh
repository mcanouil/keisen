#!/usr/bin/env bash
# Holds a formatted number to reading the same way in both writing directions,
# and to reading the way it is supposed to in either.
#
# Decimal alignment pads each number with six boxes, and Typst lays inline
# boxes out along the writing direction, so a number inherits the paragraph's
# and comes out backwards in right-to-left text: 1256.75 renders as 75.256 1.
# The number run is pinned to ltr for that reason.
#
# Asserting the pin from inside a document is not possible: a set rule leaves
# an opaque `styles` value, so a test can see that some rule wraps the run but
# not which. This reads the render instead.
#
# Two things are asserted, and the second is why the first is not enough. The
# two renders must agree with each other, and both must agree with a recorded
# order. Comparing the renders alone passes a pin that is wrong in the same way
# both times, which is exactly the failure a reversed number would be.
#
# Record a fixture's order with:
#
#   tools/direction-check.sh --record
#
# and read the diff before committing it.

set -euo pipefail

# A recorded order is compared byte for byte between a developer's machine and
# the runner, and the numbers it is sorted by are read and printed by tools that
# take the decimal separator from the locale.
export LC_ALL=C

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

OUT_DIR="${OUT_DIR:-/tmp/keisen-check}"
mkdir -p "${OUT_DIR}"

# Refused rather than ignored. `--recrod` would otherwise run the verification
# and print `direction: ok`, reporting success at the job the caller thought
# they had asked for, and `--record number` would drop the fixture name and
# rewrite every record instead of the one named.
RECORD=0
if [[ $# -gt 1 ]] || [[ $# -eq 1 && "${1}" != "--record" ]]; then
  printf 'direction: usage: direction-check.sh [--record]\n' >&2
  exit 2
fi
if [[ $# -eq 1 ]]; then
  RECORD=1
fi

# Every glyph on the page, in reading order.
#
# A glyph's own x and y are relative to the groups it sits in, and Typst nests
# one group per cell inside one per row. Reading the attribute alone, as this
# did, sorted glyphs by their offset within a cell rather than by where they sit
# on the page, so a glyph early in a late cell sorted ahead of one late in an
# early cell. The enclosing translations are composed here instead.
#
# A glyph's own y is composed as well as its x, and the vertical flip its text
# run sits under is carried with it. Typst writes y="0" on every `<use>` it has
# been seen to emit, raised runs included: a footnote mark is moved by a group
# of its own rather than by the attribute. The attribute is read anyway, because
# it exists in the format and an ordering that silently ignores half a
# coordinate is the defect this rewrite is for.
#
# A transform this cannot read is refused rather than approximated. Skew would
# make a single offset per axis meaningless, and reporting the glyphs in a
# plausible but wrong order is what this whole change exists to stop.
#
# The identifiers are content hashes, so the same glyph carries the same
# identifier in both renders whatever font resolved.
glyph_order() {
  awk '
    BEGIN { RS = "<"; depth = 0; x[0] = 0; y[0] = 0; flip[0] = 1 }
    /^g[ >]/ {
      dx = 0
      dy = 0
      sign = 1
      if (match($0, /transform="translate\([^)]*\)/)) {
        split(substr($0, RSTART + 21, RLENGTH - 22), t, / +/)
        dx = t[1] + 0
        dy = t[2] + 0
      } else if (match($0, /transform="matrix\([^)]*\)/)) {
        split(substr($0, RSTART + 18, RLENGTH - 19), m, / +/)
        if (m[2] + 0 != 0 || m[3] + 0 != 0) {
          print "direction: a skewed transform this cannot order: " $0 > "/dev/stderr"
          exit 1
        }
        dx = m[5] + 0
        dy = m[6] + 0
        sign = m[4] + 0
      }
      depth++
      x[depth] = x[depth - 1] + dx
      y[depth] = y[depth - 1] + dy
      flip[depth] = flip[depth - 1] * sign
      # A self-closing group encloses nothing, so it opens and shuts at once.
      if ($0 ~ /\/>/) { depth-- }
      next
    }
    /^\/g>/ { if (depth > 0) { depth-- } next }
    /^use / {
      if (match($0, /xlink:href="#g[0-9A-F]+"/)) {
        id = substr($0, RSTART + 14, RLENGTH - 15)
        gx = 0
        gy = 0
        if (match($0, / x="-?[0-9.]+"/)) { gx = substr($0, RSTART + 4, RLENGTH - 5) + 0 }
        if (match($0, / y="-?[0-9.]+"/)) { gy = substr($0, RSTART + 4, RLENGTH - 5) + 0 }
        printf "%9.3f %9.3f %s\n", y[depth] + flip[depth] * gy, x[depth] + gx, id
      }
    }
  ' "$1" |
    sort -k1,1n -k2,2n |
    awk '{ print $3 }'
}

failures=0
fixtures=0

for fixture in tests/direction/*.typ; do
  fixtures=$((fixtures + 1))
  name="$(basename "${fixture%.typ}")"
  expected="tests/direction/${name}.order"

  for direction in ltr rtl; do
    typst compile "${fixture}" --root "${REPO_ROOT}" \
      --input "direction=${direction}" \
      --format svg "${OUT_DIR}/direction-${name}-${direction}.svg" \
      --ignore-system-fonts

    glyph_order "${OUT_DIR}/direction-${name}-${direction}.svg" \
      >"${OUT_DIR}/direction-${name}-${direction}.order"
  done

  # A render carrying no glyphs would compare equal to another one, and report
  # that the thing under test holds.
  if [[ ! -s "${OUT_DIR}/direction-${name}-ltr.order" ]]; then
    printf '  FAIL  direction  %s  rendered no glyphs\n' "${fixture}" >&2
    failures=$((failures + 1))
    continue
  fi

  # Checked before recording as well as before comparing. Recording from a tree
  # whose pin is broken would bake the broken order in, and the check would then
  # agree with it for good.
  if ! diff -q "${OUT_DIR}/direction-${name}-ltr.order" "${OUT_DIR}/direction-${name}-rtl.order" >/dev/null; then
    printf '  FAIL  direction  %s  reads differently in right-to-left text\n' "${fixture}" >&2
    printf '        the glyphs come out in another order; a number is not pinned to ltr\n' >&2
    failures=$((failures + 1))
    continue
  fi

  if [[ ${RECORD} -eq 1 ]]; then
    {
      printf '# The glyphs of %s, in reading order.\n' "${fixture}"
      printf '# Content hashes of the outlines Typst embeds, recorded by\n'
      printf '# tools/direction-check.sh --record. Regenerate rather than edit.\n'
      cat "${OUT_DIR}/direction-${name}-ltr.order"
    } >"${expected}"
    printf '  recorded  %s  %s glyphs\n' "${expected}" \
      "$(wc -l <"${OUT_DIR}/direction-${name}-ltr.order" | tr -d ' ')"
    continue
  fi

  if [[ ! -f "${expected}" ]]; then
    printf '  FAIL  direction  %s  has no recorded order\n' "${fixture}" >&2
    printf '        run tools/direction-check.sh --record and commit %s\n' "${expected}" >&2
    failures=$((failures + 1))
    continue
  fi

  # Both renders agree; either will do against the record. `|| true` because a
  # record holding nothing but its header makes grep exit 1, which under
  # pipefail would end the run with no word about which file was at fault.
  grep -v '^#' "${expected}" >"${OUT_DIR}/direction-${name}.expected" || true
  if [[ ! -s "${OUT_DIR}/direction-${name}.expected" ]]; then
    printf '  FAIL  direction  %s  the recorded order holds no glyphs\n' "${fixture}" >&2
    printf '        %s was truncated; record it again\n' "${expected}" >&2
    failures=$((failures + 1))
    continue
  fi

  if ! diff -q "${OUT_DIR}/direction-${name}.expected" "${OUT_DIR}/direction-${name}-ltr.order" >/dev/null; then
    printf '  FAIL  direction  %s  reads differently from the recorded order\n' "${fixture}" >&2
    printf '        both directions agree with each other and neither agrees with %s\n' "${expected}" >&2
    printf '        a pin wrong in the same way both times looks right to a comparison alone\n' >&2
    failures=$((failures + 1))
  fi
done

# No fixture at all would report success having read nothing.
if [[ ${fixtures} -eq 0 ]]; then
  printf 'direction: no fixture under tests/direction\n' >&2
  exit 1
fi

if [[ ${failures} -gt 0 ]]; then
  exit 1
fi

if [[ ${RECORD} -eq 1 ]]; then
  printf 'direction: recorded\n'
else
  printf 'direction: ok\n'
fi
