#!/usr/bin/env bash
# Suite: check-review-findings.sh (feature-workflow/scripts).
# Covers: the header line and finding table for three real pass-1 lens files (standards, end-state, targets with no targets),
#   a targets file with measurements, a failed target and discovered work, the pass taken from the file over the path,
#   one malformed file per shape rule (exit 1, the message names the field), two errors in one file,
#   JRN-003: the review-lessons pass file for a repeated lesson (one high RL-1 lesson row) and with no findings, and an RS- id,
#   a confidence of 70 and a lesson finding under review-standards each refused naming the field,
#   the review-combined pass file (RC- ids, end-state, standards and lesson categories together; a target category or an RE- id
#   refused), the proof rule (a medium or high finding without evidence.reproduction or evidence.basis refused naming evidence;
#   a reproduction alone, or a low finding without evidence, accepted),
#   and the exit-2 cases: no argument, two arguments, missing file, YAML that does not parse.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/review-lessons.sh
source "$TESTS_DIR/fixtures/review-lessons.sh"
preflight

new_workdir
copy_agents "$WORK/scaffold"
CRF="$WORK/scaffold/.agents/skills/feature-workflow/scripts/check-review-findings.sh"
TAB=$'\t'

# row FIELD... : join the fields with tabs, the way the script prints a table row.
row() {
  local IFS=$TAB
  printf '%s' "$*"
}

# run_crf FILE : run the script on FILE, capturing stdout and stderr in OUT and the exit code in RC.
run_crf() {
  OUT=$("$CRF" "$@" 2>&1)
  RC=$?
}

# line N : print line N of OUT.
line() { sed -n "${1}p" <<<"$OUT"; }

# --- Three real pass-1 files (a light-path spec: no targets to measure)
P1="$WORK/spec/artifacts/review/pass-1"
mkdir -p "$P1"
cat >"$P1/review-standards.yaml" <<'Y'
lens: review-standards
status: done
blocked_reason: ""
baseline_revision: "f8ea802e8efa7f56499a2743930887986e1ec020"
head: "9fe4e82d5435bd769bfe58f9e39b65d63ae3b662"
findings:
  - id: RS-1
    category: rule
    severity: low
    confidence: 95
    location: "commits 91407dc, f786aa3"
    claim: "The two T1 code commits use a 'T1:' subject prefix instead of a Conventional Commits type."
    consequence: "These subjects reach main when the spec merges, breaking the convention earlier implementation commits follow, so filtering or changelogging history by type misses this change."
    evidence:
      basis: ".workflow/rules.md, Cross-cutting policy: Commit subjects are Conventional Commits (feat:, fix:, docs:, chore:, test:, refactor:)."
      diff: "91407dc T1: scoped and parallel harness runs in tests/run-all.sh / f786aa3 T1: explain the empty-array guard in the run-all summary loop"
    suggested_fix: "Reword before merge: 'feat(tests): scoped and parallel harness runs in run-all.sh (T1)' and 'docs(tests): explain the empty-array guard in the run-all summary loop (T1)'."
  - id: RS-2
    category: discovered-work
    kind: decision
    summary: "commit-workflow-data.sh stages everything under .workflow/ except other spec folders, so 004's branch carries other specs' Tier A files: accepted ADR 0002 (spec 002) and deferred items from specs 002 and 003, whose folders are still untracked drafts. On merge, main gets an accepted placement ADR for a lens that does not exist yet."
    evidence: "af43dbe adds .workflow/decisions/adr/0002-review-lessons-placement.md, .workflow/deferred/boundary-check-wording.md, .workflow/deferred/retrospective-template-drift.md and 001-large-path-disc-00{2,3,4}.md; staging scope at .agents/skills/feature-workflow/scripts/commit-workflow-data.sh:6-7."
    blocker_assessment: can-wait
    reason: "None of these files touches 004's code or tests; a stakeholder must decide whether cross-spec Tier A files ride on whichever spec branch commits next."
checked: ["diff f8ea802...HEAD", "rules.md", "profiles/test-harness.md", "GLOSSARY.md", "readable-code.md", "T1 toolchain evidence", "smell baseline"]
not_checked: ["CODING_STANDARDS.md, CONTRIBUTING.md: absent", "GLOSSARY-MAP.md: absent", "Placement ADR: none (light path, one module)", "typecheck/format/boundary: no command in profile"]
Y
cat >"$P1/review-end-state.yaml" <<'Y'
lens: review-end-state
status: done
blocked_reason: ""
baseline_revision: "f8ea802e8efa7f56499a2743930887986e1ec020"
head: "9fe4e82d5435bd769bfe58f9e39b65d63ae3b662"
findings:
  - id: RE-1
    category: discovered-work
    kind: bug
    summary: "commit-workflow-data.sh stages everything under .workflow/ except other spec and initiative folders, so other in-flight specs' workflow data (ADR 0002, deferred items from 002 and 003, 001-large-path-disc-002..004) was committed on 004's branch in af43dbe; specs 002 and 003 are untracked, so main would get an accepted ADR and deferred items linking to spec folders not in git. 001-large-path-disc-004 also duplicates 004-scoped-test-runs-disc-001 (the codex-adapters flake)."
    evidence: "git show --stat af43dbe; .agents/skills/feature-workflow/scripts/commit-workflow-data.sh:6-7; git status shows 002 and 003 untracked."
    blocker_assessment: can-wait
    reason: "None of these files touches the delivered capability (tests/ only); decide before merging whether they ship with 004; the staging rule is pre-existing tooling."
checked: ["CAP-NEW-scoped-test-runs: --only-file, empty/missing only-file, F minus G, exit 2 on bad selector, parallel default matches -j 1 output and exit codes", "assumptions (--suite + file flags exit 2; default -j)", "constraints (bash 3.2, no WF_* in tests/, glob order, exit contract, profiles untouched)", "non-goals", "deferred browser-suite.md", "artifacts T1 and gate-3.9-w1"]
not_verifiable: ["Success signal 'seconds per task' depends on P1-P3 at 5.3 and Spec B", "test_scoped runs only when the excluded set is non-empty (run-toolchain.sh:152-171), by D3"]
not_checked: ["verification-plan.md absent (light path)"]
Y
cat >"$P1/review-targets.yaml" <<'Y'
lens: review-targets
status: done
blocked_reason: ""
baseline_revision: "f8ea802e8efa7f56499a2743930887986e1ec020"
head: "9fe4e82d5435bd769bfe58f9e39b65d63ae3b662"
measurements: []
findings: []
checked: []
not_checked:
  - "verification-plan.md: missing at .workflow/specs/004-scoped-test-runs/verification-plan.md, so there is no ## Targets table to measure"
  - "build: no serve started, because no targets were read and no profile pair was collected"
Y

run_crf "$P1/review-standards.yaml"
eq "standards: exit 0" "$RC" 0
eq "standards: header" "$(line 1)" "lens: review-standards  pass: 1  findings: 1 (high 0, medium 0, low 1)  discovered_work: 1  checked: 7  not_checked: 4  not_verifiable: 0"
eq "standards: column names" "$(line 2)" "$(row id category severity confidence location claim)"
eq "standards: graded row" "$(line 3)" "$(row RS-1 rule low 95 "commits 91407dc, f786aa3" "The two T1 code commits use a 'T1:' subject prefix instead of a Conventional Commits type.")"
eq "standards: discovered-work row, claim cut to 120" "$(line 4)" "$(row RS-2 discovered-work - - - "decision, can-wait: commit-workflow-data.sh stages everything under .workflow/ except other spec folders, so 004's branc")"
eq "standards: no other lines" "$(wc -l <<<"$OUT" | tr -d ' ')" 4
eq "claim column is at most 120 characters" "$(line 4 | cut -f6 | awk '{ print length($0) }')" 120

run_crf "$P1/review-end-state.yaml"
eq "end-state: exit 0" "$RC" 0
eq "end-state: header" "$(line 1)" "lens: review-end-state  pass: 1  findings: 0 (high 0, medium 0, low 0)  discovered_work: 1  checked: 6  not_checked: 1  not_verifiable: 2"
eq "end-state: discovered-work row" "$(line 3)" "$(row RE-1 discovered-work - - - "bug, can-wait: commit-workflow-data.sh stages everything under .workflow/ except other spec and initiative folders, so o")"
eq "end-state: no other lines" "$(wc -l <<<"$OUT" | tr -d ' ')" 3

run_crf "$P1/review-targets.yaml"
eq "targets, none measured: exit 0" "$RC" 0
eq "targets, none measured: header" "$(line 1)" "lens: review-targets  pass: 1  findings: 0 (high 0, medium 0, low 0)  discovered_work: 0  checked: 0  not_checked: 2  not_verifiable: 0"
eq "targets, none measured: finding and measurement column names only" "$OUT" "$(line 1)
$(row id category severity confidence location claim)
$(row target measured verdict)"

# --- A targets file with measurements, a failed target and discovered work
P2="$WORK/spec/artifacts/review/pass-2"
mkdir -p "$P2"
cat >"$P2/review-targets.yaml" <<'Y'
lens: review-targets
status: done
blocked_reason: ""
baseline_revision: "f7a4b23b895c0b7a81d8b7517ec6be87dba3b6fd"
head: "291e55289f399f767e7403715e14b73ffa5a7ccd"
measurements:
  - {target: "Script lint clean", kind: errors, threshold: "exit 0; 0 shellcheck findings", command: "shellcheck x.sh", measured: "0 shellcheck findings", result: pass, exit_code: 0, raw_output: "pass-2/targets/script-lint-clean.txt", reason: ""}
  - {target: "line coverage, billing module", kind: coverage, threshold: "lines >= 80%", command: "npx vitest run --coverage", measured: "74.2%", result: fail, exit_code: 1, raw_output: "pass-2/targets/coverage.txt", reason: ""}
  - {target: "Session-start hook wall time", kind: performance, threshold: "none", command: "", measured: "", result: not_measurable, exit_code: null, raw_output: "", reason: "no command"}
findings:
  - id: RT-1
    category: target
    severity: high
    confidence: 100
    location: "verification-plan.md#targets: line coverage, billing module"
    claim: "line coverage, billing module measured 74.2%, threshold lines >= 80%"
    consequence: "The build does not meet a target the spec committed to."
    evidence:
      basis: "pass-2/targets/coverage.txt"
      diff: ""
    suggested_fix: ""
  - id: RT-2
    category: discovered-work
    kind: bug
    summary: "The serve command logs a deprecation error on every start."
    evidence: "pass-2/targets/serve-1.log:3"
    blocker_assessment: can-wait
    reason: "The build still became ready."
checked: ["Script lint clean", "line coverage, billing module"]
not_checked: ["Session-start hook wall time: not measurable: no command"]
Y
run_crf "$P2/review-targets.yaml"
eq "targets with measurements: exit 0" "$RC" 0
eq "targets with measurements: header, pass from the directory" "$(line 1)" "lens: review-targets  pass: 2  findings: 1 (high 1, medium 0, low 0)  discovered_work: 1  checked: 2  not_checked: 1  not_verifiable: 0"
eq "targets with measurements: failed-target row" "$(line 3)" "$(row RT-1 target high 100 "verification-plan.md#targets: line coverage, billing module" "line coverage, billing module measured 74.2%, threshold lines >= 80%")"
eq "targets with measurements: discovered-work row" "$(line 4)" "$(row RT-2 discovered-work - - - "bug, can-wait: The serve command logs a deprecation error on every start.")"
eq "targets with measurements: measurement rows" "$(sed -n '5,$p' <<<"$OUT")" "$(row target measured verdict)
$(row "Script lint clean" "0 shellcheck findings" pass)
$(row "line coverage, billing module" "74.2%" fail)
$(row "Session-start hook wall time" "" not_measurable)"

# --- The pass field wins over the path; a file outside a pass-<n> directory needs one
mkdir -p "$WORK/loose"
yq '.pass = 3' "$P1/review-standards.yaml" >"$WORK/loose/review-standards.yaml"
run_crf "$WORK/loose/review-standards.yaml"
eq "pass field outside a pass directory: exit 0" "$RC" 0
check "pass field outside a pass directory: header shows it" '[[ $(line 1) == "lens: review-standards  pass: 3  "* ]]' "$OUT"

# --- One malformed file per shape rule. Each is a valid lens file with one change, in its own pass-1 directory.
# bad NAME LENS YQ_EXPR WANT : write LENS's valid pass-1 file changed by YQ_EXPR, then expect exit 1 and exactly one line, WANT.
bad() {
  local dir="$WORK/bad/$1/pass-1"
  mkdir -p "$dir"
  yq "$3" "$P_BASE/$2.yaml" >"$dir/$2.yaml"
  run_crf "$dir/$2.yaml"
  eq "$1: exit 1" "$RC" 1
  eq "$1: message names the field" "$OUT" "$4"
}
P_BASE="$WORK/base"
mkdir -p "$P_BASE"
cp "$P1/review-standards.yaml" "$P1/review-end-state.yaml" "$P_BASE/"
cp "$P2/review-targets.yaml" "$P_BASE/"

bad lens-missing review-standards 'del(.lens)' "lens: missing"
bad lens-unknown review-standards '.lens = "review-style"' "lens: 'review-style' is not review-standards, review-end-state, review-targets, review-lessons or review-combined"
bad lens-not-file-name review-standards '.lens = "review-end-state" | .findings = []' "lens: 'review-end-state' does not match the file name review-standards.yaml"
bad pass-not-integer review-standards '.pass = "one"' "pass: 'one' is not a positive integer"
bad pass-not-directory review-standards '.pass = 2' "pass: 2 does not match the directory pass-1"
bad status review-standards '.status = "finished"' "status: 'finished' is not done or blocked"
bad findings-not-list review-standards '.findings = "none"' "findings: not a list"
bad checked-not-list review-standards '.checked = "all"' "checked: not a list"
bad not-checked-not-list review-end-state '.not_checked = "x"' "not_checked: not a list"
bad not-verifiable-not-list review-end-state '.not_verifiable = 3' "not_verifiable: not a list"
bad finding-not-mapping review-standards '.findings[0] = "RS-1"' "findings[0]: not a mapping"
bad id-prefix review-standards '.findings[0].id = "RE-1"' "findings[0].id: 'RE-1' does not match RS-<n>"
bad id-missing review-end-state 'del(.findings[0].id)' "findings[0].id: '' does not match RE-<n>"
bad id-duplicate review-standards '.findings[1].id = "RS-1"' "findings: id RS-1 appears 2 times"
bad category review-standards '.findings[0].category = "missing"' "findings[0].category: 'missing' is not one of standard, rule, profile, placement, naming, smell, discovered-work"
bad category-end-state review-end-state '.findings[0] = {"id": "RE-1", "category": "rule", "severity": "low", "confidence": 90, "location": "a.sh:1", "claim": "c"}' "findings[0].category: 'rule' is not one of missing, unasked, wrong, discovered-work"
bad category-targets review-targets '.findings[0].category = "smell"' "findings[0].category: 'smell' is not one of target, discovered-work"
bad severity review-standards '.findings[0].severity = "critical"' "findings[0].severity: 'critical' is not high, medium or low"
bad confidence-text review-standards '.findings[0].confidence = "95"' "findings[0].confidence: '95' is not an integer from 0 to 100"
bad confidence-fraction review-standards '.findings[0].confidence = 85.5' "findings[0].confidence: '85.5' is not an integer from 0 to 100"
bad confidence-over-100 review-standards '.findings[0].confidence = 101' "findings[0].confidence: '101' is not an integer from 0 to 100"
bad confidence-below-cutoff review-standards '.findings[0].confidence = 79' "findings[0].confidence: 79 is below the 80 cutoff"
bad location review-standards '.findings[0].location = ""' "findings[0].location: missing or empty"
bad claim review-targets 'del(.findings[0].claim)' "findings[0].claim: missing or empty"
bad dw-kind review-standards '.findings[1].kind = "idea"' "findings[1].kind: 'idea' is not bug, requirement, refactor, scope-expansion or decision"
bad dw-summary review-standards '.findings[1].summary = ""' "findings[1].summary: missing or empty"
bad dw-evidence review-end-state 'del(.findings[0].evidence)' "findings[0].evidence: missing or empty"
bad dw-reason review-end-state '.findings[0].reason = ""' "findings[0].reason: missing or empty"
bad dw-blocker review-standards '.findings[1].blocker_assessment = "later"' "findings[1].blocker_assessment: 'later' is not blocks-this-task or can-wait"
bad measurements-missing review-targets 'del(.measurements)' "measurements: not a list"
bad measurement-not-mapping review-targets '.measurements[0] = "lint"' "measurements[0]: not a mapping"
bad measurement-target review-targets '.measurements[0].target = ""' "measurements[0].target: missing or empty"
bad measurement-result review-targets '.measurements[1].result = "missed"' "measurements[1].result: 'missed' is not pass, fail or not_measurable"
bad measurement-measured review-targets '.measurements[1].measured = ""' "measurements[1].measured: missing or empty"
bad measurement-reason review-targets '.measurements[2].reason = ""' "measurements[2].reason: missing or empty, required when not_measurable"
bad root-not-mapping review-standards '.findings' "root: not a mapping"
bad proof-missing review-standards '.findings[0].severity = "medium" | del(.findings[0].evidence)' "findings[0].evidence: a medium finding needs evidence.reproduction or evidence.basis"
bad proof-empty review-targets '.findings[0].evidence = {"basis": "", "reproduction": ""}' "findings[0].evidence: a high finding needs evidence.reproduction or evidence.basis"
bad proof-not-mapping review-standards '.findings[0].severity = "high" | .findings[0].evidence = "trust me"' "findings[0].evidence: a high finding needs evidence.reproduction or evidence.basis"

mkdir -p "$WORK/proof/pass-1"
yq '.findings[0].severity = "high" | .findings[0].evidence = {"reproduction": "bash -c probe: exit 1"}' "$P_BASE/review-standards.yaml" \
  >"$WORK/proof/pass-1/review-standards.yaml"
run_crf "$WORK/proof/pass-1/review-standards.yaml"
eq "a high finding proven by a reproduction alone: exit 0" "$RC" 0
mkdir -p "$WORK/proof-low/pass-1"
yq 'del(.findings[0].evidence)' "$P_BASE/review-standards.yaml" >"$WORK/proof-low/pass-1/review-standards.yaml"
run_crf "$WORK/proof-low/pass-1/review-standards.yaml"
eq "a low finding with no evidence: exit 0 (the proof gate is for medium and high)" "$RC" 0

mkdir -p "$WORK/bad/no-pass"
cp "$P1/review-standards.yaml" "$WORK/bad/no-pass/review-standards.yaml"
run_crf "$WORK/bad/no-pass/review-standards.yaml"
eq "no pass field and no pass directory: exit 1" "$RC" 1
eq "no pass field and no pass directory: message" "$OUT" "pass: no pass field and the file is not in a pass-<n> directory"

mkdir -p "$WORK/bad/two-docs/pass-1"
{ cat "$P1/review-targets.yaml"; echo "---"; cat "$P1/review-targets.yaml"; } >"$WORK/bad/two-docs/pass-1/review-targets.yaml"
run_crf "$WORK/bad/two-docs/pass-1/review-targets.yaml"
eq "two YAML documents: exit 1" "$RC" 1
eq "two YAML documents: message" "$OUT" "root: expected one YAML document, found 2"

# --- Two errors in one file: both lines, in rule order
mkdir -p "$WORK/bad/two-errors/pass-1"
yq '.status = "finished" | .findings[0].severity = "critical"' "$P1/review-standards.yaml" >"$WORK/bad/two-errors/pass-1/review-standards.yaml"
run_crf "$WORK/bad/two-errors/pass-1/review-standards.yaml"
eq "two errors: exit 1" "$RC" 1
eq "two errors: both lines" "$OUT" "status: 'finished' is not done or blocked
findings[0].severity: 'critical' is not high, medium or low"

# --- The review-lessons lens file the lens writes for a change that repeats lesson RL-001
PL="$WORK/lessons-spec/artifacts/review/pass-1"
expected_lens_block "$PL/review-lessons.yaml"
run_crf "$PL/review-lessons.yaml"
eq "JRN-003 lessons: exit 0" "$RC" 0
check "JRN-003 lessons: header counts one high finding" \
  '[[ $(line 1) == "lens: review-lessons  pass: 1  findings: 1 (high 1, medium 0, low 0)  "* ]]' "$OUT"
check "JRN-003 lessons: one RL-1 lesson row, high, confidence 90, in the diff" \
  '[[ $(line 3) == "$(row RL-1 lesson high 90 "src/report.sh:$REPORT_REPEAT_LINE")$TAB"* ]]' "$OUT"
eq "JRN-003 lessons: no other finding rows" "$(wc -l <<<"$OUT" | tr -d ' ')" 3

# names_field NAME FILE FIELD : the script exits 1 on FILE with one line, naming FIELD.
names_field() {
  local field=$3
  run_crf "$2"
  eq "$1: exit 1" "$RC" 1
  eq "$1: one line naming $field" "$(grep -c . <<<"$OUT"):${OUT%%: *}" "1:$field"
}
mkdir -p "$WORK/bad/lessons-rs-id/pass-1" "$WORK/bad/lessons-confidence/pass-1" "$WORK/bad/lesson-under-standards/pass-1"
yq '.findings[0].id = "RS-1"' "$PL/review-lessons.yaml" >"$WORK/bad/lessons-rs-id/pass-1/review-lessons.yaml"
names_field "JRN-003 lessons: an RS- id" "$WORK/bad/lessons-rs-id/pass-1/review-lessons.yaml" "findings[0].id"
yq '.findings[0].confidence = 70' "$PL/review-lessons.yaml" >"$WORK/bad/lessons-confidence/pass-1/review-lessons.yaml"
names_field "JRN-003 lessons: confidence 70" "$WORK/bad/lessons-confidence/pass-1/review-lessons.yaml" "findings[0].confidence"
yq '.lens = "review-standards" | .findings[0].id = "RS-1"' "$PL/review-lessons.yaml" \
  >"$WORK/bad/lesson-under-standards/pass-1/review-standards.yaml"
names_field "JRN-003 a lesson finding under review-standards" "$WORK/bad/lesson-under-standards/pass-1/review-standards.yaml" "findings[0].category"

# --- The combined lens of the light and small paths: one RC- file holding end-state, standards and lesson findings
PC="$WORK/combined/pass-1"
mkdir -p "$PC"
cat >"$PC/review-combined.yaml" <<'Y'
lens: review-combined
status: done
blocked_reason: ""
baseline_revision: "f8ea802e8efa7f56499a2743930887986e1ec020"
head: "9fe4e82d5435bd769bfe58f9e39b65d63ae3b662"
findings:
  - id: RC-1
    category: wrong
    severity: high
    confidence: 95
    location: "tests/run-all.sh:88"
    claim: "Suites no longer get /dev/null as stdin."
    consequence: "A suite that reads stdin hangs the harness."
    evidence:
      basis: "spec.md CAP-001: every suite runs unattended"
      reproduction: "bash tests/run-all.sh --suite x </dev/tty: hangs; with the fix: exits 0"
  - id: RC-2
    category: naming
    severity: low
    confidence: 85
    location: "tests/run-all.sh:12"
    claim: "Says named worktree where the glossary term is agent worktree."
  - id: RC-3
    category: lesson
    severity: medium
    confidence: 90
    location: "tests/run-all.sh:40"
    claim: "Repeats the pitfall about unquoted array expansion."
    evidence:
      basis: "pitfalls.md: Quote every array expansion"
  - id: RC-4
    category: discovered-work
    kind: bug
    summary: "The summary loop drops a suite name with a space."
    evidence: "bash -c 'run-all.sh --suite \"a b\"': prints a and b as two suites"
    blocker_assessment: can-wait
    reason: "Pre-existing; no suite name has a space today."
checked: ["spec.md", "rules.md", "review-lessons.md"]
not_checked: ["a suspicion about SIGPIPE: not reproduced; a run with a closed stdout would settle it"]
Y
run_crf "$PC/review-combined.yaml"
eq "combined: exit 0" "$RC" 0
eq "combined: header" "$(line 1)" "lens: review-combined  pass: 1  findings: 3 (high 1, medium 1, low 1)  discovered_work: 1  checked: 3  not_checked: 1  not_verifiable: 0"
eq "combined: end-state, naming and lesson rows, then discovered work" "$(sed -n '3,6p' <<<"$OUT" | cut -f1,2)" "$(row RC-1 wrong)
$(row RC-2 naming)
$(row RC-3 lesson)
$(row RC-4 discovered-work)"
mkdir -p "$WORK/bad/combined-target/pass-1" "$WORK/bad/combined-prefix/pass-1"
yq '.findings[1].category = "target"' "$PC/review-combined.yaml" >"$WORK/bad/combined-target/pass-1/review-combined.yaml"
names_field "combined: a target finding" "$WORK/bad/combined-target/pass-1/review-combined.yaml" "findings[1].category"
yq '.findings[0].id = "RE-1"' "$PC/review-combined.yaml" >"$WORK/bad/combined-prefix/pass-1/review-combined.yaml"
names_field "combined: an RE- id" "$WORK/bad/combined-prefix/pass-1/review-combined.yaml" "findings[0].id"

mkdir -p "$WORK/lessons-clean/pass-1"
yq '.findings = []' "$PL/review-lessons.yaml" >"$WORK/lessons-clean/pass-1/review-lessons.yaml"
run_crf "$WORK/lessons-clean/pass-1/review-lessons.yaml"
eq "JRN-003 lessons, no findings: exit 0" "$RC" 0
check "JRN-003 lessons, no findings: header counts none" \
  '[[ $(line 1) == "lens: review-lessons  pass: 1  findings: 0 (high 0, medium 0, low 0)  "* ]]' "$OUT"

# --- Exit 2: usage, missing file, YAML that does not parse
run_crf
eq "no argument: exit 2" "$RC" 2
check "no argument: usage" '[[ $OUT == "usage: check-review-findings.sh <file>" ]]' "$OUT"
run_crf "$P1/review-standards.yaml" "$P1/review-end-state.yaml"
eq "two arguments: exit 2" "$RC" 2
run_crf "$WORK/spec/artifacts/review/pass-9/review-standards.yaml"
eq "missing file: exit 2" "$RC" 2
check "missing file: says so" '[[ $OUT == *"no such file"* ]]' "$OUT"
mkdir -p "$WORK/bad/unparsable/pass-1"
printf 'lens: review-standards\nfindings: [unclosed\n' >"$WORK/bad/unparsable/pass-1/review-standards.yaml"
run_crf "$WORK/bad/unparsable/pass-1/review-standards.yaml"
eq "unparsable YAML: exit 2" "$RC" 2
check "unparsable YAML: says so" '[[ $OUT == *"cannot parse YAML"* ]]' "$OUT"

shellcheck_files "shellcheck: check-review-findings.sh and its suite" "$CRF" "$TESTS_DIR/scripts/check-review-findings.sh"

finish
