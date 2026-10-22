#!/usr/bin/env bash
# Suite: tests/run-all.sh suite selection and parallel runs.
# Covers: --only-file and --exclude-file (repo-relative and label selectors, F minus G, empty or missing files),
#   unknown selectors and --suite conflicts exiting 2, -j validation, concurrent runs by default and serial with -j 1,
#   output in glob order identical to a serial run apart from timings, -v printing full logs, exit codes 0 / 1.
# The runner is copied into a fixture tree with stub suites, so this suite never runs the real harness.
# shellcheck disable=SC2016  # check expressions are single-quoted so check evaluates them
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

new_workdir
FIXTURE_TESTS=$WORK/repo/tests
mkdir -p "$FIXTURE_TESTS/lib" "$FIXTURE_TESTS/scripts" "$FIXTURE_TESTS/hooks" "$FIXTURE_TESTS/lint"
cp "$TESTS_DIR/run-all.sh" "$FIXTURE_TESTS/run-all.sh"
cp "$TESTS_DIR/lib/common.sh" "$FIXTURE_TESTS/lib/common.sh"
RUNNER=$FIXTURE_TESTS/run-all.sh

# stub_suite PATH SLEEP_SECONDS PASSED FAILED : a suite that sleeps, then prints its checks and the result footer.
stub_suite() {
  local path=$1 pause=$2 passed=$3 failed=$4 name
  name=$(basename "$path" .sh)
  {
    printf '#!/usr/bin/env bash\n'
    printf 'sleep %s\n' "$pause"
    printf 'echo "ok   %s check"\n' "$name"
    [ "$failed" -eq 0 ] || printf 'echo "FAIL %s check"; echo "       %s detail"\n' "$name" "$name"
    printf 'echo "xfail %s known (reason)"\n' "$name"
    printf 'printf "\\nRESULT passed=%s failed=%s skipped=0 xfail=1\\n"\n' "$passed" "$failed"
    printf 'exit %s\n' "$failed"
  } >"$path"
}

stub_suite "$FIXTURE_TESTS/scripts/alpha.sh" 2 3 0
stub_suite "$FIXTURE_TESTS/scripts/beta.sh" 2 2 0
stub_suite "$FIXTURE_TESTS/hooks/gamma.sh" 0 1 1
stub_suite "$FIXTURE_TESTS/lint/delta.sh" 0 4 0

# run_all ARGS... : run the fixture runner; sets OUT (stdout and stderr) and RC.
run_all() {
  OUT=$(bash "$RUNNER" "$@" 2>&1)
  RC=$?
}

# summary_labels : the suite labels of the summary rows in OUT, space-separated, in printed order.
summary_labels() {
  printf '%s\n' "$OUT" | sed -nE 's/^(PASS|FAIL) +([a-z]+\/[a-z]+) .*/\2/p' | tr '\n' ' ' | sed 's/ $//'
}

# without_timings : OUT with the per-suite seconds column removed, so two runs can be compared.
without_timings() { printf '%s\n' "$OUT" | sed 's/ [0-9][0-9]*s$//'; }

selector_file() {
  local file=$WORK/$1
  shift
  printf '%s\n' "$@" >"$file"
  printf '%s' "$file"
}

# --only-file
only=$(selector_file only-two tests/scripts/beta.sh tests/lint/delta.sh)
run_all --only-file "$only"
eq "--only-file runs exactly the suites it names" "$(summary_labels)" "scripts/beta lint/delta"
eq "--only-file run of passing suites exits 0" "$RC" 0

only=$(selector_file only-label hooks/gamma)
run_all --only-file "$only"
eq "--only-file accepts a suite label" "$(summary_labels)" "hooks/gamma"

# --exclude-file
exclude=$(selector_file exclude-two tests/scripts/alpha.sh tests/scripts/beta.sh)
run_all --exclude-file "$exclude"
eq "--exclude-file runs every suite except those it names" "$(summary_labels)" "hooks/gamma lint/delta"
eq "a failing suite makes the run exit 1" "$RC" 1

empty=$(selector_file only-empty "")
run_all --only-file "$empty" --exclude-file "$exclude"
eq "an empty --only-file with --exclude-file runs every suite not excluded" "$(summary_labels)" "hooks/gamma lint/delta"

run_all --only-file "$WORK/no-such-file" --exclude-file "$exclude"
eq "a missing --only-file with --exclude-file runs every suite not excluded" "$(summary_labels)" "hooks/gamma lint/delta"

only=$(selector_file only-three tests/scripts/alpha.sh tests/hooks/gamma.sh tests/lint/delta.sh)
exclude=$(selector_file exclude-gamma tests/hooks/gamma.sh)
run_all --only-file "$only" --exclude-file "$exclude"
eq "--only-file and --exclude-file together run F minus G" "$(summary_labels)" "scripts/alpha lint/delta"

only=$(selector_file only-all-excluded tests/hooks/gamma.sh)
run_all --only-file "$only" --exclude-file "$exclude"
eq "a selection left empty by exclusion runs nothing and exits 0" "$RC" 0

# Unknown selectors and conflicting flags
only=$(selector_file only-unknown tests/scripts/beta.sh tests/scripts/omega.sh)
run_all --only-file "$only"
eq "an --only-file selector naming no suite exits 2" "$RC" 2
check "the unknown --only-file selector is named in the message" '[[ "$OUT" == *tests/scripts/omega.sh* ]]' "$OUT"

exclude=$(selector_file exclude-unknown tests/lint/omega.sh)
run_all --exclude-file "$exclude"
eq "an --exclude-file selector naming no suite exits 2" "$RC" 2
check "the unknown --exclude-file selector is named in the message" '[[ "$OUT" == *tests/lint/omega.sh* ]]' "$OUT"

only=$(selector_file only-beta tests/scripts/beta.sh)
run_all --suite beta --only-file "$only"
eq "--suite with --only-file exits 2" "$RC" 2
run_all --suite beta --exclude-file "$only"
eq "--suite with --exclude-file exits 2" "$RC" 2
run_all --only-file
eq "--only-file without a path exits 2" "$RC" 2

# -j validation
for bad in 0 -1 two 1.5 ""; do
  run_all -j "$bad" --suite delta
  eq "-j '$bad' exits 2" "$RC" 2
done

# Parallel and serial runs: alpha and beta each sleep 2 seconds.
only=$(selector_file only-sleepers tests/scripts/alpha.sh tests/scripts/beta.sh tests/hooks/gamma.sh)
start=$(date +%s)
run_all --only-file "$only"
parallel_secs=$(($(date +%s) - start))
parallel_out=$(without_timings)
check "with no -j, suites run concurrently" '[ "$parallel_secs" -lt 4 ]' "took ${parallel_secs}s for 4s of sleeping suites"

start=$(date +%s)
run_all -j 1 --only-file "$only"
serial_secs=$(($(date +%s) - start))
serial_out=$(without_timings)
check "-j 1 runs one suite at a time" '[ "$serial_secs" -ge 4 ]' "took ${serial_secs}s for 4s of sleeping suites"

eq "a parallel run prints the same report as a serial run, apart from timings" "$parallel_out" "$serial_out"
expected_report='== scripts/alpha
xfail alpha known (reason)
== scripts/beta
xfail beta known (reason)
== hooks/gamma
FAIL gamma check
       gamma detail
xfail gamma known (reason)

== summary'
eq "suite output appears in glob order with failure and xfail detail" "${parallel_out:0:${#expected_report}}" "$expected_report"
check "the summary rows and totals follow in glob order" \
  '[[ "$parallel_out" == *"TOTAL passed=6 failed=1 skipped=0 xfail=3 (3 suites)
FAILED suites: hooks/gamma" ]]' "$parallel_out"

# -v prints each suite's full log in glob order.
only=$(selector_file only-verbose tests/hooks/gamma.sh tests/lint/delta.sh)
run_all -v --only-file "$only"
check "-v prints each suite's full log in glob order" \
  '[[ "$OUT" == "== hooks/gamma
ok   gamma check
FAIL gamma check"*"== lint/delta
ok   delta check
xfail delta known (reason)"* ]]' "$OUT"

# A suite that dies before its footer still fails and its log is shown.
printf '#!/usr/bin/env bash\necho "crashed early"\nexit 3\n' >"$FIXTURE_TESTS/lint/broken.sh"
only=$(selector_file only-broken tests/lint/broken.sh)
run_all --only-file "$only"
eq "a suite without a result footer makes the run exit 1" "$RC" 1
check "the log of a suite without a footer is printed indented" '[[ "$OUT" == *"   crashed early"* ]]' "$OUT"

# Help
run_all --help
check "the usage header documents --only-file, --exclude-file and -j" \
  '[[ "$OUT" == *--only-file* && "$OUT" == *--exclude-file* && "$OUT" == *"-j N"* ]]' "$OUT"

shellcheck_files "run-all.sh and this suite are shellcheck clean" "$TESTS_DIR/run-all.sh" "${BASH_SOURCE[0]}"

finish
