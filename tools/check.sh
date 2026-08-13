#!/usr/bin/env bash
# Compiles every Typst unit test, visual test, and example from the project root.
# Also enforces the import boundary: no @preview import outside src/integrations.
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

compile_glob "unit" "tests/unit/*.typ"
compile_glob "visual" "tests/visual/*.typ"
compile_glob "examples" "examples/*.typ"

if [[ ${failures} -gt 0 ]]; then
  printf '\n%d failure(s) out of %d compile(s).\n' "${failures}" "${total}" >&2
  exit 1
fi

printf '\n%d compile(s) ok.\n' "${total}"
