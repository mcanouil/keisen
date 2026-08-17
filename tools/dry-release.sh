#!/usr/bin/env bash
# Local rehearsal of a Typst Universe release. Publishes nothing: no tag, no
# GitHub Release, no upstream pull request.
#
# Stages the payload tools/package.sh produces, installs it under Typst's data
# directory as @preview/keisen:<version> through a symlink, compiles the whole
# suite and the documentation's listings against that installed copy, then
# removes the symlink.
#
# The point is the import. A module that cannot be reached from a package
# specification compiles perfectly from this working tree and fails for
# everyone who installs it, which is how the package shipped a nanoplot module
# nobody could import. Compiling from an installed copy is the only check that
# sees it.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

tools/version-check.sh

VERSION="$(awk -F'"' '/^version[[:space:]]*=/ { print $2; exit }' typst.toml)"

STAGE_ROOT="${STAGE_ROOT:-/tmp/keisen-dry-release}"
STAGE="${STAGE_ROOT}/keisen/${VERSION}"

case "$(uname -s)" in
Darwin) DATA_DIR="${HOME}/Library/Application Support/typst" ;;
Linux) DATA_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/typst" ;;
*)
  echo "unsupported OS: $(uname -s)" >&2
  exit 1
  ;;
esac
INSTALL_DIR="${DATA_DIR}/packages/preview/keisen"
INSTALL_LINK="${INSTALL_DIR}/${VERSION}"

# Only a link this run created is removed. A developer may keep one of their
# own pointing somewhere they are working, and a rehearsal that silently
# deletes it would be worse than one that refuses to run.
LINKED_HERE=0

cleanup() {
  if [[ ${LINKED_HERE} -eq 1 && -L "${INSTALL_LINK}" ]]; then
    rm -f "${INSTALL_LINK}"
  fi
}
trap cleanup EXIT

rm -rf "${STAGE_ROOT}"
tools/package.sh stage "${STAGE}"
printf 'Staged payload at %s\n' "${STAGE}"

mkdir -p "${INSTALL_DIR}"
if [[ -e "${INSTALL_LINK}" || -L "${INSTALL_LINK}" ]]; then
  printf '%s already exists; refusing to overwrite an installed copy\n' "${INSTALL_LINK}" >&2
  printf '  remove it, or run with a version this machine does not carry\n' >&2
  exit 1
fi
ln -sfn "${STAGE}" "${INSTALL_LINK}"
LINKED_HERE=1
printf 'Linked @preview/keisen:%s -> %s\n' "${VERSION}" "${STAGE}"

SMOKE_DIR="${STAGE_ROOT}/smoke"
mkdir -p "${SMOKE_DIR}"

failures=0
total=0

# Every visual test, with its relative import rewritten to the package
# specification. These exercise the whole public surface, since most of them
# import it wholesale.
for f in tests/visual/*.typ; do
  total=$((total + 1))
  name="$(basename "${f%.typ}")"
  smoke="${SMOKE_DIR}/visual-${name}.typ"
  sed -E "s|\"\.\./\.\./lib\.typ\"|\"@preview/keisen:${VERSION}\"|" "${f}" >"${smoke}"

  if ! typst compile "${smoke}" "${SMOKE_DIR}/visual-${name}.pdf" 2>"${SMOKE_DIR}/visual-${name}.err"; then
    failures=$((failures + 1))
    printf '  FAIL  installed  %s\n' "${f}" >&2
    sed -n '1,5p' "${SMOKE_DIR}/visual-${name}.err" >&2
  fi
done

# The documentation's own listings, which is where the unreachable import was
# printed. A listing that names the package is a whole document; the fragments
# that show a directive or two are skipped by that same test.
listings=0
# Every page of the site, at any depth. The documentation is laid out as a
# section per topic, so a non-recursive glob would walk past every page that
# carries a listing and report success having compiled none of them.
#
# Directories Quarto ignores are skipped: nothing under _site, _extensions or
# _scripts is served, and a listing there would be checked twice or not at all.
shopt -s globstar nullglob
for qmd in docs/**/*.qmd; do
  [[ "${qmd}" == */_* ]] && continue
  # Named after the path rather than the file: docs/reference/index.qmd and
  # docs/examples/index.qmd are both "index", and one would silently overwrite
  # the other's smoke files.
  name="${qmd#docs/}"
  name="${name%.qmd}"
  name="${name//\//-}"
  listings=$((listings + $(awk -v dir="${SMOKE_DIR}" -v name="${name}" '
    /^```typst$/ { inside = 1; body = ""; next }
    inside && /^```$/ {
      inside = 0
      if (body ~ /@preview\/keisen:/) {
        count += 1
        file = sprintf("%s/listing-%s-%02d.typ", dir, name, count)
        printf "%s", body > file
        close(file)
      }
      next
    }
    inside { body = body $0 "\n" }
    END { print count + 0 }
  ' "${qmd}")))
done

# Finding no listing would report success without compiling one, and a
# documentation site whose imports nobody checks is what this script is for.
if [[ ${listings} -eq 0 ]]; then
  echo "dry-release: no documentation listing imports the package" >&2
  exit 1
fi

for smoke in "${SMOKE_DIR}"/listing-*.typ; do
  total=$((total + 1))
  name="$(basename "${smoke%.typ}")"
  if ! typst compile "${smoke}" "${SMOKE_DIR}/${name}.pdf" 2>"${SMOKE_DIR}/${name}.err"; then
    failures=$((failures + 1))
    printf '  FAIL  installed  %s\n' "${smoke}" >&2
    sed -n '1,5p' "${SMOKE_DIR}/${name}.err" >&2
  fi
done

printf 'installed: %d/%d compiled (%d from documentation listings)\n' \
  "$((total - failures))" "${total}" "${listings}"

if [[ ${failures} -gt 0 ]]; then
  printf '\n%d failure(s) compiling against the installed package.\n' "${failures}" >&2
  exit 1
fi

# The lint Typst Universe itself runs on a submission, so a finding here is a
# finding upstream. It is reported rather than fatal: it fetches the homepage
# and repository URLs, and the homepage 404s until the documentation site is
# published, which happens at the release this script rehearses. Failing on
# that would make the rehearsal fail on every machine that has the tool, which
# is the same as having no rehearsal.
#
# It must be clean before a submission. Nothing here can tell that apart from
# the expected 404, so a human reads it.
if command -v typst-package-check >/dev/null 2>&1; then
  printf '\nManifest lint (advisory, reaches the network):\n'
  if typst-package-check check "${STAGE}"; then
    printf 'Manifest lint clean.\n'
  else
    printf '\ntypst-package-check reported the above. Until the documentation site\n' >&2
    printf 'is published an unreachable homepage is expected; anything else is not.\n' >&2
  fi
else
  printf 'typst-package-check not installed; skipping manifest lint.\n'
fi

printf '\nDry-run OK for keisen:%s\n' "${VERSION}"
