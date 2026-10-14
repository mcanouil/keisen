#!/usr/bin/env bash
# Compiles every Typst unit test, visual test, and example from the project root.
# Also enforces the import boundary: no package import from any namespace under
# src,
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

# The Release workflow writes the next version with this, and a release is the
# one time it runs on the real files, so it runs against fixtures here.
if ! tools/bump-version.sh --self-test; then
  fail_check "bump self-test"
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

# A visual test imports the working tree as "/lib.typ", and nothing else. The
# documentation shows that line as `@preview/keisen:<version>`, read from
# typst.toml, and tools/dry-release.sh compiles it as the installed package, so
# the version is written in no test. Both rewrite that exact string, one space
# included, so a relative path, a versioned import or another spacing would
# reach the page as written.
# Anchored at the start of a line, so a commented-out import is not read.
visual_imports() {
  local offenders=()
  local f
  while IFS= read -r f; do
    offenders+=("${f}")
  done < <(grep -HE '^[[:space:]]*#(import|include)[[:space:]]+"' tests/visual/*.typ |
    grep -vE '^[^:]+:[[:space:]]*#import "/lib\.typ"' | cut -d: -f1 | sort -u)
  if [[ ${#offenders[@]} -gt 0 ]]; then
    printf 'imports: a visual test imports something other than "/lib.typ"; got %d file(s)\n' "${#offenders[@]}" >&2
    printf '  %s\n' "${offenders[@]}" >&2
    printf '  use #import "/lib.typ": *; the documentation shows it as @preview/keisen:<version>\n' >&2
    fail_check "imports"
    return
  fi
  printf 'imports:  ok\n'
}

visual_imports

# Two unit tests scan a list of files written out by hand, because Typst cannot
# walk a directory. Each list can go stale without a word: the scan still runs,
# its assertion still holds, and the record quietly stops describing the tree. A
# key read by a module nobody listed reads as read by nothing.
#
# The shell can walk the tree, so each list is held to what a grep finds. The
# comparison is one way on purpose: a path in the tree and not in the list is
# the failure. A path in the list and not in the tree fails already, since the
# scan reads every file it names.
option_scan() {
  local label="$1" scanner="$2"
  shift 2

  # Both scanners sit in tests/unit and read their sources from there, so a
  # listed path is made into one from the repository root by its own shape:
  # ../../ leaves tests, ../ leaves tests/unit, and a bare name stays in it.
  # The bare-name rule runs last and only on a path that carries no separator,
  # so it cannot prefix what the two rules above have already rewritten.
  # Neither side may kill the run: a grep that matches nothing exits 1, and under
  # `set -e` with `pipefail` the assignment would end the script with no message
  # and no named check. Only that status is taken for "nothing matched"; anything
  # above it is the walk itself failing, which can leave partial output on
  # stdout, and a truncated list would otherwise read as a clean pass.
  local listed found missing status
  listed="$(
    grep -oE 'source\("[^"]+"\)' "${scanner}" |
      sed -E 's/^source\("//; s/"\)$//; s@^\.\./\.\./@@; s@^\.\./@tests/@' |
      sed -E '/\//!s@^@tests/unit/@' |
      sort
  )" && status=0 || status=$?
  if [[ ${status} -gt 1 ]]; then
    printf 'option scans: reading the sources of %s failed, exit %d\n' "${scanner}" "${status}" >&2
    fail_check "option scans"
    return 1
  fi

  found="$("$@" | sort)" && status=0 || status=$?
  if [[ ${status} -gt 1 ]]; then
    printf 'option scans: the tree walk for %s failed, exit %d\n' "${label}" "${status}" >&2
    fail_check "option scans"
    return 1
  fi

  if [[ -z "${listed}" || -z "${found}" ]]; then
    printf 'option scans: %s has nothing to compare\n' "${scanner}" >&2
    printf '  the sources list holds %d paths and the tree walk found %d\n' \
      "$(printf '%s' "${listed}" | grep -c . || true)" \
      "$(printf '%s' "${found}" | grep -c . || true)" >&2
    fail_check "option scans"
    return 1
  fi

  missing="$(comm -13 <(printf '%s\n' "${listed}") <(printf '%s\n' "${found}"))"
  if [[ -n "${missing}" ]]; then
    printf 'option scans: %s does not scan every file the tree has\n' "${scanner}" >&2
    printf 'the %s below are in the tree and not in its sources list\n' "${label}" >&2
    while read -r path; do
      printf '  %s\n' "${path}" >&2
    done <<<"${missing}"
    fail_check "option scans"
    return 1
  fi

  printf 'scans:    %s ok\n' "${label}"
}

# A reader is a file that calls `option` or `setting`, which are the two shapes
# `read-by` in the scanner accepts. src/theme/options.typ defines `option`, so it
# is the one file the grep names and the list does not want.
option_readers() {
  grep -rlE '(^|[^-[:alnum:]_])(option|setting)\(' src --include='*.typ' |
    grep -v '^src/theme/options.typ$'
}

# The markers `configures` in the scanner reads, spelled the way it spells them:
# it matches `theme` and `options` followed by optional space and a colon, so a
# grep holding it to the bare colon would leave a spaced one unlisted. Edit the
# two together.
#
# The grep names the scanner itself, which is left out there on purpose and so is
# left out here.
option_setters() {
  grep -rlE 'table-options\(|build-spec\(|theme[[:space:]]*:|options[[:space:]]*:' \
    tests examples --include='*.typ' |
    grep -v '^tests/unit/test-options-set.typ$'
}

# Every answer the scan can give, against a tree written for the purpose. A guard
# nothing exercises is a guard that passes because its pattern stopped matching,
# which is the reason the boundary, the version and the asset checks each run
# against their own fixtures too.
#
# Each case runs inside a command substitution, which is a subshell, so the
# failures it reports there are read as text and do not count against this run.
option_scan_self_test() {
  local dir="${OUT_DIR}/option-scan-self-test"
  rm -rf "${dir}"
  mkdir -p "${dir}"
  printf 'source("../../src/a.typ"),\nsource("b.typ"),\n' >"${dir}/listing.typ"
  printf '// no sources here\n' >"${dir}/nothing.typ"

  _walk_listed() { printf 'src/a.typ\ntests/unit/b.typ\n'; }
  _walk_extra() { printf 'src/a.typ\nsrc/c.typ\ntests/unit/b.typ\n'; }
  _walk_empty() { return 1; }
  _walk_broken() {
    printf 'src/a.typ\n'
    return 2
  }

  local passed=0 total=0 out
  expect() {
    local wanted="$1" name="$2" scanner="$3" walker="$4"
    total=$((total + 1))
    out="$(option_scan "${name}" "${scanner}" "${walker}" 2>&1)" || true
    if [[ "${out}" == *"${wanted}"* ]]; then
      passed=$((passed + 1))
    else
      printf 'option scans self-test: %s did not say %s\n' "${name}" "${wanted}" >&2
      printf '  it said: %s\n' "${out}" >&2
    fi
  }

  # A list naming every path the walk finds.
  expect "ok" "complete" "${dir}/listing.typ" _walk_listed
  # A path in the tree and not in the list, which is the failure this exists for.
  expect "src/c.typ" "stale" "${dir}/listing.typ" _walk_extra
  # A walk that matches nothing, which `set -e` would otherwise end the run on.
  expect "has nothing to compare" "empty-walk" "${dir}/listing.typ" _walk_empty
  # A list that reads no sources, the same failure from the other side.
  expect "has nothing to compare" "empty-list" "${dir}/nothing.typ" _walk_listed
  # A walk that fails rather than finding nothing, with partial output on stdout.
  expect "the tree walk for broken failed, exit 2" "broken" "${dir}/listing.typ" _walk_broken

  if [[ ${passed} -ne ${total} ]]; then
    fail_check "option scans self-test"
  fi
  printf 'scans:    self-test %d/%d\n' "${passed}" "${total}"
}

option_scan_self_test
option_scan "readers" tests/unit/test-options-read.typ option_readers
option_scan "setters" tests/unit/test-options-set.typ option_setters

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

# The packaging script refuses a payload entry that would ship nothing. This
# tree holds no such entry, and `package.sh archive` is reached by no script
# here, so it runs against its own fixtures.
if ! tools/package.sh --self-test; then
  fail_check "package self-test"
fi

# Each table on the site is compiled from the file a page names in a
# `//| file:` line. A renamed or deleted test would otherwise surface only when
# the site is built, so every name is resolved here against its page. A page
# whose card image typst-render writes must also hold the block that writes it,
# or its listing card and social card point at nothing.
#
# Every page at any depth, as tools/dry-release.sh sweeps them; directories
# Quarto ignores (_site, _extensions) are skipped.
documented_files() {
  local missing=()
  local page line target image expected
  for page in docs/**/*.qmd; do
    [[ "${page}" == */_* ]] && continue
    # Quarto runs a {typst} block as code to execute unless the page sets the
    # markdown engine, and fails the build when it cannot start a kernel.
    if grep -qE '^[[:space:]]*```\{typst\}' "${page}" && ! grep -q '^engine: markdown' "${page}"; then
      missing+=("${page}: engine: markdown (the page holds a {typst} block)")
    fi
    image="$(sed -n 's|^image: \(.*assets/typst-render/.*\)$|\1|p' "${page}")"
    if [[ -n "${image}" ]]; then
      # A section writes into assets/typst-render/<section>/, as its _metadata.yml
      # sets, so the card must name that directory and a file a block writes.
      expected="../assets/typst-render/$(basename "$(dirname "${page}")")/$(basename "${image}")"
      if [[ "${image}" != "${expected}" ]] ||
        ! grep -qF "//| output-filename: \"$(basename "${image}")\"" "${page}"; then
        missing+=("${page}: ${image} (no block on the page writes it)")
      fi
    fi
    while IFS= read -r line; do
      # A block indented inside a list carries its options indented too.
      target="${line#*//| file: }"
      target="${target%\"}"
      target="${target#\"}"
      if [[ ! -f "$(dirname "${page}")/${target}" ]]; then
        missing+=("${page}: ${target}")
      fi
    done < <(grep -E '^[[:space:]]*//\| file: ' "${page}" || true)
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    printf 'docs: a page names a file that does not exist; got %d\n' "${#missing[@]}" >&2
    printf '  %s\n' "${missing[@]}" >&2
    printf '  point the //| file: path at the test that renders the table,\n' >&2
    printf '  give the card image the output-filename its block writes,\n' >&2
    printf '  and set engine: markdown on a page that holds a {typst} block\n' >&2
    fail_check "docs files"
    return
  fi
  printf 'docs:     files ok\n'
}

documented_files

# The landing page highlights a range of lines in a file it shows, by number. A
# line added above the range would move the highlight off the code the prose
# describes, so each range is held to the lines it must open and close on.
highlighted_lines() {
  local stale=()
  local page source range first last from to
  while IFS='|' read -r page source range first last; do
    from="${range%-*}"
    to="${range#*-}"
    if ! grep -q "data-highlight-lines=\"${range}\"" "${page}" ||
      [[ "$(sed -n "${from}p" "${source}")" != ${first}* ]] ||
      [[ "$(sed -n "${to}p" "${source}")" != "${last}" ]]; then
      stale+=("${page}: lines ${range} of ${source}")
    fi
  done <<'RANGES'
docs/index.qmd|tests/visual/gallery-income-statement-native.typ|40-54|#for section in|}
RANGES
  if [[ ${#stale[@]} -gt 0 ]]; then
    printf 'docs: a highlighted range no longer covers its code; got %d\n' "${#stale[@]}" >&2
    printf '  %s\n' "${stale[@]}" >&2
    printf '  update data-highlight-lines on the page and the range here\n' >&2
    fail_check "docs highlight"
    return
  fi
  printf 'docs:     highlight ok\n'
}

highlighted_lines

# The site shows each visual test's "/lib.typ" import as the package import, and
# a filter that stopped matching would publish a line no reader can run. Run on
# a listing of each import form, the filter must write every one as the
# manifest's version and leave a listing in another language alone. The render
# itself is checked by docs/_scripts/typst-render-check.sh.
documented_imports() {
  local filter=docs/_filters/package-import.lua
  local version want got
  version="$(awk -F'"' '/^version[[:space:]]*=/ { print $2; exit }' typst.toml)"
  want="#import \"@preview/keisen:${version}\": *
#import \"@preview/keisen:${version}\" as keisen
#import \"@preview/keisen:${version}\": nanoplot-bar
#import \"/lib.typ\""
  if ! got="$(printf '%s\n' '```typst' '#import "/lib.typ": *' '#import "/lib.typ" as keisen' \
    '#import "/lib.typ": nanoplot-bar' '```' '' '```bash' '#import "/lib.typ"' '```' |
    quarto pandoc -f markdown -t plain -L "${filter}" 2>&1)"; then
    printf 'docs: the import filter failed; got %s\n' "${got}" >&2
    fail_check "docs imports"
    return
  fi
  got="$(grep -v '^[[:space:]]*$' <<<"${got}" | sed 's/^[[:space:]]*//' || true)"
  if [[ "${got}" != "${want}" ]]; then
    printf 'docs: the import filter does not write the package import; got\n' >&2
    printf '  %s\n' "${got//$'\n'/$'\n'  }" >&2
    printf '  %s matches #import "/lib.typ" in typst listings only\n' "${filter}" >&2
    fail_check "docs imports"
    return
  fi
  printf 'docs:     imports ok\n'
}

documented_imports

# Last, because it is the only check that leaves this repository: it renders a
# table through Quarto, which is how most R and Python users reach the package.
if ! tools/quarto-check.sh; then
  fail_check "quarto"
fi

# A failed document with no failed check beside it would exit 0 today only by
# accident of where the counters sit, so the count gates the exit as well.
if [[ ${documents_failed} -gt 0 && ${#failed_checks[@]} -eq 0 ]]; then
  failed_checks+=("a document, under no named check")
fi

if [[ ${#failed_checks[@]} -gt 0 ]]; then
  named="$(printf ', %s' "${failed_checks[@]}")"
  printf '\n%d check(s) failed: %s\n' "${#failed_checks[@]}" "${named:2}" >&2
  printf '%d compile(s) run; %d document(s) failed.\n' "${compiles}" "${documents_failed}" >&2
  exit 1
fi

printf '\n%d compile(s) ok.\n' "${compiles}"
