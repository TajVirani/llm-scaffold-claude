#!/usr/bin/env bash
# Install end-to-end check (Claude Code): install.sh into a sample target (twice), seed minimal workflow data by hand, then verify the
# installed hooks and deny rules in two headless runs. Scaffold-only harness; not part of the install payload (D30).
# Usage: PLAN/install-e2e/run.sh [model]          (default model: haiku; about $0.06 for all five runs: base about $0.015, follow-up about $0.045)
#   E2E_BASE=<dir>     parent of the fresh temp work dir (default: ${TMPDIR:-/tmp})
#   E2E_SKIP_CLAUDE=1  install + seed + idempotence + follow-up seed only, no headless runs (free)
#   E2E_SKIP_BASE=1    skip the base runs run1/run2 (section 3) and run only the follow-up runs f1-f3 (section 5)
# Follow-up (section 5, PLAN/install-e2e.md "Follow-up run"): model switch via model-map, spec single-writer guard, rules -> boundary
#   config sync, evidence-capture with a fake Playwright report, implementation sub-agent in a worktree (Tier A/B guards, SubagentStop audit).
# Requires: claude, jq, git, mikefarah yq v4 on PATH. Headless runs use --permission-mode bypassPermissions inside the temp project only.
# Results: printed at the end and kept in <work>/runs/ (stream-json transcripts, per-run tool-call summaries). Compare with PLAN/install-e2e.md.
# The transcripts contain session ids and home paths: they stay in the temp dir and are not committed.
set -euo pipefail
REPO=$(cd "$(dirname "$0")/../.." && pwd -P)
MODEL=${1:-haiku}
BASE=${E2E_BASE:-${TMPDIR:-/tmp}}
mkdir -p "$BASE"
W=$(cd "$(mktemp -d "$BASE/install-e2e.XXXXXX")" && pwd -P)
P=$W/proj R=$W/runs
mkdir -p "$P" "$R"
echo "work dir: $W"
yq --version | grep -q mikefarah || { echo "mikefarah yq v4 required on PATH" >&2; exit 2; }
G() { git -C "$P" -c user.name=e2e -c user.email=e2e@example.invalid "$@"; }

# ── 1. Sample TS-ish target with a pre-existing .claude/settings.json (user env key, permissions, user hook) ──
mkdir -p "$P/src" "$P/.claude"
cat > "$P/package.json" <<'J'
{ "name": "e2e-sample", "version": "0.1.0", "type": "module", "scripts": { "test": "true" } }
J
cat > "$P/tsconfig.json" <<'J'
{ "compilerOptions": { "strict": true, "target": "ES2022", "module": "ESNext" }, "include": ["src"] }
J
printf 'export function add(a: number, b: number): number {\n  return a + b;\n}\n' > "$P/src/math.ts"
printf 'import { add } from "./math";\n\nconsole.log(add(1, 2));\n' > "$P/src/index.ts"
cat > "$P/.claude/settings.json" <<'J'
{
  "env": { "E2E_USER_KEY": "kept" },
  "permissions": { "allow": ["Bash(npm test:*)"], "deny": ["Read(./.env)"] },
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [ { "type": "command", "command": "jq -c '{cmd: .tool_input.command}' >> \"$CLAUDE_PROJECT_DIR\"/.claude/user-hook.log" } ] }
    ]
  }
}
J
G init -q && G add -A && G commit -qm "sample project"
cp "$P/.claude/settings.json" "$R/settings.before.json"

snap() { (cd "$P" && find . -path ./.git -prune -o \( -type f -o -type l \) -print | LC_ALL=C sort | while read -r f; do
  if [ -L "$f" ]; then echo "$f -> $(readlink "$f")"; else echo "$f $(shasum "$f" | cut -c1-12)"; fi; done); }
rc=0; "$REPO/install.sh" "$P" --host claude > "$R/install1.log" 2>&1 || rc=$?
echo "install 1 exit $rc"; [ "$rc" = 0 ] || { cat "$R/install1.log"; exit 1; }
cp "$P/.claude/settings.json" "$R/settings.after1.json"
snap > "$R/snap1.txt"
rc=0; "$REPO/install.sh" "$P" --host claude > "$R/install2.log" 2>&1 || rc=$?
echo "install 2 exit $rc"
snap > "$R/snap2.txt"
if diff -u "$R/snap1.txt" "$R/snap2.txt" > "$R/idempotence.diff"; then echo "idempotence: no file changed on re-run"
else echo "idempotence: FILES CHANGED"; cat "$R/idempotence.diff"; fi
echo "== install 1 output"; cat "$R/install1.log"
echo "== install 2 output"; cat "$R/install2.log"
echo "== merged settings.json"; cat "$P/.claude/settings.json"
echo "== .gitignore"; cat "$P/.gitignore"

# ── 2. Minimal workflow data, by hand (no project-setup toolchain installs) ──
A=$P/.agents/skills/project-setup/assets
cat > "$P/GLOSSARY.md" <<'M'
# Sample

A sample project for the install end-to-end check.

## Language

**Adder**:
The function that sums two numbers.
_Avoid_: summer
M
mkdir -p "$P/docs/cache" "$P/model-map" "$P/profiles" "$P/specs/001-demo"
cp "$A/docs/rules.md" "$P/docs/rules.md"
touch "$P/docs/cache/.gitkeep"
cat > "$P/model-map/fact-lookup.md" <<'M'
---
tier: cheap
claude: haiku
codex: gpt-6-luna
---
# fact-lookup

## Why this model

Cheap tier: read-only fact finding.

## Observations
M
cat > "$P/profiles/ts.md" <<'M'
# Profile: ts

## File locations

- Source: `src/`. Never in `dist/`.

## Approved libraries per concern

- Testing: none yet. Do not add one.

## Language and style rules

- Strict TypeScript.

## Toolchain

```yaml
lint: "true"
typecheck: "true"
format: "true"
boundary: "true"
test: "true"
e2e: ""
serve: ""
serve_ready: ""
config:
  lint: ""
  typecheck: ""
rule_set: "none"
```

## Mini-review checklist

- Nothing yet.
M
cp "$P/.agents/skills/feature-workflow/assets/spec.md" "$P/specs/001-demo/spec.md"
ST=$P/.agents/skills/feature-workflow/scripts/status-transition.sh
(cd "$P" && "$ST" status specs/001-demo draft --step 0.1.4) > "$R/seed.log" 2>&1
G add -A && G commit -qm "seed workflow data"
echo "== seeded .step"; cat "$P/specs/001-demo/.step"
printf '== .step gitignored: '; (cd "$P" && git check-ignore -q specs/001-demo/.step && echo yes) || echo NO
# Logging only: record PostToolUse(Agent) payloads (rewritten tool_input, resolvedModel). Kept out of the merged settings.json.
cat > "$P/.claude/settings.local.json" <<'J'
{ "hooks": { "PostToolUse": [ { "matcher": "Agent", "hooks": [ { "type": "command", "command": "jq -c . >> \"$CLAUDE_PROJECT_DIR\"/.claude/agent-post.jsonl" } ] } ] } }
J
HEAD0=$(G rev-parse HEAD)

# ── 3. Headless runs ──
run() { # name max-turns prompt
  (cd "$P" && claude -p --model "$MODEL" --max-turns "$2" --permission-mode bypassPermissions \
     --output-format stream-json --verbose "$3") > "$R/$1.jsonl" 2> "$R/$1.err" || echo "$1: claude exited $?"
}
FENCE='```'
HDR="${FENCE}yaml launch-header
task_type: fact-lookup
spec_dir: specs/001-demo
${FENCE}

Questions: 1. What is the \"name\" field in package.json? Affected area: package.json."
DGIT="git reset --""hard HEAD"
calls() { # tool_use -> tool_result pairs from a stream-json transcript
  jq -s -c '
    ([.[] | select(.type=="user") | .message.content[]? | objects | select(.type=="tool_result")
      | {key: .tool_use_id, value: {is_error, content: (.content | if type=="array" then map(.text? // "") | join(" ") else tostring end)[0:300]}}] | from_entries) as $res
    | .[] | select(.type=="assistant") | .message.content[]? | select(.type=="tool_use")
    | {name, input: (.input | if .prompt then .prompt |= .[0:90] else . end | if .content then .content |= .[0:60] else . end), result: $res[.id]}' "$1"
}
report() { # per-run evidence: tool calls, hook/permission/launch events, final text and cost
  local r
  for r in "$@"; do
    echo "== $r tool calls"; calls "$R/$r.jsonl" | tee "$R/$r.calls.jsonl"
    echo "== $r system events (hooks, permission denials, launches)"
    jq -c 'select(.type=="system" and (.subtype | test("^(hook_response|permission_denied|task_started|task_notification)$")))
      | {subtype, hook_event, tool_name, message, subagent_type, is_backgrounded, status, output: ((.output // "") | .[0:400])}' "$R/$r.jsonl" | tee "$R/$r.system.jsonl"
    echo "== $r final (total_cost_usd is cumulative; the last result event counts)"
    jq -r 'select(.type=="result") | "cost $\(.total_cost_usd)  turns \(.num_turns)\n\(.result)"' "$R/$r.jsonl"
  done
}

if [ "${E2E_SKIP_CLAUDE:-0}" = 1 ] || [ "${E2E_SKIP_BASE:-0}" = 1 ]; then echo "skipping base runs run1/run2"; else
run run1 30 "This is an automated hook test. Do each numbered step exactly once, in order. If a step is denied or blocked, record the exact error text and move on. Never retry, never work around a denial, never use another tool or command than the one named.
1) If your context contains a SessionStart message about in-flight features, quote it verbatim; otherwise say NONE.
2) Read GLOSSARY.md, then use the Edit tool to replace '_Avoid_: summer' with '_Avoid_: summer, totaliser'.
3) Use the Write tool to create docs/cache/x.md with content 'x'.
4) Use Bash to run exactly: echo x > docs/cache/y.md
5) Use Bash to run exactly: echo 'step: 9.9' > specs/001-demo/.step
6) Use Bash to run exactly: $DGIT
7) Use the Agent tool with subagent_type 'fact-lookup', description 'no header', prompt 'What is the name field in package.json?'.
8) Use the Agent tool with subagent_type 'fact-lookup', description 'with header', and this prompt, copied byte for byte (it must start with the three backticks):
$HDR
9) Finish with a table: step, tool, allowed or denied, exact error text."

(cd "$P" && "$ST" step specs/001-demo 0.2.3) >> "$R/seed.log" 2>&1
echo "== .step before run2"; cat "$P/specs/001-demo/.step"
run run2 6 "Automated hook test. Read GLOSSARY.md, then use the Edit tool once to replace '_Avoid_: summer' with '_Avoid_: summer, totaliser'. Do not retry or work around a denial. Report whether the edit was allowed and the exact error text if not."

# ── 4. Evidence (base runs) ──
report run1 run2
echo "== PostToolUse(Agent): rewritten tool_input.model / prompt head / resolvedModel"
jq -c '{model: .tool_input.model, prompt_head: .tool_input.prompt[0:70], resolvedModel: .tool_response.resolvedModel, status: .tool_response.status}' \
  "$P/.claude/agent-post.jsonl" 2>/dev/null || echo "(no PostToolUse(Agent) records)"
echo "== files"
for f in docs/cache/x.md docs/cache/y.md; do printf '%s: ' "$f"; if [ -e "$P/$f" ]; then echo PRESENT; else echo absent; fi; done
echo ".step now: $(tr '\n' ' ' < "$P/specs/001-demo/.step")"
echo "HEAD unchanged: $([ "$(G rev-parse HEAD)" = "$HEAD0" ] && echo yes || echo NO)"
echo "GLOSSARY Avoid line: $(grep '_Avoid_' "$P/GLOSSARY.md")"
echo "== user hook log (pre-existing user hook still fires after merge)"; cat "$P/.claude/user-hook.log" 2>/dev/null || echo "(empty)"
echo "== direct SessionStart hook output (deterministic cross-check)"
jq -cn --arg c "$P" '{session_id:"x", cwd:$c, hook_event_name:"SessionStart", source:"startup"}' \
  | CLAUDE_PROJECT_DIR=$P "$P/.agents/hooks/session-start-resume.sh" | jq -r '.hookSpecificOutput.additionalContext'
fi  # base runs


# ── 5. Follow-up (PLAN/install-e2e.md "Follow-up run") ──
# 5a. Seed: model switch, implementation model, task T1, stateful lint, e2e-browser profile + fake suite, logging hooks.
sed -i.bak 's/^claude: haiku$/claude: sonnet/' "$P/model-map/fact-lookup.md" && rm -f "$P/model-map/fact-lookup.md.bak"
sed 's/^claude: .*/claude: haiku/; s/^# fact-lookup/# implementation/' "$P/model-map/fact-lookup.md" > "$P/model-map/implementation.md"
cat > "$P/specs/001-demo/tasks.md" <<'M'
---
tasks:
  - id: T1
    title: "hello file"
    status: pending
    capability: CAP-NEW-demo
    depends_on: []
    touches_core: false
    work_type: ts
    module: app
    seam: "none (harness task)"
---
# Tasks: demo

## T1: hello file

**What to build:** hello.txt containing `hello`.
M
# Lint fails on the first stop audit and passes on the next: toolchain.json is written by run-toolchain.sh only after its commands ran.
# Every lint invocation is logged outside the project, so audit runs and any agent-run lint can be counted.
LINT="echo \"lint \$(date -u +%H:%M:%S) \$PWD\" >> $W/lint.log; test -f $P/specs/001-demo/artifacts/T1/toolchain.json || { echo \"E2E deliberate lint failure: first stop audit\"; exit 1; }"
awk -v l="lint: '$LINT'" '/^lint: "true"$/ { print l; next } { print }' "$P/profiles/ts.md" > "$P/profiles/ts.md.new" && mv "$P/profiles/ts.md.new" "$P/profiles/ts.md"
sed 's/^# Profile: ts$/# Profile: e2e-browser/; s/^lint: .*/lint: "true"/; s/^e2e: ""$/e2e: ".\/e2e.sh"/' "$P/profiles/ts.md" > "$P/profiles/e2e-browser.md"
cat > "$P/e2e.sh" <<'S'
#!/usr/bin/env bash
# Fake browser suite for the install E2E: writes a minimal Playwright-shaped JSON report. No Playwright involved.
# E2E_EXIT=<n> sets the exit code (a real suite with a failing test exits 1).
set -e
mkdir -p test-results
printf 'PNG-placeholder\n' > test-results/fail-shot.png
LOG=$(printf 'console: hello from JRN-001\n' | base64 | tr -d '\n')
cat > test-results/e2e-results.json <<J
{ "config": {}, "stats": {"expected": 1, "unexpected": 1, "skipped": 0, "flaky": 0},
  "suites": [ { "title": "demo.spec.ts", "file": "demo.spec.ts", "specs": [
    { "title": "adds numbers", "file": "demo.spec.ts", "line": 3, "tags": ["JRN-001"], "tests": [
      { "projectName": "chromium", "status": "expected", "results": [
        { "retry": 0, "status": "passed", "attachments": [ { "name": "console", "contentType": "text/plain", "body": "$LOG" } ] } ] } ] },
    { "title": "shows the total", "file": "demo.spec.ts", "line": 9, "tags": [], "tests": [
      { "projectName": "chromium", "status": "unexpected", "results": [
        { "retry": 0, "status": "failed", "attachments": [ { "name": "screenshot", "contentType": "image/png", "path": "test-results/fail-shot.png" } ] } ] } ] }
  ] } ] }
J
echo "fake suite: 1 passed, 1 failed"
exit "${E2E_EXIT:-0}"
S
chmod +x "$P/e2e.sh"
printf 'test-results/\n' >> "$P/.gitignore"
# Logging only (settings.local.json, never merged): PostToolUse(Agent) as before, plus every SubagentStop payload and a copy of the
# sub-agent transcript at that moment (it holds the block reason fed back after a blocked stop).
cat > "$P/.claude/log-stop.sh" <<'S'
#!/usr/bin/env bash
p=$(cat); d="$CLAUDE_PROJECT_DIR/.claude"
printf '%s' "$p" | jq -c '{agent_type, agent_id, stop_hook_active, cwd, agent_transcript_path}' >> "$d/subagent-stop.jsonl"
t=$(printf '%s' "$p" | jq -r '.agent_transcript_path // ""')
n=$(wc -l < "$d/subagent-stop.jsonl" | tr -d ' ')
[ -f "$t" ] && cp "$t" "$d/subagent-transcript.$n.jsonl"
exit 0
S
chmod +x "$P/.claude/log-stop.sh"
cat > "$P/.claude/settings.local.json" <<'J'
{ "hooks": {
  "PostToolUse": [ { "matcher": "Agent", "hooks": [ { "type": "command", "command": "jq -c . >> \"$CLAUDE_PROJECT_DIR\"/.claude/agent-post.jsonl" } ] } ],
  "SubagentStop": [ { "hooks": [ { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/log-stop.sh" } ] } ] } }
J
G add -A && G commit -qm "follow-up seed" || true
(cd "$P" && "$ST" step specs/001-demo 0.2.3) >> "$R/seed.log" 2>&1
echo "== follow-up seed: model-map, lint, e2e profile"
grep -H '^claude:' "$P/model-map/"*.md; grep '^lint:' "$P/profiles/ts.md"; grep '^e2e:' "$P/profiles/e2e-browser.md"
echo "boundary config before f1: $([ -e "$P/tools/boundaries/dependency-cruiser.cjs" ] && echo PRESENT || echo absent)"

if [ "${E2E_SKIP_CLAUDE:-0}" = 1 ]; then echo "E2E_SKIP_CLAUDE=1: stopping before headless runs"; echo "Work dir: $W"; exit 0; fi

STEPCMD=".agents/skills/feature-workflow/scripts/status-transition.sh step specs/001-demo"
RULES_OK='modules:
  math:
    owns: ["src/math.ts"]
    may_depend_on: []
  app:
    owns: ["src/index.ts"]
    may_depend_on: [math]'

# 5b. f1 (.step 0.2.3): spec single-writer guard, then rules -> boundary config sync.
run f1 30 "This is an automated hook test. Do each numbered step exactly once, in order. If a step is denied or blocked, record the exact error or hook text and move on. Never retry, never fix or work around a denial or block, never use another tool than the one named.
1) Read specs/001-demo/spec.md. Use the Edit tool to replace '## Non-goals' with '## Non-goals (e2e)'.
2) Use Bash to run exactly: $STEPCMD 0.3.17
3) Use the Edit tool on specs/001-demo/spec.md to replace 'status: draft ' with 'status: in-progress ' (note the trailing spaces).
4) Use the Edit tool on specs/001-demo/spec.md to replace '## Non-goals' with '## Non-goals (e2e)'.
5) Use Bash to run exactly: $STEPCMD 0.3.7
6) Read docs/rules.md. Use the Edit tool to replace the line 'modules: {}' with exactly these lines:
$RULES_OK
7) Use Bash to run exactly: grep -c not-to tools/boundaries/dependency-cruiser.cjs
8) Use the Edit tool on docs/rules.md to replace 'may_depend_on: [math]' with 'may_depend_on: [math'. A hook may then report that the rules do not parse: quote that text and do NOT fix the file.
9) Finish with a table: step, tool, allowed / denied / blocked, exact error or hook text."
echo "== after f1"; echo ".step: $(tr '\n' ' ' < "$P/specs/001-demo/.step")"
grep -n '^status:\|^## Non-goals' "$P/specs/001-demo/spec.md"
echo "boundary config: $([ -e "$P/tools/boundaries/dependency-cruiser.cjs" ] && shasum "$P/tools/boundaries/dependency-cruiser.cjs" | cut -c1-12 || echo absent)"
grep -n '"name"' "$P/tools/boundaries/dependency-cruiser.cjs" 2>/dev/null || true
grep -n 'may_depend_on: \[math' "$P/docs/rules.md" || true

# 5c. Spec to in-progress (3.1) so evidence-capture finds an in-flight spec; commit so the worktree sees tasks.md and profiles.
(cd "$P" && "$ST" status specs/001-demo ready-for-dev --step 0.6 && "$ST" status specs/001-demo in-progress --step 3.1) >> "$R/seed.log" 2>&1
G add -A && G commit -qm "after f1" || true
echo "== spec status for f2/f3: $(grep '^status:' "$P/specs/001-demo/spec.md" | cut -c1-30); .step $(tr '\n' ' ' < "$P/specs/001-demo/.step")"

# 5d. f2: evidence-capture (fake suite, exit 0 and exit 1), then fact-lookup with model-map claude: sonnet.
run f2 12 "This is an automated hook test. Do each numbered step exactly once, in order. Never retry or work around anything.
1) Use Bash to run exactly: ./e2e.sh
2) Use Bash to run exactly: E2E_EXIT=1 ./e2e.sh
3) Use the Agent tool with subagent_type 'fact-lookup', description 'model switch', and this prompt, copied byte for byte (it must start with the three backticks):
$HDR
4) Report: for steps 1-2 any hook message you received (quote it), for step 3 the agent's answer."

# 5e. f3: implementation agent in a worktree: Tier A/B writes from a sub-agent, then the SubagentStop audit (fails once, then passes).
IHDR="${FENCE}yaml launch-header
task_type: implementation
spec_dir: specs/001-demo
task_id: T1
work_type: ts
${FENCE}

This is an automated hook test, not real work. Do each numbered step exactly once, in order. If a step is denied, record the exact error text and move on; never retry or work around a denial.
1) Read GLOSSARY.md, then use the Edit tool to replace '_Avoid_: summer' with '_Avoid_: summer, adder-sum'.
2) Use the Write tool to create docs/cache/z.md with content 'z'.
3) Use the Write tool to create hello.txt in your working directory with content 'hello'. Then use Bash to run exactly: git add hello.txt && git commit -qm 'T1: hello file'
4) Do not run lint, tests or any toolchain command yourself; the stop hook runs them. Stop now with a short result: each step, allowed or denied, exact error text, and the output of git rev-parse --git-dir and git rev-parse --git-common-dir.
If your stop is blocked by a hook, quote the hook's reason in your next reply, change nothing, and stop again."
run f3 10 "This is an automated hook test. Use the Agent tool exactly once with subagent_type 'implementation', description 'T1 hello', isolation 'worktree', and this prompt, copied byte for byte (it must start with the three backticks):
$IHDR
Wait for the agent to finish, then report its final result verbatim and any hook messages you saw. Do nothing else."

# 5f. Evidence (follow-up runs)
report f1 f2 f3
echo "== f1: PostToolUse block reason from rules-boundary-config-sync (transcript)"
grep -o 'docs/rules.md was written, but its boundary rules do not parse[^"]*' "$R/f1.jsonl" | head -2 || echo "(not found)"
echo "== PostToolUse(Agent) (all runs): model / resolvedModel / isolation / worktree"
jq -c '{type: .tool_input.subagent_type, model: .tool_input.model, isolation: .tool_input.isolation, resolvedModel: .tool_response.resolvedModel,
  status: .tool_response.status, worktreePath: .tool_response.worktreePath}' "$P/.claude/agent-post.jsonl" 2>/dev/null || echo "(none)"
echo "== evidence-capture artifacts"
find "$P/specs/001-demo/artifacts" -path '*/e2e-*' -type f | sed "s|$P/||" | sort
for idx in "$P"/specs/001-demo/artifacts/e2e-*/evidence-index.json; do
  [ -f "$idx" ] && jq -c '{run_id, command, spec_dir, stats, tests: [.tests[] | {title, journeys, status, files}]}' "$idx"; done
echo "== SubagentStop payloads (logger)"; cat "$P/.claude/subagent-stop.jsonl" 2>/dev/null || echo "(none)"
echo "== block reasons fed back to the implementation agent (logged transcript copies)"
for t in "$P"/.claude/subagent-transcript.*.jsonl; do
  [ -f "$t" ] || continue; echo "-- $(basename "$t")"
  jq -r 'select(.type=="user") | .message.content | if type=="string" then . else (map(.text? // "") | join(" ")) end
    | select(startswith("Stop hook feedback")) | .[0:700]' "$t" 2>/dev/null
done
echo "== lint invocations"; cat "$W/lint.log" 2>/dev/null || echo "(none)"
echo "== audit evidence specs/001-demo/artifacts/T1"; ls -la "$P/specs/001-demo/artifacts/T1" 2>/dev/null || echo "(none)"
jq -c '{status, ran, results: [.results[] | {key, status, exit_code}]}' "$P/specs/001-demo/artifacts/T1/toolchain.json" 2>/dev/null || true
echo "== Tier A/B from the sub-agent: GLOSSARY Avoid line (main and worktrees), docs/cache/z.md"
grep -H '_Avoid_' "$P/GLOSSARY.md" "$P"/.claude/worktrees/*/GLOSSARY.md 2>/dev/null || true
find "$P" -path '*/docs/cache/z.md' 2>/dev/null | sed "s|$P/||" || true
echo "== worktrees"; G worktree list; G branch -a --list 'worktree-*' 2>/dev/null; for b in $(G for-each-ref --format='%(refname:short)' 'refs/heads/worktree-*'); do G log --oneline -1 "$b"; done
echo "Work dir: $W"
