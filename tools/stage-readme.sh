#!/usr/bin/env bash
# Strips the repository-only parts of README.md for the published package.
#
# Typst Universe renders the README itself, and several things in ours mean
# nothing there: the Ask DeepWiki badge points at this repository, GitHub's
# alert blocks (`> [!WARNING]`) render as plain quotes outside GitHub, and a
# `<picture>` element is dropped rather than shown.
#
# Everything from "## Dependencies" onward is repository business too:
# dependencies, contributing, citation, licence. The published README keeps
# what a reader of the package needs, which is the introduction, the quick
# look, and the note for AI assistants.

set -euo pipefail

SRC="${1:?source README path required}"
DEST_DIR="${2:?destination directory required}"
DEST="${DEST_DIR}/README.md"

[[ -f "${SRC}" ]] || {
  echo "stage-readme: source not found: ${SRC}" >&2
  exit 1
}
[[ -d "${DEST_DIR}" ]] || {
  echo "stage-readme: destination directory not found: ${DEST_DIR}" >&2
  exit 1
}

# Refuse when source and destination are the same file: the redirect below
# truncates the destination before perl reads the source.
src_real="$(cd "$(dirname "${SRC}")" && pwd -P)/$(basename "${SRC}")"
dest_real="$(cd "${DEST_DIR}" && pwd -P)/README.md"
if [[ "${src_real}" == "${dest_real}" ]]; then
  echo "stage-readme: refusing to overwrite source (${src_real})" >&2
  exit 1
fi

perl -0777 -pe '
  s{[ \t]*<picture\b[^>]*>.*?</picture>}{}gs;
  s{^\[!\[Ask DeepWiki\]\([^\n]*\n\n?}{}gm;
  s{^> \[![A-Z]+\][ \t]*\n(?:> [^\n]*\n)*\n?}{}gm;
  s{(^## Quick look\b[^\n]*\n.*?\n)^## Dependencies\b.*\z}{$1}ms;
' "${SRC}" >"${DEST}"

# The staged README is checked against the headings it must carry as well as the
# ones it must not.
#
# Checking only for what should be gone is not enough, and it failed in exactly
# the way it was written to prevent. Rename `## Dependencies` in the source and
# the substitution above matches nothing, so it cuts nothing; the guard then
# looks for a heading that no longer exists anywhere and passes, and the
# published package ships Contributing, Citation and License to Typst Universe.
#
# Naming what must survive is what makes a rename loud: whichever side of the
# boundary the renamed heading falls, one of the two lists disagrees with the
# file.
KEPT=("## Quick look" "## AI assistants")
DROPPED=("## Dependencies" "## Contributing" "## Citation" "## License")

for heading in "${KEPT[@]}"; do
  if ! grep -qxF "${heading}" "${DEST}"; then
    printf "stage-readme: '%s' is missing from the staged README\n" "${heading}" >&2
    printf '  the published package keeps the introduction, the quick look and the note for AI assistants\n' >&2
    printf '  a heading was renamed or removed in %s; update KEPT in this script to match\n' "${SRC}" >&2
    exit 1
  fi
done

for heading in "${DROPPED[@]}"; do
  if grep -qxF "${heading}" "${DEST}"; then
    printf "stage-readme: '%s' survived into the staged README\n" "${heading}" >&2
    printf '  everything from the boundary heading onward is repository business\n' >&2
    printf '  the boundary the substitution cuts on no longer matches %s\n' "${SRC}" >&2
    exit 1
  fi
done
