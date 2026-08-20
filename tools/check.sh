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

# Two counts, because they answer two questions: how many documents were
# compiled, and which checks failed. A document counted as failed is one this
# refused, whether it was compiled or turned away before that, which is why the
# two numbers are printed as separate sentences rather than as a ratio. One number for both reported "1 failure(s)
# out of 111 compile(s)" whether a single document or a whole sub-suite had
# failed, and named neither.
compiles=0
documents_failed=0
failed_checks=()

fail_check() {
  failed_checks+=("$1")
}

compile_glob() {
  local label="$1"
  local glob="$2"
  local label_passed=0
  local label_total=0

  for f in ${glob}; do
    label_total=$((label_total + 1))
    compiles=$((compiles + 1))
    if typst compile "${f}" --root "${REPO_ROOT}" "${OUT_DIR}/$(basename "${f%.typ}").pdf" 2>/dev/null; then
      label_passed=$((label_passed + 1))
    else
      documents_failed=$((documents_failed + 1))
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
    fail_check "${label}"
    return
  fi

  if [[ ${label_passed} -ne ${label_total} ]]; then
    fail_check "${label}"
  fi

  printf '%-9s %d/%d\n' "${label}:" "${label_passed}" "${label_total}"
}

# The boundary holds on a tree that has none of the shapes it refuses, so it runs
# against its own fixtures as well, as the version check does.
if ! tools/import-boundary.sh --self-test; then
  fail_check "boundary self-test"
fi

if ! tools/import-boundary.sh; then
  fail_check "boundary"
fi

# The rules that script holds fire on a released tree, on a stale date, and on a
# manifest that drifted, and on this tree they fire on none of those, so it runs
# against its own fixtures as well: a guard nothing exercises is a guard that
# passes because its pattern stopped matching.
if ! tools/version-check.sh --self-test; then
  fail_check "version self-test"
fi

if ! tools/version-check.sh; then
  fail_check "version"
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
    fail_check "modules"
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
#
# A document with no page rule at all is skipped, which is how a unit test or an
# expect-fail fixture opts out of a rule that does not apply to it. It was also
# how a visual test that forgot the rule escaped it, so the rule is required of
# the two globs CONTRIBUTING.md says it holds for, and the skip stays for the
# rest.
fitted_pages() {
  local offenders=()
  local unruled=()
  for f in tests/**/*.typ examples/*.typ; do
    if ! grep -q 'set page(' "${f}"; then
      case "${f}" in
      tests/visual/*.typ | examples/*.typ) unruled+=("${f}") ;;
      esac
      continue
    fi

    if ! grep -q 'set page(width: auto' "${f}"; then
      offenders+=("${f}")
      continue
    fi

    [[ "${f}" == "tests/visual/breakable.typ" ]] && continue
    if ! grep -q 'set page(width: auto, height: auto' "${f}"; then
      offenders+=("${f}")
    fi
  done

  # Both lists before the return, so a tree with one of each fault is one run
  # rather than two.
  if [[ ${#unruled[@]} -gt 0 ]]; then
    printf 'page size: a rendered test sets no page at all\n' >&2
    printf '  %s\n' "${unruled[@]}" >&2
    printf '  a visual test and an example carry the page rule; see CONTRIBUTING.md\n' >&2
  fi

  if [[ ${#offenders[@]} -gt 0 ]]; then
    printf 'page size: a test page does not grow to fit its content\n' >&2
    printf '  %s\n' "${offenders[@]}" >&2
    printf '  use #set page(width: auto, height: auto, margin: ..)\n' >&2
  fi

  if [[ ${#unruled[@]} -gt 0 || ${#offenders[@]} -gt 0 ]]; then
    fail_check "pages"
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
# pin each part on its own: the scope with its problem, the value, and the hint.
# The whole message is then covered without any one assertion depending on the
# spelling of the parts around it.
#
# A fixture that names no expectation is refused. Asserting only that a document
# does not compile says nothing about why, and a message that drifts to another
# defect entirely would still pass.
expect_fail() {
  local label_passed=0
  local label_total=0

  for f in tests/expect-fail/*.typ; do
    label_total=$((label_total + 1))

    local expected=()
    while IFS= read -r line; do
      [[ -z "${line}" ]] && continue
      expected+=("${line}")
    done < <(sed -n 's/^\/\/ expect: //p' "${f}")

    if [[ ${#expected[@]} -eq 0 ]]; then
      documents_failed=$((documents_failed + 1))
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
      documents_failed=$((documents_failed + 1))
      printf '  FAIL  expect-fail  %s  %s expectation line(s) written, %s read\n' "${f}" "${written}" "${#expected[@]}"
      printf '        an expectation reads "// expect: <text>", with one space either side of the colon\n'
      continue
    fi

    # An expectation that stops at the scope asserts only that the failure came
    # from somewhere in the package, which every failure in the package does.
    # The grammar is `<scope>: <problem>; got <repr(value)>. <hint>`, and each
    # fixture pins the parts its message carries, one per line: the scope with
    # its problem, the value, and the hint. Every hint in the suite could be
    # deleted from `src/utils/errors.typ` and the whole run stayed green.
    local wanted
    for wanted in "${expected[@]}"; do
      if [[ "${wanted}" =~ ^[a-z-]+:[[:space:]]*$ ]]; then
        documents_failed=$((documents_failed + 1))
        printf '  FAIL  expect-fail  %s  the expectation "%s" names a scope and nothing else\n' "${f}" "${wanted}"
        printf '        pin what the message says, not only where it came from\n'
        continue 2
      fi
    done

    local output
    compiles=$((compiles + 1))
    if output="$(typst compile "${f}" --root "${REPO_ROOT}" "${OUT_DIR}/$(basename "${f%.typ}").pdf" 2>&1)"; then
      documents_failed=$((documents_failed + 1))
      printf '  FAIL  expect-fail  %s  compiled, but should not have\n' "${f}"
      continue
    fi

    # The message alone, not the whole output. Typst prints a traceback under the
    # error, and each frame of it echoes the source line it called from, hints
    # and all. So an expectation naming a hint matched the call site that passes
    # the hint rather than the message that printed it, and a fixture went on
    # passing with the hint deleted from the panic.
    local message
    message="$(sed -n 's/^error: panicked with: //p' <<<"${output}" | head -1)"
    if [[ -z "${message}" ]]; then
      documents_failed=$((documents_failed + 1))
      printf '  FAIL  expect-fail  %s  did not fail through the error grammar\n' "${f}"
      printf '        got:    %s\n' "$(grep -m1 'error:' <<<"${output}")"
      printf '        every failure in the package panics through src/utils/errors.typ\n'
      continue
    fi

    local missing=0
    for wanted in "${expected[@]}"; do
      if ! grep -qF "${wanted}" <<<"${message}"; then
        if [[ ${missing} -eq 0 ]]; then
          documents_failed=$((documents_failed + 1))
          printf '  FAIL  expect-fail  %s  failed with the wrong message\n' "${f}"
          printf '        got:    %s\n' "${message}"
        fi
        missing=1
        printf '        wanted: %s\n' "${wanted}"
      fi
    done

    # Every part the message carries is pinned by some expectation. Without
    # this, a fixture added tomorrow pins its problem and leaves its hint unread,
    # which is exactly the state the whole suite was in.
    local body="${message#*: }"
    local tail="${body}"
    local value=""
    if [[ "${body}" == *"; got "* ]]; then
      tail="${body#*; got }"
      value="${tail%%. *}"
    fi
    local hint=""
    if [[ "${tail}" == *". "* ]]; then
      hint="${tail#*. }"
    fi

    local part
    for part in "${value:+got ${value}${hint:+.}}" "${hint}"; do
      [[ -z "${part}" ]] && continue
      if ! printf '%s\n' "${expected[@]}" | grep -qF "${part}"; then
        if [[ ${missing} -eq 0 ]]; then
          documents_failed=$((documents_failed + 1))
          printf '  FAIL  expect-fail  %s  part of the message is pinned by nothing\n' "${f}"
          printf '        got:    %s\n' "${message}"
        fi
        missing=1
        printf '        unpinned: %s\n' "${part}"
      fi
    done

    if [[ ${missing} -eq 0 ]]; then
      label_passed=$((label_passed + 1))
    fi
  done

  if [[ ${label_total} -eq 0 ]]; then
    printf 'expect-fail: no fixture under tests/expect-fail\n' >&2
    fail_check "expect-fail"
    return
  fi

  if [[ ${label_passed} -ne ${label_total} ]]; then
    fail_check "expect-fail"
  fi

  printf '%-9s %d/%d\n' "expect-fail:" "${label_passed}" "${label_total}"
}

compile_glob "unit" "tests/unit/*.typ"
expect_fail

# Compiling proves a document compiles, not that it looks right. The probes read
# the render for the marks a theme promises.
if ! tools/probe.sh; then
  fail_check "probe"
fi

# A number reads the same way in every script, and nothing inside a document
# can assert that: this compares the two renders.
if ! tools/direction-check.sh; then
  fail_check "direction"
fi

# A column label is a header cell to a screen reader or it is not, and no
# document can read its own tags back: this reads the PDF structure tree.
#
# Every fixture in the tree is well formed, so the shape guard runs against its
# own strings: a malformed assertion used to be read as a pass.
if ! tools/accessibility-check.sh --self-test; then
  fail_check "accessibility self-test"
fi

if ! tools/accessibility-check.sh; then
  fail_check "accessibility"
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
    fail_check "assets"
    return
  fi

  local stage
  stage="${OUT_DIR}/asset-freshness"
  rm -rf "${stage}"

  if ! tools/render-docs-assets.sh "${stage}" >/dev/null; then
    printf 'assets: the visual tests could not be rendered\n' >&2
    fail_check "assets"
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
    fail_check "assets"
    return
  fi

  printf 'assets:   ok\n'
}

fresh_assets

# Last, because it is the only check that leaves this repository: it renders a
# table through Quarto, which is how most R and Python users reach the package.
if ! tools/quarto-check.sh; then
  fail_check "quarto"
fi

if [[ ${#failed_checks[@]} -gt 0 ]]; then
  named="$(printf ', %s' "${failed_checks[@]}")"
  printf '\n%d check(s) failed: %s\n' "${#failed_checks[@]}" "${named:2}" >&2
  printf '%d compile(s) run; %d document(s) failed.\n' "${compiles}" "${documents_failed}" >&2
  exit 1
fi

printf '\n%d compile(s) ok.\n' "${compiles}"
