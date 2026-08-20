#!/usr/bin/env bash
# Reads the PDF structure tree for the header cells a table promises.
#
# The design says `table.header` carries accessibility metadata "for free by
# construction". Free is not the same as true: nothing here compiled a tagged
# PDF, and no document can read its own tags back, so the claim stood on
# nobody's word.
#
# Each fixture under tests/accessibility compiles to PDF/UA-1, which Typst
# refuses to produce for a document it cannot tag, so the compile is the first
# assertion. The tagged PDF is then written with --pretty, where the structure
# tree is plain text, and every structure type and scope in it is counted.
#
# A fixture names the counts it wants:
#
#   // expect-tag: 3 /S /TH
#   // expect-tag: 3 /Scope /Column
#   // expect-tag: 0 /Scope /Row
#
# Counts rather than presence, because one tagged header cell out of three
# reads as coverage while two columns go unlabelled. A count of zero says a tag
# must be absent, which is how a documented limitation is pinned.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

# One assertion, read into the count it wants and the tag it counts.
#
# The shape is refused before anything is compared, because a count that is not
# a number is an arithmetic error: `[[ "0" -ne "/S" ]]` raises, and inside an
# `if` condition `set -e` does not catch it, so the condition read false and the
# fixture was marked passed. A line reading `// expect-tag: /S /TH`, with the
# count left out, was a fixture that asserted nothing and said so to nobody.
#
# Written as a function of a string, so --self-test below can run every branch:
# the live path needs a compiled PDF, and every fixture in the tree is well
# formed, so only the passing shape would ever run.
read_assertion() {
  local assertion="$1"
  [[ "${assertion}" =~ ^([0-9]+)[[:space:]]+([^[:space:]].*)$ ]] || return 1
  printf '%s\n%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
}

if [[ "${1:-}" == "--self-test" ]]; then
  cases=0
  bad=0

  expect() {
    local wanted="$1" count="$2" tag="$3" assertion="$4" name="$5"
    cases=$((cases + 1))
    local got=0 read_back
    read_back="$(read_assertion "${assertion}")" || got=$?
    if [[ "${got}" -ne "${wanted}" ]]; then
      bad=$((bad + 1))
      printf '  FAIL  self-test  %s  wanted exit %s, got %s\n' "${name}" "${wanted}" "${got}" >&2
      return
    fi
    [[ "${wanted}" -ne 0 ]] && return
    if [[ "${read_back%%$'\n'*}" != "${count}" ]]; then
      bad=$((bad + 1))
      printf '  FAIL  self-test  %s  wanted the count %s\n' "${name}" "${count}" >&2
      return
    fi
    if [[ "${read_back#*$'\n'}" != "${tag}" ]]; then
      bad=$((bad + 1))
      printf '  FAIL  self-test  %s  wanted the tag %s\n' "${name}" "${tag}" >&2
    fi
  }

  expect 0 '3' '/S /TH' '3 /S /TH' 'a count and a tag'
  expect 0 '0' '/Scope /Row' '0 /Scope /Row' 'a count of zero, which pins an absence'
  expect 0 '3' '/S /TH' '3   /S /TH' 'more than one space between them'
  expect 1 '' '' '/S /TH' 'the count left out'
  expect 1 '' '' 'three /S /TH' 'the count written as a word'
  expect 1 '' '' '3' 'a count naming no tag'
  expect 1 '' '' '3 ' 'a count and a space'
  expect 1 '' '' '' 'an assertion that reads as nothing'

  if [[ ${bad} -gt 0 ]]; then
    printf 'accessibility: %d/%d self-test case(s) failed\n' "${bad}" "${cases}" >&2
    exit 1
  fi

  printf 'accessibility: self-test %d/%d\n' "${cases}" "${cases}"
  exit 0
fi

# An argument this does not know is a typo, and a typo that runs the live check
# and reports a pass is how a caller loses the self-test without noticing.
if [[ $# -gt 0 ]]; then
  printf 'accessibility: unknown argument %s\n' "$1" >&2
  printf '  the only one is --self-test\n' >&2
  exit 1
fi

OUT_DIR="${OUT_DIR:-/tmp/keisen-check}"
mkdir -p "${OUT_DIR}"

shopt -s nullglob

passed=0
total=0
failed=0

for f in tests/accessibility/*.typ; do
  total=$((total + 1))
  name="$(basename "${f%.typ}")"
  pdf="${OUT_DIR}/accessibility-${name}.pdf"
  tags="${OUT_DIR}/accessibility-${name}.tags"

  if ! typst compile "${f}" --root "${REPO_ROOT}" "${pdf}" \
    --pdf-standard ua-1 --pretty 2>"${OUT_DIR}/accessibility-${name}.err"; then
    failed=$((failed + 1))
    printf '  FAIL  accessibility  %s  did not compile to PDF/UA-1\n' "${f}" >&2
    sed -n '1,5p' "${OUT_DIR}/accessibility-${name}.err" >&2
    continue
  fi

  # One token per line, so a count is an exact match rather than a substring:
  # /S /TH otherwise counts every /S /THead as well.
  grep -a -o -E '/(S|Scope) /[A-Za-z0-9]+' "${pdf}" | sort >"${tags}"

  ok=1

  while IFS= read -r assertion; do
    if ! read_back="$(read_assertion "${assertion}")"; then
      ok=0
      printf '  FAIL  accessibility  %s  an assertion is malformed\n' "${f}" >&2
      printf '        read: // expect-tag: %s\n' "${assertion}" >&2
      printf '        an assertion reads "// expect-tag: <count> <tag>"\n' >&2
      continue
    fi
    wanted="${read_back%%$'\n'*}"
    tag="${read_back#*$'\n'}"

    found="$(grep -c -x -F "${tag}" "${tags}" || true)"
    if [[ "${found}" -ne "${wanted}" ]]; then
      ok=0
      printf '  FAIL  accessibility  %s  the structure tree carries the wrong count\n' "${f}" >&2
      printf '        %s: wanted %s, found %s\n' "${tag}" "${wanted}" "${found}" >&2
    fi
  done < <(sed -n 's|^// expect-tag: ||p' "${f}")

  # A fixture that asserts nothing compiles forever and proves nothing.
  if ! grep -qE '^// expect-tag: ' "${f}"; then
    ok=0
    printf '  FAIL  accessibility  %s  asserts nothing\n' "${f}" >&2
  fi

  # A line that looks like an assertion and was not read is worse than none at
  # all, because the fixture reads as covered. Counted loosely on purpose:
  # anchoring this the way the extractor is anchored would let an indented line,
  # or `//expect-tag:` without the space, be missed by both.
  written="$(grep -cE '^[[:space:]]*//.*expect-tag:' "${f}" || true)"
  read_lines="$(grep -cE '^// expect-tag: ' "${f}" || true)"
  if [[ "${written}" -ne "${read_lines}" ]]; then
    ok=0
    printf '  FAIL  accessibility  %s  %s assertion line(s) written, %s read\n' \
      "${f}" "${written}" "${read_lines}" >&2
    printf '        an assertion reads "// expect-tag: <count> <tag>", with one space either side of the colon\n' >&2
  fi

  if [[ ${ok} -eq 1 ]]; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi
done

# No fixture at all would report success having read nothing.
if [[ ${total} -eq 0 ]]; then
  printf 'accessibility: no fixture under tests/accessibility\n' >&2
  exit 1
fi

printf '%-9s %d/%d\n' "accessibility:" "${passed}" "${total}"

[[ ${failed} -eq 0 ]]
