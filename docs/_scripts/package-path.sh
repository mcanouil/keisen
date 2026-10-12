#!/usr/bin/env bash
#
# Package path for typst-render.
#
# The pages show the visual tests, which import @preview/keisen as a reader
# does. typst-render resolves that import through docs/.typst-packages, linked
# back to the working tree; _quarto.yml names it as the package path. Kept apart
# from pre-render.sh, which is the same in every repository.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(dirname "${SCRIPT_DIR}")"
ROOT_DIR="$(dirname "${DOCS_DIR}")"

"${ROOT_DIR}/tools/package-path.sh" "${DOCS_DIR}/.typst-packages" >/dev/null
printf '[pre-render] @preview/keisen -> working tree (.typst-packages)\n'
