#!/usr/bin/env bash
# Renders the visual tests into docs/assets/examples/, which is where the
# examples page gets its images. Run it after changing a visual test, so the
# picture on the site is the output of the code beside it.
#
# The render is reproducible, which is what lets tools/check.sh compare a fresh
# one with the tracked images rather than trusting that someone remembered to
# run this. Two things make it so, and both are deliberate:
#
#   - the resolution is fixed here rather than read from the environment, so an
#     exported PPI cannot make every tracked image look stale;
#   - system fonts are ignored, so the four families Typst embeds are the only
#     ones in play. Libertinus Serif, which every visual test names, is one of
#     them, so nothing falls back and a machine with its own copy installed
#     renders what the runner renders.
#
# A destination other than the tracked directory may be given, which is how the
# freshness check renders somewhere disposable.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

OUT_DIR="${1:-docs/assets/examples}"
PPI=144

mkdir -p "${OUT_DIR}"

shopt -s nullglob

# One staging directory for the whole run, removed however the script ends. Made
# inside the loop and removed on the success path alone, a compile that failed
# left it behind, and tools/check.sh runs this on every invocation.
stage="$(mktemp -d "${TMPDIR:-/tmp}/keisen-assets.XXXXXX")"
trap 'rm -rf "${stage}"' EXIT

total=0

for f in tests/visual/*.typ; do
  total=$((total + 1))
  name="$(basename "${f%.typ}")"

  # Rendered aside and moved into place only once every page is written.
  # Clearing first, as this did, meant a compile that failed halfway left the
  # tracked image deleted and the site serving nothing at all.
  rm -f "${stage:?}"/*.png
  # A document of several pages needs a page-number template in the path.
  typst compile "${f}" --root "${REPO_ROOT}" "${stage}/${name}-{p}.png" \
    --format png --ppi "${PPI}" --ignore-system-fonts

  pages="$(find "${stage}" -name "${name}-[0-9]*.png" | wc -l | tr -d ' ')"

  # A single-page document reads better without a page number in its name.
  if [[ "${pages}" == "1" ]]; then
    mv "${stage}/${name}-1.png" "${stage}/${name}.png"
  fi

  # Only now is the previous output cleared. The page suffix is matched as
  # digits, not as anything: a plain -* would make "nanoplots" claim the output
  # of "nanoplots-inline", deleting it and counting its pages as its own.
  rm -f "${OUT_DIR}/${name}".png "${OUT_DIR}/${name}"-[0-9]*.png
  mv "${stage}/${name}"*.png "${OUT_DIR}/"

  printf '%-12s %s page(s)\n' "${name}:" "${pages}"
done

# Rendering nothing and reporting success is how a suite claims coverage it does
# not have.
if [[ ${total} -eq 0 ]]; then
  printf 'render-docs-assets: no visual test under tests/visual\n' >&2
  exit 1
fi
