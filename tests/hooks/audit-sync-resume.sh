#!/usr/bin/env bash
# Suite: hooks/post-implementation-audit.sh (SubagentStop), hooks/rules-boundary-config-sync.sh (PostToolUse) and
#   hooks/session-start-resume.sh (SessionStart).
# Covers: audit block / loop counter / give-up / evidence in the main checkout, phase-1 and malformed headers;
#   rules.md -> boundary config sync (block on parse error, missing yq, worktree); resume offer listing,
#   discovered-work and size-budget prompts, work-backlog count, output cap.
# The three share one fixture project, so the sections run in order.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

new_workdir
B=$WORK
P=$B/proj
copy_agents "$P"
cd "$P" || exit 1
git init -q -b main && git config user.email t@t.invalid && git config user.name tester
mkdir -p .workflow/specs/001-demo .workflow/profiles
cat > .workflow/specs/001-demo/spec.md <<'S'
---
status: in-progress
baseline_revision: ""
light_path: false
followup_review_recommended: false
deferred: []
---
# Demo
S
cat > .workflow/specs/001-demo/tasks.md <<'S'
---
tasks:
  - id: T1
    title: "a"
    status: in-progress
    capability: CAP-NEW-x
    depends_on: []
    touches_core: false
    work_type: web
    module: m
    seam: s
---
S
cat > .workflow/profiles/web.md <<'S'
# web
## Toolchain

```yaml
lint: "test -f lint-ok"
typecheck: ""
format: "true"
boundary: ""
e2e: ""
```
S
cat > .workflow/profiles/harness.md <<'S'
## Toolchain

```yaml
lint: "true"
```
S
cp .agents/skills/project-setup/assets/docs/rules.md .workflow/rules.md
git add -A >/dev/null && git commit -qm init
git worktree add -q "$B/wt" -b wt1 2>/dev/null
WT=$B/wt

H=$P/.agents/hooks
mk_transcript() { # file prompt
  jq -cn --arg p "$2" '{type:"user",isSidechain:true,message:{role:"user",content:$p}}' > "$1"
  jq -cn '{type:"user",isMeta:true,message:{role:"user",content:"<system-reminder>x</system-reminder>"}}' >> "$1"
  jq -cn '{type:"assistant",message:{role:"assistant",content:[{type:"text",text:"ok"}]}}' >> "$1"
}
stop_payload() { # transcript active [agent_type] [cwd]
  jq -cn --arg t "$1" --argjson a "$2" --arg at "${3:-implementation}" --arg c "${4:-$WT}" \
    '{session_id:"s",transcript_path:"/x",cwd:$c,prompt_id:"p",agent_id:"a1",agent_type:$at,agent_transcript_path:$t,last_assistant_message:"done",stop_hook_active:$a,hook_event_name:"SubagentStop"}'
}
HDR_T1=$'```yaml launch-header\ntask_type: implementation\nspec_dir: .workflow/specs/001-demo\ntask_id: T1\n```\n\nImplement T1.'
mk_transcript "$B/t1.jsonl" "$HDR_T1"
EV=$P/.workflow/specs/001-demo/artifacts/T1

echo "== post-implementation-audit"
out=$(stop_payload "$B/t1.jsonl" false explore | bash "$H/post-implementation-audit.sh"); rc=$?
check "non-implementation agent ignored" '[ $rc -eq 0 ] && [ -z "$out" ]' "$out"

out=$(stop_payload "$B/t1.jsonl" false | bash "$H/post-implementation-audit.sh" 2>/dev/null); rc=$?
check "failing toolchain blocks" '[ $rc -eq 0 ] && [ "$(jq -r .decision <<<"$out")" = block ] && jq -r .reason <<<"$out" | grep -q "\[lint\]"' "$out"
check "evidence in main checkout, not worktree" '[ -f "$EV/toolchain.json" ] && [ ! -e "$WT/.workflow/specs/001-demo/artifacts" ]'
check "counter=1" '[ "$(jq .count "$EV/audit-loop.json")" = 1 ]'

out=$(stop_payload "$B/t1.jsonl" true | bash "$H/post-implementation-audit.sh" 2>/dev/null)
check "same digest, active -> still block, count 2" '[ "$(jq -r .decision <<<"$out")" = block ] && [ "$(jq .count "$EV/audit-loop.json")" = 2 ]' "$out"
out=$(stop_payload "$B/t1.jsonl" true | bash "$H/post-implementation-audit.sh" 2>/dev/null)
check "3rd identical -> give up, allow with systemMessage" '[ "$(jq -r ".decision // empty" <<<"$out")" = "" ] && jq -e .systemMessage <<<"$out" >/dev/null && [ "$(jq -r .outcome "$EV/audit.json")" = gave-up ] && [ "$(jq .repeats "$EV/audit.json")" = 3 ] && [ ! -f "$EV/audit-loop.json" ] && [ "$(jq -r .status "$EV/toolchain.json")" = fail ]' "$out"

stop_payload "$B/t1.jsonl" false | bash "$H/post-implementation-audit.sh" >/dev/null 2>&1
out=$(stop_payload "$B/t1.jsonl" false | bash "$H/post-implementation-audit.sh" 2>/dev/null)
check "inactive stop resets counter to 1" '[ "$(jq -r .decision <<<"$out")" = block ] && [ "$(jq .count "$EV/audit-loop.json")" = 1 ]' "$out"
# change digest: different failure output (lint-ok as dir -> test -f fails same; instead change profile cmd)
sed -i.bak 's/lint: "test -f lint-ok"/lint: "test -f lint-ok || echo changed; test -f lint-ok"/' "$WT/.workflow/profiles/web.md"
rm -f "$WT/.workflow/profiles/web.md.bak"
out=$(stop_payload "$B/t1.jsonl" true | bash "$H/post-implementation-audit.sh" 2>/dev/null)
check "changed digest while active resets to 1" '[ "$(jq -r .decision <<<"$out")" = block ] && [ "$(jq .count "$EV/audit-loop.json")" = 1 ]' "$out"

touch "$WT/lint-ok"
out=$(stop_payload "$B/t1.jsonl" true | bash "$H/post-implementation-audit.sh" 2>/dev/null); rc=$?
check "passing toolchain -> silent allow, counter cleared" '[ $rc -eq 0 ] && [ -z "$out" ] && [ "$(jq -r .status "$EV/toolchain.json")" = pass ] && [ ! -f "$EV/audit-loop.json" ] && [ ! -f "$EV/audit.json" ]' "$out"
rm -f "$WT/lint-ok"

HDR_P1=$'```yaml launch-header\ntask_type: implementation\nspec_dir: .workflow/specs/001-demo\nwork_type: harness\n```\nSet up the harness.'
mk_transcript "$B/p1.jsonl" "$HDR_P1"
out=$(stop_payload "$B/p1.jsonl" false | bash "$H/post-implementation-audit.sh" 2>/dev/null); rc=$?
check "phase 1 header -> evidence under phase-1-harness, pass silent" '[ $rc -eq 0 ] && [ -z "$out" ] && [ "$(jq -r .status "$P/.workflow/specs/001-demo/artifacts/phase-1-harness/toolchain.json")" = pass ]' "$out"
# D70: Phase 1 audits skip `test` (red by design); Phase 3 task audits run it
sed 's/^lint: "true"/lint: "true"\ntest: "false"/' .workflow/profiles/harness.md > .workflow/profiles/redtest.md
HDR_P1R=$'```yaml launch-header\ntask_type: implementation\nspec_dir: .workflow/specs/001-demo\nwork_type: redtest\n```\nSet up.'
mk_transcript "$B/p1r.jsonl" "$HDR_P1R"
out=$(stop_payload "$B/p1r.jsonl" false | bash "$H/post-implementation-audit.sh" 2>/dev/null); rc=$?
check "phase 1 with failing test key -> allowed, test skipped (D70)" '[ $rc -eq 0 ] && [ -z "$out" ] && [ "$(jq -r ".results[]|select(.key==\"test\")|.status+\":\"+.reason" "$P/.workflow/specs/001-demo/artifacts/phase-1-redtest/toolchain.json")" = "skipped:skipped by caller" ]' "$out"
HDR_P3R=$'```yaml launch-header\ntask_type: implementation\nspec_dir: .workflow/specs/001-demo\ntask_id: T9\nwork_type: redtest\n```\n\nImplement T9.'
mk_transcript "$B/p3r.jsonl" "$HDR_P3R"
out=$(stop_payload "$B/p3r.jsonl" false | bash "$H/post-implementation-audit.sh" 2>/dev/null)
check "phase 3 task with failing test key -> test still runs, stop blocked (D70 skips only Phase 1)" '[ "$(jq -r .decision <<<"$out")" = block ] && [ "$(jq -r ".results[]|select(.key==\"test\")|.status" "$P/.workflow/specs/001-demo/artifacts/T9/toolchain.json")" = fail ]' "$out"

# D85: Claude task launches run in the orchestrator-made worktree .workflow/.worktrees/s<NNN>_t<N>, not an isolation cwd
rm -f "$EV/audit-loop.json" "$EV/audit.json"
out=$(stop_payload "$B/t1.jsonl" false implementation "$P" | bash "$H/post-implementation-audit.sh" 2>/dev/null)
check "D85: main-checkout cwd, no task worktree -> allow + warning, toolchain not run" '[ -z "$(jq -r ".decision // empty" <<<"$out")" ] && jq -r .systemMessage <<<"$out" | grep -q "s001_t1" && [ "$(jq -r .outcome "$EV/audit.json")" = warning ]' "$out"
rm -f "$EV/audit.json"
git worktree add -q "$P/.workflow/.worktrees/s001_t1" -b task/001-demo/T01-a 2>/dev/null
touch "$P/.workflow/.worktrees/s001_t1/lint-ok"
out=$(stop_payload "$B/t1.jsonl" false implementation "$P" | bash "$H/post-implementation-audit.sh" 2>/dev/null); rc=$?
check "D85: .workflow/.worktrees/s001_t1 audited (pass there)" '[ $rc -eq 0 ] && [ -z "$out" ] && [ "$(jq -r .cwd "$EV/toolchain.json")" = "$(cd "$P/.workflow/.worktrees/s001_t1" && pwd -P)" ]' "$out"
out=$(stop_payload "$B/t1.jsonl" false implementation "$WT" | bash "$H/post-implementation-audit.sh" 2>/dev/null)
check "D85: task worktree preferred over an isolation cwd" '[ -z "$out" ] && [ "$(jq -r .cwd "$EV/toolchain.json")" = "$(cd "$P/.workflow/.worktrees/s001_t1" && pwd -P)" ]' "$out"
git worktree remove --force "$P/.workflow/.worktrees/s001_t1"
git branch -q -D task/001-demo/T01-a
out=$(stop_payload "$B/t1.jsonl" false | bash "$H/post-implementation-audit.sh" 2>/dev/null)
check "D85 fallback: isolation worktree cwd still audited" '[ "$(jq -r .decision <<<"$out")" = block ] && [ "$(jq -r .cwd "$EV/toolchain.json")" = "$(cd "$WT" && pwd -P)" ]' "$out"
rm -f "$EV/audit-loop.json"

# array content form
jq -cn --arg p "$HDR_T1" '{type:"user",message:{role:"user",content:[{type:"text",text:$p}]}}' > "$B/arr.jsonl"
out=$(stop_payload "$B/arr.jsonl" false | bash "$H/post-implementation-audit.sh" 2>/dev/null)
check "array-content first user message parsed" '[ "$(jq -r .decision <<<"$out")" = block ]' "$out"

mk_transcript "$B/nohdr.jsonl" "Just implement something."
out=$(stop_payload "$B/nohdr.jsonl" false | bash "$H/post-implementation-audit.sh" 2>/dev/null); rc=$?
check "missing header -> allow with systemMessage" '[ $rc -eq 0 ] && [ -z "$(jq -r ".decision // empty" <<<"$out")" ] && jq -r .systemMessage <<<"$out" | grep -q "header"' "$out"

BAD=$'```yaml launch-header\ntask_type: implementation\nspec_dir: .workflow/specs/001-demo\ntask_id: bogus id\n```\nx'
mk_transcript "$B/bad.jsonl" "$BAD"
rm -f "$P/.workflow/specs/001-demo/artifacts/audit-warnings.jsonl"
out=$(stop_payload "$B/bad.jsonl" false | bash "$H/post-implementation-audit.sh" 2>/dev/null)
check "malformed header -> allow + warning filed under spec artifacts" '[ -z "$(jq -r ".decision // empty" <<<"$out")" ] && grep -q malformed "$P/.workflow/specs/001-demo/artifacts/audit-warnings.jsonl"' "$out"

out=$(stop_payload "$B/missing.jsonl" false | bash "$H/post-implementation-audit.sh" 2>/dev/null)
check "missing transcript -> allow + systemMessage" 'jq -e .systemMessage <<<"$out" >/dev/null' "$out"

HDR_T9=$'```yaml launch-header\ntask_type: implementation\nspec_dir: .workflow/specs/001-demo\ntask_id: T1\nwork_type: nope\n```\nx'
mk_transcript "$B/t9.jsonl" "$HDR_T9"
out=$(stop_payload "$B/t9.jsonl" false | bash "$H/post-implementation-audit.sh" 2>/dev/null)
check "run-toolchain config error (no profile) -> allow + audit.json warning" '[ -z "$(jq -r ".decision // empty" <<<"$out")" ] && [ "$(jq -r .outcome "$EV/audit.json")" = warning ]' "$out"
rm -f "$EV/audit.json"

echo "== rules-boundary-config-sync"
post_payload() { jq -cn --arg tool "$1" --arg f "$2" --arg c "${3:-$P}" '{session_id:"s",cwd:$c,hook_event_name:"PostToolUse",tool_name:$tool,tool_input:{file_path:$f},tool_response:{}}'; }
out=$(post_payload Write "$P/README.md" | bash "$H/rules-boundary-config-sync.sh"); rc=$?
check "other path ignored" '[ $rc -eq 0 ] && [ -z "$out" ]' "$out"
out=$(post_payload Read "$P/.workflow/rules.md" | bash "$H/rules-boundary-config-sync.sh")
check "other tool ignored" '[ -z "$out" ]' "$out"
cat > "$P/.workflow/rules.md" <<'S'
# Rules
## Ownership

```yaml
modules:
  a:
    owns: ["src/a/**"]
    may_depend_on: []
  b:
    owns: ["src/b/**"]
    may_depend_on: [a]
```

## Shared core

```yaml
shared_core:
  paths: ["src/core/**"]
```
S
out=$(post_payload Edit ".workflow/rules.md" | bash "$H/rules-boundary-config-sync.sh"); rc=$?
check "valid rules.md (relative path) -> silent, config generated" '[ $rc -eq 0 ] && [ -z "$out" ] && [ -f "$P/.workflow/tools/boundaries/dependency-cruiser.cjs" ]' "$out"
cp "$P/.workflow/tools/boundaries/dependency-cruiser.cjs" "$B/good.cjs"
printf '## Ownership\n\n```yaml\nmodules: [unclosed\n```\n\n## Shared core\n\n```yaml\nshared_core:\n  paths: []\n```\n' > "$P/.workflow/rules.md"
out=$(post_payload Write "$P/.workflow/rules.md" | bash "$H/rules-boundary-config-sync.sh")
check "parse error -> block with reason, config untouched" '[ "$(jq -r .decision <<<"$out")" = block ] && jq -r .reason <<<"$out" | grep -q "Ownership" && cmp -s "$B/good.cjs" "$P/.workflow/tools/boundaries/dependency-cruiser.cjs"' "$out"
out=$(jq -cn --arg f "$P/.workflow/rules.md" --arg c "$P" '{cwd:$c,tool_name:"NotebookEdit",tool_input:{notebook_path:$f}}' | bash "$H/rules-boundary-config-sync.sh")
check "NotebookEdit notebook_path handled" '[ "$(jq -r .decision <<<"$out")" = block ]' "$out"
out=$(post_payload Write "$P/sub/docs/rules.md" | bash "$H/rules-boundary-config-sync.sh")
check "nested .workflow/rules.md elsewhere ignored" '[ -z "$out" ]' "$out"
out=$(post_payload Write "$P/.workflow/rules.md" | PATH=/usr/bin:/bin:$(dirname "$(command -v jq)") bash "$H/rules-boundary-config-sync.sh")
check "missing yq -> systemMessage, no block" '[ -z "$(jq -r ".decision // empty" <<<"$out")" ] && jq -r .systemMessage <<<"$out" | grep -q "exit 3"' "$out"
out=$(post_payload Write "$WT/.workflow/rules.md" "$WT" | bash "$H/rules-boundary-config-sync.sh"); rc=$?
check "worktree rules.md -> generated in worktree" '[ $rc -eq 0 ] && [ -z "$out" ] && [ -f "$WT/.workflow/tools/boundaries/dependency-cruiser.cjs" ]' "$out"

echo "== session-start-resume"
ss() { jq -cn --arg c "$1" --arg s "${2:-startup}" '{session_id:"s",transcript_path:"/x",cwd:$c,hook_event_name:"SessionStart",source:$s}' | bash "$H/session-start-resume.sh"; }
E=$B/empty; rm -rf "$E"; mkdir -p "$E"
out=$(ss "$E"); rc=$?
check "no .workflow/specs/ -> nothing" '[ $rc -eq 0 ] && [ -z "$out" ]' "$out"
mkdir -p "$P/.workflow/specs/002-done" "$P/.workflow/specs/003-blocked" "$P/.workflow/specs/004-broken"
printf -- '---\nstatus: done\n---\n' > "$P/.workflow/specs/002-done/spec.md"
printf -- '---\nstatus: blocked\nblocked_condition: "need API key"\n---\n' > "$P/.workflow/specs/003-blocked/spec.md"
printf -- '---\nstatus: [oops\n---\n' > "$P/.workflow/specs/004-broken/spec.md"
printf 'step: "3.3"\nupdated_at: "2026-10-15T12:00:00Z"\n' > "$P/.workflow/specs/001-demo/.step"
printf 'step: "4.7"\nupdated_at: "2026-10-15T13:00:00Z"\nblocked_from: "in-review"\n' > "$P/.workflow/specs/003-blocked/.step"
out=$(ss "$WT" compact); rc=$?
ctx=$(jq -r .hookSpecificOutput.additionalContext <<<"$out")
check "SessionStart output shape" '[ $rc -eq 0 ] && [ "$(jq -r .hookSpecificOutput.hookEventName <<<"$out")" = SessionStart ]' "$out"
check "in-progress listed with step" 'grep -q ".workflow/specs/001-demo: status in-progress; current step 3.3 (since 2026-10-15T12:00:00Z)" <<<"$ctx"' "$ctx"
check "blocked listed with blocked_from + condition" 'grep -q ".workflow/specs/003-blocked: status blocked; current step 4.7.*blocked from in-review; blocked_condition: need API key" <<<"$ctx"' "$ctx"
check "done omitted" '! grep -q 002-done <<<"$ctx"' "$ctx"
check "broken frontmatter flagged" 'grep -q "004-broken: spec.md frontmatter unreadable" <<<"$ctx"' "$ctx"
check "points at feature-workflow" 'grep -q "feature-workflow" <<<"$ctx"' "$ctx"
rm -rf "$P/.workflow/specs/003-blocked" "$P/.workflow/specs/004-broken" "$P/.workflow/specs/001-demo/.step"
printf -- '---\nstatus: done\n---\n' > "$B/done.md"; cp "$P/.workflow/specs/001-demo/spec.md" "$B/keep.md"; cp "$B/done.md" "$P/.workflow/specs/001-demo/spec.md"
out=$(ss "$P")
check "only done specs -> nothing" '[ -z "$out" ]' "$out"
cp "$B/keep.md" "$P/.workflow/specs/001-demo/spec.md"
out=$(ss "$P"); ctx=$(jq -r .hookSpecificOutput.additionalContext <<<"$out")
check "no .step marker noted" 'grep -q "no .step marker" <<<"$ctx"' "$ctx"
for i in $(seq 100 260); do mkdir -p "$P/.workflow/specs/$i-feature-with-a-rather-long-slug-name"; printf -- '---\nstatus: blocked\nblocked_condition: "%s"\n---\n' "$(printf 'x%.0s' $(seq 1 150))" > "$P/.workflow/specs/$i-feature-with-a-rather-long-slug-name/spec.md"; done
start=$(date +%s)
out=$(ss "$P"); ctx=$(jq -r .hookSpecificOutput.additionalContext <<<"$out"); dur=$(( $(date +%s) - start ))
check "cap: additionalContext < 10000 chars with omitted count (took ${dur}s)" '[ ${#ctx} -lt 10000 ] && grep -q "more not listed" <<<"$ctx"' "${#ctx}"
mkdir -p "$P/.workflow/.handoff"; for i in 1 2 3 4 5; do printf -- '---\ngoal: "%s"\nspec: ""\ncreated: 2026-10-19T10:00:00Z\n---\n' "$(printf 'g%.0s' $(seq 1 400))" > "$P/.workflow/.handoff/long-$i.md"; done
out=$(ss "$P"); ctx=$(jq -r .hookSpecificOutput.additionalContext <<<"$out")
check "cap holds with handoffs listed (entries cut at 300 chars)" '[ ${#ctx} -lt 10000 ] && grep -q "more not listed" <<<"$ctx" && grep -q "^- .workflow/.handoff/long-" <<<"$ctx" && ! grep -q "$(printf "g%.0s" $(seq 1 300))" <<<"$ctx"' "${#ctx}"
rm -rf "$P/.workflow/.handoff"
rm -rf "$P"/.workflow/specs/[12][0-9][0-9]-feature-*

echo "== session-start-resume: discovered work and backlog"
mkdir -p "$P/.workflow/specs/002-dw" "$P/.workflow/specs/work-backlog"
bl() { printf -- '---\nstatus: blocked\nblocked_condition: "%s"\n---\n' "$1" > "$P/.workflow/specs/002-dw/spec.md"; out=$(ss "$P"); ctx=$(jq -r .hookSpecificOutput.additionalContext <<<"$out"); }
bl "discovered work: login-bug"
check "discovered work blocked -> prompt pending" 'grep -q "002-dw: status blocked.*discovered-work prompt pending.*blocked_condition: discovered work: login-bug" <<<"$ctx"' "$ctx"
bl "size budget: 12 tasks"
check "size budget blocked -> prompt pending" 'grep -q "discovered-work prompt pending" <<<"$ctx"' "$ctx"
bl "intent gap"
check "other blocked condition -> no pending note" '! grep -q "002-dw.*prompt pending" <<<"$ctx"' "$ctx"
for i in 1 2 3 4 5 6 7; do printf -- '---\nstatus: open\n---\n# item\n' > "$P/.workflow/specs/work-backlog/001-demo-disc-00$i.md"; done
printf -- '---\nstatus: promoted\n---\n' > "$P/.workflow/specs/work-backlog/001-demo-disc-008.md"
out=$(ss "$P"); ctx=$(jq -r .hookSpecificOutput.additionalContext <<<"$out")
check "backlog: 7 open counted, 5 names, promoted skipped, not scanned as a spec" 'grep -q "work-backlog/: 7 (001-demo-disc-001.md, 001-demo-disc-002.md, 001-demo-disc-003.md, 001-demo-disc-004.md, 001-demo-disc-005.md, ...)" <<<"$ctx" && ! grep -q "disc-006" <<<"$ctx" && ! grep -q "disc-008" <<<"$ctx" && ! grep -q "^- .workflow/specs/work-backlog" <<<"$ctx"' "$ctx"
printf -- '---\nstatus: open\n---\n' > "$P/.workflow/specs/work-backlog/spec.md"
out=$(ss "$P"); ctx=$(jq -r .hookSpecificOutput.additionalContext <<<"$out")
check "work-backlog/spec.md never scanned as a spec" '! grep -q "^- .workflow/specs/work-backlog" <<<"$ctx"' "$ctx"
rm "$P/.workflow/specs/work-backlog/spec.md"
mv "$P/.workflow/specs/001-demo/spec.md" "$B/keep.bak"; rm -rf "$P/.workflow/specs/002-dw" "$P/.workflow/specs/001-demo"
out=$(ss "$P"); ctx=$(jq -r .hookSpecificOutput.additionalContext <<<"$out")
check "backlog only (no in-flight spec) still offers" 'grep -q "work-backlog/: 7" <<<"$ctx" && ! grep -q "In-flight" <<<"$ctx"' "$ctx"
for i in 1 2 3 4 5 6 7; do printf -- '---\nstatus: dismissed\n---\n' > "$P/.workflow/specs/work-backlog/001-demo-disc-00$i.md"; done
out=$(ss "$P")
check "no open backlog and no specs -> nothing" '[ -z "$out" ]' "$out"
rm -rf "$P/.workflow/specs/work-backlog"

echo "== session-start-resume: session handoffs (.workflow/.handoff/)"
hand() { # name goal spec [created]
  printf -- '---\ngoal: "%s"\nspec: "%s"\nstep_at_handoff: ""\ncreated: %s\n---\n# Handoff\n' "$2" "$3" "${4:-2026-10-19T10:00:00Z}" > "$P/.workflow/.handoff/$1.md"
}
mkdir -p "$P/.workflow/.handoff"; printf '*\n' > "$P/.workflow/.handoff/.gitignore"
hand fix-login "Fix the login redirect" ""
out=$(ss "$WT"); ctx=$(jq -r .hookSpecificOutput.additionalContext <<<"$out")
check "handoff only (empty .workflow/specs/), worktree cwd -> listed from main checkout" 'grep -q "^- .workflow/.handoff/fix-login.md (created 2026-10-19T10:00:00Z): Fix the login redirect$" <<<"$ctx" && ! grep -q "In-flight" <<<"$ctx" && grep -q "load the handoff skill" <<<"$ctx" && ! grep -q "gitignore" <<<"$ctx"' "$ctx"
rm -rf "$P/.workflow/specs"
out=$(ss "$P"); ctx=$(jq -r .hookSpecificOutput.additionalContext <<<"$out")
check "no .workflow/specs/ directory, handoff present -> still offered" 'grep -q "fix-login.md" <<<"$ctx"' "$ctx"
mkdir -p "$P/.workflow/specs/005-live"; printf -- '---\nstatus: in-progress\n---\n' > "$P/.workflow/specs/005-live/spec.md"
hand 005-live "Ship the export" .workflow/specs/005-live; touch -t 202610191200 "$P/.workflow/.handoff/005-live.md"; touch -t 202610191100 "$P/.workflow/.handoff/fix-login.md"
out=$(ss "$P"); ctx=$(jq -r .hookSpecificOutput.additionalContext <<<"$out")
check "handoff naming a spec listed with the spec list; footer names both skills" 'grep -q ".workflow/specs/005-live: status in-progress" <<<"$ctx" && grep -q "^- .workflow/.handoff/005-live.md (created [^)]*); spec .workflow/specs/005-live: Ship the export$" <<<"$ctx" && grep -q "feature-workflow skill for that spec" <<<"$ctx" && grep -q "resume a session handoff instead, load the handoff skill" <<<"$ctx"' "$ctx"
check "newest handoff first" '[ "$(grep -n "^- .workflow/.handoff/005-live" <<<"$ctx" | cut -d: -f1)" -lt "$(grep -n "^- .workflow/.handoff/fix-login" <<<"$ctx" | cut -d: -f1)" ]' "$ctx"
printf 'no frontmatter here\n' > "$P/.workflow/.handoff/broken.md"
printf -- '---\ngoal: [oops\n---\n' > "$P/.workflow/.handoff/bad.md"
hand older-one "Old" "" ; touch -t 202601010000 "$P/.workflow/.handoff/older-one.md" "$P/.workflow/.handoff/broken.md" "$P/.workflow/.handoff/bad.md"
touch -t 202610191300 "$P/.workflow/.handoff/bad.md"
out=$(ss "$P"); ctx=$(jq -r .hookSpecificOutput.additionalContext <<<"$out")
check "unreadable handoff flagged; 5 handoffs -> 3 listed, 2 counted" 'grep -q "^- .workflow/.handoff/bad.md: frontmatter unreadable" <<<"$ctx" && [ "$(grep -c "^- .workflow/.handoff/" <<<"$ctx")" = 3 ] && grep -q "and 2 older not listed" <<<"$ctx"' "$ctx"
rm -rf "$P/.workflow/.handoff" "$P/.workflow/specs/005-live"
out=$(ss "$P")
check "no handoffs and no specs -> nothing" '[ -z "$out" ]' "$out"


shellcheck_files "shellcheck: audit/sync/resume hooks" "$H/post-implementation-audit.sh" "$H/rules-boundary-config-sync.sh" "$H/session-start-resume.sh"
finish
