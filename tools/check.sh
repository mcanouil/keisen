#!/usr/bin/env bash
# Compiles every Typst unit test, visual test, and example from the project root.
# Also enforces the import boundary: no @preview import anywhere under src,
# holds the version to the same value everywhere it is written, runs the
# expect-fail suite, where a document that compiles is the failure, the probes,
# which read the rendered output for what a theme promises, the accessibility
# fixtures, which read the PDF structure tree for header cells, and the Quarto
# fixtures, which render the package the way most R and Python users reach it.
# Exits non-zero on the first failure across all targets.
#
# Quarto is required. The check that needs it fails and says so when it is
# absent, rather than skipping: a suite that reports success without running a
# check reports coverage it does not have.

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

  # nullglob is set above, so a directory that holds nothing yields no
  # iterations and would print 0/0 and pass. The accessibility and Quarto checks
  # already refuse that; these did not, and moving tests/unit aside left the
  # whole suite green.
  if [[ ${label_total} -eq 0 ]]; then
    printf '%s: nothing matched %s\n' "${label}" "${glob}" >&2
    failures=$((failures + 1))
    return
  fi

  printf '%-9s %d/%d\n' "${label}:" "${label_passed}" "${label_total}"
}

if ! tools/import-boundary.sh; then
  failures=$((failures + 1))
fi

if ! tools/version-check.sh; then
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
#
# Every expectation line is read, not the first. The error grammar is
# `<scope>: <problem>; got <repr(value)>. <hint>`, and pinning it as one string
# would drag the repr of the offending value into the middle of the assertion,
# which is the most volatile part of the message. Several lines let a fixture
# pin the scope and the problem on one and the hint on another, and skip the
# value.
#
# A fixture that names no expectation is refused. Asserting only that a document
# does not compile says nothing about why, and a message that drifts to another
# defect entirely would still pass.
expect_fail() {
  local label_passed=0
  local label_total=0

  for f in tests/expect-fail/*.typ; do
    label_total=$((label_total + 1))
    total=$((total + 1))

    local expected=()
    while IFS= read -r line; do
      [[ -z "${line}" ]] && continue
      expected+=("${line}")
    done < <(sed -n 's/^\/\/ expect: //p' "${f}")

    if [[ ${#expected[@]} -eq 0 ]]; then
      failures=$((failures + 1))
      printf '  FAIL  expect-fail  %s  names no expectation\n' "${f}"
      printf '        add a line reading "// expect: <the message it should print>"\n'
      continue
    fi

    # A line that looks like an expectation and was not read is worse than none
    # at all, because the file reads as covered. Counted loosely on purpose:
    # anchoring this the way the extractor is anchored would let `//expect:`
    # without the space be missed by both.
    local written
    written="$(grep -cE '^[[:space:]]*//.*expect:' "${f}" || true)"
    if [[ "${written}" -ne "${#expected[@]}" ]]; then
      failures=$((failures + 1))
      printf '  FAIL  expect-fail  %s  %s expectation line(s) written, %s read\n' "${f}" "${written}" "${#expected[@]}"
      printf '        an expectation reads "// expect: <text>", with one space either side of the colon\n'
      continue
    fi

    local output
    if output="$(typst compile "${f}" --root "${REPO_ROOT}" "${OUT_DIR}/$(basename "${f%.typ}").pdf" 2>&1)"; then
      failures=$((failures + 1))
      printf '  FAIL  expect-fail  %s  compiled, but should not have\n' "${f}"
      continue
    fi

    local missing=0
    local wanted
    for wanted in "${expected[@]}"; do
      if ! grep -qF "${wanted}" <<<"${output}"; then
        if [[ ${missing} -eq 0 ]]; then
          failures=$((failures + 1))
          printf '  FAIL  expect-fail  %s  failed with the wrong message\n' "${f}"
          printf '        got:    %s\n' "$(grep -m1 'error:' <<<"${output}")"
        fi
        missing=1
        printf '        wanted: %s\n' "${wanted}"
      fi
    done

    if [[ ${missing} -eq 0 ]]; then
      label_passed=$((label_passed + 1))
    fi
  done

  if [[ ${label_total} -eq 0 ]]; then
    printf 'expect-fail: no fixture under tests/expect-fail\n' >&2
    failures=$((failures + 1))
    return
  fi

  printf '%-9s %d/%d\n' "expect-fail:" "${label_passed}" "${label_total}"
}

compile_glob "unit" "tests/unit/*.typ"
expect_fail

# Compiling proves a document compiles, not that it looks right. The probes read
# the render for the marks a theme promises.
if ! tools/probe.sh; then
  failures=$((failures + 1))
fi

# A number reads the same way in every script, and nothing inside a document
# can assert that: this compares the two renders.
if ! tools/direction-check.sh; then
  failures=$((failures + 1))
fi

# A column label is a header cell to a screen reader or it is not, and no
# document can read its own tags back: this reads the PDF structure tree.
if ! tools/accessibility-check.sh; then
  failures=$((failures + 1))
fi

compile_glob "visual" "tests/visual/*.typ"
compile_glob "examples" "examples/*.typ"

# The documentation shows a listing beside a picture and says the picture is
# what the listing produces. Nothing held it to that: tools/render-docs-assets.sh
# is run by hand, and two tracked images were found to be the output of source
# that had changed three times since.
#
# The render is reproducible, so comparing the bytes is enough. It runs after
# the visual tests so a failure to compile is reported as a compile failure
# rather than as a stale image.
fresh_assets() {
  # The manifest names the compiler the package needs, and an older one renders
  # something this repository never agreed to. It is a floor rather than a pin:
  # 0.15.0, which CI installs, and 0.15.1 render all fourteen visual tests to
  # identical bytes, so requiring equality would fail the suite over a
  # difference that makes none.
  #
  # A newer Typst that does change a render is caught by the comparison below,
  # which is why the running version is named when an image is reported stale.
  local wanted running
  wanted="$(awk -F'"' '/^compiler[[:space:]]*=/ { print $2; exit }' typst.toml)"
  running="$(typst --version | awk '{ print $2; exit }')"
  if [[ "$(printf '%s\n%s\n' "${wanted}" "${running}" | sort -V | head -1)" != "${wanted}" ]]; then
    printf 'assets: this Typst is older than the package declares\n' >&2
    printf '  typst.toml: %s\n' "${wanted}" >&2
    printf '  running:    %s\n' "${running}" >&2
    failures=$((failures + 1))
    return
  fi

  local stage
  stage="${OUT_DIR}/asset-freshness"
  rm -rf "${stage}"

  if ! tools/render-docs-assets.sh "${stage}" >/dev/null; then
    printf 'assets: the visual tests could not be rendered\n' >&2
    failures=$((failures + 1))
    return
  fi

  local stale=()
  local rendered
  for rendered in "${stage}"/*.png; do
    local name
    name="$(basename "${rendered}")"
    if ! cmp -s "${rendered}" "docs/assets/examples/${name}"; then
      stale+=("${name}")
    fi
  done

  # A tracked image whose visual test is gone is served by the site and produced
  # by nothing, which is the same defect read from the other end.
  local tracked
  for tracked in docs/assets/examples/*.png; do
    local name
    name="$(basename "${tracked}")"
    if [[ ! -f "${stage}/${name}" ]]; then
      stale+=("${name} (no visual test renders it)")
    fi
  done

  # A second copy of every image is nothing to leave behind after a check that
  # has read them.
  rm -rf "${stage}"

  if [[ ${#stale[@]} -gt 0 ]]; then
    printf 'assets: a documentation image is not what its source renders\n' >&2
    printf '  %s\n' "${stale[@]}" >&2
    printf '  run tools/render-docs-assets.sh and commit the result\n' >&2
    printf '  rendered here by typst %s; the manifest declares %s\n' "${running}" "${wanted}" >&2
    failures=$((failures + 1))
    return
  fi

  printf 'assets:   ok\n'
}

fresh_assets

# Last, because it is the only check that leaves this repository: it renders a
# table through Quarto, which is how most R and Python users reach the package.
if ! tools/quarto-check.sh; then
  failures=$((failures + 1))
fi

if [[ ${failures} -gt 0 ]]; then
  printf '\n%d failure(s) out of %d compile(s).\n' "${failures}" "${total}" >&2
  exit 1
fi

printf '\n%d compile(s) ok.\n' "${total}"
