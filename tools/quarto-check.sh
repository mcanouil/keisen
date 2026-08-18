#!/usr/bin/env bash
# Renders the package through Quarto's Typst path.
#
# Most R and Python users reach a Typst table through Quarto, and none of them
# write `#figure`: they put the table alone inside a cross-referenced div and
# let Quarto own the float, the number and the caption. That path crosses
# Pandoc, Quarto's crossref filter and its Typst template before a single line
# of this package runs, and nothing here had ever compiled it.
#
# Each fixture under tests/quarto is rendered to Typst with `keep-typ`, so both
# artefacts can be read: the Typst document Quarto generated, and the PDF it
# compiled. A fixture names what each must contain, in HTML comments, which
# Pandoc drops on the way to Typst so an assertion never matches itself:
#
#   <!-- expect-typ: #figure( -->
#   <!-- reject-typ: ?@tbl-sales -->
#   <!-- expect-pdf: /Table -->
#
# Rendering happens in a staging directory rather than in place, so a check
# leaves no artefacts in the working tree. Quarto passes `--root` to Typst only
# for a project, and ignores TYPST_ROOT, so Typst's root is the directory the
# generated document sits in: the staging directory links the package into it,
# which is what makes `#import "/lib.typ"` resolve.
#
# Quarto carries a Typst of its own, and every release so far carries 0.13.0,
# which is older than the compiler typst.toml requires. QUARTO_TYPST points it
# at the one on PATH instead, so this checks the part of Quarto that belongs to
# Quarto: Pandoc, the crossref filter and the Typst template. Which compiler a
# Quarto user ends up with is a question about the package's minimum version,
# and belongs nowhere near a float.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

OUT_DIR="${OUT_DIR:-/tmp/keisen-check}"
STAGE="${OUT_DIR}/quarto"

# Loudly, rather than as a skip. A check that passes on a machine without the
# tool it needs reports coverage it does not have.
if ! command -v quarto >/dev/null 2>&1; then
  printf 'quarto:   not installed, and this check cannot run without it\n' >&2
  printf '          it renders the package through Quarto to Typst\n' >&2
  printf '          install it from https://quarto.org and run this again\n' >&2
  exit 1
fi

if ! command -v typst >/dev/null 2>&1; then
  printf 'quarto:   typst is not on PATH, and this check compiles with it\n' >&2
  exit 1
fi

QUARTO_TYPST="$(command -v typst)"
export QUARTO_TYPST

rm -rf "${STAGE}"
mkdir -p "${STAGE}"
ln -sfn "${REPO_ROOT}/lib.typ" "${STAGE}/lib.typ"
ln -sfn "${REPO_ROOT}/src" "${STAGE}/src"

shopt -s nullglob

passed=0
total=0
failed=0

for f in tests/quarto/*.qmd; do
  total=$((total + 1))
  name="$(basename "${f%.qmd}")"
  cp "${f}" "${STAGE}/${name}.qmd"

  if ! quarto render "${STAGE}/${name}.qmd" --to typst \
    >"${OUT_DIR}/quarto-${name}.log" 2>&1; then
    failed=$((failed + 1))
    printf '  FAIL  quarto  %s  did not render\n' "${f}" >&2
    grep -v '^    at ' "${OUT_DIR}/quarto-${name}.log" | tail -10 >&2
    continue
  fi

  ok=1
  # Counted rather than grepped for. The guard below used to look for the
  # assertion prefix while the extractor anchored on ` -->` at the end of the
  # line, so a trailing space or a CRLF left the guard satisfied and the
  # assertion unread. Counting what was actually extracted makes the two agree
  # by construction.
  assertions=0

  assert() {
    local artefact="$1"
    local key="$2"
    local sense="$3"

    while IFS= read -r pattern; do
      [[ -z "${pattern}" ]] && continue
      assertions=$((assertions + 1))
      if [[ "${sense}" == "expect" ]] && ! grep -qaF "${pattern}" "${artefact}"; then
        ok=0
        printf '  FAIL  quarto  %s  missing from %s\n' "${f}" "$(basename "${artefact}")" >&2
        printf '        wanted: %s\n' "${pattern}" >&2
      elif [[ "${sense}" == "reject" ]] && grep -qaF "${pattern}" "${artefact}"; then
        ok=0
        printf '  FAIL  quarto  %s  present in %s and should not be\n' "${f}" "$(basename "${artefact}")" >&2
        printf '        rejected: %s\n' "${pattern}" >&2
      fi
      # Trailing whitespace is tolerated on the close, so an editor that trims
      # and one that does not read the same. That covers a carriage return too:
      # [[:space:]] holds one, and writing \r beside it would match a literal r
      # under BSD sed rather than the character it names.
    done < <(sed -n "s|^<!-- ${sense}-${key}: \\(.*\\) -->[[:space:]]*\$|\\1|p" "${f}")
  }

  assert "${STAGE}/${name}.typ" "typ" "expect"
  assert "${STAGE}/${name}.typ" "typ" "reject"
  assert "${STAGE}/${name}.pdf" "pdf" "expect"
  assert "${STAGE}/${name}.pdf" "pdf" "reject"

  # A fixture that asserts nothing renders forever and proves nothing.
  if [[ ${assertions} -eq 0 ]]; then
    ok=0
    printf '  FAIL  quarto  %s  asserts nothing\n' "${f}" >&2
  fi

  # A line that looks like an assertion and was not read is worse than one that
  # asserts nothing, because the file reads as covered. Counting the two
  # separately is what tells them apart.
  # Counted loosely on purpose. Anchoring this the way the extractor is anchored
  # would let an indented line, or `expect-typst:` for `expect-typ:`, be missed
  # by both and leave the fixture reading as covered.
  written="$(grep -cE '^[[:space:]]*<!--.*(expect|reject)-(typ|pdf):' "${f}" || true)"
  if [[ "${written}" -ne "${assertions}" ]]; then
    ok=0
    printf '  FAIL  quarto  %s  %s assertion line(s) written, %s read\n' "${f}" "${written}" "${assertions}" >&2
    printf '        an assertion must close with " -->" and nothing else\n' >&2
  fi

  if [[ ${ok} -eq 1 ]]; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi
done

# No fixture at all would report success having rendered nothing.
if [[ ${total} -eq 0 ]]; then
  printf 'quarto: no fixture under tests/quarto\n' >&2
  exit 1
fi

printf '%-9s %d/%d\n' "quarto:" "${passed}" "${total}"

[[ ${failed} -eq 0 ]]
