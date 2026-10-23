#!/usr/bin/env bash
# File: Test runner (scaffold-only, never installed in a target project).
# Usage:
#   tests/run-all.sh                  run every suite under tests/scripts, tests/hooks and tests/lint, print a summary
#   tests/run-all.sh --suite NAME     run one suite (basename without .sh, e.g. pre-launch; or scripts/NAME, hooks/NAME, lint/NAME);
#                                     repeat it to run several suites, in --list order
#   tests/run-all.sh --only-file F    run only the suites F names, one per line (tests/scripts/NAME.sh or scripts/NAME);
#                                     an empty or missing F selects every suite
#   tests/run-all.sh --exclude-file G leave out the suites G names (same format); with --only-file, runs F minus G
#   tests/run-all.sh -j N             run N suites at once (default: the number of CPUs, else 4; -j 1 runs serially)
#   tests/run-all.sh --list           list suite names
#   tests/run-all.sh -v               print each suite's full output (default: only failures and xfail lines); when a suite
#                                     failed, the run ends with a "== failures" block of every FAIL line and its detail
# Output is printed suite by suite in --list order whatever -j is, so a parallel run reads like a serial one.
# Exit: 0 all suites passed; 1 any suite failed; 2 missing prerequisite, unknown suite or selector, or bad argument.
# Requires: bash 3.2+, git, jq, mikefarah yq v4, shellcheck (a missing shellcheck fails the run here;
#   a suite run directly skips its shellcheck assertion instead).

set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/common.sh
source "$HERE/lib/common.sh"

usage_error() { echo "run-all: $1" >&2; exit 2; }

default_jobs() {
  local cpus
  cpus=$(getconf _NPROCESSORS_ONLN 2>/dev/null)
  case "$cpus" in
    '' | *[!0-9]* | 0) echo 4 ;;
    *) echo "$cpus" ;;
  esac
}

# The --suite names, each followed by a newline, so a case pattern can test membership.
suite_names=$'\n'
only_file=""
exclude_file=""
jobs=$(default_jobs)
verbose=0
list=0
while [ $# -gt 0 ]; do
  case "$1" in
    --suite)
      [ $# -ge 2 ] && [ -n "$2" ] || usage_error "--suite needs a name"
      suite_names+="$2"$'\n'
      shift
      ;;
    --only-file)
      [ $# -ge 2 ] || usage_error "--only-file needs a path"
      only_file=$2
      shift
      ;;
    --exclude-file)
      [ $# -ge 2 ] || usage_error "--exclude-file needs a path"
      exclude_file=$2
      shift
      ;;
    -j)
      [ $# -ge 2 ] || usage_error "-j needs a number"
      case "$2" in
        '' | *[!0-9]*) usage_error "-j needs a positive whole number, got '$2'" ;;
      esac
      [ "$2" -ge 1 ] || usage_error "-j needs a positive whole number, got '$2'"
      jobs=$2
      shift
      ;;
    --list) list=1 ;;
    -v | --verbose) verbose=1 ;;
    -h | --help)
      sed -n '/^# Usage:/,/^# Exit:/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) usage_error "unknown argument: $1" ;;
  esac
  shift
done
if [ "$suite_names" != $'\n' ] && { [ -n "$only_file" ] || [ -n "$exclude_file" ]; }; then
  usage_error "--suite cannot be combined with --only-file or --exclude-file"
fi

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

all_labels=$'\n'
all_names=$'\n'
for f in "${suites[@]}"; do
  all_labels+="$(suite_label "$f")"$'\n'
  all_names+="$(suite_name "$f")"$'\n'
done

# A --suite name is a basename or a label; the first name that matches no suite ends the run with exit 2.
while IFS= read -r name; do
  [ -n "$name" ] || continue
  case "$all_labels$all_names" in
    *$'\n'"$name"$'\n'*) ;;
    *) usage_error "no suite named '$name' (try --list)" ;;
  esac
done <<<"$suite_names"

# selector_labels FILE : the suite label of each selector in FILE, one per line. A selector is a repo-relative
# path (tests/scripts/NAME.sh) or a label (scripts/NAME). Exits 2 naming the first selector that matches no suite.
selector_labels() {
  local file=$1 selector label
  [ -f "$file" ] || return 0
  while IFS= read -r selector || [ -n "$selector" ]; do
    selector=$(printf '%s' "$selector" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    [ -n "$selector" ] || continue
    label=${selector#./}
    label=${label#"$(basename "$HERE")"/}
    label=${label%.sh}
    case "$all_labels" in
      *$'\n'"$label"$'\n'*) printf '%s\n' "$label" ;;
      *) usage_error "no suite matches '$selector' in $file (try --list)" ;;
    esac
  done <"$file"
}

# Run in this shell, not a command substitution, so an unknown selector's exit 2 ends the run.
only_list=$'\n'
exclude_list=$'\n'
selector_tmp=$(mktemp "${TMPDIR:-/tmp}/scaffold-tests-selectors.XXXXXX")
if [ -n "$only_file" ]; then
  selector_labels "$only_file" >"$selector_tmp" || { rm -f "$selector_tmp"; exit 2; }
  [ -s "$selector_tmp" ] && only_list+=$(cat "$selector_tmp")$'\n'
fi
if [ -n "$exclude_file" ]; then
  selector_labels "$exclude_file" >"$selector_tmp" || { rm -f "$selector_tmp"; exit 2; }
  [ -s "$selector_tmp" ] && exclude_list+=$(cat "$selector_tmp")$'\n'
fi
rm -f "$selector_tmp"

is_selected() {
  local f=$1 label
  label=$(suite_label "$f")
  if [ "$suite_names" != $'\n' ]; then
    case "$suite_names" in
      *$'\n'"$(suite_name "$f")"$'\n'* | *$'\n'"$label"$'\n'*) return 0 ;;
      *) return 1 ;;
    esac
  fi
  if [ "$only_list" != $'\n' ]; then
    case "$only_list" in *$'\n'"$label"$'\n'*) ;; *) return 1 ;; esac
  fi
  case "$exclude_list" in *$'\n'"$label"$'\n'*) return 1 ;; esac
  return 0
}

selected=()
for f in "${suites[@]}"; do
  is_selected "$f" && selected+=("$f")
done

preflight
if ! have_shellcheck; then
  echo "preflight: shellcheck not found on PATH (brew install shellcheck)" >&2
  exit 2
fi

results=$(mktemp -d "${TMPDIR:-/tmp}/scaffold-tests.XXXXXX")
trap 'rm -rf "$results"' EXIT
total_pass=0
total_fail=0
total_skip=0
total_xfail=0
failed_suites=()
# The index of each failed suite, in step with failed_suites, so its log can be read again after the summary.
failed_indexes=()
rows=()

# start_suite INDEX FILE : run one suite in the background. Its log goes to INDEX.log; INDEX.done appears last,
# holding "rc seconds", and is written by rename so the reporter never reads it half written.
start_suite() {
  local index=$1 file=$2
  (
    start=$(date +%s)
    bash "$file" >"$results/$index.log" 2>&1
    rc=$?
    printf '%s %s\n' "$rc" "$(($(date +%s) - start))" >"$results/$index.tmp"
    mv "$results/$index.tmp" "$results/$index.done"
  ) &
}

finished_count() {
  local done_file count=0
  for done_file in "$results"/*.done; do
    [ -e "$done_file" ] && count=$((count + 1))
  done
  echo "$count"
}

# report_suite INDEX : print one finished suite's output and add its counts to the totals.
report_suite() {
  local index=$1 f label log rc secs res p fl sk xf status
  f=${selected[$index]}
  label=$(suite_label "$f")
  log=$results/$index.log
  read -r rc secs <"$results/$index.done"
  printf '== %s\n' "$label"
  if [ "$verbose" -eq 1 ]; then
    cat "$log"
  else
    grep -E '^(FAIL|xfail|skip) |^       ' "$log" || true
  fi
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
  if [ "$rc" -ne 0 ]; then
    failed_suites+=("$label")
    failed_indexes+=("$index")
  fi
  total_pass=$((total_pass + p))
  total_fail=$((total_fail + fl))
  total_skip=$((total_skip + sk))
  total_xfail=$((total_xfail + xf))
  status=PASS
  [ "$rc" -eq 0 ] || status=FAIL
  rows+=("$(printf '%-4s %-38s passed=%-4s failed=%-3s skipped=%-3s xfail=%-3s %ss' "$status" "$label" "$p" "$fl" "$sk" "$xf" "$secs")")
}

# print_failures LOG RC : print each FAIL line of a suite log with the indented detail lines under it. A log without a
# result footer is printed whole and indented, as the default output shows it. When that leaves nothing to show (the
# suite exited non-zero without a FAIL line), print its RESULT line, or its exit code when it has no RESULT line.
print_failures() {
  local log=$1 rc=$2 out
  if grep -q '^RESULT ' "$log"; then
    out=$(awk '/^FAIL / { in_fail = 1; print; next } /^       / { if (in_fail) print; next } { in_fail = 0 }' "$log")
  else
    out=$(sed 's/^/   /' "$log")
  fi
  if [ -n "$out" ]; then
    printf '%s\n' "$out"
  elif grep -q '^RESULT ' "$log"; then
    grep '^RESULT ' "$log" | tail -1 | sed 's/^/       /'
  else
    printf '       exited %s with no FAIL line\n' "$rc"
  fi
}

# Keep up to $jobs suites running and print each one as soon as it and every suite before it have finished.
# bash 3.2 has no `wait -n`, so finished suites are found by polling for their .done files.
suite_count=${#selected[@]}
# Suites start largest file first, so the long ones are not left to start last and set the run's length;
# file size stands in for run time. Output order is unaffected: suites are still reported by glob index.
start_order=()
if [ "$suite_count" -gt 0 ]; then
  while IFS= read -r i; do start_order+=("$i"); done < <(
    for i in "${!selected[@]}"; do printf '%s %s\n' "$(($(wc -c <"${selected[$i]}")))" "$i"; done | sort -k1,1nr -k2,2n | cut -d' ' -f2
  )
fi
launched=0
reported=0
while [ "$reported" -lt "$suite_count" ]; do
  while [ "$launched" -lt "$suite_count" ] && [ $((launched - $(finished_count))) -lt "$jobs" ]; do
    start_suite "${start_order[$launched]}" "${selected[${start_order[$launched]}]}"
    launched=$((launched + 1))
  done
  if [ -e "$results/$reported.done" ]; then
    report_suite "$reported"
    reported=$((reported + 1))
  else
    sleep 0.1
  fi
done
wait

printf '\n== summary\n'
# The guard keeps `set -u` from failing on an empty array in bash 3.2, which happens when no suite is selected.
for r in ${rows[@]+"${rows[@]}"}; do printf '%s\n' "$r"; done
printf 'TOTAL passed=%s failed=%s skipped=%s xfail=%s (%s suites)\n' "$total_pass" "$total_fail" "$total_skip" "$total_xfail" "$suite_count"
if [ "${#failed_suites[@]}" -gt 0 ]; then
  printf 'FAILED suites: %s\n' "${failed_suites[*]}"
  # A verbose log is long, so it ends with every failure gathered in one place.
  if [ "$verbose" -eq 1 ]; then
    printf '\n== failures\n'
    for i in "${!failed_suites[@]}"; do
      printf -- '-- %s\n' "${failed_suites[$i]}"
      read -r rc _ <"$results/${failed_indexes[$i]}.done"
      print_failures "$results/${failed_indexes[$i]}.log" "$rc"
    done
  fi
  exit 1
fi
exit 0
