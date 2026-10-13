#!/usr/bin/env bash
# Writes the next version into the four files that hold it, then holds them to
# one another with tools/version-check.sh. The Release workflow runs it, and so
# can anyone, since it changes files and nothing else.
#
# Usage:
#   bump-version.sh <patch|minor|major>
#   bump-version.sh --self-test
#
# The version is read from typst.toml. The files are:
#
#   - typst.toml, the version Typst Universe publishes;
#   - CITATION.cff, its version and the date it was released;
#   - CHANGELOG.md, whose `## Unreleased` heading becomes `## X.Y.Z (date)`;
#   - README.md, whose quick look is the one import that names a version.
#
# The list is short because tools/version-check.sh refuses a versioned import
# anywhere else, so no file can join it without that check saying so.
#
# RELEASE_DATE overrides today's date, in UTC, as YYYY-MM-DD.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

next_version() {
  local current="$1" part="$2"
  local major minor patch
  if [[ ! "${current}" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    printf 'bump-version: typst.toml names no semantic version; got "%s". Set version = "x.y.z".\n' "${current}" >&2
    return 1
  fi
  major="${BASH_REMATCH[1]}"
  minor="${BASH_REMATCH[2]}"
  patch="${BASH_REMATCH[3]}"
  case "${part}" in
  major) printf '%d.0.0\n' "$((major + 1))" ;;
  minor) printf '%d.%d.0\n' "${major}" "$((minor + 1))" ;;
  patch) printf '%d.%d.%d\n' "${major}" "${minor}" "$((patch + 1))" ;;
  *)
    printf 'bump-version: the part to bump is patch, minor or major; got "%s".\n' "${part}" >&2
    return 1
    ;;
  esac
}

# The changelog must hold an Unreleased section with an entry in it: a release
# with nothing under its heading publishes empty notes.
unreleased_entries() {
  local changelog="$1"
  awk '
    /^## Unreleased$/ { inside = 1; found = 1; next }
    /^## / { inside = 0 }
    inside && /^- / { entries += 1 }
    END { if (!found) exit 2; print entries + 0 }
  ' "${changelog}"
}

rewrite_files() {
  local dir="$1" version="$2" date="$3"
  local entries
  entries="$(unreleased_entries "${dir}/CHANGELOG.md")" || {
    printf 'bump-version: CHANGELOG.md has no "## Unreleased" heading; got none. Add one above the last release.\n' >&2
    return 1
  }
  if [[ "${entries}" -eq 0 ]]; then
    printf 'bump-version: "## Unreleased" in CHANGELOG.md holds no entry; got 0. Record the changes first.\n' >&2
    return 1
  fi

  sed -E -i.bak 's/^(version[[:space:]]*=[[:space:]]*")[^"]+/\1'"${version}"'/' "${dir}/typst.toml"
  sed -E -i.bak 's/^## Unreleased$/## '"${version}"' ('"${date}"')/' "${dir}/CHANGELOG.md"
  sed -E -i.bak 's|(@preview/keisen:)[0-9]+\.[0-9]+\.[0-9]+|\1'"${version}"'|' "${dir}/README.md"
  sed -E -i.bak 's/^version:.*/version: '"${version}"'/' "${dir}/CITATION.cff"
  # The citation carries no date while nothing is released, so the first
  # release adds the line rather than replacing it.
  if grep -qE '^date-released[[:space:]]*:' "${dir}/CITATION.cff"; then
    sed -E -i.bak 's/^date-released[[:space:]]*:.*/date-released: "'"${date}"'"/' "${dir}/CITATION.cff"
  else
    sed -E -i.bak 's/^version:.*/&\
date-released: "'"${date}"'"/' "${dir}/CITATION.cff"
  fi
  rm -f "${dir}"/*.bak
}

if [[ "${1:-}" == "--self-test" ]]; then
  fixtures="$(mktemp -d)"
  trap 'rm -rf "${fixtures}"' EXIT
  cases=0
  bad=0

  versioned() {
    local current="$1" part="$2" wanted="$3"
    cases=$((cases + 1))
    local got
    got="$(next_version "${current}" "${part}" 2>/dev/null)" || got="<refused>"
    if [[ "${got}" != "${wanted}" ]]; then
      bad=$((bad + 1))
      printf '  FAIL  self-test  %s %s  wanted %s, got %s\n' "${part}" "${current}" "${wanted}" "${got}" >&2
    fi
  }

  versioned 0.0.1 minor 0.1.0
  versioned 0.0.1 patch 0.0.2
  versioned 0.9.3 major 1.0.0
  versioned 1.2.3 minor 1.3.0
  versioned 0.1 minor '<refused>'
  versioned 0.1.0 build '<refused>'

  # The spelling of the import is built from a variable, as in version-check.sh,
  # so the live scan of tracked files does not read a fixture as an offender.
  mark='@preview/keisen'
  write_fixtures() {
    printf '[package]\nname = "keisen"\nversion = "0.0.1"\ncompiler = "0.15.0"\n' >"${fixtures}/typst.toml"
    printf 'title: "Keisen"\nversion: 0.0.1\nlicense: "MIT"\n' >"${fixtures}/CITATION.cff"
    printf '# Changelog\n\n## Unreleased\n\n- feat: Initial release.\n' >"${fixtures}/CHANGELOG.md"
    # shellcheck disable=SC2016 # the backticks are a Markdown fence, not a command
    printf '# Keisen\n\n```typst\n#import "%s:0.0.1": *\n```\n' "${mark}" >"${fixtures}/README.md"
  }

  holds() {
    local file="$1" line="$2" name="$3"
    cases=$((cases + 1))
    if ! grep -qxF "${line}" "${fixtures}/${file}"; then
      bad=$((bad + 1))
      printf '  FAIL  self-test  %s  wanted %s to hold: %s\n' "${name}" "${file}" "${line}" >&2
      sed 's/^/        /' "${fixtures}/${file}" >&2
    fi
  }

  write_fixtures
  rewrite_files "${fixtures}" 0.1.0 2026-10-14
  holds typst.toml 'version = "0.1.0"' 'the manifest'
  holds typst.toml 'compiler = "0.15.0"' 'the compiler left alone'
  holds CITATION.cff 'version: 0.1.0' 'the citation version'
  holds CITATION.cff 'date-released: "2026-10-14"' 'the citation date, added'
  holds CHANGELOG.md '## 0.1.0 (2026-10-14)' 'the changelog heading'
  holds README.md "#import \"${mark}:0.1.0\": *" 'the README import'

  rewrite_files "${fixtures}" 0.1.0 2026-10-14 2>/dev/null &&
    {
      bad=$((bad + 1))
      printf '  FAIL  self-test  a changelog with no Unreleased section was bumped\n' >&2
    }
  cases=$((cases + 1))

  printf '# Changelog\n\n## Unreleased\n\n## 0.1.0 (2026-10-14)\n\n- feat: Initial release.\n' >"${fixtures}/CHANGELOG.md"
  sed -i.bak 's/date-released: .*/date-released: "2026-10-14"/' "${fixtures}/CITATION.cff" && rm -f "${fixtures}"/*.bak
  rewrite_files "${fixtures}" 0.2.0 2026-11-01 2>/dev/null &&
    {
      bad=$((bad + 1))
      printf '  FAIL  self-test  an empty Unreleased section was bumped\n' >&2
    }
  cases=$((cases + 1))

  printf '# Changelog\n\n## Unreleased\n\n- fix: A fix.\n\n## 0.1.0 (2026-10-14)\n\n- feat: Initial release.\n' >"${fixtures}/CHANGELOG.md"
  rewrite_files "${fixtures}" 0.2.0 2026-11-01
  holds CITATION.cff 'date-released: "2026-11-01"' 'the citation date, replaced'
  holds CHANGELOG.md '## 0.2.0 (2026-11-01)' 'the next heading'
  holds CHANGELOG.md '## 0.1.0 (2026-10-14)' 'the last release left alone'

  if [[ ${bad} -gt 0 ]]; then
    printf 'bump-version: %d/%d self-test case(s) failed\n' "${bad}" "${cases}" >&2
    exit 1
  fi
  printf 'bump:     self-test %d/%d\n' "${cases}" "${cases}"
  exit 0
fi

if [[ $# -ne 1 ]]; then
  printf 'bump-version: expected one argument; got %d. Run tools/bump-version.sh <patch|minor|major>.\n' "$#" >&2
  exit 1
fi

cd "${REPO_ROOT}"
current="$(awk -F'"' '/^version[[:space:]]*=/ { print $2; exit }' typst.toml)"
version="$(next_version "${current}" "$1")"
date="${RELEASE_DATE:-$(date -u +%Y-%m-%d)}"
if [[ ! "${date}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  printf 'bump-version: RELEASE_DATE is not YYYY-MM-DD; got "%s".\n' "${date}" >&2
  exit 1
fi

rewrite_files "${REPO_ROOT}" "${version}" "${date}"
tools/version-check.sh >&2
printf '%s\n' "${version}"
