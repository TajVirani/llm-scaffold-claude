#!/usr/bin/env bash
# Suite: check-task-result.sh (feature-workflow/scripts).
# Covers: one valid file per kind (implementation, integration, mini-review) with its header line and rows, a stop status's
#   line, the kind taken from the file name and from --kind, one malformed file per shape rule (exit 1, the message names
#   the field), task_id against the artifacts folder, a mini-review verdict that disagrees with its items, carried_from
#   outside re-check mode, a multi-document file, and the exit-2 cases: no argument, missing file, YAML that does not parse,
#   a name that implies no kind, an unknown --kind.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

new_workdir
copy_agents "$WORK/scaffold"
CTR="$WORK/scaffold/.agents/skills/feature-workflow/scripts/check-task-result.sh"
TAB=$'\t'
ART="$WORK/spec/artifacts"

# row FIELD... : join the fields with tabs, the way the script prints a table row.
row() {
  local IFS=$TAB
  printf '%s' "$*"
}

# run_ctr ARGS... : run the script, capturing stdout and stderr in OUT and the exit code in RC.
run_ctr() {
  OUT=$("$CTR" "$@" 2>&1)
  RC=$?
}

# line N : print line N of OUT.
line() { sed -n "${1}p" <<<"$OUT"; }

# variant SRC DEST YQ_EXPR : write SRC with one yq edit applied to DEST (directories created).
variant() {
  mkdir -p "$(dirname "$2")"
  yq "$3" "$1" >"$2"
}

# expect_error NAME FILE YQ_EXPR PREFIX [--kind K] : a copy of FILE with YQ_EXPR applied exits 1 with a line
# starting PREFIX. The copy keeps FILE's name, in its own folder, so the kind still comes from the name.
N=0
expect_error() {
  local name=$1 src=$2 expr=$3 prefix=$4 dest
  shift 4
  N=$((N + 1))
  dest="$WORK/bad/$N/$(basename "$src")"
  variant "$src" "$dest" "$expr"
  run_ctr "$dest" "$@"
  if [[ $RC == 1 ]] && grep -q "^$prefix" <<<"$OUT"; then ok "$name"; else ko "$name" "rc=$RC want=1 and a line starting '$prefix': $OUT"; fi
}

# --- implementation: a valid file in artifacts/T1/
IMPL="$ART/T1/implementation.yaml"
mkdir -p "$ART/T1"
cat >"$IMPL" <<'Y'
status: done
summary: "check-task-result.sh validates the three result files.
  It prints a bounded table."
task_id: T1
worktree: /work/wt-T1
branch: task/T1
base_commit: 1a2b3c4d
head_commit: 9f8e7d6c5b4a
files_changed: [.agents/skills/feature-workflow/scripts/check-task-result.sh, tests/scripts/check-task-result.sh]
tests_added:
  - {file: tests/scripts/check-task-result.sh, test: valid implementation file, kind: behaviour}
  - {file: tests/scripts/check-task-result.sh, test: valid mini-review file, kind: behaviour}
  - {file: tests/scripts/check-task-result.sh, test: bad status, kind: negative}
  - {file: tests/scripts/check-task-result.sh, test: multi-document file, kind: edge}
evidence:
  red: "tests/run-all.sh --suite check-task-result; FAIL valid implementation file"
  green: "tests/run-all.sh --suite check-task-result; 40/40 passed"
  suite: run-toolchain.sh shell-scripts; test pass
  toolchain: .workflow/specs/005-x/artifacts/T1/toolchain.txt (pass)
considered_not_built: ["a JSON output mode: nothing reads it"]
profile_wrong: null
scope_expansion: null
blocked: null
discovered_work:
  - kind: bug
    summary: "run-all.sh drops a suite's detail line"
    evidence: "tests/run-all.sh:210"
    blocker_assessment: can-wait
    reason: "unrelated to this task"
Y

run_ctr "$IMPL"
eq "a valid implementation file exits 0" "$RC" 0
eq "the implementation header line" "$(line 1)" \
  "status: done  task: T1  head: 9f8e7d6  files: 2  tests: 4 (behaviour 2, negative 1, edge 1)  discovered_work: 1"
eq "the implementation summary line joins the summary onto one line" "$(line 2)" \
  "summary: check-task-result.sh validates the three result files. It prints a bounded table."
eq "the implementation discovered-work row" "$(line 3)" \
  "$(row bug can-wait tests/run-all.sh:210 "run-all.sh drops a suite's detail line")"
eq "a done implementation prints no stop line" "$(wc -l <<<"$OUT" | tr -d ' ')" 3

# Stop statuses print the stop field; a null head_commit is allowed for them and prints as "-".
STOP="$ART/T2/implementation.yaml"
variant "$IMPL" "$STOP" '.task_id = "T2" | .status = "blocked" | .head_commit = null | .discovered_work = []
  | .blocked = {"reason": "the fixture repo has no main branch", "tried": "git init", "needed": "a main branch"}'
run_ctr "$STOP"
eq "a blocked implementation with a null head exits 0" "$RC" 0
eq "a null head prints as a dash" "$(line 1)" \
  "status: blocked  task: T2  head: -  files: 2  tests: 4 (behaviour 2, negative 1, edge 1)  discovered_work: 0"
eq "a blocked implementation ends with blocked.reason" "$(line 3)" "blocked.reason: the fixture repo has no main branch"

variant "$IMPL" "$WORK/stop-sx/implementation.yaml" '.status = "scope-expansion" | .scope_expansion = {"requested_paths": ["install.sh", "README.md"], "reason": "r"}'
run_ctr "$WORK/stop-sx/implementation.yaml"
eq "a scope-expansion implementation ends with the requested paths" "$(tail -n 1 <<<"$OUT")" \
  "scope_expansion.requested_paths: install.sh, README.md"

variant "$IMPL" "$WORK/stop-pw/implementation.yaml" '.status = "profile-wrong" | .profile_wrong = {"section": "Toolchain", "line": "lint: shellcheck", "problem": "p", "needed": "n"}'
run_ctr "$WORK/stop-pw/implementation.yaml"
eq "a profile-wrong implementation ends with profile_wrong.line" "$(tail -n 1 <<<"$OUT")" "profile_wrong.line: lint: shellcheck"

# A Phase 1 result sits in artifacts/phase-1-<work_type>/ and names that folder as its task_id.
variant "$IMPL" "$ART/phase-1-test-harness/implementation.yaml" '.task_id = "phase-1-test-harness"'
run_ctr "$ART/phase-1-test-harness/implementation.yaml"
eq "a Phase 1 implementation file whose task_id is its folder exits 0" "$RC" 0

# A file outside artifacts/ is not held to a folder name.
variant "$IMPL" "$WORK/loose/implementation.yaml" '.task_id = "T9"'
run_ctr "$WORK/loose/implementation.yaml"
eq "outside artifacts/ any task_id is accepted" "$RC" 0

# --- integration: a valid partial batch
INTEG="$ART/integration-shell-scripts/integration.yaml"
mkdir -p "$(dirname "$INTEG")"
cat >"$INTEG" <<'Y'
status: partial
summary: "Added wf_path_join to workflow-paths.sh; request 2 is not shared core."
work_type: shell-scripts
worktree: /work/main
branch: null
base_commit: 1a2b3c4
head_commit: 5d6e7f8a
requests:
  - n: 1
    verdict: applied
    reason: "adds wf_path_join"
    interface: "wf_path_join DIR NAME"
    awaiting_contract: []
    tests: ["tests/scripts/cache-scripts.sh: joins paths"]
  - n: 2
    verdict: reject-not-shared-core
    reason: "check-write.sh belongs to feature-workflow"
  - n: 3
    verdict: conflict
    reason: "request 1 renames the same function"
files_changed: [.agents/lib/workflow-paths.sh]
evidence:
  toolchain: .workflow/specs/005-x/artifacts/integration-shell-scripts/toolchain.txt (pass)
  tests: "tests/run-all.sh; all passed"
  callers_checked: []
profile_wrong: null
blocked: null
discovered_work:
  - kind: refactor
    summary: "two helpers build the same path"
    evidence: ".agents/lib/workflow-paths.sh:40"
    blocker_assessment: can-wait
    reason: "cosmetic"
Y

run_ctr "$INTEG"
eq "a valid integration file exits 0" "$RC" 0
eq "the integration header line" "$(line 1)" \
  "status: partial  work_type: shell-scripts  head: 5d6e7f8  requests: 3 (applied 1, rejected 1, conflict 1, blocked 0)  discovered_work: 1"
eq "the integration request rows, in file order" "$(sed -n '2,4p' <<<"$OUT")" "$(row 1 applied "adds wf_path_join")
$(row 2 reject-not-shared-core "check-write.sh belongs to feature-workflow")
$(row 3 conflict "request 1 renames the same function")"
eq "the integration discovered-work row" "$(line 5)" \
  "$(row refactor can-wait .agents/lib/workflow-paths.sh:40 "two helpers build the same path")"

# --- mini-review: a valid re-check that fails one item
MINI="$ART/T1/mini-review.yaml"
cat >"$MINI" <<'Y'
verdict: fail
task_id: T1
work_type: shell-scripts
diff: /work/wt-T1@1a2b3c4..9f8e7d6
tool_output: .workflow/specs/005-x/artifacts/T1/toolchain.json
mode: re-check
previous: .workflow/specs/005-x/artifacts/T1/mini-review-r1.yaml
items:
  - {n: 1, verdict: not-applicable, location: "", carried_from: r1}
  - {n: 2, verdict: pass, location: "check-task-result.sh:60", carried_from: r1}
  - {n: 3, verdict: tool-covered, location: "check-task-result.sh:12", note: "lint: shellcheck SC2086"}
  - {n: R3, verdict: fail, location: "check-task-result.sh:88, check-task-result.sh:91", note: "the comment restates the case below it; delete it"}
  - {n: R4, verdict: pass, location: "check-task-result.sh:1"}
read_outside_diff: ["tests/lib/common.sh: helper names"]
out_of_scope_noticed:
  - kind: decision
    summary: "the 120-character cut may hide a long reason"
    evidence: "check-task-result.sh:70"
    blocker_assessment: can-wait
    reason: "the file holds the full text"
Y

run_ctr "$MINI"
eq "a valid mini-review file exits 0" "$RC" 0
eq "the mini-review header line" "$(line 1)" \
  "verdict: fail  task: T1  mode: re-check  items: 5 (pass 2, fail 1, tool-covered 1, not-applicable 1, carried 2)  out_of_scope: 1"
eq "the mini-review rows list only tool-covered and fail items, in file order" "$(sed -n '2,3p' <<<"$OUT")" \
  "$(row 3 tool-covered check-task-result.sh:12 "lint: shellcheck SC2086")
$(row R3 fail "check-task-result.sh:88, check-task-result.sh:91" "the comment restates the case below it; delete it")"
eq "the mini-review out-of-scope row" "$(line 4)" \
  "$(row decision can-wait check-task-result.sh:70 "the 120-character cut may hide a long reason")"

FULL="$ART/T1/mini-review-full.yaml"
variant "$MINI" "$FULL" '.mode = "full" | .previous = null | .verdict = "pass" | del(.items[].carried_from)
  | .items[3].verdict = "pass" | del(.items[3].note)'
run_ctr "$FULL"
eq "a passing full mini-review exits 0" "$RC" 0
eq "a passing full mini-review header counts no carried items" "$(line 1)" \
  "verdict: pass  task: T1  mode: full  items: 5 (pass 3, fail 0, tool-covered 1, not-applicable 1, carried 0)  out_of_scope: 1"

# --- the kind: from the name, or from --kind
cp "$INTEG" "$WORK/integration-r1.yaml"
run_ctr "$WORK/integration-r1.yaml"
check "an integration-r1.yaml name is read as integration" '[[ $RC == 0 && $(line 1) == "status: partial  work_type: shell-scripts  "* ]]' "$OUT"
cp "$MINI" "$WORK/result.yaml"
run_ctr "$WORK/result.yaml" --kind mini-review
eq "--kind mini-review checks a file whose name implies no kind" "$RC" 0
run_ctr --kind mini-review "$WORK/result.yaml"
eq "--kind may come before the file" "$RC" 0
cp "$MINI" "$WORK/implementation-copy.yaml"
run_ctr "$WORK/implementation-copy.yaml" --kind mini-review
eq "--kind wins over the kind the name implies" "$RC" 0
run_ctr "$WORK/implementation-copy.yaml"
check "a mini-review block named implementation*.yaml is checked as implementation and fails" \
  '[[ $RC == 1 && $OUT == *"status: "* ]]' "$OUT"

# --- implementation shape rules, one breach each
expect_error "implementation: unknown status" "$IMPL" '.status = "finished"' "status: 'finished' is not one of"
expect_error "implementation: empty summary" "$IMPL" '.summary = ""' "summary: "
expect_error "implementation: summary not a string" "$IMPL" '.summary = ["a"]' "summary: "
expect_error "implementation: missing task_id" "$IMPL" 'del(.task_id)' "task_id: missing"
variant "$IMPL" "$ART/T7/implementation.yaml" '.task_id = "T1"'
run_ctr "$ART/T7/implementation.yaml"
check "implementation: a task_id other than the artifacts folder is refused" \
  '[[ $RC == 1 && $OUT == "task_id: '"'"'T1'"'"' does not match the artifacts folder T7" ]]' "$OUT"
expect_error "implementation: missing worktree" "$IMPL" 'del(.worktree)' "worktree: "
expect_error "implementation: empty base_commit" "$IMPL" '.base_commit = ""' "base_commit: "
expect_error "implementation: branch a list" "$IMPL" '.branch = ["a"]' "branch: not a string or null"
expect_error "implementation: head_commit not hex" "$IMPL" '.head_commit = "zz12345"' "head_commit: 'zz12345' is not 7 to 40 hex"
expect_error "implementation: head_commit too short" "$IMPL" '.head_commit = "abc12"' "head_commit: 'abc12'"
expect_error "implementation: null head_commit on a done status" "$IMPL" '.head_commit = null' "head_commit: missing"
expect_error "implementation: files_changed not a list" "$IMPL" '.files_changed = "a.sh"' "files_changed: not a list"
expect_error "implementation: files_changed holds a non-string" "$IMPL" '.files_changed[1] = {"a": 1}' "files_changed\\[1\\]: not a string"
expect_error "implementation: tests_added not a list" "$IMPL" '.tests_added = {}' "tests_added: not a list"
expect_error "implementation: tests_added entry without a test name" "$IMPL" 'del(.tests_added[0].test)' "tests_added\\[0\\].test: "
expect_error "implementation: tests_added kind unknown" "$IMPL" '.tests_added[2].kind = "unit"' "tests_added\\[2\\].kind: 'unit'"
expect_error "implementation: evidence not a mapping" "$IMPL" '.evidence = "ran it"' "evidence: not a mapping"
expect_error "implementation: evidence without toolchain" "$IMPL" 'del(.evidence.toolchain)' "evidence.toolchain: "
expect_error "implementation: considered_not_built not a list" "$IMPL" '.considered_not_built = "none"' "considered_not_built: not a list"
expect_error "implementation: profile_wrong a string" "$IMPL" '.profile_wrong = "no"' "profile_wrong: not null or a mapping"
expect_error "implementation: scope_expansion a list" "$IMPL" '.scope_expansion = []' "scope_expansion: not null or a mapping"
expect_error "implementation: blocked a string" "$IMPL" '.blocked = "no"' "blocked: not null or a mapping"
expect_error "implementation: discovered_work not a list" "$IMPL" '.discovered_work = {}' "discovered_work: not a list"
expect_error "implementation: discovered_work kind unknown" "$IMPL" '.discovered_work[0].kind = "chore"' "discovered_work\\[0\\].kind: 'chore'"
expect_error "implementation: discovered_work without summary" "$IMPL" 'del(.discovered_work[0].summary)' "discovered_work\\[0\\].summary: "
expect_error "implementation: discovered_work without evidence" "$IMPL" '.discovered_work[0].evidence = ""' "discovered_work\\[0\\].evidence: "
expect_error "implementation: discovered_work bad blocker_assessment" "$IMPL" '.discovered_work[0].blocker_assessment = "later"' \
  "discovered_work\\[0\\].blocker_assessment: 'later'"
expect_error "implementation: discovered_work without reason" "$IMPL" 'del(.discovered_work[0].reason)' "discovered_work\\[0\\].reason: "
expect_error "implementation: profile-wrong without profile_wrong.line" "$IMPL" '.status = "profile-wrong"' "profile_wrong.line: "
expect_error "implementation: scope-expansion without requested paths" "$IMPL" \
  '.status = "scope-expansion" | .scope_expansion = {"requested_paths": [], "reason": "r"}' "scope_expansion.requested_paths: "
expect_error "implementation: blocked without blocked.reason" "$IMPL" '.status = "blocked"' "blocked.reason: "
expect_error "implementation: discovered-work with no entries" "$IMPL" '.status = "discovered-work" | .discovered_work = []' \
  "discovered_work: empty, required"

# Two breaches in one file give two lines.
variant "$IMPL" "$WORK/two/implementation.yaml" '.status = "x" | .summary = ""'
run_ctr "$WORK/two/implementation.yaml"
check "two breaches in one file give two lines and exit 1" '[[ $RC == 1 && $(wc -l <<<"$OUT" | tr -d " ") == 2 ]]' "$OUT"

# --- integration shape rules
expect_error "integration: unknown status" "$INTEG" '.status = "applied"' "status: 'applied' is not one of"
expect_error "integration: empty summary" "$INTEG" '.summary = ""' "summary: "
expect_error "integration: missing work_type" "$INTEG" 'del(.work_type)' "work_type: "
expect_error "integration: missing worktree" "$INTEG" 'del(.worktree)' "worktree: "
expect_error "integration: missing base_commit" "$INTEG" 'del(.base_commit)' "base_commit: "
expect_error "integration: branch a number" "$INTEG" '.branch = 3' "branch: not a string or null"
expect_error "integration: head_commit not hex" "$INTEG" '.head_commit = "HEAD"' "head_commit: 'HEAD'"
expect_error "integration: requests not a list" "$INTEG" '.requests = "all"' "requests: not a list"
expect_error "integration: request n not an integer" "$INTEG" '.requests[0].n = "one"' "requests\\[0\\].n: 'one'"
expect_error "integration: request verdict unknown" "$INTEG" '.requests[1].verdict = "rejected"' "requests\\[1\\].verdict: 'rejected'"
expect_error "integration: request without reason" "$INTEG" 'del(.requests[2].reason)' "requests\\[2\\].reason: "
expect_error "integration: partial with every request applied" "$INTEG" '.requests[1].verdict = "applied" | .requests[2].verdict = "applied"' \
  "requests: status is partial but every verdict is applied"
expect_error "integration: files_changed not a list" "$INTEG" '.files_changed = null' "files_changed: not a list"
expect_error "integration: evidence without toolchain" "$INTEG" '.evidence.toolchain = ""' "evidence.toolchain: "
expect_error "integration: discovered_work entry bad kind" "$INTEG" '.discovered_work[0].kind = "x"' "discovered_work\\[0\\].kind: "
expect_error "integration: profile_wrong a list" "$INTEG" '.profile_wrong = []' "profile_wrong: not null or a mapping"
expect_error "integration: blocked a string" "$INTEG" '.blocked = "b"' "blocked: not null or a mapping"

# --- mini-review shape rules
expect_error "mini-review: unknown verdict" "$MINI" '.verdict = "ok"' "verdict: 'ok' is not one of"
expect_error "mini-review: missing task_id" "$MINI" 'del(.task_id)' "task_id: "
expect_error "mini-review: missing work_type" "$MINI" 'del(.work_type)' "work_type: "
expect_error "mini-review: empty diff" "$MINI" '.diff = ""' "diff: "
expect_error "mini-review: missing tool_output" "$MINI" 'del(.tool_output)' "tool_output: "
expect_error "mini-review: unknown mode" "$MINI" '.mode = "partial"' "mode: 'partial' is not one of"
expect_error "mini-review: re-check without previous" "$MINI" '.previous = null' "previous: missing or empty, required when mode is re-check"
expect_error "mini-review: full mode with a previous file" "$FULL" '.previous = "mini-review-r1.yaml"' "previous: must be null"
expect_error "mini-review: empty items" "$MINI" '.items = []' "items: not a non-empty list"
expect_error "mini-review: item n out of range" "$MINI" '.items[4].n = "R6"' "items\\[4\\].n: 'R6'"
expect_error "mini-review: item verdict unknown" "$MINI" '.items[0].verdict = "skip"' "items\\[0\\].verdict: 'skip'"
expect_error "mini-review: item without location" "$MINI" 'del(.items[1].location)' "items\\[1\\].location: "
expect_error "mini-review: fail item without note" "$MINI" 'del(.items[3].note)' "items\\[3\\].note: missing or empty, required when the verdict is fail"
expect_error "mini-review: tool-covered item without note" "$MINI" '.items[2].note = ""' "items\\[2\\].note: missing or empty, required when the verdict is tool-covered"
expect_error "mini-review: carried_from not r<k>" "$MINI" '.items[0].carried_from = "round1"' "items\\[0\\].carried_from: 'round1' is not r<k>"
expect_error "mini-review: carried_from in full mode" "$FULL" '.items[0].carried_from = "r1"' "items\\[0\\].carried_from: allowed only when mode is re-check"
expect_error "mini-review: verdict fail with no failed item" "$FULL" '.verdict = "fail"' "verdict: fail but no item is fail"
expect_error "mini-review: verdict pass with a failed item" "$MINI" '.verdict = "pass"' "verdict: pass but an item is fail"
expect_error "mini-review: read_outside_diff not a list" "$MINI" '.read_outside_diff = "none"' "read_outside_diff: not a list"
expect_error "mini-review: out_of_scope_noticed entry without reason" "$MINI" 'del(.out_of_scope_noticed[0].reason)' \
  "out_of_scope_noticed\\[0\\].reason: "

# --- root shape
mkdir -p "$WORK/multi"
printf -- '---\nverdict: pass\n---\nverdict: fail\n' >"$WORK/multi/mini-review.yaml"
run_ctr "$WORK/multi/mini-review.yaml"
check "a multi-document file is a root shape error" '[[ $RC == 1 && $OUT == "root: expected one YAML document, found 2" ]]' "$OUT"
mkdir -p "$WORK/list"
printf -- '- status: done\n' >"$WORK/list/implementation.yaml"
run_ctr "$WORK/list/implementation.yaml"
check "a list at the root is a root shape error" '[[ $RC == 1 && $OUT == "root: not a mapping" ]]' "$OUT"

# --- exit 2: usage, files and kinds
run_ctr
eq "no argument exits 2" "$RC" 2
run_ctr "$IMPL" "$MINI"
eq "two files exit 2" "$RC" 2
run_ctr "$IMPL" --kind
eq "--kind without a value exits 2" "$RC" 2
run_ctr "$WORK/missing/implementation.yaml"
eq "a missing file exits 2" "$RC" 2
check "the missing file is named on stderr" '[[ $OUT == *"no such file"*missing/implementation.yaml* ]]' "$OUT"
mkdir -p "$WORK/broken"
printf 'status: [done\n' >"$WORK/broken/implementation.yaml"
run_ctr "$WORK/broken/implementation.yaml"
eq "YAML that does not parse exits 2" "$RC" 2
check "the parse failure is reported" '[[ $OUT == *"cannot parse YAML"* ]]' "$OUT"
run_ctr "$WORK/result.yaml"
eq "a name that implies no kind exits 2" "$RC" 2
check "the message asks for --kind" '[[ $OUT == *"--kind"* ]]' "$OUT"
run_ctr "$WORK/result.yaml" --kind review
eq "an unknown --kind exits 2" "$RC" 2
check "the unknown kind is named" '[[ $OUT == *"unknown kind '"'"'review'"'"'"* ]]' "$OUT"

shellcheck_files "check-task-result.sh is shellcheck clean" "$AGENTS_SRC/skills/feature-workflow/scripts/check-task-result.sh" "${BASH_SOURCE[0]}"

finish
