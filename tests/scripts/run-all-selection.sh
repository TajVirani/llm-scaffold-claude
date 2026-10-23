#!/usr/bin/env bash
# Suite: tests/run-all.sh suite selection and parallel runs.
# Covers: --only-file and --exclude-file (repo-relative and label selectors, F minus G, empty or missing files),
#   unknown selectors and --suite conflicts exiting 2, repeated --suite (only the named suites, in glob order; one
#   unknown name exits 2), -j validation, concurrent runs by default and serial with -j 1 (judged by whether the
#   suites' recorded run times overlap, never by elapsed time), output in glob order identical to a serial run apart
#   from timings, largest-file-first start order with glob-order output, -v printing full logs and ending with a
#   failures block only when a suite failed (a failed suite with no FAIL line shows its RESULT line), exit codes 0 / 1.
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
MARKERS=$WORK/markers
mkdir -p "$MARKERS"

# stub_suite PATH SLEEP_SECONDS PASSED FAILED : a suite that sleeps, then prints its checks and the result footer.
# It writes its start and end times in epoch seconds to MARKERS/<name>.start and .end, so a test can tell whether
# two suites ran at the same time without timing the whole run.
stub_suite() {
  local path=$1 pause=$2 passed=$3 failed=$4 name
  name=$(basename "$path" .sh)
  {
    printf '#!/usr/bin/env bash\n'
    printf 'date +%%s >"%s/%s.start"\n' "$MARKERS" "$name"
    printf 'sleep %s\n' "$pause"
    printf 'date +%%s >"%s/%s.end"\n' "$MARKERS" "$name"
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

# Repeated --suite: the names are given out of glob order, by label and by basename.
run_all --suite lint/delta --suite alpha
eq "two --suite flags run both suites and only those, in glob order" "$(summary_labels)" "scripts/alpha lint/delta"
eq "a repeated --suite run of passing suites exits 0" "$RC" 0
run_all --suite alpha --suite omega --suite delta
eq "one unknown --suite name among several exits 2" "$RC" 2
check "the unknown --suite name is named in the message" '[[ "$OUT" == *"no suite named"*omega* ]]' "$OUT"
run_all --suite alpha --suite delta --only-file "$only"
eq "--suite twice with --only-file exits 2" "$RC" 2

# -j validation
for bad in 0 -1 two 1.5 ""; do
  run_all -j "$bad" --suite delta
  eq "-j '$bad' exits 2" "$RC" 2
done

# alpha_beta_overlap : print "overlap" when the recorded run times of alpha and beta overlap, else "apart", followed
# by the intervals so a failure shows them. Whole seconds are enough because each suite sleeps 2 seconds.
alpha_beta_overlap() {
  local a_start a_end b_start b_end verdict=apart
  a_start=$(cat "$MARKERS/alpha.start") a_end=$(cat "$MARKERS/alpha.end")
  b_start=$(cat "$MARKERS/beta.start") b_end=$(cat "$MARKERS/beta.end")
  if [ "$a_start" -lt "$b_end" ] && [ "$b_start" -lt "$a_end" ]; then verdict=overlap; fi
  printf '%s (alpha %s-%s, beta %s-%s)' "$verdict" "$a_start" "$a_end" "$b_start" "$b_end"
}

# Parallel and serial runs: alpha and beta each sleep 2 seconds. Concurrency is judged by whether their recorded
# run times overlap, not by how long the whole run took, so a loaded machine cannot fail these checks.
only=$(selector_file only-sleepers tests/scripts/alpha.sh tests/scripts/beta.sh tests/hooks/gamma.sh)
rm -f "$MARKERS"/*
run_all --only-file "$only"
parallel_out=$(without_timings)
intervals=$(alpha_beta_overlap)
check "with no -j, suites run concurrently" '[[ $intervals == overlap* ]]' "$intervals"

rm -f "$MARKERS"/*
run_all -j 1 --only-file "$only"
serial_out=$(without_timings)
intervals=$(alpha_beta_overlap)
check "-j 1 runs one suite at a time" '[[ $intervals == apart* ]]' "$intervals"

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
check "the default output has no failures block" '[[ "$parallel_out" != *"== failures"* ]]' "$parallel_out"

# -v prints each suite's full log in glob order.
only=$(selector_file only-verbose tests/hooks/gamma.sh tests/lint/delta.sh)
run_all -v --only-file "$only"
check "-v prints each suite's full log in glob order" \
  '[[ "$OUT" == "== hooks/gamma
ok   gamma check
FAIL gamma check"*"== lint/delta
ok   delta check
xfail delta known (reason)"* ]]' "$OUT"

# -v with a failed suite ends with a failures block: each failed suite's FAIL lines and their detail.
check "-v ends with a failures block holding the failed suite's FAIL line and detail" \
  '[[ "$OUT" == *"FAILED suites: hooks/gamma

== failures
-- hooks/gamma
FAIL gamma check
       gamma detail" ]]' "$OUT"
check "the failures block leaves out ok and xfail lines" \
  '[[ "${OUT##*== failures}" != *"ok   gamma"* && "${OUT##*== failures}" != *xfail* ]]' "$OUT"
eq "a failed -v run still exits 1" "$RC" 1

run_all -v --suite delta
check "-v with no failed suite prints no failures block" '[[ "$OUT" != *"== failures"* ]]' "$OUT"
eq "a passing -v run exits 0" "$RC" 0

# A suite that dies before its footer still fails and its log is shown.
printf '#!/usr/bin/env bash\necho "crashed early"\nexit 3\n' >"$FIXTURE_TESTS/lint/broken.sh"
only=$(selector_file only-broken tests/lint/broken.sh)
run_all --only-file "$only"
eq "a suite without a result footer makes the run exit 1" "$RC" 1
check "the log of a suite without a footer is printed indented" '[[ "$OUT" == *"   crashed early"* ]]' "$OUT"
run_all -v --only-file "$only"
check "-v lists a suite without a footer in the failures block with its log indented" \
  '[[ "$OUT" == *"== failures
-- lint/broken
   crashed early" ]]' "$OUT"

# A suite that prints its footer and exits non-zero without a FAIL line shows its RESULT line in the failures block.
printf '#!/usr/bin/env bash\necho "ok   quiet check"\nprintf "\\nRESULT passed=1 failed=0 skipped=0 xfail=0\\n"\nexit 1\n' \
  >"$FIXTURE_TESTS/lint/quiet.sh"
only=$(selector_file only-quiet tests/lint/quiet.sh)
run_all -v --only-file "$only"
check "-v shows the RESULT line of a failed suite that has no FAIL line" \
  '[[ "$OUT" == *"== failures
-- lint/quiet
       RESULT passed=1 failed=0 skipped=0 xfail=0" ]]' "$OUT"

# Start order: the larger suite starts first, but output stays in glob order. late.sh is padded so it is the
# larger file although its name sorts last; -j 1 makes the start order observable through a shared log.
starts=$WORK/start-order
for name in early late; do
  {
    printf '#!/usr/bin/env bash\n'
    printf 'echo %s >>"%s"\n' "$name" "$starts"
    printf 'printf "\\nRESULT passed=1 failed=0 skipped=0 xfail=0\\n"\n'
  } >"$FIXTURE_TESTS/lint/$name.sh"
done
for _ in 1 2 3 4 5 6 7 8; do printf '# padding so this stub is the larger file\n' >>"$FIXTURE_TESTS/lint/late.sh"; done
run_all -j 1 --suite lint/early --suite lint/late
eq "suites start largest file first" "$(tr '\n' ' ' <"$starts")" "late early "
eq "output stays in glob order when the start order differs" "$(summary_labels)" "lint/early lint/late"

# Help
run_all --help
check "the usage header documents --only-file, --exclude-file and -j" \
  '[[ "$OUT" == *--only-file* && "$OUT" == *--exclude-file* && "$OUT" == *"-j N"* ]]' "$OUT"

shellcheck_files "run-all.sh and this suite are shellcheck clean" "$TESTS_DIR/run-all.sh" "${BASH_SOURCE[0]}"

finish
