#!/usr/bin/env bash
# Suite: hooks/evidence-capture.sh (PostToolUse and PostToolUseFailure, Bash): files browser-suite evidence from the Playwright JSON report.
# Covers: command match (default prefix, argv-array command, profile e2e value, env prefix with E2E_INJECT_FAULT=1, --list excluded, run-toolchain.sh --e2e
#   with --task-id / --spec-dir, run-toolchain.sh without --e2e), selection (failing and journey-tagged tests; passing untagged skipped),
#   layout (JRN-### / untagged dirs, retry suffix, name clash counter, base64 bodies decoded, report copy, index JSON), profile
#   e2e_report key, re-run into a task dir replaces earlier output, in-flight spec choice by latest .step, worktree cwd -> main checkout,
#   failure event (PostToolUseFailure payload: error, no tool_response; hookEventName echoed), silence (non-Bash, unrelated command, no specs/), notices (missing / stale report, no in-flight spec), fail-safe exit 0, shellcheck.
# shellcheck disable=SC2016,SC2329  # check expressions (and the helpers they call) are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

new_workdir
P=$WORK/proj
make_fixture_repo "$P"
HOOK=$P/.agents/hooks/evidence-capture.sh
EX=$P/.agents/skills/project-setup/assets/profiles/examples

mkspec() { # mkspec NAME STATUS [UPDATED_AT]
  mkdir -p "$P/specs/$1"
  printf -- '---\nstatus: %s\nbaseline_revision: ""\n---\n# %s\n' "$2" "$1" >"$P/specs/$1/spec.md"
  if [ -n "${3:-}" ]; then printf 'step: "3.10"\nupdated_at: "%s"\n' "$3" >"$P/specs/$1/.step"; fi
}
mkspec 001-old in-progress 2026-10-01T10:00:00Z
mkspec 002-live in-progress 2026-10-15T12:00:00Z
mkspec 003-shipped "done" 2026-10-16T00:00:00Z
mkdir -p "$P/specs/work-backlog" "$P/profiles"
cp "$EX/e2e-browser.md" "$P/profiles/e2e-browser.md"
printf 'specs/*/.step\ntest-results/\n' >"$P/.gitignore"
git_commit_all "$P" fixture

# Playwright output files referenced by the report (absolute paths, as Playwright writes them).
OUT=$P/test-results/e2e
mkdir -p "$OUT/jrn1" "$OUT/jrn2" "$OUT/plain"
echo png1 >"$OUT/jrn1/test-failed-1.png"
echo zip1 >"$OUT/jrn1/trace.zip"
echo png1r >"$OUT/jrn1/retry1.png"
echo png2 >"$OUT/jrn2/test-finished-1.png"
echo png3 >"$OUT/plain/test-failed-1.png"
b64() { printf '%s' "$1" | base64 | tr -d '\n'; }
CONSOLE=$(b64 'pageerror: boom')
NET=$(b64 '500 GET http://localhost:3000/api/cards')

# write_report DIR_ROOT [REPORT_REL] : a JSON report with nested suites: JRN-001 failing (with a retry and a second screenshot,
#   so names clash), JRN-002 passing, an untagged failing test and an untagged passing test.
write_report() {
  local root=$1 rel=${2:-test-results/e2e-results.json}
  mkdir -p "$(dirname "$root/$rel")"
  jq -n --arg o "$OUT" --arg c "$CONSOLE" --arg n "$NET" '
  { config: {}, stats: {expected: 2, unexpected: 2, flaky: 0, skipped: 0},
    suites: [ { title: "journeys", file: "e2e/journeys", specs: [], suites: [
      { title: "jrn-001.spec.ts", file: "e2e/journeys/jrn-001.spec.ts", specs: [
        { title: "JRN-001 expired card shows renewal form", file: "e2e/journeys/jrn-001.spec.ts", line: 4, tags: ["JRN-001"],
          tests: [ { projectName: "chromium", status: "unexpected", results: [
            { retry: 0, status: "failed", attachments: [
              {name: "screenshot", contentType: "image/png", path: ($o + "/jrn1/test-failed-1.png")},
              {name: "screenshot", contentType: "image/png", path: ($o + "/jrn1/test-failed-1.png")},
              {name: "trace", contentType: "application/zip", path: ($o + "/jrn1/trace.zip")},
              {name: "console-errors", contentType: "text/plain", body: $c},
              {name: "network-failures", contentType: "text/plain", body: $n} ] },
            { retry: 1, status: "failed", attachments: [
              {name: "screenshot", contentType: "image/png", path: ($o + "/jrn1/retry1.png")} ] } ] } ] } ] },
      { title: "jrn-002.spec.ts", file: "e2e/journeys/jrn-002.spec.ts", specs: [
        { title: "JRN-002 refund flow", file: "e2e/journeys/jrn-002.spec.ts", line: 3, tags: ["JRN-002", "slow"],
          tests: [ { projectName: "chromium", status: "expected", results: [
            { retry: 0, status: "passed", attachments: [
              {name: "screenshot", contentType: "image/png", path: ($o + "/jrn2/test-finished-1.png")},
              {name: "console-errors", contentType: "text/plain", body: ""} ] } ] } ] } ] } ] },
    { title: "misc.spec.ts", file: "e2e/misc.spec.ts", specs: [
      { title: "header renders", file: "e2e/misc.spec.ts", line: 2, tags: [],
        tests: [ { projectName: "chromium", status: "unexpected", results: [
          { retry: 0, status: "timedOut", attachments: [
            {name: "screenshot", contentType: "image/png", path: ($o + "/plain/test-failed-1.png")} ] } ] } ] },
      { title: "footer renders", file: "e2e/misc.spec.ts", line: 9, tags: [],
        tests: [ { projectName: "chromium", status: "expected", results: [
          { retry: 0, status: "passed", attachments: [
            {name: "screenshot", contentType: "image/png", path: "/nonexistent/never-copied.png"} ] } ] } ] } ] } ] }' >"$root/$rel"
}
write_report "$P"

# hook COMMAND [CWD] [TOOL] : run the hook on a PostToolUse(Bash) payload; sets out and rc.
hook() {
  local c=$1 d=${2:-$P} tool=${3:-Bash} pl
  pl=$(jq -cn --arg c "$c" --arg d "$d" --arg t "$tool" \
    '{session_id:"s",transcript_path:"/x",cwd:$d,hook_event_name:"PostToolUse",tool_name:$t,tool_input:{command:$c},tool_use_id:"u",
      tool_response:{stdout:"",stderr:"",interrupted:false}}')
  out=$(printf '%s' "$pl" | (cd "$d" && bash "$HOOK" 2>/dev/null))
  rc=$?
}
art() { find "$P/specs/$1/artifacts" -mindepth 1 -maxdepth 1 -type d -name "${2:-e2e-*}" 2>/dev/null | sort | tail -1; }
clean_art() { rm -rf "$P"/specs/*/artifacts; }
ctx() { jq -r '.hookSpecificOutput.additionalContext // empty' <<<"$out" 2>/dev/null; }
sysmsg() { jq -r '.systemMessage // empty' <<<"$out" 2>/dev/null; }

# --- silence -------------------------------------------------------------------------------------------------------------------
hook 'npx playwright test' "$P" Write
check "non-Bash tool: silent, exit 0" '[ "$rc" = 0 ] && [ -z "$out" ] && [ ! -d "$P/specs/002-live/artifacts" ]'
hook 'ls -la'
check "unrelated command: silent, nothing filed" '[ "$rc" = 0 ] && [ -z "$out" ] && [ ! -d "$P/specs/002-live/artifacts" ]'
hook 'npx playwright testing'
check "prefix must end at a word boundary" '[ "$rc" = 0 ] && [ -z "$out" ]'
hook 'npx playwright test --list'
check "--list (collect only) is not a suite run" '[ "$rc" = 0 ] && [ -z "$out" ] && [ ! -d "$P/specs/002-live/artifacts" ]'
hook '.agents/skills/feature-workflow/scripts/run-toolchain.sh --spec-dir specs/001-old --task-id T1 --cwd .'
check "run-toolchain.sh without --e2e: silent" '[ "$rc" = 0 ] && [ -z "$out" ] && [ ! -d "$P/specs/001-old/artifacts" ]'
out=$(printf 'not json' | bash "$HOOK" 2>/dev/null); rc=$?
check "unparsable payload: silent, exit 0" '[ "$rc" = 0 ] && [ -z "$out" ]'
out=$(printf '' | bash "$HOOK" 2>/dev/null); rc=$?
check "empty payload: silent, exit 0" '[ "$rc" = 0 ] && [ -z "$out" ]'

# --- direct run: default prefix plus appended flags -----------------------------------------------------------------------------
hook 'npx playwright test --grep @JRN-001 --project chromium'
D=$(art 002-live)
check "direct run: exit 0 with additionalContext" '[ "$rc" = 0 ] && ctx | grep -q "artifacts/e2e-"' "out=$out"
check "filed into the in-flight spec with the latest .step" '[ -n "$D" ] && [ ! -d "$P/specs/001-old/artifacts" ] && [ ! -d "$P/specs/003-shipped/artifacts" ]'
check "run dir named e2e-<UTC timestamp>-<short sha>" 'basename "$D" | grep -Eq "^e2e-[0-9]{8}T[0-9]{6}Z-[0-9a-f]{4,}$"'
check "failing journey: screenshot copied" '[ "$(cat "$D/JRN-001/screenshot.png")" = png1 ]'
check "name clash gets a counter" '[ "$(cat "$D/JRN-001/screenshot-2.png")" = png1 ]'
check "retry suffix" '[ "$(cat "$D/JRN-001/screenshot-retry1.png")" = png1r ]'
check "trace copied with its extension" '[ "$(cat "$D/JRN-001/trace.zip")" = zip1 ]'
eq "console body decoded from base64" "$(cat "$D/JRN-001/console-errors.txt")" "pageerror: boom"
eq "network body decoded" "$(cat "$D/JRN-001/network-failures.txt")" "500 GET http://localhost:3000/api/cards"
check "passing journey: evidence copied too (5.4)" '[ "$(cat "$D/JRN-002/screenshot.png")" = png2 ] && [ -f "$D/JRN-002/console-errors.txt" ] && [ ! -s "$D/JRN-002/console-errors.txt" ]'
check "failing untagged test: filed under untagged/" '[ "$(cat "$D/untagged/screenshot.png")" = png3 ]'
check "passing untagged test: not filed" '! grep -rq never-copied "$D" --include=*.png 2>/dev/null && [ "$(ls "$D/untagged" | wc -l | tr -d " ")" = 1 ]'
check "report copied" 'jq -e ".stats.unexpected == 2" "$D/e2e-results.json" >/dev/null'
IDX=$D/evidence-index.json
check "index: valid JSON with run fields" 'jq -e ".run_id and .captured_at and .command == \"npx playwright test --grep @JRN-001 --project chromium\" and .spec_dir == \"specs/002-live\" and .fault_injected == false and .report == \"e2e-results.json\"" "$IDX" >/dev/null'
eq "index: selected tests (2 journeys + 1 failing untagged)" "$(jq '.tests | length' "$IDX")" 3
eq "index: JRN-001 files" "$(jq -c '[.tests[] | select(.journeys == ["JRN-001"]) | .files[]] | sort' "$IDX")" \
  '["JRN-001/console-errors.txt","JRN-001/network-failures.txt","JRN-001/screenshot-2.png","JRN-001/screenshot-retry1.png","JRN-001/screenshot.png","JRN-001/trace.zip"]'
check "index: status, outcome and retries recorded" 'jq -e "[.tests[] | select(.title == \"header renders\")][0] | .status == \"timedOut\" and .outcome == \"unexpected\" and .retries == 1 and .line == 2" "$IDX" >/dev/null'
check "index: tags kept, journeys filtered to JRN ids" 'jq -e "[.tests[] | select(.title == \"JRN-002 refund flow\")][0] | .tags == [\"JRN-002\",\"slow\"] and .journeys == [\"JRN-002\"]" "$IDX" >/dev/null'
check "index: stats from the report" 'jq -e ".stats.expected == 2" "$IDX" >/dev/null'
check "context names counts" 'ctx | grep -q "for 3 tests (2 failing, 2 journeys)"'
clean_art

# --- argv-array command (Codex) ---------------------------------------------------------------------------------------------------
# hook_argv JSON_ARRAY : like hook, with tool_input.command as an argv array.
hook_argv() {
  local pl
  pl=$(jq -cn --argjson c "$1" --arg d "$P" '{cwd:$d,hook_event_name:"PostToolUse",tool_name:"Bash",tool_input:{command:$c},tool_response:"x"}')
  out=$(printf '%s' "$pl" | (cd "$P" && bash "$HOOK" 2>/dev/null))
  rc=$?
}
hook_argv '["npx","playwright","test","--grep","@JRN-001"]'
D=$(art 002-live)
check "argv array joined: filed, command recorded" '[ "$rc" = 0 ] && [ -n "$D" ] && jq -e ".command == \"npx playwright test --grep @JRN-001\"" "$D/evidence-index.json" >/dev/null' "out=$out"
clean_art
hook_argv '["bash","-lc","E2E_INJECT_FAULT=1 npx playwright test"]'
D=$(art 002-live)
check "argv [bash, -lc, script]: the script is matched" '[ -n "$D" ] && jq -e ".fault_injected == true" "$D/evidence-index.json" >/dev/null' "out=$out"
clean_art
hook_argv '["npx","playwright","test","--list"]'
check "argv array with --list: silent" '[ "$rc" = 0 ] && [ -z "$out" ] && [ ! -d "$P/specs/002-live/artifacts" ]'
hook_argv '["ls","-la"]'
check "argv array, unrelated: silent" '[ "$rc" = 0 ] && [ -z "$out" ]'

# --- env prefix and fault switch --------------------------------------------------------------------------------------------------
hook 'E2E_INJECT_FAULT=1 CI=1 npx playwright test'
D=$(art 002-live)
check "env assignments skipped; fault run recorded" '[ -n "$D" ] && jq -e ".fault_injected == true" "$D/evidence-index.json" >/dev/null && ctx | grep -q "fault-injected"'
clean_art
hook 'CI=1 npx playwright test -x'
D=$(art 002-live)
check "other env prefix: not fault-injected" '[ -n "$D" ] && jq -e ".fault_injected == false" "$D/evidence-index.json" >/dev/null'
clean_art

# --- profile e2e value and e2e_report key ---------------------------------------------------------------------------------------
cp "$P/profiles/e2e-browser.md" "$WORK/profile.bak"
sed -e 's#^e2e: "npx playwright test"#e2e: "pnpm exec playwright test"#' \
  -e 's#^e2e_report: "test-results/e2e-results.json"#e2e_report: "out/pw.json"#' "$WORK/profile.bak" >"$P/profiles/e2e-browser.md"
write_report "$P" out/pw.json
hook 'pnpm exec playwright test --grep @JRN-002'
D=$(art 002-live)
check "profile e2e value matched; report read from e2e_report" '[ -n "$D" ] && jq -e ".report_source | endswith(\"/out/pw.json\")" "$D/evidence-index.json" >/dev/null'
clean_art
cp "$WORK/profile.bak" "$P/profiles/e2e-browser.md"
rm -rf "$P/out"

# --- run-toolchain.sh --e2e: task dir, explicit spec, replacement on re-run -----------------------------------------------------
RT='.agents/skills/feature-workflow/scripts/run-toolchain.sh --spec-dir specs/001-old --task-id e2e-r1 --work-type e2e-browser --cwd "$PWD" --e2e'
mkdir -p "$P/specs/001-old/artifacts/e2e-r1"
echo keep >"$P/specs/001-old/artifacts/e2e-r1/toolchain.txt"
hook "$RT"
D=$P/specs/001-old/artifacts/e2e-r1
check "run-toolchain --e2e: filed under --spec-dir/artifacts/<task-id>/" '[ -f "$D/evidence-index.json" ] && [ -f "$D/JRN-001/screenshot.png" ] && [ ! -d "$P/specs/002-live/artifacts" ]'
hook "$RT"
check "re-run replaces this hook's output, keeps toolchain.txt" '[ ! -e "$D/JRN-001/screenshot-3.png" ] && [ "$(cat "$D/toolchain.txt")" = keep ] && [ "$(ls "$D/JRN-001" | wc -l | tr -d " ")" = 6 ]'
check "unexpanded --cwd ignored: payload cwd used" 'jq -e ".cwd == \"$P\"" "$D/evidence-index.json" >/dev/null'
clean_art

# --- worktree: report in the worktree, evidence in the main checkout ------------------------------------------------------------
git -C "$P" worktree add -q --detach "$WORK/wt" HEAD
write_report "$WORK/wt"
mv "$P/test-results/e2e-results.json" "$WORK/main-report.json"
hook 'npx playwright test' "$WORK/wt"
D=$(art 002-live)
check "worktree run: evidence in the main checkout" '[ -n "$D" ] && [ -f "$D/JRN-001/trace.zip" ] && [ ! -d "$WORK/wt/specs/002-live/artifacts" ]'
check "worktree run: report read from the worktree" 'jq -e ".report_source == \"$WORK/wt/test-results/e2e-results.json\"" "$D/evidence-index.json" >/dev/null'
clean_art
mv "$WORK/main-report.json" "$P/test-results/e2e-results.json"

# --- notices for a matched run that cannot be filed -----------------------------------------------------------------------------
mv "$P/test-results/e2e-results.json" "$WORK/r.json"
hook 'npx playwright test'
check "missing report: systemMessage, nothing filed" '[ "$rc" = 0 ] && sysmsg | grep -q "no JSON report" && [ ! -d "$P/specs/002-live/artifacts" ]'
mv "$WORK/r.json" "$P/test-results/e2e-results.json"
touch -t 202001010000 "$P/test-results/e2e-results.json"
hook 'npx playwright test'
check "stale report: systemMessage, nothing filed" '[ "$rc" = 0 ] && sysmsg | grep -q "older than" && [ ! -d "$P/specs/002-live/artifacts" ]'
touch "$P/test-results/e2e-results.json"
echo '{"not":"a report"}' >"$WORK/bad.json"
cp "$P/test-results/e2e-results.json" "$WORK/good.json"
cp "$WORK/bad.json" "$P/test-results/e2e-results.json"
hook 'npx playwright test'
check "non-Playwright JSON: systemMessage" '[ "$rc" = 0 ] && sysmsg | grep -q "not a Playwright JSON report"'
cp "$WORK/good.json" "$P/test-results/e2e-results.json"

# --- spec choice ----------------------------------------------------------------------------------------------------------------
mkspec 001-old "done"
mkspec 002-live in-review
rm -f "$P/specs/002-live/.step"
hook 'npx playwright test'
check "single in-flight spec without .step is chosen" '[ -n "$(art 002-live)" ]'
clean_art
mkspec 002-live draft
hook 'npx playwright test'
check "no in-flight spec: systemMessage, nothing filed" '[ "$rc" = 0 ] && sysmsg | grep -q "no in-flight spec" && [ -z "$(find "$P/specs" -name evidence-index.json)" ]'
mkspec 004-blocked blocked 2026-10-16T01:00:00Z
mkspec 005-ready ready-for-dev 2026-10-16T02:00:00Z
hook 'npx playwright test'
check "latest .step wins across ready-for-dev and blocked (1.4 runs at ready-for-dev)" '[ -n "$(art 005-ready)" ] && [ -z "$(art 004-blocked)" ]'
clean_art

# --- PostToolUseFailure (a failing suite exits non-zero; 2.1.303 fires only this event for it, F-1) ---------------------------------
clean_art
pl=$(jq -cn --arg d "$P" '{session_id:"s",transcript_path:"/x",cwd:$d,hook_event_name:"PostToolUseFailure",tool_name:"Bash",
  tool_input:{command:"npx playwright test --grep @JRN-001",description:"Run suite"},tool_use_id:"u",error:"Exit code 1\n1 failed",is_interrupt:false,duration_ms:4187}')
out=$(printf '%s' "$pl" | (cd "$P" && bash "$HOOK" 2>/dev/null)); rc=$?
D=$(art 005-ready)
check "failure event: filed, exit 0, hookEventName echoed" '[ "$rc" = 0 ] && [ "$(jq -r .hookSpecificOutput.hookEventName <<<"$out")" = PostToolUseFailure ] && ctx | grep -q "artifacts/e2e-" && [ "$(cat "$D/JRN-001/screenshot.png")" = png1 ]' "out=$out"
pl=$(jq -cn --arg d "$P" '{cwd:$d,hook_event_name:"PostToolUseFailure",tool_name:"Bash",tool_input:{command:"ls"},error:"Exit code 2",is_interrupt:false}')
clean_art
out=$(printf '%s' "$pl" | (cd "$P" && bash "$HOOK" 2>/dev/null)); rc=$?
check "failure event, unrelated command: silent, exit 0" '[ "$rc" = 0 ] && [ -z "$out" ] && [ ! -d "$P/specs/005-ready/artifacts" ]'
pl=$(jq -cn --arg d "$P" '{cwd:$d,hook_event_name:"PostToolUseFailure",tool_name:"Write",tool_input:{command:"npx playwright test"},error:"x"}')
out=$(printf '%s' "$pl" | (cd "$P" && bash "$HOOK" 2>/dev/null)); rc=$?
check "failure event, non-Bash tool: silent, exit 0" '[ "$rc" = 0 ] && [ -z "$out" ]'
clean_art

# --- no workflow ----------------------------------------------------------------------------------------------------------------
Q=$WORK/plain
git_init_repo "$Q"
copy_agents "$Q"
write_report "$Q"
pl=$(jq -cn --arg d "$Q" '{cwd:$d,hook_event_name:"PostToolUse",tool_name:"Bash",tool_input:{command:"npx playwright test"}}')
out=$(printf '%s' "$pl" | bash "$Q/.agents/hooks/evidence-capture.sh" 2>/dev/null); rc=$?
check "project without specs/: silent" '[ "$rc" = 0 ] && [ -z "$out" ]'

shellcheck_files "shellcheck evidence-capture.sh" "$HOOK"
finish
