#!/usr/bin/env bash
# Assembles the payload a Typst Universe release publishes, in one place, so
# the local dry-run and any future release job describe the same package.
#
# Usage:
#   package.sh stage   <dest-dir> [version]
#   package.sh archive <out-dir> [basename] [version]
#
# stage   fills <dest-dir> with the published payload: typst.toml, lib.typ,
#         LICENSE, the stripped README, and src/. Given a version, the staged
#         typst.toml is rewritten to it and stamped with the source commit,
#         which is what a development build wants.
# archive stages into a temporary directory, then writes <out-dir>/<basename>
#         as both .tar.gz and .zip. version defaults to the typst.toml value;
#         basename defaults to keisen-<version>.
#
# What ships is decided here and by `exclude` in typst.toml. The two must
# agree, and `stage` refuses to run when they do not: a tracked file named by
# neither would ship without anyone deciding that it should.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

read_version() {
  awk -F'"' '/^version[[:space:]]*=/ { print $2; exit }' typst.toml
}

# What ships is decided twice: by the payload this script copies, and by
# `exclude` in typst.toml, which is what Typst Universe reads. A file named by
# neither ships without anyone having decided that it should, which is how a
# repository's own housekeeping ends up published.
verify_coverage() {
  local excluded payload=" typst.toml lib.typ LICENSE README.md src "
  excluded=" $(awk '/^exclude[[:space:]]*=/, /\]/' typst.toml |
    grep -oE '"[^"]+"' | tr -d '"' | tr '\n' ' ')"

  local uncovered=()
  local entry
  while IFS= read -r entry; do
    [[ "${payload}" == *" ${entry} "* ]] && continue
    [[ "${excluded}" == *" ${entry} "* ]] && continue
    uncovered+=("${entry}")
  done < <(git ls-files | sed -E 's|/.*||' | sort -u)

  if [[ ${#uncovered[@]} -gt 0 ]]; then
    printf 'package: tracked and neither staged nor excluded\n' >&2
    printf '  %s\n' "${uncovered[@]}" >&2
    printf '  add each to the payload above, or to exclude in typst.toml\n' >&2
    exit 1
  fi
}

stage() {
  local dest="${1:?stage: destination dir required}"
  local version="${2:-}"

  verify_coverage

  mkdir -p "${dest}"
  cp typst.toml lib.typ LICENSE "${dest}/"
  tools/stage-readme.sh README.md "${dest}"
  # Tracked files only, at their working-tree state. A plain `cp -r` would
  # sweep ignored strays into the payload, so what shipped would depend on
  # what happened to be lying in the tree.
  git ls-files -z -- src | tar -cf - --null -T - | tar -xf - -C "${dest}"

  if [[ -n "${version}" ]]; then
    local commit date_utc
    commit="$(git describe --tags --always)"
    date_utc="$(date -u +%Y-%m-%d)"
    sed -E -i.bak \
      -e "s/^(version[[:space:]]*=[[:space:]]*\")[^\"]+/\1${version}/" \
      "${dest}/typst.toml"
    rm -f "${dest}/typst.toml.bak"
    printf '# dev build: %s (%s)\n%s' \
      "${commit}" "${date_utc}" "$(cat "${dest}/typst.toml")" \
      >"${dest}/typst.toml"
  fi
}

archive() {
  local out_dir="${1:?archive: output dir required}"
  local basename="${2:-}"
  local override="${3:-}"

  # Only an explicit caller version reaches stage, where it triggers the
  # development-build rewrite; the resolved default merely names the archive.
  local version="${override}"
  [[ -n "${version}" ]] || version="$(read_version)"
  [[ -n "${version}" ]] || {
    echo "archive: version not found in typst.toml" >&2
    exit 1
  }
  [[ -n "${basename}" ]] || basename="keisen-${version}"

  local tmp leaf
  tmp="$(mktemp -d)"
  trap 'rm -rf "${tmp}"' RETURN
  leaf="keisen-${version}"
  stage "${tmp}/${leaf}" "${override}"

  mkdir -p "${out_dir}"
  out_dir="$(cd "${out_dir}" && pwd)"
  rm -f "${out_dir}/${basename}.tar.gz" "${out_dir}/${basename}.zip"
  tar -czf "${out_dir}/${basename}.tar.gz" -C "${tmp}" "${leaf}"
  (cd "${tmp}" && zip -qr "${out_dir}/${basename}.zip" "${leaf}")
}

cmd="${1:-}"
case "${cmd}" in
stage)
  shift
  stage "$@"
  ;;
archive)
  shift
  archive "$@"
  ;;
*)
  echo "usage: package.sh {stage <dest-dir> [version] | archive <out-dir> [basename] [version]}" >&2
  exit 1
  ;;
esac
