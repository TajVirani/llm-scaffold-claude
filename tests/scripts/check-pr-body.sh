#!/usr/bin/env bash
# Suite: check-pr-body.sh (feature-workflow/scripts) and the PR template asset (feature-workflow/assets/pr-template.md).
# Covers: JRN-001: the template holds the ten sections in order, each with guidance, and a body filled from it passes with
#   no output. JRN-002: one variant per fault (a section removed, two sections swapped, a section emptied, Risk: Severe,
#   Reversibility: Never, Reversibility: Irreversible with Risk: Low, no Risk line) exits 1 with one stdout line naming
#   it; two faults give two lines; every scale value is accepted and Irreversible passes with Risk: High; no argument and
#   a missing file exit 2 with the message on stderr. Beyond those: an unknown option exits 2; a section left with only the
#   template's guidance comment is empty; Irreversible without a Risk line gives both faults; a Risk line with no score is
#   refused; punctuation after a score and trailing spaces after a heading are tolerated. JRN-003: project mode (`--project-template`) against a fixture
#   project's .github/pull_request_template.md with three headings: a filled body passes in any order and without risk
#   lines, an empty or a missing heading exits 1 naming it, a missing project template or one with no `##` headings exits 2.
#   Ends with shellcheck.
# shellcheck disable=SC2016,SC2034  # check expressions are single-quoted and eval'd on purpose, and read variables shellcheck cannot see
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/pr-template.sh
source "$TESTS_DIR/fixtures/pr-template.sh"
preflight

new_workdir
copy_agents "$WORK/scaffold"
CPB="$WORK/scaffold/.agents/skills/feature-workflow/scripts/check-pr-body.sh"
TEMPLATE="$WORK/scaffold/.agents/skills/feature-workflow/assets/pr-template.md"
BODIES="$WORK/bodies"
mkdir -p "$BODIES"

# run_cpb ARG... : run the check from RUN_DIR (default WORK), keeping stdout in OUT, stderr in ERR and the exit code in RC.
run_cpb() {
  OUT=$(cd "${RUN_DIR:-$WORK}" && "${TEST_BASH:-bash}" "$CPB" "$@" 2>"$WORK/cpb.err")
  RC=$?
  ERR=$(cat "$WORK/cpb.err")
}

# expect_pass NAME ARG... : the check exits 0 and prints nothing on either stream.
expect_pass() {
  local name=$1
  shift
  run_cpb "$@"
  check "$name" '[ "$RC" -eq 0 ] && [ -z "$OUT$ERR" ]' "rc=$RC stdout=$OUT stderr=$ERR"
}

# expect_faults NAME COUNT PATTERN ARG... : the check exits 1 with COUNT stdout lines, one of them matching the extended
#   regex PATTERN.
expect_faults() {
  local name=$1 count=$2 pattern=$3
  shift 3
  run_cpb "$@"
  check "$name" '[ "$RC" -eq 1 ] && [ "$(grep -c . <<<"$OUT")" -eq "$count" ] && grep -Eq -- "$pattern" <<<"$OUT"' \
    "rc=$RC stdout=$OUT stderr=$ERR"
}

# expect_usage_error NAME ARG... : the check exits 2 with a message on stderr and nothing on stdout.
expect_usage_error() {
  local name=$1
  shift
  run_cpb "$@"
  check "$name" '[ "$RC" -eq 2 ] && [ -z "$OUT" ] && [ -n "$ERR" ]' "rc=$RC stdout=$OUT stderr=$ERR"
}

template_headings() { sed -n 's/^## *//p' "$TEMPLATE" | sed 's/[[:space:]]*$//'; }

# sections_without_guidance : print each template heading whose section has no non-blank line before the next heading.
sections_without_guidance() {
  awk '
    /^## / { if (heading != "" && !guided) print heading; heading = substr($0, 4); guided = 0; next }
    heading != "" && NF { guided = 1 }
    END { if (heading != "" && !guided) print heading }
  ' "$TEMPLATE"
}

echo "== JRN-001: the template and a well-filled body"
eq "JRN-001 the template holds the ten sections in order" "$(template_headings)" "$PR_TEMPLATE_SECTIONS"
check "JRN-001 every template section carries guidance" \
  '[ -n "$(template_headings)" ] && [ -z "$(sections_without_guidance)" ]' "unguided: $(sections_without_guidance)"

# The filled body copies the template's headings and replaces each section's guidance with filled text.
template_headings | pr_body_from_headings >"$BODIES/filled.md"
expect_pass "JRN-001 a body filled from the template passes with no output" "$BODIES/filled.md"

echo "== JRN-002: each bad shape is caught"
template_headings | grep -vx 'How to test' | pr_body_from_headings >"$BODIES/section-removed.md"
expect_faults "JRN-002 a removed section is named as missing" 1 '^How to test: .*[Mm]issing' "$BODIES/section-removed.md"

template_headings | awk '$0 == "How to test" { held = $0; next } { print } $0 == "Blast radius" && held != "" { print held; held = "" }' |
  pr_body_from_headings >"$BODIES/sections-swapped.md"
expect_faults "JRN-002 two swapped sections are named as out of order" 1 '^(How to test|Blast radius): .*[Oo]rder' \
  "$BODIES/sections-swapped.md"

template_headings | PR_EMPTY_SECTION='Why this approach' pr_body_from_headings >"$BODIES/section-emptied.md"
expect_faults "JRN-002 an emptied section is named as empty" 1 '^Why this approach: .*[Ee]mpty' "$BODIES/section-emptied.md"

sed 's/^Risk: Medium/Risk: Severe/' "$BODIES/filled.md" >"$BODIES/risk-severe.md"
expect_faults "JRN-002 Risk: Severe is off the scale" 1 '^Risk: .*Severe' "$BODIES/risk-severe.md"

sed 's/^Reversibility: Easy/Reversibility: Never/' "$BODIES/filled.md" >"$BODIES/reversibility-never.md"
expect_faults "JRN-002 Reversibility: Never is off the scale" 1 '^Reversibility: .*Never' "$BODIES/reversibility-never.md"

sed -e 's/^Risk: Medium/Risk: Low/' -e 's/^Reversibility: Easy/Reversibility: Irreversible/' "$BODIES/filled.md" \
  >"$BODIES/irreversible-low.md"
expect_faults "JRN-002 Reversibility: Irreversible with Risk: Low is refused" 1 '^(Risk|Reversibility): .*Irreversible' \
  "$BODIES/irreversible-low.md"

sed '/^Risk: /d' "$BODIES/filled.md" >"$BODIES/risk-line-missing.md"
expect_faults "JRN-002 a Risk and reversibility section without a Risk line is refused" 1 '^Risk: ' \
  "$BODIES/risk-line-missing.md"

template_headings | grep -vx 'How to test' | pr_body_from_headings | sed 's/^Risk: Medium/Risk: Severe/' \
  >"$BODIES/two-faults.md"
expect_faults "JRN-002 two faults give two lines (the missing section)" 2 '^How to test: ' "$BODIES/two-faults.md"
expect_faults "JRN-002 two faults give two lines (the off-scale Risk)" 2 '^Risk: .*Severe' "$BODIES/two-faults.md"

for risk in Low Medium High; do
  sed "s/^Risk: Medium/Risk: $risk/" "$BODIES/filled.md" >"$BODIES/risk-$risk.md"
  expect_pass "JRN-002 Risk: $risk is accepted" "$BODIES/risk-$risk.md"
done
for reversibility in Easy Moderate Hard; do
  sed "s/^Reversibility: Easy/Reversibility: $reversibility/" "$BODIES/filled.md" >"$BODIES/reversibility-$reversibility.md"
  expect_pass "JRN-002 Reversibility: $reversibility is accepted" "$BODIES/reversibility-$reversibility.md"
done
sed -e 's/^Risk: Medium/Risk: High/' -e 's/^Reversibility: Easy/Reversibility: Irreversible/' "$BODIES/filled.md" \
  >"$BODIES/irreversible-high.md"
expect_pass "JRN-002 Reversibility: Irreversible with Risk: High is accepted" "$BODIES/irreversible-high.md"

expect_usage_error "JRN-002 no argument exits 2"
expect_usage_error "JRN-002 a missing file exits 2" "$BODIES/no-such-body.md"
expect_usage_error "JRN-002 an unknown option exits 2" "$BODIES/filled.md" --no-such-option

# template_guidance HEADING : print the non-blank lines under HEADING in the template, its guidance.
template_guidance() {
  awk -v wanted="$1" '/^## / { in_section = (substr($0, 4) == wanted); next } in_section && NF' "$TEMPLATE"
}

GUIDANCE=$(template_guidance 'Why this approach')
check "JRN-002 the template guides Why this approach in an HTML comment" '[[ $GUIDANCE == "<!--"* ]]' "guidance=$GUIDANCE"
template_headings | PR_EMPTY_SECTION='Why this approach' pr_body_from_headings |
  GUIDANCE=$GUIDANCE awk '{ print } $0 == "## Why this approach" { print ENVIRON["GUIDANCE"] }' >"$BODIES/guidance-only.md"
expect_faults "JRN-002 a section holding only the template's guidance comment is named as empty" 1 \
  '^Why this approach: .*[Ee]mpty' "$BODIES/guidance-only.md"

sed -e '/^Risk: /d' -e 's/^Reversibility: Easy/Reversibility: Irreversible/' "$BODIES/filled.md" \
  >"$BODIES/irreversible-no-risk.md"
expect_faults "JRN-002 Irreversible without a Risk line names the missing Risk" 2 '^Risk: ' "$BODIES/irreversible-no-risk.md"
expect_faults "JRN-002 Irreversible without a Risk line names the Irreversible rule" 2 '^Reversibility: .*Irreversible' \
  "$BODIES/irreversible-no-risk.md"

sed 's/^Risk:.*/Risk:/' "$BODIES/filled.md" >"$BODIES/risk-blank.md"
expect_faults "JRN-002 a Risk line with no score is refused" 1 '^Risk: ' "$BODIES/risk-blank.md"

sed 's/^Risk: Medium -/Risk: Medium,/' "$BODIES/filled.md" >"$BODIES/risk-comma.md"
expect_pass "JRN-002 a score followed by punctuation reads as the score" "$BODIES/risk-comma.md"

sed 's/^## How to test$/## How to test   /' "$BODIES/filled.md" >"$BODIES/heading-trailing-spaces.md"
expect_pass "JRN-002 trailing spaces after a heading still match it" "$BODIES/heading-trailing-spaces.md"

echo "== JRN-003: project mode checks the project's own headings"
PROJ="$WORK/project"
mkdir -p "$PROJ/.github"
cat >"$PROJ/.github/pull_request_template.md" <<'EOF'
<!-- Thanks for the change. Fill every section. -->
## Summary

What does this change do?

## Testing

How did you test it?

## Checklist

- [ ] Tests added
EOF
cat >"$PROJ/filled.md" <<'EOF'
## Summary

Sign-off fills the PR description from the spec's evidence.

## Testing

Ran tests/run-all.sh; every suite passed.

## Checklist

- [x] Tests added
EOF
cat >"$PROJ/reordered.md" <<'EOF'
## Testing

Ran tests/run-all.sh; every suite passed.

## Checklist

- [x] Tests added

## Summary

Sign-off fills the PR description from the spec's evidence.
EOF
cat >"$PROJ/testing-empty.md" <<'EOF'
## Summary

Sign-off fills the PR description from the spec's evidence.

## Testing

## Checklist

- [x] Tests added
EOF
cat >"$PROJ/checklist-missing.md" <<'EOF'
## Summary

Sign-off fills the PR description from the spec's evidence.

## Testing

Ran tests/run-all.sh; every suite passed.
EOF
PROJECT_TEMPLATE=.github/pull_request_template.md
RUN_DIR=$PROJ
expect_pass "JRN-003 a body filling every project heading passes without risk lines" \
  filled.md --project-template "$PROJECT_TEMPLATE"
expect_pass "JRN-003 project mode does not check the order of headings" \
  reordered.md --project-template "$PROJECT_TEMPLATE"
expect_faults "JRN-003 an empty project heading is named" 1 '^Testing: ' \
  testing-empty.md --project-template "$PROJECT_TEMPLATE"
expect_faults "JRN-003 a missing project heading is named" 1 '^Checklist: ' \
  checklist-missing.md --project-template "$PROJECT_TEMPLATE"
expect_usage_error "JRN-003 a missing project template exits 2" \
  filled.md --project-template .github/no_such_template.md
cat >"$PROJ/.github/no_headings_template.md" <<'EOF'
### Summary

What does this change do?
EOF
expect_usage_error "JRN-003 a project template with no ## headings exits 2" \
  filled.md --project-template .github/no_headings_template.md
RUN_DIR=$WORK

shellcheck_files "shellcheck: check-pr-body.sh" "$CPB"
finish
