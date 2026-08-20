#!/usr/bin/env bash
# Enforces the dependency boundary: the core is dependency-free.
# No file under src may import a Typst package from any namespace, so installing
# keisen fetches keisen and nothing else.
#
# `@preview` is the namespace the rule in .claude/CLAUDE.md names, and it is not
# the only one that breaks it. `@local` resolves on the machine that wrote it and
# nowhere else, so the published package would carry an import nobody who
# installs it can read. The pattern is therefore any namespace at all.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

# Written as a function of a root, so --self-test can run it over fixture trees:
# the live path has only one root and it is never empty, which is exactly the
# case that used to pass. The scan ended in `|| true`, so a missing src read
# nothing and reported ok.
boundary_scan() {
  local root="$1"
  local files offenders

  files="$(find "${root}" -type f -name '*.typ' 2>/dev/null || true)"
  if [[ -z "${files}" ]]; then
    printf 'import boundary: no Typst file was read under %s\n' "${root}" >&2
    printf '  the boundary holds over the files it reads, and it read none\n' >&2
    return 1
  fi

  offenders="$(grep -rlE '@[A-Za-z0-9_-]+/' "${root}" --include='*.typ' || true)"
  if [[ -n "${offenders}" ]]; then
    printf 'import boundary: a package import under %s\n' "${root}" >&2
    printf '  %s\n' "${offenders}" >&2
    printf '  the core is dependency-free, in every namespace\n' >&2
    return 1
  fi
}

# Every branch of the rule above, against fixture trees. A guard nothing
# exercises is a guard that passes because its pattern stopped matching.
if [[ "${1:-}" == "--self-test" ]]; then
  fixtures="$(mktemp -d)"
  trap 'rm -rf "${fixtures}"' EXIT
  cases=0
  bad=0

  # The message is asserted beside the exit code, since both failing branches
  # end in 1 and a pattern that stopped matching would move a case from one to
  # the other without changing the status.
  expect() {
    local wanted="$1" reported="$2" name="$3" body="${4:-}"
    cases=$((cases + 1))
    rm -rf "${fixtures}/tree"
    mkdir -p "${fixtures}/tree"
    if [[ -n "${body}" ]]; then
      printf '%s\n' "${body}" >"${fixtures}/tree/module.typ"
    fi
    local got=0
    local said
    said="$(boundary_scan "${fixtures}/tree" 2>&1 >/dev/null)" || got=$?
    if [[ "${got}" -ne "${wanted}" ]]; then
      bad=$((bad + 1))
      printf '  FAIL  self-test  %s  wanted exit %s, got %s\n' "${name}" "${wanted}" "${got}" >&2
      return
    fi
    if [[ -n "${reported}" && "${said}" != *"${reported}"* ]]; then
      bad=$((bad + 1))
      printf '  FAIL  self-test  %s  wanted the %s branch\n' "${name}" "${reported}" >&2
    fi
  }

  expect 0 "" "a module that imports nothing" '#let table-header(title) = (kind: "header")'
  expect 0 "" "a module that imports a sibling" '#import "utils/errors.typ": check'
  expect 1 "a package import" "an @preview import" '#import "@preview/other:0.1.0": *'
  expect 1 "a package import" "an @local import" '#import "@local/other:0.1.0": *'
  expect 1 "no Typst file was read" "a tree holding no Typst file"

  cases=$((cases + 1))
  boundary_missing=0
  boundary_scan "${fixtures}/absent" >/dev/null 2>&1 || boundary_missing=$?
  if [[ "${boundary_missing}" -ne 1 ]]; then
    bad=$((bad + 1))
    printf '  FAIL  self-test  a root that is not there  wanted exit 1, got %s\n' "${boundary_missing}" >&2
  fi

  if [[ ${bad} -gt 0 ]]; then
    printf 'boundary: %d/%d self-test case(s) failed\n' "${bad}" "${cases}" >&2
    exit 1
  fi

  printf 'boundary: self-test %d/%d\n' "${cases}" "${cases}"
  exit 0
fi

# An argument this does not know is a typo, and a typo that runs the live check
# and reports a pass is how a caller loses the self-test without noticing.
if [[ $# -gt 0 ]]; then
  printf 'import boundary: unknown argument %s\n' "$1" >&2
  printf '  the only one is --self-test\n' >&2
  exit 1
fi

boundary_scan src

printf 'boundary: ok\n'
