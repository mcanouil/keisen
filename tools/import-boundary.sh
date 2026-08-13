#!/usr/bin/env bash
# Enforces the dependency boundary: the core is dependency-free.
# Only files under src/integrations may import a third-party Typst package,
# so a user who never imports an integration never fetches its dependency.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

offenders="$(grep -rln '@preview/' src --include='*.typ' | grep -v '^src/integrations/' || true)"

if [[ -n "${offenders}" ]]; then
  printf 'import boundary: @preview import outside src/integrations\n' >&2
  printf '  %s\n' "${offenders}" >&2
  exit 1
fi

printf 'boundary: ok\n'
