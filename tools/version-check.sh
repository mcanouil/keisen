#!/usr/bin/env bash
# Holds every place a version is written to the same value.
#
# typst.toml is what Typst Universe publishes, CITATION.cff is what a citation
# resolves to, and CHANGELOG.md is what a reader is told changed. Bumping one
# and forgetting another is silent, and permanent once published.
#
# The import lines the README and the documentation show are the fourth place,
# and the only one a reader copies.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

# The one-line description is written in four places, and Typst Universe renders
# the manifest's beside the packaged README's tagline, so two of them sit on one
# page. A copy that drifts is a page that describes the package twice, and
# differently.
#
# The README writes the tagline with emphasis, `**display tables**`, since it is
# a heading rather than a field, so the markers are removed before comparing. It
# is read as the first line with anything on it after the title, rather than by
# its number, since a badge row above it would otherwise be read as the tagline.
package_description() {
  local toml="$1" readme_file="$2" quarto="$3" webmanifest_file="$4"
  local manifest readme site webmanifest offenders=()

  manifest="$(sed -n 's/^description[[:space:]]*=[[:space:]]*"\(.*\)"[[:space:]]*$/\1/p' "${toml}" | head -1)"
  readme="$(awk '/^[[:space:]]*$/ || /^#/ || /^!/ || /^\[/ || /^</ { next } { print; exit }' \
    "${readme_file}" | tr -d '*')"
  # The site description is read inside the `website:` block alone, since Quarto
  # writes a `description:` under a listing or a format as readily, and either
  # would otherwise stand in for the site's own. All three scalar forms YAML
  # writes are read, as the citation date is.
  local block
  block="$(sed -n '/^website:/,/^[^[:space:]#]/p' "${quarto}")"
  site="$(printf '%s\n' "${block}" | sed -n \
    -e 's/^[[:space:]]\{1,\}description:[[:space:]]*"\(.*\)"[[:space:]]*$/\1/p' \
    -e "s/^[[:space:]]\{1,\}description:[[:space:]]*'\(.*\)'[[:space:]]*\$/\1/p" \
    -e 's/^[[:space:]]\{1,\}description:[[:space:]]*\([^"'"'"'[:space:]].*[^[:space:]]\)[[:space:]]*$/\1/p' |
    head -1)"

  if printf '%s\n' "${block}" | grep -qE '^[[:space:]]+description:' && [[ -z "${site}" ]]; then
    printf 'description: %s carries a website description this cannot read\n' "${quarto}" >&2
    printf '%s\n' "${block}" | grep -nE '^[[:space:]]+description:' | sed 's/^/  /' >&2
    return 1
  fi
  webmanifest="$(sed -n 's/^[[:space:]]*"description":[[:space:]]*"\(.*\)",\{0,1\}[[:space:]]*$/\1/p' \
    "${webmanifest_file}" | head -1)"

  if [[ -z "${manifest}" ]]; then
    printf 'description: %s carries no description\n' "${toml}" >&2
    return 1
  fi

  [[ "${readme}" != "${manifest}" ]] && offenders+=("${readme_file}: ${readme:-<none>}")
  [[ "${site}" != "${manifest}" ]] && offenders+=("${quarto}: ${site:-<none>}")
  [[ "${webmanifest}" != "${manifest}" ]] && offenders+=("${webmanifest_file}: ${webmanifest:-<none>}")

  if [[ ${#offenders[@]} -gt 0 ]]; then
    printf 'description: the one-line description is written four ways\n' >&2
    printf '  %s: %s\n' "${toml}" "${manifest}" >&2
    printf '  %s\n' "${offenders[@]}" >&2
    printf '  the GitHub repository description is a fifth copy, outside the tree\n' >&2
    return 1
  fi
}

# The category vocabulary Typst Universe accepts, from docs/CATEGORIES.md in
# typst/packages. A value outside it is refused at submission, and the entry is
# permanent, so a typo is worth catching here rather than there.
#
# typst-package-check is the authority, and it gates tools/dry-release.sh. This
# is the offline half: it reads the names, not their fit.
manifest_categories() {
  local toml="$1"
  local upstream=(
    components visualization model layout text
    languages scripting integration utility fun
    book report paper thesis poster
    flyer presentation cv office
  )
  local offenders=() names=()

  # The value is read whole rather than line by line, since TOML writes an array
  # across lines as readily as on one, and `exclude` in this same file does.
  # Both quotings are accepted: TOML has basic strings and literal ones. The key
  # is read where it is declared, at the start of a line, so a commented copy of
  # an old value is not read as the live one.
  local written
  written="$(sed -n '/^categories[[:space:]]*=/,/\]/p' "${toml}" |
    tr '\n' ' ' |
    sed -n "s/^categories[[:space:]]*=[[:space:]]*\[\([^]]*\)\].*/\1/p" |
    tr ',' '\n' | tr -d " \"'")"

  while IFS= read -r name; do
    [[ -z "${name}" ]] && continue
    names+=("${name}")
    local known=0
    for candidate in "${upstream[@]}"; do
      if [[ "${name}" == "${candidate}" ]]; then
        known=1
        break
      fi
    done
    [[ ${known} -eq 0 ]] && offenders+=("${name}")
  done <<<"${written}"

  # A guard that read nothing is a guard that passes for the wrong reason.
  if [[ ${#names[@]} -eq 0 ]]; then
    printf 'manifest: %s names no category, or none this can read\n' "${toml}" >&2
    printf '  expected: categories = ["visualization", "components"]\n' >&2
    return 1
  fi

  if [[ ${#offenders[@]} -gt 0 ]]; then
    printf 'manifest: %s names a category Typst Universe does not carry\n' "${toml}" >&2
    printf '  %s\n' "${offenders[@]}" >&2
    printf '  see docs/CATEGORIES.md in typst/packages\n' >&2
    return 1
  fi
}

citation_date() {
  local changelog="$1" citation="$2" version="$3"
  local escaped="${version//./\\.}"
  local released dated

  released="$(sed -n "s/^## ${escaped} (\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\))$/\1/p" "${changelog}" | head -1)"

  # CFF writes a scalar bare, in single quotes, or in double ones, and all three
  # resolve to the same date, so all three are read here. Each form is matched
  # whole, since a quote opened one way and closed the other is broken YAML that
  # every CFF reader refuses.
  #
  # The date itself is matched by shape: a field carrying anything else is a
  # field this cannot read, and reading it as absent is how a stale date passes.
  local key='^date-released[[:space:]]*:[[:space:]]*'
  local day='\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\)'
  local tail='[[:space:]]*$'
  dated="$(sed -n \
    -e "s/${key}${day}${tail}/\1/p" \
    -e "s/${key}'${day}'${tail}/\1/p" \
    -e "s/${key}\"${day}\"${tail}/\1/p" \
    "${citation}" | head -1)"

  # The key is read the same loose way on both sides, since YAML accepts a space
  # before the colon and a reader that missed it would report the field absent.
  if grep -qE '^date-released[[:space:]]*:' "${citation}" && [[ -z "${dated}" ]]; then
    printf 'version: %s carries a date-released this cannot read\n' "${citation}" >&2
    grep -nE '^date-released[[:space:]]*:' "${citation}" | sed 's/^/  /' >&2
    printf '  expected: date-released: "YYYY-MM-DD", and nothing after it\n' >&2
    return 1
  fi

  if [[ -z "${released}" && -n "${dated}" ]]; then
    printf 'version: %s dates a release %s does not have\n' "${citation}" "${changelog}" >&2
    printf '  date-released: %s\n' "${dated}" >&2
    printf '  %s is still under "## Unreleased"\n' "${version}" >&2
    printf '  remove date-released until the release rolls the changelog\n' >&2
    return 1
  fi

  if [[ -n "${released}" && "${released}" != "${dated}" ]]; then
    printf 'version: %s and %s disagree on the release date\n' "${citation}" "${changelog}" >&2
    printf '  changelog: %s\n' "${released}" >&2
    printf '  citation:  %s\n' "${dated:-<none>}" >&2
    return 1
  fi
}

# The import lines a scan read, held to the manifest's version.
#
# Written as a function of the lines rather than of the scan, so --self-test can
# run every branch: `git grep` finding nothing and every import being correct
# look the same from outside, and with `|| true` on the scan they were the same
# here. A guard that read nothing is a guard that passes for the wrong reason.
import_versions() {
  local wanted="$1" lines="$2"
  local read_lines stale

  read_lines="$(grep -c '@preview/keisen:' <<<"${lines}" || true)"
  if [[ "${read_lines}" -eq 0 ]]; then
    printf 'version: no import of @preview/keisen was read at all\n' >&2
    printf '  the install line is written in the README, the reference and the examples\n' >&2
    return 1
  fi

  stale="$(awk -F'@preview/keisen:' -v want="${wanted}" '$2 != want' <<<"${lines}")"
  if [[ -n "${stale}" ]]; then
    printf 'version: an import names a version the manifest does not\n' >&2
    printf '  typst.toml: %s\n' "${wanted}" >&2
    # Every offender, rather than the first: a bump is then one pass over the
    # repository instead of one run of this script per file.
    printf '%s\n' "${stale}" |
      awk -F'@preview/keisen:' '{ sub(/:$/, "", $1); printf "  %s names %s\n", $1, $2 }' >&2
    return 1
  fi
}

# Every branch of the rule above, against fixtures. A guard nothing exercises is
# a guard that passes because its pattern stopped matching.
if [[ "${1:-}" == "--self-test" ]]; then
  fixtures="$(mktemp -d)"
  trap 'rm -rf "${fixtures}"' EXIT
  cases=0
  bad=0

  # The message is asserted as well as the exit code, since three branches all
  # end in 1 and a pattern that stopped matching would move a case from one to
  # another without changing the status.
  expect() {
    local wanted="$1" reported="$2" changelog="$3" citation="$4" name="$5"
    cases=$((cases + 1))
    printf '%s\n' "${changelog}" >"${fixtures}/CHANGELOG.md"
    printf '%s\n' "${citation}" >"${fixtures}/CITATION.cff"
    local got=0
    local said
    said="$(citation_date "${fixtures}/CHANGELOG.md" "${fixtures}/CITATION.cff" "0.1.0" 2>&1 >/dev/null)" ||
      got=$?
    if [[ "${got}" -ne "${wanted}" ]]; then
      bad=$((bad + 1))
      printf '  FAIL  self-test  %s  wanted exit %s, got %s\n' "${name}" "${wanted}" "${got}" >&2
      return
    fi
    if [[ -n "${reported}" && "${said}" != *"${reported}"* ]]; then
      bad=$((bad + 1))
      printf '  FAIL  self-test  %s  wanted the %s branch\n' "${name}" "${reported}" >&2
      printf '        said: %s\n' "${said%%$'\n'*}" >&2
    fi
  }

  # A stale date, in the three shapes a reader might leave it in. Each of these
  # fails whether the date parses or not, so they say the field is refused, not
  # that it was read.
  expect 0 '' '## Unreleased' 'version: 0.1.0' 'unreleased, no date'
  expect 1 'dates a release' '## Unreleased' 'date-released: "2026-08-17"' 'unreleased, dated'
  expect 1 'cannot read' '## Unreleased' 'date-released: "2026-08-17 # left over' 'unreadable date'
  expect 1 'cannot read' '## Unreleased' 'date-released: "2026-8-7"' 'date of the wrong shape'

  # That each shape is read is asserted on a released tree, where a date the
  # pattern misses turns into a disagreement and the exit code changes.
  expect 0 '' '## 0.1.0 (2026-09-01)' 'date-released: "2026-09-01"' 'released, double quotes'
  expect 0 '' '## 0.1.0 (2026-09-01)' "date-released: '2026-09-01'" 'released, single quotes'
  expect 0 '' '## 0.1.0 (2026-09-01)' 'date-released: 2026-09-01' 'released, bare'
  expect 0 '' '## 0.1.0 (2026-09-01)' 'date-released : 2026-09-01' 'released, space before the colon'
  expect 1 'disagree' '## 0.1.0 (2026-09-01)' 'version: 0.1.0' 'released, no date'
  expect 1 'disagree' '## 0.1.0 (2026-09-01)' 'date-released: "2026-08-17"' 'released, dates disagree'

  # The other two guards read three file formats between them, and on this tree
  # every copy agrees, so only the passing path would ever run.
  describes() {
    local wanted="$1" reported="$2" toml="$3" readme="$4" quarto="$5" webmanifest="$6" name="$7"
    cases=$((cases + 1))
    printf '%s\n' "${toml}" >"${fixtures}/typst.toml"
    printf '%s\n' "${readme}" >"${fixtures}/README.md"
    printf '%s\n' "${quarto}" >"${fixtures}/_quarto.yml"
    printf '%s\n' "${webmanifest}" >"${fixtures}/site.webmanifest"
    local got=0 said
    said="$(package_description "${fixtures}/typst.toml" "${fixtures}/README.md" \
      "${fixtures}/_quarto.yml" "${fixtures}/site.webmanifest" 2>&1 >/dev/null)" || got=$?
    if [[ "${got}" -ne "${wanted}" ]]; then
      bad=$((bad + 1))
      printf '  FAIL  self-test  %s  wanted exit %s, got %s\n' "${name}" "${wanted}" "${got}" >&2
      return
    fi
    if [[ -n "${reported}" && "${said}" != *"${reported}"* ]]; then
      bad=$((bad + 1))
      printf '  FAIL  self-test  %s  wanted the %s branch\n' "${name}" "${reported}" >&2
      printf '        said: %s\n' "${said%%$'\n'*}" >&2
    fi
  }

  # The four files, written the way each format writes them. The webmanifest
  # description is written last in its object here, since a trailing comma is a
  # neighbour's business rather than this field's.
  agreed_toml='description = "A description."'
  agreed_readme='# Title

A **description**.'
  agreed_quarto='website:
  description: "A description."'
  agreed_web='{
  "name": "Keisen",
  "description": "A description."
}'

  describes 0 '' "${agreed_toml}" "${agreed_readme}" "${agreed_quarto}" "${agreed_web}" 'every copy agrees'
  describes 0 '' "${agreed_toml}" '# Title

[![badge](x)](y)

A **description**.' "${agreed_quarto}" "${agreed_web}" 'a badge row above the tagline'
  describes 1 'written four ways' "${agreed_toml}" '# Title

Another description.' "${agreed_quarto}" "${agreed_web}" 'the README drifted'
  describes 1 'written four ways' "${agreed_toml}" "${agreed_readme}" 'website:
  description: "Another description."' "${agreed_web}" 'the site drifted'
  describes 0 '' "${agreed_toml}" "${agreed_readme}" "website:
  description: 'A description.'" "${agreed_web}" 'the site in single quotes'
  describes 0 '' "${agreed_toml}" "${agreed_readme}" 'website:
  description: A description.' "${agreed_web}" 'the site unquoted'
  describes 0 '' "${agreed_toml}" "${agreed_readme}" 'format:
  html:
    description: "Another description."
website:
  description: "A description."' "${agreed_web}" 'a description above the website block'
  describes 1 'cannot read' "${agreed_toml}" "${agreed_readme}" 'website:
  description:' "${agreed_web}" 'a website description that reads as nothing'
  describes 1 'written four ways' "${agreed_toml}" "${agreed_readme}" "${agreed_quarto}" '{
  "description": "Another description.",
  "name": "Keisen"
}' 'the web app manifest drifted'
  describes 1 'carries no description' 'name = "keisen"' "${agreed_readme}" "${agreed_quarto}" "${agreed_web}" 'the manifest carries none'

  categorised() {
    local wanted="$1" reported="$2" toml="$3" name="$4"
    cases=$((cases + 1))
    printf '%s\n' "${toml}" >"${fixtures}/typst.toml"
    local got=0 said
    said="$(manifest_categories "${fixtures}/typst.toml" 2>&1 >/dev/null)" || got=$?
    if [[ "${got}" -ne "${wanted}" ]]; then
      bad=$((bad + 1))
      printf '  FAIL  self-test  %s  wanted exit %s, got %s\n' "${name}" "${wanted}" "${got}" >&2
      return
    fi
    if [[ -n "${reported}" && "${said}" != *"${reported}"* ]]; then
      bad=$((bad + 1))
      printf '  FAIL  self-test  %s  wanted the %s branch\n' "${name}" "${reported}" >&2
      printf '        said: %s\n' "${said%%$'\n'*}" >&2
    fi
  }

  categorised 0 '' 'categories = ["visualization", "components"]' 'two categories on one line'
  categorised 0 '' 'categories = [
  "visualization",
  "components",
]' 'an array across lines'
  categorised 0 '' "categories = ['report']" 'a literal string'
  categorised 1 'does not carry' 'categories = ["visualisation"]' 'a category upstream does not carry'
  categorised 1 'names no category' 'name = "keisen"' 'no categories key'
  categorised 1 'names no category' 'categories = []' 'an empty array'
  categorised 1 'names no category' '# categories = ["report"]' 'a commented key'

  imported() {
    local wanted="$1" reported="$2" lines="$3" name="$4"
    cases=$((cases + 1))
    local got=0 said
    said="$(import_versions "0.1.0" "${lines}" 2>&1 >/dev/null)" || got=$?
    if [[ "${got}" -ne "${wanted}" ]]; then
      bad=$((bad + 1))
      printf '  FAIL  self-test  %s  wanted exit %s, got %s\n' "${name}" "${wanted}" "${got}" >&2
      return
    fi
    if [[ -n "${reported}" && "${said}" != *"${reported}"* ]]; then
      bad=$((bad + 1))
      printf '  FAIL  self-test  %s  wanted the %s branch\n' "${name}" "${reported}" >&2
      printf '        said: %s\n' "${said%%$'\n'*}" >&2
    fi
  }

  # The import line is spelled from a variable rather than written out, because
  # the live scan below reads this file too, and a fixture naming another version
  # would be an offender of its own.
  mark='@preview/keisen'

  imported 0 '' "README.md:12:${mark}:0.1.0" 'one import, the manifest version'
  imported 0 '' "README.md:12:${mark}:0.1.0
docs/index.qmd:4:${mark}:0.1.0" 'two imports that agree'
  imported 1 'a version the manifest does not' "README.md:12:${mark}:0.2.0" 'an import that drifted'
  imported 1 'a version the manifest does not' "README.md:12:${mark}:0.1.0
docs/index.qmd:4:${mark}:0.0.9" 'one of two that drifted'
  imported 1 'read at all' '' 'a scan that read nothing'

  if [[ ${bad} -gt 0 ]]; then
    printf 'version: %d/%d self-test case(s) failed\n' "${bad}" "${cases}" >&2
    exit 1
  fi
  printf 'version:  self-test %d/%d\n' "${cases}" "${cases}"
  exit 0
fi

# One argument is understood. A mistyped flag would otherwise run the live check
# and report a pass, which is how a caller loses the self-test without noticing.
if [[ -n "${1:-}" ]]; then
  printf 'version: unknown argument %s\n' "$1" >&2
  printf '  the only one is --self-test\n' >&2
  exit 2
fi

manifest="$(awk -F'"' '/^version[[:space:]]*=/ { print $2; exit }' typst.toml)"
citation="$(awk '/^version:[[:space:]]*/ { print $2; exit }' CITATION.cff)"

if [[ -z "${manifest}" ]]; then
  echo "version: typst.toml carries no version" >&2
  exit 1
fi

if [[ "${manifest}" != "${citation}" ]]; then
  printf 'version: typst.toml and CITATION.cff disagree\n' >&2
  printf '  typst.toml:   %s\n' "${manifest}" >&2
  printf '  CITATION.cff: %s\n' "${citation:-<none>}" >&2
  exit 1
fi

# Either the version has a dated section of its own, or the changes are still
# being gathered under Unreleased. Neither means the changelog was never
# touched.
#
# The two accepted headings are the grammar docs/_scripts/pre-render.sh reads to
# build the changelog page. It matches `## Unreleased` and `## X.Y.Z (date)`, and
# nothing else, so a heading written any other way reaches the site as loose text
# under no version at all. Checking the same grammar here is what keeps the two
# from disagreeing in silence.
escaped="${manifest//./\\.}"
if ! grep -qE "^## (Unreleased|${escaped} \([0-9]{4}-[0-9]{2}-[0-9]{2}\))$" CHANGELOG.md; then
  printf 'version: CHANGELOG.md holds no dated section for %s and none for Unreleased\n' "${manifest}" >&2
  printf '  expected: "## %s (YYYY-MM-DD)" or "## Unreleased"\n' "${manifest}" >&2
  exit 1
fi

# A citation carries the date the software was released, and GitHub renders it
# through the "Cite this repository" widget. Nothing else reads the field, and it
# was wrong once already: a rehearsal left the date of a tag that was deleted, so
# the widget cited a release that does not exist.
#
# The changelog is what says whether there is a release. A dated section for the
# manifest version means the version shipped on that day, and the citation says
# the same day; Unreleased means nothing shipped, and the citation says no date.
#
# Written as a function of two files, so `--self-test` below can run every
# branch against fixtures rather than leaving them to be read.
#
# What this does not hold: the citation's `version` follows the manifest, so a
# development version after a release makes the widget cite a version nobody can
# install, with no date. Pinning the citation to the last released version would
# settle it, and that is a decision rather than a check.

citation_date CHANGELOG.md CITATION.cff "${manifest}"
package_description typst.toml README.md docs/_quarto.yml docs/site.webmanifest
manifest_categories typst.toml

# The import line is what a reader copies, and it carries the version by hand.
# README.md reaches furthest: tools/stage-readme.sh keeps its quick look for the
# packaged README, which Typst Universe renders on the package page, so a stale
# import there is published alongside the release it misnames.
#
# The documentation's listings are compiled against an installed copy by
# tools/dry-release.sh, which catches a stale one as a Typst compile error. That
# is the release rehearsal; tools/check.sh runs before every commit and runs
# this script instead, so without this check the first report comes late and
# names a missing package rather than a version.
#
# Tracked files are scanned rather than listed, so a page written after this was
# is covered on the day it is written.
#
# A placeholder is not a version. ARCHITECTURE.md writes `x.y.z` and
# CONTRIBUTING.md writes `<version>`, and a semantic version matches neither.
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "version: not a git checkout, so the import lines cannot be read" >&2
  exit 1
fi

# git grep reads the tracked files, skips the binary ones, and carries a path
# with a space in it through unharmed. Finding nothing is not an error to git, so
# the count is read by the function above rather than trusted here.
lines="$(git grep -nEo '@preview/keisen:[0-9]+\.[0-9]+\.[0-9]+' || true)"

import_versions "${manifest}" "${lines}" || exit 1

printf 'version:  %s\n' "${manifest}"
