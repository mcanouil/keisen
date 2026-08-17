#!/usr/bin/env bash
# Times the 2000-row table and records the result.
#
# The design indexes styles and formats once per part into a dictionary keyed
# by cell address, then reads that dictionary once per cell, rather than
# re-testing every directive against every cell. The difference between the two
# is invisible on a four-row table, so the argument for the index rested on a
# table nobody had ever compiled. This compiles it.
#
# It records rather than judges. A threshold on a wall-clock number measures the
# machine, and a threshold on the ratio between two row counts was measured here
# before it was written: the same unmodified package reported anything from 8.0
# to 15.2 times the cost for ten times the rows, depending only on what else the
# machine was doing, while replacing the index with a scan of every entry per
# cell reported 32.7. The noise is as wide as the signal, so a ceiling in
# between would fail on a busy runner as readily as on a regression, and a
# ceiling outside it would catch nothing. The numbers go in the record and a
# human reads them.
#
# Two things here are assertions, because neither can flake:
#
# - The table must compile. A 2000-row table reaches limits a small one never
#   does, and until this existed nothing compiled one.
# - The compile must finish inside a deliberately enormous budget. That is a
#   guard against a table that no longer terminates, not a performance gate.
#
# tools/dry-release.sh runs this, which is the cadence the design asks for:
# recorded per release.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

OUT_DIR="${OUT_DIR:-/tmp/keisen-check}"
mkdir -p "${OUT_DIR}"

# The small size carries the fixed cost of starting the compiler and resolving
# fonts, and is the denominator of the recorded growth, which is why that growth
# is a reading rather than a rule.
SMALL_ROWS="${SMALL_ROWS:-200}"
LARGE_ROWS="${LARGE_ROWS:-2000}"
REPETITIONS="${REPETITIONS:-2}"
# Seconds. Roughly twenty-five times what the large compile costs on the author's
# machine, so only a table that has stopped terminating can reach it.
TIME_CEILING="${TIME_CEILING:-300}"

RECORD="${BENCHMARK_RECORD:-${OUT_DIR}/benchmark.tsv}"

# The clock. `date +%s%N` prints a literal N on a BSD userland and EPOCHREALTIME
# needs bash 5, so the one that is here is checked rather than assumed. The
# separator follows the locale, which is why both are removed.
if [[ -z "${EPOCHREALTIME:-}" ]]; then
  printf 'benchmark: this needs bash 5 or later for EPOCHREALTIME\n' >&2
  exit 1
fi

microseconds() {
  local now="${EPOCHREALTIME}"
  printf '%s' "${now/[.,]/}"
}

# The best of several runs, in milliseconds. The minimum rather than the mean:
# a compile cannot run faster than the work it does, so every deviation upwards
# is another process on the machine rather than this one.
best_milliseconds() {
  local rows="$1"
  local best=""

  for _ in $(seq "${REPETITIONS}"); do
    local started ended elapsed
    started="$(microseconds)"
    if ! typst compile tools/benchmark.typ --root "${REPO_ROOT}" \
      --input "rows=${rows}" "${OUT_DIR}/benchmark-${rows}.pdf" \
      2>"${OUT_DIR}/benchmark-${rows}.err"; then
      printf '  FAIL  benchmark  the %s-row table did not compile\n' "${rows}" >&2
      sed -n '1,5p' "${OUT_DIR}/benchmark-${rows}.err" >&2
      return 1
    fi
    ended="$(microseconds)"
    elapsed=$(((ended - started) / 1000))
    if [[ -z "${best}" || ${elapsed} -lt ${best} ]]; then
      best="${elapsed}"
    fi
  done

  printf '%s' "${best}"
}

small="$(best_milliseconds "${SMALL_ROWS}")"
large="$(best_milliseconds "${LARGE_ROWS}")"

rows_ratio=$((LARGE_ROWS / SMALL_ROWS))
# Tenths, so a growth reads as 13.6 rather than 13. A compile too fast to time
# would divide by zero and report any curve as flat, so it reads as unknown.
if [[ "${small}" -gt 0 ]]; then
  growth="$((large * 10 / small))"
  growth_text="$((growth / 10)).$((growth % 10))x"
else
  growth_text="unknown"
fi

{
  printf 'rows\tmilliseconds\n'
  printf '%s\t%s\n' "${SMALL_ROWS}" "${small}"
  printf '%s\t%s\n' "${LARGE_ROWS}" "${large}"
} >"${RECORD}"

printf 'benchmark: %s rows in %s ms, %s rows in %s ms\n' \
  "${SMALL_ROWS}" "${small}" "${LARGE_ROWS}" "${large}"
printf '           %sx the rows cost %s the time, recorded, not enforced\n' \
  "${rows_ratio}" "${growth_text}"
printf '           written to %s\n' "${RECORD}"

if [[ $((large / 1000)) -gt ${TIME_CEILING} ]]; then
  printf '  FAIL  benchmark  the %s-row table took %s s, and the budget is %s s\n' \
    "${LARGE_ROWS}" "$((large / 1000))" "${TIME_CEILING}" >&2
  printf '        this is not a performance gate: something no longer terminates\n' >&2
  exit 1
fi
