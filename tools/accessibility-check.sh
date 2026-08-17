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
    [[ -z "${assertion}" ]] && continue
    wanted="${assertion%% *}"
    tag="${assertion#* }"

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
