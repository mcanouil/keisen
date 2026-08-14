#!/usr/bin/env bash
# Compiles every Typst unit test, visual test, and example from the project root.
# Also enforces the import boundary: no @preview import anywhere under src,
# runs the expect-fail suite, where a document that compiles is the failure,
# and the probes, which read the rendered output for what a theme promises.
# Exits non-zero on the first failure across all targets.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

OUT_DIR="${OUT_DIR:-/tmp/keisen-check}"
mkdir -p "${OUT_DIR}"

shopt -s nullglob

failures=0
total=0

compile_glob() {
  local label="$1"
  local glob="$2"
  local label_passed=0
  local label_total=0

  for f in ${glob}; do
    label_total=$((label_total + 1))
    total=$((total + 1))
    if typst compile "${f}" --root "${REPO_ROOT}" "${OUT_DIR}/$(basename "${f%.typ}").pdf" 2>/dev/null; then
      label_passed=$((label_passed + 1))
    else
      failures=$((failures + 1))
      printf '  FAIL  %s  %s\n' "${label}" "${f}"
      typst compile "${f}" --root "${REPO_ROOT}" "${OUT_DIR}/$(basename "${f%.typ}").pdf" || true
    fi
  done

  printf '%-9s %d/%d\n' "${label}:" "${label_passed}" "${label_total}"
}

if ! tools/import-boundary.sh; then
  failures=$((failures + 1))
fi

# A module holding only its header comment describes structure the package does
# not have. Scaffolding is fine until it outlives the milestone that wanted it.
empty_modules() {
  local offenders=()
  for f in src/**/*.typ src/*.typ; do
    if ! grep -qvE '^\s*(//.*)?$' "${f}"; then
      offenders+=("${f}")
    fi
  done

  if [[ ${#offenders[@]} -gt 0 ]]; then
    printf 'empty modules: a file under src holds no code\n' >&2
    printf '  %s\n' "${offenders[@]}" >&2
    failures=$((failures + 1))
    return
  fi

  printf 'modules:  ok\n'
}

shopt -s globstar
empty_modules

# A document rendered into the documentation should be the table, not the table
# and a field of white, so every test page grows to fit what it holds.
#
# The width is required of every page, with no exception. The height is required
# too, except of tests/visual/breakable.typ: a page that grows to hold the table
# never breaks, and breaking is what it tests, so its height alone stays fixed.
fitted_pages() {
  local offenders=()
  for f in tests/**/*.typ examples/*.typ; do
    grep -q 'set page(' "${f}" || continue

    if ! grep -q 'set page(width: auto' "${f}"; then
      offenders+=("${f}")
      continue
    fi

    [[ "${f}" == "tests/visual/breakable.typ" ]] && continue
    if ! grep -q 'set page(width: auto, height: auto' "${f}"; then
      offenders+=("${f}")
    fi
  done

  if [[ ${#offenders[@]} -gt 0 ]]; then
    printf 'page size: a test page does not grow to fit its content\n' >&2
    printf '  %s\n' "${offenders[@]}" >&2
    printf '  use #set page(width: auto, height: auto, margin: ..)\n' >&2
    failures=$((failures + 1))
    return
  fi

  printf 'pages:    ok\n'
}

fitted_pages

# Typst has no try, so a panic cannot be asserted from inside a document. These
# documents are expected to fail, and each names the message it should produce.
expect_fail() {
  local label_passed=0
  local label_total=0

  for f in tests/expect-fail/*.typ; do
    label_total=$((label_total + 1))
    total=$((total + 1))

    local expected
    expected="$(sed -n 's/^\/\/ expect: //p' "${f}" | head -1)"

    local output
    if output="$(typst compile "${f}" --root "${REPO_ROOT}" "${OUT_DIR}/$(basename "${f%.typ}").pdf" 2>&1)"; then
      failures=$((failures + 1))
      printf '  FAIL  expect-fail  %s  compiled, but should not have\n' "${f}"
    elif [[ -n "${expected}" ]] && ! grep -qF "${expected}" <<<"${output}"; then
      failures=$((failures + 1))
      printf '  FAIL  expect-fail  %s  failed with the wrong message\n' "${f}"
      printf '        wanted: %s\n' "${expected}"
      printf '        got:    %s\n' "$(grep -m1 'error:' <<<"${output}")"
    else
      label_passed=$((label_passed + 1))
    fi
  done

  printf '%-9s %d/%d\n' "expect-fail:" "${label_passed}" "${label_total}"
}

compile_glob "unit" "tests/unit/*.typ"
expect_fail

# Compiling proves a document compiles, not that it looks right. The probes read
# the render for the marks a theme promises.
if ! tools/probe.sh; then
  failures=$((failures + 1))
fi

compile_glob "visual" "tests/visual/*.typ"
compile_glob "examples" "examples/*.typ"

if [[ ${failures} -gt 0 ]]; then
  printf '\n%d failure(s) out of %d compile(s).\n' "${failures}" "${total}" >&2
  exit 1
fi

printf '\n%d compile(s) ok.\n' "${total}"
