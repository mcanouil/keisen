#!/usr/bin/env bash
# Enforces the dependency boundary: the core is dependency-free.
# No file under src may import a third-party Typst package, so installing keisen
# fetches keisen and nothing else.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

offenders="$(grep -rln '@preview/' src --include='*.typ' || true)"

if [[ -n "${offenders}" ]]; then
  printf 'import boundary: @preview import under src\n' >&2
  printf '  %s\n' "${offenders}" >&2
  exit 1
fi

printf 'boundary: ok\n'
