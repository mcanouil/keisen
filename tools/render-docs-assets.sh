#!/usr/bin/env bash
# Renders the visual tests into docs/assets/examples/, which is where the
# examples page gets its images. Run it after changing a visual test, so the
# picture on the site is the output of the code beside it.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

OUT_DIR="docs/assets/examples"
PPI="${PPI:-144}"

mkdir -p "${OUT_DIR}"

for f in tests/visual/*.typ; do
  name="$(basename "${f%.typ}")"
  # A document of several pages needs a page-number template in the path.
  typst compile "${f}" --root "${REPO_ROOT}" "${OUT_DIR}/${name}-{p}.png" --format png --ppi "${PPI}"

  pages="$(find "${OUT_DIR}" -name "${name}-*.png" | wc -l | tr -d ' ')"

  # A single-page document reads better without a page number in its name.
  if [[ "${pages}" == "1" ]]; then
    mv "${OUT_DIR}/${name}-1.png" "${OUT_DIR}/${name}.png"
  fi

  printf '%-12s %s page(s)\n' "${name}:" "${pages}"
done
