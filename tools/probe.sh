#!/usr/bin/env bash
# Reads the rendered output for the marks a theme promises.
#
# Compile tests prove a document compiles, not that it looks right. A table
# without source notes once drew no closing rule and the whole suite stayed
# green, because every visual test happened to carry a note.
#
# Each probe under tests/probe compiles to SVG, which is text, and names what
# must appear in it and what must not:
#
#   // expect-svg: stroke="#ff0000"
#   // reject-svg: stroke="#00ff00"
#
# Probes give each rule a colour of its own, so an assertion names one rule
# rather than "some stroke somewhere".

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

OUT_DIR="${OUT_DIR:-/tmp/keisen-check}"
mkdir -p "${OUT_DIR}"

shopt -s nullglob

passed=0
total=0
failed=0

for f in tests/probe/*.typ; do
  total=$((total + 1))
  name="$(basename "${f%.typ}")"
  svg="${OUT_DIR}/probe-${name}.svg"

  if ! typst compile "${f}" --root "${REPO_ROOT}" "${svg}" --format svg 2>"${OUT_DIR}/probe-${name}.err"; then
    failed=$((failed + 1))
    printf '  FAIL  probe  %s  did not compile\n' "${f}" >&2
    sed -n '1,5p' "${OUT_DIR}/probe-${name}.err" >&2
    continue
  fi

  ok=1

  while IFS= read -r wanted; do
    [[ -z "${wanted}" ]] && continue
    if ! grep -qF "${wanted}" "${svg}"; then
      ok=0
      printf '  FAIL  probe  %s  missing from the render\n' "${f}" >&2
      printf '        wanted: %s\n' "${wanted}" >&2
    fi
  done < <(sed -n 's|^// expect-svg: ||p' "${f}")

  while IFS= read -r unwanted; do
    [[ -z "${unwanted}" ]] && continue
    if grep -qF "${unwanted}" "${svg}"; then
      ok=0
      printf '  FAIL  probe  %s  present in the render and should not be\n' "${f}" >&2
      printf '        rejected: %s\n' "${unwanted}" >&2
    fi
  done < <(sed -n 's|^// reject-svg: ||p' "${f}")

  # A probe that asserts nothing passes silently and proves nothing.
  if ! grep -qE '^// (expect|reject)-svg: ' "${f}"; then
    ok=0
    printf '  FAIL  probe  %s  asserts nothing\n' "${f}" >&2
  fi

  if [[ ${ok} -eq 1 ]]; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi
done

printf '%-9s %d/%d\n' "probe:" "${passed}" "${total}"

[[ ${failed} -eq 0 ]]
