#!/usr/bin/env bash
#
# Failed tables fail the render.
#
# typst-render reports a block that does not compile as a warning, puts an error
# box on the page in place of the table, and lets the render succeed. A site
# built that way would publish error boxes with a green build, so this runs
# after the render and fails it instead. It also fails when a page's card image,
# which a hidden block writes, did not reach the site, and when a listing still
# shows a visual test's "/lib.typ" import, which _filters/package-import.lua
# writes as the package import.
# Kept apart from post-render.sh, which is the same in every repository.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(dirname "${SCRIPT_DIR}")"
OUTPUT_DIR="${QUARTO_PROJECT_OUTPUT_DIR:-_site}"
[[ "${OUTPUT_DIR}" = /* ]] || OUTPUT_DIR="${DOCS_DIR}/${OUTPUT_DIR}"

# The pages this render wrote, one per line, or every page when Quarto names none.
pages=()
source_of_pages="QUARTO_PROJECT_OUTPUT_FILES named no .html file"
if [[ -n "${QUARTO_PROJECT_OUTPUT_FILES:-}" ]]; then
  while IFS= read -r page; do
    [[ "${page}" == *.html ]] && pages+=("${page}")
  done <<<"${QUARTO_PROJECT_OUTPUT_FILES}"
else
  source_of_pages="no .html file under ${OUTPUT_DIR}"
  while IFS= read -r page; do
    pages+=("${page}")
  done < <(find "${OUTPUT_DIR}" -name '*.html')
fi

# Reading no page would report success having checked nothing.
if [[ ${#pages[@]} -eq 0 ]]; then
  printf '[post-render] typst-render: no rendered page was read; got 0 pages\n' >&2
  printf '  %s\n' "${source_of_pages}" >&2
  exit 1
fi

failed=()
for page in "${pages[@]}"; do
  [[ "${page}" = /* ]] || page="${DOCS_DIR}/${page}"
  [[ -f "${page}" ]] || continue
  if grep -q 'typst-render-error' "${page}"; then
    failed+=("${page#"${DOCS_DIR}"/} (a table did not compile)")
  fi
  # Only the listings, inside <pre>, so prose may name the import. Highlighting
  # splits a line into spans, so the tags are removed first. grep reads to the
  # end, rather than -q, so pipefail does not see the pipe cut short.
  if awk '/<pre/ { inside = 1 } inside { print } /<\/pre>/ { inside = 0 }' "${page}" |
    sed 's/<[^>]*>//g; s/&quot;/"/g' | grep '#import "/lib\.typ"' >/dev/null; then
    failed+=("${page#"${DOCS_DIR}"/} (a listing shows the \"/lib.typ\" import)")
  fi

  # A card image is named in the page's front matter and written by a hidden
  # block, which shows nothing when it fails, so the served file is what proves
  # it compiled. Only the pages this render wrote are checked.
  relative="${page#"${OUTPUT_DIR}"/}"
  source="${DOCS_DIR}/${relative%.html}.qmd"
  [[ -f "${source}" ]] || continue
  image="$(sed -n 's|^image: \(.*assets/typst-render/.*\)$|\1|p' "${source}")"
  if [[ -n "${image}" && ! -f "$(dirname "${page}")/${image}" ]]; then
    failed+=("${relative%.html}.qmd: ${image} (card image not written)")
  fi
done

if [[ ${#failed[@]} -gt 0 ]]; then
  printf '[post-render] typst-render: %d failure(s); got:\n' "${#failed[@]}" >&2
  printf '  %s\n' "${failed[@]}" >&2
  printf '  a table: compile the test the page names with tools/check.sh to see its error\n' >&2
  printf '  an import: check that _quarto.yml lists _filters/package-import.lua\n' >&2
  exit 1
fi
printf '[post-render] typst-render: every table compiled\n'
