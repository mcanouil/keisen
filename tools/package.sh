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

# What ships, named once. `verify_coverage` reads this list and `stage` copies
# it, so a name declared here and shipped by nobody is not expressible. The two
# were separate lists, a string the check trusted and a `cp` beside it, and only
# the check read the string: a file could be declared and never shipped.
PAYLOAD=(typst.toml lib.typ LICENSE README.md src)

# The one file that is rewritten on its way into the payload, named here rather
# than tested for as a literal beside the copy: renamed in the list alone, it
# would have fallen through to a plain `cp` and shipped the repository's own
# README, badges and contributing sections and all.
README_NAME="README.md"

# The tracked files under a payload directory, null-separated for tar.
#
# The list is read before it is used, because a directory holding no tracked
# file makes an empty archive that bsdtar extracts to nothing: the entry would
# be declared, copied, and absent from the package, which is the shape this pass
# set out to remove.
tracked_under() {
  local entry="$1"
  local tracked=() path
  while IFS= read -r -d '' path; do tracked+=("${path}"); done < <(git ls-files -z -- "${entry}")
  if [[ ${#tracked[@]} -eq 0 ]]; then
    printf 'package: the payload names %s, which holds no tracked file\n' "${entry}" >&2
    return 1
  fi
  printf '%s\0' "${tracked[@]}"
}

# What a payload entry is, so `stage` copies it the one right way and a name
# that is none of the three is refused rather than skipped.
payload_kind() {
  local entry="$1"
  if [[ "${entry}" == "${README_NAME}" ]]; then
    printf 'readme\n'
  elif [[ -d "${entry}" ]]; then
    printf 'directory\n'
  elif [[ -f "${entry}" ]]; then
    printf 'file\n'
  else
    return 1
  fi
}

# The staging directory an archive builds in, named at this level because the
# trap that removes it runs after the frame that made it has gone.
STAGE_TMP=""

remove_stage() {
  [[ -n "${STAGE_TMP}" ]] && rm -rf "${STAGE_TMP}"
  return 0
}

# What ships is decided twice: by the payload this script copies, and by
# `exclude` in typst.toml, which is what Typst Universe reads. A file named by
# neither ships without anyone having decided that it should, which is how a
# repository's own housekeeping ends up published.
verify_coverage() {
  # Guarded rather than expanded straight, because an empty array under `set -u`
  # is an error on the bash macOS ships, and an empty payload is what a caller
  # passes to watch this refuse.
  local excluded payload=" "
  [[ ${#PAYLOAD[@]} -gt 0 ]] && payload=" ${PAYLOAD[*]} "
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

  local entry kind
  for entry in "${PAYLOAD[@]}"; do
    if ! kind="$(payload_kind "${entry}")"; then
      printf 'package: the payload names %s, which is neither a file nor a directory\n' "${entry}" >&2
      exit 1
    fi

    case "${kind}" in
    readme)
      # The published README is the stripped one: the badges and the sections
      # about developing the package are repository furniture.
      tools/stage-readme.sh "${README_NAME}" "${dest}"
      ;;
    directory)
      # Tracked files only, at their working-tree state. A plain `cp -r` would
      # sweep ignored strays into the payload, so what shipped would depend on
      # what happened to be lying in the tree.
      tracked_under "${entry}" | tar -cf - --null -T - | tar -xf - -C "${dest}"
      ;;
    file)
      cp "${entry}" "${dest}/"
      ;;
    esac
  done

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

  local leaf
  STAGE_TMP="$(mktemp -d "${TMPDIR:-/tmp}/keisen-package.XXXXXX")"
  # On EXIT rather than RETURN: `stage` below exits through `verify_coverage`
  # when the payload and `exclude` disagree, and an `exit` unwinding the frame
  # runs no RETURN trap, so a failed archive left its staging directory behind.
  trap remove_stage EXIT
  leaf="keisen-${version}"
  stage "${STAGE_TMP}/${leaf}" "${override}"

  mkdir -p "${out_dir}"
  out_dir="$(cd "${out_dir}" && pwd)"
  rm -f "${out_dir}/${basename}.tar.gz" "${out_dir}/${basename}.zip"
  tar -czf "${out_dir}/${basename}.tar.gz" -C "${STAGE_TMP}" "${leaf}"
  (cd "${STAGE_TMP}" && zip -qr "${out_dir}/${basename}.zip" "${leaf}")
}

# Every branch of the two rules above, against the payload as it stands and
# against names that are not in it. `archive` is reached by no script here, so
# without this the staging cleanup would run nowhere at all.
if [[ "${1:-}" == "--self-test" ]]; then
  cases=0
  bad=0

  check() {
    local name="$1" held="$2"
    cases=$((cases + 1))
    [[ "${held}" == "yes" ]] && return 0
    bad=$((bad + 1))
    printf '  FAIL  self-test  %s\n' "${name}" >&2
  }

  kind_is() {
    local wanted="$1" entry="$2" name="$3"
    local got=""
    got="$(payload_kind "${entry}")" || got="refused"
    if [[ "${got}" == "${wanted}" ]]; then
      check "${name}" yes
    else
      check "${name}: wanted ${wanted}, got ${got}" no
    fi
  }

  # Every entry of the payload is one of the three shapes `stage` can copy.
  for entry in "${PAYLOAD[@]}"; do
    if payload_kind "${entry}" >/dev/null; then
      check "the payload names ${entry}" yes
    else
      check "the payload names ${entry}, which is neither a file nor a directory" no
    fi
  done

  kind_is readme "${README_NAME}" 'the README is rewritten rather than copied'
  kind_is directory src 'a directory ships its tracked files'
  kind_is file typst.toml 'a file is copied'
  kind_is refused no-such-file.md 'a name that is not there is refused'

  # A directory ships the files it tracks, and one that tracks none is refused
  # rather than copied as an empty archive.
  if tracked_under src >/dev/null 2>&1; then
    check 'a tracked directory names its files' yes
  else
    check 'a tracked directory names its files' no
  fi

  if tracked_under .git >/dev/null 2>&1; then
    check 'a directory holding no tracked file is refused' no
  else
    check 'a directory holding no tracked file is refused' yes
  fi

  # The staging directory goes, however the archive ended.
  probe="$(mktemp -d)"
  STAGE_TMP="${probe}"
  remove_stage
  if [[ -d "${probe}" ]]; then
    check 'the staging directory is removed' no
    rm -rf "${probe}"
  else
    check 'the staging directory is removed' yes
  fi

  STAGE_TMP=""
  remove_stage
  check 'no staging directory is nothing to remove' yes

  # And an archive whose stage refuses leaves none behind. The payload is
  # emptied, so `verify_coverage` reports every tracked name and exits.
  sandbox="$(mktemp -d)"
  (
    TMPDIR="${sandbox}"
    PAYLOAD=()
    archive "${sandbox}/out"
  ) >/dev/null 2>&1 || true
  left="$(find "${sandbox}" -maxdepth 1 -type d -name 'keisen-package.*' | wc -l | tr -d ' ')"
  rm -rf "${sandbox}"
  if [[ "${left}" -eq 0 ]]; then
    check 'a refused archive leaves no staging directory' yes
  else
    check 'a refused archive leaves no staging directory' no
  fi

  if [[ ${bad} -gt 0 ]]; then
    printf 'package: %d/%d self-test case(s) failed\n' "${bad}" "${cases}" >&2
    exit 1
  fi

  printf 'package:  self-test %d/%d\n' "${cases}" "${cases}"
  exit 0
fi

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
  echo "usage: package.sh {stage <dest-dir> [version] | archive <out-dir> [basename] [version] | --self-test}" >&2
  exit 1
  ;;
esac
