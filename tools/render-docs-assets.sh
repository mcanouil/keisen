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

# Enabled before anything below is parsed, since a page glob written with
# `+([0-9])` is a syntax error to a shell that has not been told to read it.
shopt -s nullglob extglob

# A page suffix is a number, and a visual test may be named with one, so
# `nanoplots-2.png` is either the second page of `nanoplots` or the whole of
# `nanoplots-2`. Nothing in the name says which, and the run that cleared the
# destination by `-[0-9]*` deleted the second while reporting success on both.
#
# Refused rather than resolved, because either reading is wrong for the other
# test. With the pair refused, the clearing glob below names this test's own
# pages and nothing else.
#
# Written as a function of a name list, so --self-test can run it over lists:
# the tree holds no such pair, so the live path never reaches the refusal.
name_collisions() {
  local name other
  for name in "$@"; do
    [[ "${name}" =~ ^(.+)-[0-9]+$ ]] || continue
    for other in "$@"; do
      if [[ "${other}" == "${BASH_REMATCH[1]}" ]]; then
        printf '%s.png reads as page %s of %s\n' "${name}" "${name##*-}" "${other}"
      fi
    done
  done
}

if [[ "${1:-}" == "--self-test" ]]; then
  if [[ $# -gt 1 ]]; then
    printf 'render-docs-assets: unknown argument %s\n' "$2" >&2
    printf '  the only one is --self-test\n' >&2
    exit 2
  fi

  cases=0
  bad=0

  collide() {
    local wanted="$1" name="$2"
    shift 2
    cases=$((cases + 1))
    local found
    found="$(name_collisions "$@" | wc -l | tr -d ' ')"
    if [[ "${found}" -ne "${wanted}" ]]; then
      bad=$((bad + 1))
      printf '  FAIL  self-test  %s  wanted %s collision(s), found %s\n' "${name}" "${wanted}" "${found}" >&2
    fi
  }

  collide 0 'a name and a worded sibling' nanoplots nanoplots-inline
  collide 0 'a numbered name on its own' nanoplots-2
  collide 0 'a sibling whose tail is not a number' nanoplots nanoplots-3d
  collide 1 'a name and its numbered sibling' nanoplots nanoplots-2 nanoplots-inline
  collide 2 'two numbered siblings of one name' report report-1 report-2
  collide 0 'no visual test at all'

  # The page glob itself, against files rather than against a string. The
  # counting and the clearing below are written as the same pattern, and this
  # holds that pattern to selecting the pages and nothing beside them: a name
  # whose tail is not a number belongs to the test that carries it.
  probe="$(mktemp -d)"
  trap 'rm -rf "${probe}"' EXIT
  for leaf in report.png report-1.png report-12.png report-3d.png report-inline.png; do
    : >"${probe}/${leaf}"
  done
  selected=("${probe}/report"-+([0-9]).png)
  # Sorted rather than taken in the order the glob returned, because pathname
  # expansion sorts by the locale and a UTF-8 one ignores the hyphen, which puts
  # report-12 before report-1.
  chosen=""
  if [[ ${#selected[@]} -gt 0 ]]; then
    chosen="$(for path in "${selected[@]}"; do basename "${path}"; done | LC_ALL=C sort | tr '\n' ' ')"
  fi

  cases=$((cases + 1))
  if [[ "${chosen}" != "report-1.png report-12.png " ]]; then
    bad=$((bad + 1))
    printf '  FAIL  self-test  the page glob selects the pages alone  got %s\n' "${chosen}" >&2
  fi

  if [[ ${bad} -gt 0 ]]; then
    printf 'render-docs-assets: %d/%d self-test case(s) failed\n' "${bad}" "${cases}" >&2
    exit 1
  fi

  printf 'assets:   self-test %d/%d\n' "${cases}" "${cases}"
  exit 0
fi

OUT_DIR="${1:-docs/assets/examples}"
PPI=144

mkdir -p "${OUT_DIR}"

# One staging directory for the whole run, removed however the script ends. Made
# inside the loop and removed on the success path alone, a compile that failed
# left it behind, and tools/check.sh runs this on every invocation.
stage="$(mktemp -d "${TMPDIR:-/tmp}/keisen-assets.XXXXXX")"
trap 'rm -rf "${stage}"' EXIT

names=()
for f in tests/visual/*.typ; do
  names+=("$(basename "${f%.typ}")")
done

# Rendering nothing and reporting success is how a suite claims coverage it does
# not have. Read here rather than after the loop, since an empty array is what
# every line below walks.
if [[ ${#names[@]} -eq 0 ]]; then
  printf 'render-docs-assets: no visual test under tests/visual\n' >&2
  exit 1
fi

collisions=()
while IFS= read -r line; do
  [[ -n "${line}" ]] && collisions+=("${line}")
done < <(name_collisions "${names[@]}")

if [[ ${#collisions[@]} -gt 0 ]]; then
  printf 'render-docs-assets: two visual tests share a rendered name\n' >&2
  printf '  %s\n' "${collisions[@]}" >&2
  printf '  rename one of them; a trailing number reads as a page\n' >&2
  exit 1
fi

for name in "${names[@]}"; do
  f="tests/visual/${name}.typ"

  # Rendered aside and moved into place only once every page is written.
  # Clearing first, as this did, meant a compile that failed halfway left the
  # tracked image deleted and the site serving nothing at all.
  rm -f "${stage:?}"/*.png
  # A document of several pages needs a page-number template in the path.
  typst compile "${f}" --root "${REPO_ROOT}" "${stage}/${name}-{p}.png" \
    --format png --ppi "${PPI}" --ignore-system-fonts

  # The pattern the clearing line below uses, and the one the self-test holds:
  # a page is the name, a hyphen, and digits.
  rendered=("${stage}/${name}"-+([0-9]).png)
  pages="${#rendered[@]}"

  # A single-page document reads better without a page number in its name.
  if [[ "${pages}" == "1" ]]; then
    mv "${stage}/${name}-1.png" "${stage}/${name}.png"
  fi

  # Only now is the previous output cleared. The page suffix is matched as
  # digits and nothing else: a plain -* would make "nanoplots" claim the output
  # of "nanoplots-inline", and -[0-9]* would claim "nanoplots-3d", which is a
  # name the refusal above allows because it is not a page number.
  rm -f "${OUT_DIR}/${name}".png "${OUT_DIR}/${name}"-+([0-9]).png
  mv "${stage}/${name}"*.png "${OUT_DIR}/"

  printf '%-12s %s page(s)\n' "${name}:" "${pages}"
done
