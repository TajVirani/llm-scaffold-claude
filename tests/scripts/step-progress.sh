#!/usr/bin/env bash
# Suite: step-progress.sh (feature-workflow/scripts), the phase progress line.
# Covers: full vs light totals and phase numbering, run-order positions (0.3.22 before 0.3.8, 3.16 before 3.9), ids that
#   compare equal as numbers (3.1 / 3.10, 00.2 / 00.20), steps off the chosen path, cross-cutting 00.x with and without --at,
#   intake (no line), side artifacts, unknown ids, --spec-dir defaults from spec.md light_path and .step, usage errors;
#   JRN-007: the large form for the first and last large-track rows, the conversion node and a phase 0 row still in the
#   "Phase 1 of 6" form; large-track numbering (6.10 vs 6.1) and a 6.x id refused on --path full, light or --spec-dir.
# Env: TEST_BASH=<bash binary> runs the script under another bash (default: bash).
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/initiative.sh
source "$TESTS_DIR/fixtures/initiative.sh"
preflight

TEST_BASH=${TEST_BASH:-bash}
SP="$FW_SKILL/scripts/step-progress.sh"
sp() { "$TEST_BASH" "$SP" "$@" 2>/dev/null; }
new_workdir

shellcheck_files "shellcheck step-progress.sh" "$SP"
check "step-progress.sh is executable" '[ -x "$SP" ]'

# Full path: 6 phases.
eq "full: first step" "$(sp 0.1.1)" "Phase 1 of 6 · step 1 of 48 — Discovery: Scan the specs folder (0.1.1)"
eq "full: 0.3.22 runs before 0.3.8" "$(sp 0.3.22)" "Phase 1 of 6 · step 22 of 48 — Discovery: Deeper prompt (0.3.22)"
eq "full: 0.3.8" "$(sp 0.3.8)" "Phase 1 of 6 · step 23 of 48 — Discovery: Compute the frontier (0.3.8)"
eq "full: Phase 0 exit gate is its last step" "$(sp 0.6)" "Phase 1 of 6 · step 48 of 48 — Discovery: Exit gate (0.6)"
eq "full: 1.1 is Phase 2" "$(sp 1.1)" "Phase 2 of 6 · step 1 of 5 — Verification setup: Measurable targets (1.1)"
eq "full: 2.6 after 2.5" "$(sp 2.6)" "Phase 3 of 6 · step 6 of 6 — Task breakdown: Within the size budget? (2.6)"
eq "full: 3.1 is not 3.10" "$(sp 3.1)" "Phase 4 of 6 · step 1 of 14 — Implementation: Classify tasks and start (3.1)"
eq "full: 3.16 merges before 3.9" "$(sp 3.16)" "Phase 4 of 6 · step 9 of 14 — Implementation: Merge the wave (3.16)"
eq "full: 3.10" "$(sp 3.10)" "Phase 4 of 6 · step 13 of 14 — Implementation: Run the browser suite (3.10)"
eq "full: 4.7" "$(sp 4.7)" "Phase 5 of 6 · step 7 of 8 — Review and triage: Rework attempts remaining? (4.7)"
eq "full: 5.8 is the last step" "$(sp 5.8)" "Phase 6 of 6 · step 9 of 9 — Sign-off: Merge and close (5.8)"
eq "full: 5.9 runs before 5.7" "$(sp 5.9)" "Phase 6 of 6 · step 7 of 9 — Sign-off: Offer backlog items (5.9)"

# Light path: 4 phases (0, 3, 4, 5).
eq "light: 0.3.8 keeps its position, smaller total" "$(sp 0.3.8 --path light)" "Phase 1 of 4 · step 23 of 36 — Discovery: Compute the frontier (0.3.8)"
eq "light: 0.3.20 ends Phase 0" "$(sp 0.3.20 --path light)" "Phase 1 of 4 · step 36 of 36 — Discovery: Light-path test (0.3.20)"
eq "light: 3.1 is Phase 2 of 4" "$(sp 3.1 --path light)" "Phase 2 of 4 · step 1 of 15 — Implementation: Classify tasks and start (3.1)"
eq "light: 3.14 is counted" "$(sp 3.14 --path light)" "Phase 2 of 4 · step 12 of 15 — Implementation: Record the suite gap (3.14)"
eq "light: 4.1" "$(sp 4.1 --path light)" "Phase 3 of 4 · step 1 of 8 — Review and triage: Standards review (4.1)"
eq "light: 5.8" "$(sp 5.8 --path light)" "Phase 4 of 4 · step 9 of 9 — Sign-off: Merge and close (5.8)"

# Loop steps keep their number: the same id always prints the same line.
eq "loop: a second questioning round prints the same line" "$(sp 0.3.11)" "$(sp 0.3.11)"
eq "loop: a later wave's 3.3 has the same number" "$(sp 3.3)" "Phase 4 of 6 · step 3 of 14 — Implementation: Launch the wave (3.3)"

# Off-path, side, intake, cross-cutting, unknown.
t "full-only step on the light path exits 2" 2 "$TEST_BASH" "$SP" 0.4.1 --path light
t "Phase 1 step on the light path exits 2" 2 "$TEST_BASH" "$SP" 1.1 --path light
t "light-only 3.14 on the full path exits 2" 2 "$TEST_BASH" "$SP" 3.14
t "side artifact 0.3.21 exits 2" 2 "$TEST_BASH" "$SP" 0.3.21
t "side artifact 3.12 exits 2" 2 "$TEST_BASH" "$SP" 3.12
t "intake 0.0.1 exits 0" 0 "$TEST_BASH" "$SP" 0.0.1
eq "intake prints nothing" "$(sp 0.0.1)" ""
t "unknown id exits 2" 2 "$TEST_BASH" "$SP" 9.9
err=$("$TEST_BASH" "$SP" 0.3.99 2>&1 >/dev/null)
check "unknown id names the id on stderr" '[[ "$err" == *"unknown step id '"'"'0.3.99'"'"'"* ]]' "$err"
t "00.x without --at exits 2" 2 "$TEST_BASH" "$SP" 00.22
eq "00.x with --at shows the linear step, then the 00.x step" "$(sp 00.22 --at 3.3)" "Phase 4 of 6 · step 3 of 14 — Implementation: Launch the wave (3.3) · Discovered work: present (00.22)"
eq "00.2 is not 00.20" "$(sp 00.20 --at 3.1)" "Phase 4 of 6 · step 1 of 14 — Implementation: Classify tasks and start (3.1) · Inject the profile (00.20)"
t "--at another 00.x exits 2" 2 "$TEST_BASH" "$SP" 00.22 --at 00.21
t "--at on a linear step is a usage error" 1 "$TEST_BASH" "$SP" 3.3 --at 3.1
t "bad --path is a usage error" 1 "$TEST_BASH" "$SP" 3.3 --path medium
t "no id is a usage error" 1 "$TEST_BASH" "$SP"

# --spec-dir: path from light_path, step from .step.
D=$WORK/.workflow/specs/001-alpha
mkdir -p "$D"
cp "$FW_SKILL/assets/spec.md" "$D/spec.md"
printf 'step: "0.3.8"\nupdated_at: "2026-10-19T00:00:00Z"\n' >"$D/.step"
cd "$WORK" || exit 1
eq "--spec-dir: unsized spec counts the full path, step from .step" "$(sp --spec-dir .workflow/specs/001-alpha)" "Phase 1 of 6 · step 23 of 48 — Discovery: Compute the frontier (0.3.8)"
yq --front-matter=process -i '.light_path = true' "$D/spec.md"
printf 'step: "3.9"\n' >"$D/.step"
eq "--spec-dir: light_path true counts the light path" "$(sp --spec-dir .workflow/specs/001-alpha/)" "Phase 2 of 4 · step 13 of 15 — Implementation: Tests pass and CI green? (3.9)"
eq "--spec-dir: an explicit id wins over .step" "$(sp --spec-dir .workflow/specs/001-alpha 4.2)" "Phase 3 of 4 · step 2 of 8 — Review and triage: End-state review (4.2)"
eq "--spec-dir: --path overrides light_path" "$(sp --spec-dir .workflow/specs/001-alpha 1.1 --path full)" "Phase 2 of 6 · step 1 of 5 — Verification setup: Measurable targets (1.1)"
printf 'step: "00.21"\nblocked_from: "in-progress"\n' >"$D/.step"
t "--spec-dir: a 00.x marker needs --at" 2 "$TEST_BASH" "$SP" --spec-dir .workflow/specs/001-alpha
eq "--spec-dir: a 00.x marker with --at" "$(sp --spec-dir .workflow/specs/001-alpha --at 3.15)" "Phase 2 of 4 · step 10 of 15 — Implementation: Within the size budget? (3.15) · Discovered work: block (00.21)"
rm "$D/.step"
t "--spec-dir: no marker and no id exits 1" 1 "$TEST_BASH" "$SP" --spec-dir .workflow/specs/001-alpha
t "--spec-dir: missing spec.md exits 1" 1 "$TEST_BASH" "$SP" --spec-dir .workflow/specs/404-none 3.3


# JRN-007: the large track. The expected lines are built from the large-track rows of steps.tsv.
large_rows() { grep -v '^#' "$FW_SKILL/references/steps.tsv" | awk -F'\t' '$3 == "large"'; }
LARGE_COUNT=$(large_rows | grep -c .)
FIRST_LARGE_ID=$(large_rows | head -n1 | cut -f1)
FIRST_LARGE_TITLE=$(large_rows | head -n1 | cut -f4)
LAST_LARGE_ID=$(large_rows | tail -n1 | cut -f1)
LAST_LARGE_TITLE=$(large_rows | tail -n1 | cut -f4)
check "JRN-007 steps.tsv has large-track rows" '[ "$LARGE_COUNT" -gt 0 ]'
eq "JRN-007 the first large row prints the large form" "$(sp "${FIRST_LARGE_ID:-6.1}")" \
  "Large path · step 1 of $LARGE_COUNT — $FIRST_LARGE_TITLE (${FIRST_LARGE_ID:-6.1})"
eq "JRN-007 the last large row prints the large form" "$(sp "${LAST_LARGE_ID:-6.1}")" \
  "Large path · step $LARGE_COUNT of $LARGE_COUNT — $LAST_LARGE_TITLE (${LAST_LARGE_ID:-6.1})"
check "JRN-007 a phase 0 row still prints Phase 1 of 6" '[[ "$(sp 0.3.8)" == "Phase 1 of 6 · step "*" — Discovery: Compute the frontier (0.3.8)" ]]' "$(sp 0.3.8)"
check "JRN-007 the conversion node prints as a Discovery step on the full path" \
  '[[ "$(sp "$CONVERSION_STEP")" == "Phase 1 of 6 · step "*" — Discovery: "*"($CONVERSION_STEP)" ]]' "$(sp "$CONVERSION_STEP")"
check "JRN-007 the conversion node prints as a Discovery step on the light path" \
  '[[ "$(sp "$CONVERSION_STEP" --path light)" == "Phase 1 of 4 · step "*"($CONVERSION_STEP)" ]]' "$(sp "$CONVERSION_STEP" --path light)"

# The large track: numbering over its own rows, ids that compare equal as numbers, and no spec path for a 6.x id.
eq "large: 6.10 is not 6.1" "$(sp 6.10)" "Large path · step 10 of 13 — Mark the initiative planned (6.10)"
eq "large: the term gate is step 6" "$(sp 6.6)" "Large path · step 6 of 13 — Term gate (6.6)"
t "large: a 6.x id on --path full exits 2" 2 "$TEST_BASH" "$SP" 6.1 --path full
t "large: a 6.x id on --path light exits 2" 2 "$TEST_BASH" "$SP" 6.13 --path light
err=$("$TEST_BASH" "$SP" 6.3 --path full 2>&1 >/dev/null)
check "large: the refusal names the large path" '[[ "$err" == *"on the large path"* ]]' "$err"
t "large: a 6.x id with --spec-dir exits 2" 2 "$TEST_BASH" "$SP" --spec-dir .workflow/specs/001-alpha 6.2
eq "large: a 00.x id with --at a 6.x step shows the large form, then the 00.x step" "$(sp 00.19 --at 6.4)" "Large path · step 4 of 13 — Launch research and fact lookups (6.4) · Define the missing profile (00.19)"
eq "the conversion node runs after 0.3.19, before 0.3.20" "$(sp 0.3.23)" "Phase 1 of 6 · step 35 of 48 — Discovery: Convert a spec into an initiative (0.3.23)"

finish
