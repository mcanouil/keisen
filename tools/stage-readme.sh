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

# A silent no-op here would ship the repository README under a name that says
# otherwise, so the boundary the last substitution cuts on is checked.
if grep -q '^## Dependencies' "${DEST}"; then
  echo "stage-readme: the '## Dependencies' section survived; the README structure changed" >&2
  exit 1
fi
