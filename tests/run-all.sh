#!/usr/bin/env bash
# File: Test runner (scaffold-only, never installed in a target project).
# Usage:
#   tests/run-all.sh                  run every suite under tests/scripts, tests/hooks and tests/lint, print a summary
#   tests/run-all.sh --suite NAME     run one suite (basename without .sh, e.g. pre-launch; or scripts/NAME, hooks/NAME, lint/NAME)
#   tests/run-all.sh --list           list suite names
#   tests/run-all.sh -v               stream each suite's full output (default: only failures and xfail lines)
# Exit: 0 all suites passed; 1 any suite failed; 2 missing prerequisite or unknown suite.
# Requires: bash 3.2+, git, jq, mikefarah yq v4, shellcheck (a missing shellcheck fails the run here;
#   a suite run directly skips its shellcheck assertion instead).

set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/common.sh
source "$HERE/lib/common.sh"

only=""
verbose=0
list=0
while [ $# -gt 0 ]; do
  case "$1" in
    --suite)
      [ $# -ge 2 ] || { echo "run-all: --suite needs a name" >&2; exit 2; }
      only=$2
      shift
      ;;
    --list) list=1 ;;
    -v | --verbose) verbose=1 ;;
    -h | --help)
      sed -n '/^# Usage:/,/^# Exit:/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "run-all: unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

suites=()
for f in "$HERE"/scripts/*.sh "$HERE"/hooks/*.sh "$HERE"/lint/*.sh; do
  [ -f "$f" ] && suites+=("$f")
done

suite_name() { basename "$1" .sh; }
suite_label() { printf '%s/%s' "$(basename "$(dirname "$1")")" "$(suite_name "$1")"; }

if [ "$list" -eq 1 ]; then
  for f in "${suites[@]}"; do printf "%s\n" "$(suite_label "$f")"; done
  exit 0
fi

selected=()
for f in "${suites[@]}"; do
  if [ -z "$only" ] || [ "$only" = "$(suite_name "$f")" ] || [ "$only" = "$(suite_label "$f")" ]; then
    selected+=("$f")
  fi
done
if [ "${#selected[@]}" -eq 0 ]; then
  echo "run-all: no suite named '$only' (try --list)" >&2
  exit 2
fi

preflight
if ! have_shellcheck; then
  echo "preflight: shellcheck not found on PATH (brew install shellcheck)" >&2
  exit 2
fi

log=$(mktemp "${TMPDIR:-/tmp}/scaffold-tests.XXXXXX")
trap 'rm -f "$log"' EXIT
total_pass=0
total_fail=0
total_skip=0
total_xfail=0
failed_suites=()
rows=()

for f in "${selected[@]}"; do
  label=$(suite_label "$f")
  printf '== %s\n' "$label"
  start=$(date +%s)
  if [ "$verbose" -eq 1 ]; then
    bash "$f" 2>&1 | tee "$log"
    rc=${PIPESTATUS[0]}
  else
    bash "$f" >"$log" 2>&1
    rc=$?
    grep -E '^(FAIL|xfail|skip) |^       ' "$log" || true
  fi
  secs=$(($(date +%s) - start))
  res=$(grep '^RESULT ' "$log" | tail -1)
  p=$(sed -n 's/.*passed=\([0-9]*\).*/\1/p' <<<"$res")
  fl=$(sed -n 's/.*failed=\([0-9]*\).*/\1/p' <<<"$res")
  sk=$(sed -n 's/.*skipped=\([0-9]*\).*/\1/p' <<<"$res")
  xf=$(sed -n 's/.*xfail=\([0-9]*\).*/\1/p' <<<"$res")
  if [ -z "$res" ]; then
    # Suite died before its footer (preflight failure, syntax error, crash).
    [ "$verbose" -eq 1 ] || sed 's/^/   /' "$log"
    p=0
    fl=1
    sk=0
    xf=0
    rc=1
  fi
  [ "$rc" -eq 0 ] || failed_suites+=("$label")
  total_pass=$((total_pass + p))
  total_fail=$((total_fail + fl))
  total_skip=$((total_skip + sk))
  total_xfail=$((total_xfail + xf))
  status=PASS
  [ "$rc" -eq 0 ] || status=FAIL
  rows+=("$(printf '%-4s %-38s passed=%-4s failed=%-3s skipped=%-3s xfail=%-3s %ss' "$status" "$label" "$p" "$fl" "$sk" "$xf" "$secs")")
done

printf '\n== summary\n'
for r in "${rows[@]}"; do printf '%s\n' "$r"; done
printf 'TOTAL passed=%s failed=%s skipped=%s xfail=%s (%s suites)\n' "$total_pass" "$total_fail" "$total_skip" "$total_xfail" "${#selected[@]}"
if [ "${#failed_suites[@]}" -gt 0 ]; then
  printf 'FAILED suites: %s\n' "${failed_suites[*]}"
  exit 1
fi
exit 0
