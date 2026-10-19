#!/usr/bin/env bash
# Suite: resolve-launch.sh (feature-workflow/scripts).
# Covers: --requirements table, model precedence (D35: override > definition > map), per-task-type launch-header
#   requirements (D31), header parsing and malformed headers, --parse-header, flag (orchestrator) mode, worktree and
#   CLAUDE_PROJECT_DIR project-root resolution (D18), usage errors.
# shellcheck disable=SC2016,SC2015  # jq programs use single quotes on purpose; A && B || C is deliberate in ok/ko lines
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

new_workdir
B2B=$WORK
copy_agents "$WORK/scaffold"
RL="$WORK/scaffold/.agents/skills/feature-workflow/scripts/resolve-launch.sh"
FX=$WORK/fixture
mkdir -p "$FX"
cd "$FX" || exit 1
git init -q -b main . && git config user.email t@t.invalid && git config user.name tester
mkdir -p .agents/agents model-map profiles specs/007-checkout
for t in implementation integration profile-mini-review retrieval library-evaluation fact-lookup module-audit review-standards review-end-state review-targets cache-regeneration; do
  printf -- '---\nname: %s\ndescription: "x"\n---\nbody\n' "$t" > ".agents/agents/$t.md"
  printf -- '---\ntier: cheap\nclaude: haiku\ncodex: <alias>\n---\n# %s\n' "$t" > "model-map/$t.md"
done
# implementation: definition pins claude sonnet (D35 level 2) and codex gpt-def
cat > .agents/agents/implementation.md <<'EOF'
---
name: implementation
description: "x"
models:
  claude: sonnet
  codex: gpt-def
---
body
EOF
printf -- '---\ntier: strong\nclaude: opus\ncodex: gpt-map\n---\n# implementation\n' > model-map/implementation.md
# overrides: comments + integration override for claude only
cat > agent-overrides.yaml <<'EOF'
# File: comments only header
#   implementation:
#     claude: <alias>
integration:
  claude: opus-override
module-audit:
  claude: "<alias>"
EOF
cat > profiles/frontend.md <<'EOF'
<!-- comment -->
# Profile: frontend

## File locations

- Components: `src/ui`.

## Toolchain

```yaml
lint: "oxlint"
## not a heading inside a fence
```

## Mini-review checklist

- [ ] Error path matches the domain.
- [ ] Names follow GLOSSARY.

## Trailing section

- not in checklist
EOF
printf '# Profile: nochecklist\n\n## File locations\n\n- x\n' > profiles/nochecklist.md
cat > specs/007-checkout/tasks.md <<'EOF'
---
tasks:
  - id: T1
    status: pending
    capability: CAP-001
    depends_on: []
    touches_core: false
    work_type: frontend
  - id: T2
    status: pending
    capability: CAP-001
    depends_on: []
    touches_core: false
    work_type: null
  - id: T3
    status: pending
    capability: CAP-001
    depends_on: []
    touches_core: false
    work_type: ghost
  - id: T4
    status: pending
    capability: CAP-001
    depends_on: []
    touches_core: false
    work_type: nochecklist
---
# Tasks
EOF
mkdir -p specs/008-other
git add -A && git commit -qm fixture
cd "$B2B" || exit 1

hdr() { # hdr key=val ... -> prompt with header + body
  printf '```yaml launch-header\n'
  for kv in "$@"; do printf '%s: %s\n' "${kv%%=*}" "${kv#*=}"; done
  printf '```\n\nDo the task.\n'
}
# run <name> <expected-exit> <jq-assert or ""> <stderr-grep or ""> -- args... (stdin from $IN)
run() {
  local name=$1 want=$2 assert=$3 errpat=$4; shift 5
  local out err code
  out=$(printf '%s' "$IN" | "$RL" "$@" 2>"$B2B/.err"); code=$?
  err=$(cat "$B2B/.err")
  if [ "$code" != "$want" ]; then ko "$name" "exit $code (want $want) stderr: $err"; return; fi
  if [ -n "$assert" ] && ! jq -e "$assert" <<<"$out" >/dev/null 2>&1; then ko "$name" "assert failed: $assert; out: $(head -c 400 <<<"$out")"; return; fi
  if [ -n "$errpat" ] && ! grep -qE -- "$errpat" <<<"$err"; then ko "$name" "stderr lacks /$errpat/: $err"; return; fi
  ok "$name"
}
P=(--project-dir "$FX")

# ── Requirements table ──
IN=""
run "requirements: all 11 types" 0 'keys|length==11' "" -- --requirements
run "requirements: implementation D31 fields" 0 '.implementation.d31_fields==["spec_dir","task_id","work_type"]' "" -- --requirements --task-type implementation
run "requirements: unknown type denied" 2 "" "unknown task type" -- --requirements --task-type nope

# ── Model precedence (D35) ──
IN=$(hdr task_type=integration spec_dir=specs/007-checkout work_type=frontend)
run "precedence 1: override wins (integration claude)" 0 '.model=="opus-override" and .model_source=="override"' "" -- --host claude --task-type integration "${P[@]}"
run "precedence 3: map when no override for host (integration codex placeholder -> none)" 2 "" "00.14" -- --host codex --task-type integration "${P[@]}"
IN=$(hdr task_type=implementation spec_dir=specs/007-checkout task_id=T1)
run "precedence 2: definition beats map (implementation claude)" 0 '.model=="sonnet" and .model_source=="definition"' "" -- --host claude --task-type implementation "${P[@]}"
run "precedence 2: definition codex" 0 '.model=="gpt-def" and .model_source=="definition"' "" -- --host codex --task-type implementation "${P[@]}"
IN=$(hdr task_type=retrieval spec_dir=specs/007-checkout)
run "precedence 3: map (retrieval claude)" 0 '.model=="haiku" and .model_source=="map" and .profile==null and .work_type==null' "" -- --host claude --task-type retrieval "${P[@]}"
run "missing model: map codex placeholder -> 00.14" 2 "" "^resolve-launch.sh: 00.14: no model for task type 'retrieval' on host 'codex'" -- --host codex --task-type retrieval "${P[@]}"
IN=$(hdr task_type=module-audit spec_dir=specs/007-checkout)
run "override placeholder skipped, falls to map" 0 '.model=="haiku" and .model_source=="map"' "" -- --host claude --task-type module-audit "${P[@]}"
mv "$FX/model-map/fact-lookup.md" "$FX/fact.bak"
IN=$(hdr task_type=fact-lookup spec_dir=specs/007-checkout)
run "missing model: no file at any level -> 00.14" 2 "" "00.14" -- --host claude --task-type fact-lookup "${P[@]}"
mv "$FX/fact.bak" "$FX/model-map/fact-lookup.md"
cp "$FX/agent-overrides.yaml" "$FX/ov.bak"
printf 'implementation:\n  claude: opus\n' >> "$FX/agent-overrides.yaml"
IN=$(hdr task_type=implementation spec_dir=specs/007-checkout task_id=T1)
run "precedence 1 over 2: override beats definition" 0 '.model=="opus" and .model_source=="override"' "" -- --host claude --task-type implementation "${P[@]}"
printf 'this: [is: broken\n' > "$FX/agent-overrides.yaml"
run "unparseable overrides -> deny" 2 "" "cannot parse YAML: agent-overrides.yaml" -- --host claude --task-type implementation "${P[@]}"
mv "$FX/ov.bak" "$FX/agent-overrides.yaml"

# ── Header requirements per task type (D31) ──
for t in retrieval library-evaluation fact-lookup module-audit review-standards review-end-state review-targets; do
  IN=$(hdr task_type=$t spec_dir=specs/007-checkout)
  run "$t: spec_dir only accepted" 0 ".task_type==\"$t\" and .header.spec_dir==\"specs/007-checkout\"" "" -- --host claude --task-type $t "${P[@]}"
  IN=$(hdr task_type=$t)
  run "$t: missing spec_dir denied" 2 "" "do not match task type '$t'" -- --host claude --task-type $t "${P[@]}"
  IN=$(hdr task_type=$t spec_dir=specs/007-checkout task_id=T1)
  run "$t: extra task_id denied" 2 "" "D31" -- --host claude --task-type $t "${P[@]}"
done
IN=$(hdr task_type=implementation spec_dir=specs/007-checkout task_id=T1 work_type=frontend)
run "implementation: full header, profile whole, header first" 0 '.work_type=="frontend" and .profile_path=="profiles/frontend.md" and (.profile|contains("## Trailing section")) and (.prompt|startswith("```yaml launch-header\ntask_type: implementation\n")) and (.prompt|test("```\n\n<!-- comment -->\n# Profile: frontend")) and (.prompt|endswith("- not in checklist\n\nDo the task."))' "" -- --host claude --task-type implementation "${P[@]}"
IN=$(hdr task_type=implementation spec_dir=specs/007-checkout task_id=T1)
run "implementation: work_type looked up from tasks.md" 0 '.work_type=="frontend" and (.header|has("work_type")|not)' "" -- --host claude --task-type implementation "${P[@]}"
IN=$(hdr task_type=implementation spec_dir=specs/007-checkout task_id=T1 work_type=backend)
run "implementation: header work_type disagrees with tasks.md" 2 "" "disagrees with task T1" -- --host claude --task-type implementation "${P[@]}"
IN=$(hdr task_type=implementation spec_dir=specs/007-checkout work_type=frontend)
run "implementation Phase 1: no task_id, explicit work_type (D14)" 0 '.work_type=="frontend" and .header.task_id==null and (.profile|length>0)' "" -- --host claude --task-type implementation "${P[@]}"
IN=$(hdr task_type=implementation spec_dir=specs/007-checkout)
run "implementation: spec_dir only denied" 2 "" "accepted: .*Phase 1" -- --host claude --task-type implementation "${P[@]}"
IN=$(hdr task_type=implementation spec_dir=specs/007-checkout task_id=T2)
run "implementation: unclassified task (work_type null) denied" 2 "" "00.18" -- --host claude --task-type implementation "${P[@]}"
IN=$(hdr task_type=implementation spec_dir=specs/007-checkout task_id=T9)
run "implementation: unknown task id denied" 2 "" "T9 not found" -- --host claude --task-type implementation "${P[@]}"
IN=$(hdr task_type=implementation spec_dir=specs/007-checkout task_id=T3)
run "implementation: missing profile -> 00.19" 2 "" "00.19: no profile for work type 'ghost'" -- --host claude --task-type implementation "${P[@]}"
IN=$(hdr task_type=implementation spec_dir=specs/008-other task_id=T1)
run "implementation: no tasks.md in spec_dir denied" 2 "" "tasks.md not found" -- --host claude --task-type implementation "${P[@]}"
IN=$(hdr task_type=implementation spec_dir=specs/009-missing task_id=T1)
run "spec_dir that does not exist denied" 2 "" "does not exist" -- --host claude --task-type implementation "${P[@]}"
IN=$(hdr task_type=integration spec_dir=specs/007-checkout work_type=frontend)
run "integration: spec_dir+work_type, whole profile" 0 '.work_type=="frontend" and (.profile|contains("## File locations"))' "" -- --host claude --task-type integration "${P[@]}"
IN=$(hdr task_type=integration spec_dir=specs/007-checkout work_type=frontend task_id=T1)
run "integration: task_id denied" 2 "" "D31" -- --host claude --task-type integration "${P[@]}"
IN=$(hdr task_type=integration spec_dir=specs/007-checkout)
run "integration: missing work_type denied" 2 "" "D31" -- --host claude --task-type integration "${P[@]}"
IN=$(hdr task_type=profile-mini-review spec_dir=specs/007-checkout task_id=T1 work_type=frontend)
run "profile-mini-review: checklist section only" 0 '(.profile|startswith("## Mini-review checklist")) and (.profile|contains("Names follow GLOSSARY")) and (.profile|contains("Trailing")|not) and (.profile|contains("not a heading")|not)' "" -- --host claude --task-type profile-mini-review "${P[@]}"
IN=$(hdr task_type=profile-mini-review spec_dir=specs/007-checkout work_type=frontend)
run "profile-mini-review: missing task_id denied (no Phase 1 exception)" 2 "" "D31" -- --host claude --task-type profile-mini-review "${P[@]}"
IN=$(hdr task_type=profile-mini-review spec_dir=specs/007-checkout task_id=T4)
run "profile-mini-review: profile lacks checklist -> 00.19" 2 "" "00.19: profile profiles/nochecklist.md has no" -- --host claude --task-type profile-mini-review "${P[@]}"
IN=$(hdr task_type=cache-regeneration spec_dir=specs/007-checkout)
run "cache-regeneration: with spec_dir (0.2.8)" 0 '.header.spec_dir=="specs/007-checkout" and .profile==null' "" -- --host claude --task-type cache-regeneration "${P[@]}"
IN=$'Regenerate docs/cache/modules.md for src/.\n'
run "cache-regeneration: header-less bulk run accepted, prompt unchanged" 0 '.header==null and .header_block==null and .prompt=="Regenerate docs/cache/modules.md for src/.\n"' "" -- --host claude --task-type cache-regeneration "${P[@]}"
run "header-less prompt for retrieval denied" 2 "" "no launch header: task type 'retrieval' requires" -- --host claude --task-type retrieval "${P[@]}"

# ── Mismatch and malformed headers ──
IN=$(hdr task_type=retrieval spec_dir=specs/007-checkout)
run "task_type != subagent_type denied" 2 "" "disagrees with the launched task type 'fact-lookup'" -- --host claude --task-type fact-lookup "${P[@]}"
IN=$(hdr spec_dir=specs/007-checkout)
run "header without task_type denied" 2 "" "no task_type" -- --host claude --task-type retrieval "${P[@]}"
IN=$'```yaml launch-header\ntask_type: retrieval\nspec_dir: specs/007-checkout\n\nDo it.\n'
run "unclosed fence denied" 2 "" "no closing" -- --host claude --task-type retrieval "${P[@]}"
IN=$'```yaml launch-header\ntask_type: [retrieval\n```\nDo it.\n'
run "invalid YAML denied" 2 "" "not valid YAML" -- --host claude --task-type retrieval "${P[@]}"
IN=$'```yaml launch-header\n- a\n- b\n```\n'
run "non-mapping YAML denied" 2 "" "mapping" -- --host claude --task-type retrieval "${P[@]}"
IN=$'```yaml launch-header\n```\n'
run "empty header denied" 2 "" "empty" -- --host claude --task-type retrieval "${P[@]}"
IN=$'Intro line\n```yaml launch-header\ntask_type: retrieval\nspec_dir: specs/007-checkout\n```\n'
run "header not on first line denied" 2 "" "first line" -- --host claude --task-type retrieval "${P[@]}"
IN=$(hdr task_type=retrieval spec_dir=../etc)
run "spec_dir format enforced" 2 "" "malformed header value" -- --host claude --task-type retrieval "${P[@]}"
IN=$(hdr task_type=implementation spec_dir=specs/007-checkout task_id=3)
run "task_id YAML number denied" 2 "" "task_id must be non-empty strings" -- --host claude --task-type implementation "${P[@]}"
IN=$(hdr task_type=implementation spec_dir=specs/007-checkout task_id=task-1)
run "task_id format enforced" 2 "" "task_id=task-1" -- --host claude --task-type implementation "${P[@]}"
IN=$(hdr task_type=implementation spec_dir=specs/007-checkout work_type=../x)
run "work_type format enforced" 2 "" "work_type=../x" -- --host claude --task-type implementation "${P[@]}"
IN=$(hdr task_type=retrieval spec_dir=specs/007-checkout spec_dir_extra=1)
run "unknown header key denied" 2 "" "D31" -- --host claude --task-type retrieval "${P[@]}"
IN=$'```yaml launch-header  \r\ntask_type: retrieval\r\nspec_dir: specs/007-checkout\r\n```\r\nDo it.\r\n'
run "CRLF / trailing spaces tolerated" 0 '.header.spec_dir=="specs/007-checkout"' "" -- --host claude --task-type retrieval "${P[@]}"
IN=$(hdr task_type=implementation spec_dir=specs/007-checkout task_id=null)
run "null value denied" 2 "" "non-empty strings" -- --host claude --task-type implementation "${P[@]}"

# ── --parse-header ──
IN=$(hdr task_type=implementation spec_dir=specs/007-checkout task_id=T1)
run "parse-header: prints header JSON" 0 '.==({task_type:"implementation",spec_dir:"specs/007-checkout",task_id:"T1"})' "" -- --parse-header
run "parse-header: matching --task-type" 0 '.task_id=="T1"' "" -- --parse-header --task-type implementation
run "parse-header: mismatch denied" 2 "" "disagrees" -- --parse-header --task-type integration
IN=$'no header here\n'
run "parse-header: missing header denied" 2 "" "no launch header" -- --parse-header
run "parse-header: header-less cache-regeneration -> {}" 0 '.=={}' "" -- --parse-header --task-type cache-regeneration
printf '%s' "$(hdr task_type=retrieval spec_dir=specs/007-checkout)" > "$B2B/prompt.txt"
IN=""
run "parse-header: --prompt-file" 0 '.task_type=="retrieval"' "" -- --parse-header --prompt-file "$B2B/prompt.txt"

# ── Orchestrator (flag) mode, Codex ──
IN=$'Implement T1.\n'
run "flags: implementation T1 codex, prompt assembled" 0 '.model=="gpt-def" and .header=={task_type:"implementation",spec_dir:"specs/007-checkout",task_id:"T1"} and .header_block=="```yaml launch-header\ntask_type: implementation\nspec_dir: specs/007-checkout\ntask_id: T1\n```" and (. as $o | $o.prompt|startswith($o.header_block+"\n\n<!-- comment -->")) and (.prompt|endswith("Implement T1.\n"))' "" -- --host codex --task-type implementation --spec-dir specs/007-checkout --task-id T1 "${P[@]}"
run "flags: --no-header for bulk cache-regeneration" 0 '.header==null and .prompt=="Implement T1.\n"' "" -- --host claude --task-type cache-regeneration --no-header "${P[@]}"
run "flags: --no-header for retrieval denied" 2 "" "requires" -- --host claude --task-type retrieval --no-header "${P[@]}"
IN=$(hdr task_type=retrieval spec_dir=specs/007-checkout)
run "flags: body carrying its own header denied" 2 "" "must not carry" -- --host claude --task-type retrieval --spec-dir specs/007-checkout "${P[@]}"
IN=""
run "flags: no stdin body -> header-only prompt" 0 '.prompt==.header_block' "" -- --host claude --task-type retrieval --spec-dir specs/007-checkout "${P[@]}" 

# ── Project root resolution (D18) ──
git -C "$FX" worktree add -q "$B2B/wt" -b wt-branch 2>/dev/null
rm -f "$B2B/wt/profiles/frontend.md"   # worktree copy differs: script must read the main checkout
IN=$(hdr task_type=implementation spec_dir=specs/007-checkout task_id=T1)
run "worktree --project-dir resolves to main checkout" 0 '.profile_path=="profiles/frontend.md" and (.profile|length>0)' "" -- --host claude --task-type implementation --project-dir "$B2B/wt"
out=$(cd "$B2B/wt" && printf '%s' "$IN" | CLAUDE_PROJECT_DIR="$FX" "$RL" --host claude --task-type implementation 2>&1) && jq -e '.model=="sonnet"' <<<"$out" >/dev/null && ok "CLAUDE_PROJECT_DIR default" || ko "CLAUDE_PROJECT_DIR default" "$out"
out=$(cd "$B2B/wt" && printf '%s' "$IN" | "$RL" --host claude --task-type implementation 2>&1) && jq -e '.work_type=="frontend"' <<<"$out" >/dev/null && ok "cwd default inside worktree -> main checkout" || ko "cwd default inside worktree" "$out"
git -C "$FX" worktree remove --force "$B2B/wt"

# ── Usage errors ──
IN=$(hdr task_type=retrieval spec_dir=specs/007-checkout)
run "usage: missing --host" 1 "" "missing --host" -- --task-type retrieval "${P[@]}"
run "usage: bad --host" 1 "" "claude or codex" -- --host gemini --task-type retrieval "${P[@]}"
run "usage: missing --task-type" 1 "" "missing --task-type" -- --host claude "${P[@]}"
out=$(printf x | PATH=/usr/bin:/bin "$RL" --parse-header 2>&1); c=$?
{ [ $c = 1 ] && grep -q "jq not found\|yq not found" <<<"$out"; } && ok "usage: missing yq/jq is exit 1" || ko "missing yq" "$c $out"


shellcheck_files "shellcheck: resolve-launch.sh" "$RL"
finish
