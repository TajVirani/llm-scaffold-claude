#!/usr/bin/env bash
# File: Hook (Claude and Codex adapter): run the profile toolchain when an implementation or integration agent tries to stop.
# Goals:
#   - Call skills/feature-workflow/scripts/run-toolchain.sh for the task (lint, typecheck, format, boundary, test per the profile's Toolchain YAML block)
#   - Failure: block the stop and return the tool output, so the implementer keeps fixing in the same context
#   - Success: let the stop through; evidence is saved to .workflow/specs/NNN-slug/artifacts/<task-id>/ and the orchestrator then launches `profile-mini-review` (a hook cannot launch an agent)
#   - Neither step skippable
# Triggers/inputs: SubagentStop JSON on stdin; act only for agent_type `implementation`, and on Claude also `integration`. Task identified
#   from the launch header: the payload carries no prompt, so read agent_transcript_path (JSONL), take the first user message (first entry
#   with type "user", message.role "user", not isMeta, with text content: a string, or the joined text blocks of an array) and parse its
#   ```yaml launch-header block with resolve-launch.sh --parse-header --task-type <agent_type>. Scripts and evidence are found in the
#   main checkout (git rev-parse --git-common-dir), like pre-launch.sh.
#   Codex: the spawn message is encrypted, so the task comes from the plaintext spawn task_name instead. A Codex transcript starts with a
#   session_meta record whose payload.agent_path is /root/<task_name> (payload.source.subagent.thread_spawn.agent_path as fallback); its last
#   segment is parsed. Codex accepts only [a-z0-9_] in a task_name, so the orchestrator encodes:
#     s<NNN>_t<N>                  task T<N> of the one spec folder .workflow/specs/<NNN>-*  (e.g. .workflow/specs/007-checkout + T3 -> s007_t3)
#     s<NNN>_phase_1_<enc(wt)>     Phase 1 launch; work_type = the one .workflow/profiles/<wt>.md whose enc(name) matches (enc: lowercase, non [a-z0-9] -> _)
#     s<NNN>_integration_<enc(wt)> integration batch (a Codex integration agent is not audited; on an implementation agent: warning)
#   Anything else, or no single matching spec folder or profile: allowed with a warning, like a missing Claude header.
#   Codex has no worktree sub-agents: the payload cwd is the main checkout. The orchestrator creates the worktree as
#   <main checkout>/.workflow/.worktrees/<task_name> (a Phase 3 task: branch task/<NNN-slug>/T<nn>-<slug> from the tasks.md record;
#   Phase 1: wf/<NNN-slug>/<task_name>), so the toolchain runs there; evidence stays in the main checkout. No such directory: allowed with a
#   warning, since auditing the main checkout would test the wrong tree.
#   Claude launches (Phase 3 task, Phase 1 and integration): the orchestrator also creates the agent worktree itself, under the name Codex
#   uses (lib/workflow-paths.sh wf_agent_worktree_name: .workflow/.worktrees/s<NNN>_t<N>, s<NNN>_phase_1_<enc(wt)> or
#   s<NNN>_integration_<enc(wt)>), and launches the agent without isolation, because the Agent tool has no working-directory input (Claude
#   Code docs, sub-agents and worktrees pages, checked 2026-10-19). The audit runs the toolchain in that directory when it exists. Fallback:
#   the launch used isolation: "worktree" (payload cwd is a linked worktree, e.g. .claude/worktrees/agent-<id>), so that cwd is audited.
#   Neither (no agent worktree and the payload cwd is the main checkout): allowed with a warning naming the missing worktree.
# Behaviour:
#   - agent_type other than implementation or integration, a Codex integration agent, an integration agent whose transcript is missing or
#     unreadable (either host), or no .agents/skills/feature-workflow in the main checkout: exit 0, no output, no evidence file.
#   - Task launch header (spec_dir, task_id[, work_type]): run-toolchain.sh --spec-dir --task-id --cwd <worktree> --reuse [--work-type] (Claude:
#     .workflow/.worktrees/s<NNN>_t<N>, else the isolation-worktree payload cwd; Codex: .workflow/.worktrees/<task_name>). run-toolchain.sh
#     scopes `test` to the task (other unfinished tasks' Phase 1 tests excluded). Without a
#     header work_type, run-toolchain.sh reads it from tasks.md (pre-launch.sh already denied a disagreeing header value).
#   - Phase 1 header (spec_dir, work_type, no task_id): run-toolchain.sh with --work-type and the evidence id `phase-1-<work_type>`, so the
#     two Phase 1 launches (1.2 harness, 1.3 browser suite) keep separate evidence under artifacts/phase-1-<work_type>/.
#     The Phase 1 stop audit (Claude header and Codex s<NNN>_phase_1_<wt> alike) passes `--skip test`: the new tests written at 1.2/1.3 are red by
#     design (step 1.4 proves the failure), so only lint, typecheck, format and boundary gate those stops. Phase 3 task audits still run `test`.
#   - Integration header (spec_dir, work_type), Claude only: run-toolchain.sh with --work-type, the evidence id `integration-<work_type>` (the
#     folder its result file uses) and --exclude-unfinished, the scoping of the integration agent's own run; the full toolchain, no --skip.
#   - run-toolchain.sh exit 0: exit 0, no output (evidence already saved by the script); the loop counter is cleared.
#   - exit 1: {"decision":"block","reason":<digest>}. Loop guard: <spec>/artifacts/<task-id>/audit-loop.json (main checkout) holds the sha256
#     of the last digest and a repeat count. The count restarts at 1 when stop_hook_active is false or the digest changed, and goes up by one
#     when stop_hook_active is true and the digest is identical. At 3 identical failures in a row the stop is allowed, and the give-up is
#     recorded in <spec>/artifacts/<task-id>/audit.json (toolchain.json keeps status "fail" for the orchestrator).
#   - Missing or malformed header (resolve-launch.sh exit 2), an implementation agent's missing or unreadable transcript, run-toolchain.sh config error (exit 2: no profile, no
#     Toolchain block, ...) or any environment error: the implementer cannot fix its own launch or the project setup, so the stop is ALLOWED
#     with a warning for the orchestrator: a `systemMessage` in the output, the reason on stderr, and, when the spec dir is known, audit.json
#     under artifacts/<task-id>/ (or artifacts/audit-warnings.jsonl when no task id is known). It deliberately does not block
#     with a reason here: blocking would loop on something the agent cannot change.
# Outputs/handoff: stdout is nothing, {"decision":"block","reason":...}, or {"systemMessage":...}; exit code always 0. Tool output feeds 3.7 and 4.1.
#   audit.json: {outcome: "gave-up"|"warning", reason, task_id, spec_dir, repeats?, digest_sha256?, at}.
# Wiring: claude-settings.template.json (merged into <target>/.claude/settings.json by install.sh): SubagentStop, matcher "implementation|integration" (matches agent type); the script also filters on agent_type.
#   codex-hooks.template.json (<target>/.codex/hooks.json): SubagentStop with no matcher; the agent_type filter does the work.
# Notes: Codex SubagentStop block-with-reason and stop_hook_active verified on 0.155.1; agent_path in the
#   transcript checked against the 0.155.1 run-3 rollouts. Codex has no worktree sub-agents, so the payload cwd is the main checkout and the
#   worktree is found from the task_name (.workflow/.worktrees/<task_name>, see above).
#   The loop guard compares exact digests: tool output that embeds timings or other varying text resets the count, so such a loop ends only when the agent stops changing nothing.
# Sources: first-party; hooks/pre-launch.sh (main-checkout resolution); lib/workflow-paths.sh (wf_enc, wf_agent_worktree_name).
# Requires: bash, jq, mikefarah yq v4 (through the shared scripts), git (optional), shasum or sha256sum.

set -euo pipefail

# shellcheck source=../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/workflow-paths.sh"

MAX_REPEATS=3

command -v jq >/dev/null 2>&1 || { echo "post-implementation-audit: jq not found; audit skipped" >&2; exit 0; }

payload=$(cat)
jq -e 'type == "object"' <<<"$payload" >/dev/null 2>&1 || { echo "post-implementation-audit: payload is not a JSON object" >&2; exit 0; }

agent_type=$(jq -r '.agent_type // "" | strings' <<<"$payload")
case "$agent_type" in implementation|integration) ;; *) exit 0 ;; esac

cwd=$(jq -r '.cwd // "" | strings' <<<"$payload")
[ -n "$cwd" ] && [ -d "$cwd" ] || cwd=${CLAUDE_PROJECT_DIR:-$PWD}
cwd=$(cd "$cwd" && pwd)
main_root=$cwd
if common=$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then
  main_root=$(dirname "$common")
fi
scripts=$main_root/.agents/skills/feature-workflow/scripts
[ -d "$main_root/.agents/skills/feature-workflow" ] || exit 0

transcript=$(jq -r '.agent_transcript_path // "" | strings' <<<"$payload")
stop_active=$(jq -r 'if .stop_hook_active == true then "true" else "false" end' <<<"$payload")

tmp=$(mktemp -d "${TMPDIR:-/tmp}/post-impl-audit.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

now() { date -u +%Y-%m-%dT%H:%M:%SZ; }
sha() { if command -v sha256sum >/dev/null 2>&1; then sha256sum | cut -d' ' -f1; else shasum -a 256 | cut -d' ' -f1; fi; }

spec_dir="" task_id=""

# Allow the stop with a warning for the orchestrator. $1 = reason.
warn_allow() {
  local reason="post-implementation-audit: $1" spec_abs
  echo "$reason" >&2
  if [ -n "$spec_dir" ] && [ -d "$main_root/$spec_dir" ]; then
    spec_abs=$main_root/${spec_dir%/}
    if [ -n "$task_id" ]; then
      mkdir -p "$spec_abs/artifacts/$task_id" 2>/dev/null &&
        jq -n --arg r "$reason" --arg t "$task_id" --arg s "$spec_dir" --arg at "$(now)" \
          '{outcome: "warning", reason: $r, task_id: $t, spec_dir: $s, at: $at}' > "$spec_abs/artifacts/$task_id/audit.json" || true
    else
      mkdir -p "$spec_abs/artifacts" 2>/dev/null &&
        jq -cn --arg r "$reason" --arg s "$spec_dir" --arg at "$(now)" \
          '{outcome: "warning", reason: $r, spec_dir: $s, at: $at}' >> "$spec_abs/artifacts/audit-warnings.jsonl" || true
    fi
  fi
  jq -cn --arg m "$reason. The implementation stop was allowed without a passing toolchain audit; the orchestrator must handle this before 3.7." \
    '{systemMessage: $m}'
  exit 0
}

if [ -z "$transcript" ] || [ ! -f "$transcript" ]; then
  # Nothing identifies an integration stop without its transcript; it passes silently, as integration stops did before they were audited.
  [ "$agent_type" = implementation ] || exit 0
  warn_allow "agent_transcript_path missing or unreadable ('$transcript'); cannot identify the task"
fi

# ── Codex: the task comes from the spawn task_name ──
# A Codex rollout starts with a session_meta record whose payload.agent_path is /root/[<parent>/]<task_name> (verified 0.155.1).
agent_path=$(head -n 1 "$transcript" | jq -r 'select(type == "object" and .type == "session_meta") | .payload
  | (.agent_path // .source.subagent.thread_spawn.agent_path // "") | strings' 2>/dev/null || true)

# Codex integration stops pass unaudited, as before: codex_task below turns only implementation task_names into a toolchain run.
[ -z "$agent_path" ] || [ "$agent_type" = implementation ] || exit 0

codex_task() {
  local name=${agent_path##*/} num rest enc matches=() d wt="" p seen=" "
  if [[ "$name" =~ ^s([0-9]+)_(.+)$ ]]; then
    num=${BASH_REMATCH[1]} rest=${BASH_REMATCH[2]}
  else
    warn_allow "Codex task_name '$name' (agent_path $agent_path) is not s<NNN>_t<N> or s<NNN>_phase_1_<work_type>; cannot identify the task"
  fi
  for d in "$main_root/$WF_SPECS/$num"-*/; do [ -d "$d" ] && matches+=("$d"); done
  [ "${#matches[@]}" -eq 1 ] || warn_allow "Codex task_name '$name': ${#matches[@]} spec folders match $WF_SPECS/$num-* (need exactly one)"
  spec_dir=$WF_SPECS/$(basename "${matches[0]}")
  if [[ "$rest" =~ ^t([0-9]+)$ ]]; then
    task_id=T${BASH_REMATCH[1]}
  elif [[ "$rest" =~ ^phase_1_([a-z0-9_]+)$ ]]; then
    enc=${BASH_REMATCH[1]}
    # Recover the work type by encoding each profile name the same way; it must match exactly one.
    matches=()
    for p in "$main_root/$WF_WORKTREES/$name/$WF_PROFILES"/*.md "$main_root/$WF_PROFILES"/*.md; do
      [ -f "$p" ] || continue
      d=$(basename "$p" .md)
      case "$seen" in *" $d "*) continue ;; esac
      seen="$seen$d "
      [ "$(wf_enc "$d")" = "$enc" ] && matches+=("$d")
    done
    [ "${#matches[@]}" -eq 1 ] || warn_allow "Codex task_name '$name': ${#matches[@]} profiles under $WF_PROFILES/ encode to '$enc' (need exactly one)"
    wt=${matches[0]}
  elif [[ "$rest" =~ ^integration_ ]]; then
    warn_allow "Codex task_name '$name' names an integration batch, but the agent is implementation"
  else
    warn_allow "Codex task_name '$name' is not s<NNN>_t<N> or s<NNN>_phase_1_<work_type>; cannot identify the task"
  fi
  header=$(jq -cn --arg s "$spec_dir" --arg t "$task_id" --arg w "$wt" \
    '{spec_dir: $s} + (if $t != "" then {task_id: $t} else {} end) + (if $w != "" then {work_type: $w} else {} end)')
  # The implementer's worktree, created by the orchestrator (Codex has no isolation option); the toolchain must run there.
  # A Phase 1 warning is filed under its evidence id (task_id is re-read from the header afterwards).
  [ -n "$task_id" ] || task_id=phase-1-$wt
  [ -d "$main_root/$WF_WORKTREES/$name" ] ||
    warn_allow "Codex task_name '$name': no worktree at $WF_WORKTREES/$name in the main checkout; the toolchain was not run (it would audit the main checkout, not the implementer's work)"
  cwd=$(cd "$main_root/$WF_WORKTREES/$name" && pwd)
}

# Lenient spec_dir recovery, used only to file warnings when the strict parse fails.
lenient_spec_dir() {
  local block
  block=$(awk 'NR==1 && $0 ~ /^```yaml launch-header[[:space:]]*$/ {f=1; next} f && /^```[[:space:]]*$/ {exit} f {print}' "$tmp/prompt")
  [ -n "$block" ] || return 0
  printf '%s\n' "$block" | yq -r '.spec_dir // "" | select(tag == "!!str")' 2>/dev/null \
    | grep -E "^$(printf '%s' "$WF_SPECS" | sed 's/[.]/\\./g')/[0-9]+-[A-Za-z0-9._-]+/?\$" | head -n1 || true
}

# ── Claude: launch prompt = first user message of the sub-agent transcript ──
claude_task() {
  jq -rs '
    [ .[] | select(type == "object" and .type == "user" and (.isMeta != true) and (.message.role // "user") == "user")
          | .message.content
          | if type == "string" then .
            elif type == "array" then ([ .[] | select(type == "object" and .type == "text") | .text ] | join("\n"))
            else "" end
          | select(. != "") ]
    | first // empty' "$transcript" > "$tmp/prompt" 2>/dev/null \
    || warn_allow "agent transcript is not valid JSONL: $transcript"
  [ -s "$tmp/prompt" ] || warn_allow "no user message with text in $transcript; cannot identify the task"

  local rc=0
  header=$(bash "$scripts/resolve-launch.sh" --parse-header --task-type "$agent_type" --prompt-file "$tmp/prompt" 2>"$tmp/err") || rc=$?
  if [ "$rc" -ne 0 ]; then
    spec_dir=$(lenient_spec_dir)
    case "$rc" in
      2) warn_allow "launch header missing or malformed: $(tr '\n' ' ' < "$tmp/err")" ;;
      *) warn_allow "resolve-launch.sh --parse-header failed (exit $rc): $(tr '\n' ' ' < "$tmp/err")" ;;
    esac
  fi
}

header=""
if [ -n "$agent_path" ]; then codex_task; else claude_task; fi

spec_dir=$(jq -r '.spec_dir // ""' <<<"$header")
spec_dir=${spec_dir%/}
task_id=$(jq -r '.task_id // ""' <<<"$header")
work_type=$(jq -r '.work_type // ""' <<<"$header")
[ -n "$spec_dir" ] || warn_allow "launch header has no spec_dir"

args=(--spec-dir "$spec_dir" --reuse)   # an unchanged tree with a passing record from the implementer's own run is not run again
if [ -n "$task_id" ]; then
  worktree_kind=task worktree_value=$task_id
  args+=(--task-id "$task_id")
elif [ "$agent_type" = integration ]; then
  [ -n "$work_type" ] || warn_allow "integration launch header has no work_type"
  worktree_kind=integration worktree_value=$work_type
  task_id=integration-$work_type
  # The same scoping as the integration agent's own run, so that passing record is reused: other tasks' Phase 1 tests are red by design.
  args+=(--task-id "$task_id" --exclude-unfinished)
else
  # Phase 1 launch: no task record yet.
  [ -n "$work_type" ] || warn_allow "Phase 1 launch header has no work_type"
  worktree_kind=phase_1 worktree_value=$work_type
  task_id=phase-1-$work_type
  args+=(--task-id "$task_id" --skip test)   # Phase 1 tests are red by design
fi
[ -z "$work_type" ] || args+=(--work-type "$work_type")

# The orchestrator makes the agent worktree; an isolation launch has none, so the payload cwd is the fallback.
if [ -z "$agent_path" ]; then
  # A header the lib cannot name still leaves the isolation cwd to audit, so the reason only goes into the warning.
  if wt_name=$(wf_agent_worktree_name "$spec_dir" "$worktree_kind" "$worktree_value" 2>"$tmp/err"); then
    missing="no worktree at $WF_WORKTREES/$wt_name"
  else
    wt_name="" missing="no agent worktree name ($(tr '\n' ' ' < "$tmp/err"))"
  fi
  if [ -n "$wt_name" ] && [ -d "$main_root/$WF_WORKTREES/$wt_name" ]; then
    cwd=$(cd "$main_root/$WF_WORKTREES/$wt_name" && pwd)
  else
    gd=$(git -C "$cwd" rev-parse --path-format=absolute --git-dir 2>/dev/null || true)
    gc=$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)
    if [ -z "$gd" ] || [ "$gd" = "$gc" ]; then
      warn_allow "$task_id: $missing and the agent ran in the main checkout; the toolchain was not run (it would audit the main checkout, not the agent's work)"
    fi
  fi
fi
args+=(--cwd "$cwd")

# ── Run the toolchain (3.5) ──
rc=0
bash "$scripts/run-toolchain.sh" "${args[@]}" > "$tmp/out" 2>"$tmp/err" || rc=$?
evidence=$main_root/$spec_dir/artifacts/$task_id
counter=$evidence/audit-loop.json

case "$rc" in
  0)
    rm -f "$counter" "$evidence/audit.json"
    exit 0
    ;;
  1) ;;
  *) warn_allow "run-toolchain.sh could not run the toolchain (exit $rc): $(tail -n 5 "$tmp/err" | tr '\n' ' ')" ;;
esac

digest=$(jq -r '.digest // ""' "$tmp/out" 2>/dev/null || true)
[ -n "$digest" ] || digest=$(cat "$tmp/err")
[ -n "$digest" ] || digest="Toolchain failed for task $task_id. Full output: $evidence/toolchain.txt"

# ── Loop guard ──
dsha=$(printf '%s' "$digest" | sha)
count=1
if [ "$stop_active" = true ] && [ -f "$counter" ]; then
  prev=$(jq -r '.digest_sha256 // ""' "$counter" 2>/dev/null || true)
  if [ "$prev" = "$dsha" ]; then
    count=$(( $(jq -r '.count // 0 | tonumber? // 0' "$counter" 2>/dev/null || echo 0) + 1 ))
  fi
fi
mkdir -p "$evidence"
jq -n --arg s "$dsha" --argjson c "$count" --arg at "$(now)" '{digest_sha256: $s, count: $c, updated_at: $at}' > "$counter"

if [ "$count" -ge "$MAX_REPEATS" ]; then
  reason="post-implementation-audit: gave up after $count identical toolchain failures in a row for task $task_id; stop allowed with the toolchain still failing (see toolchain.json, toolchain-digest.txt)"
  jq -n --arg r "$reason" --arg t "$task_id" --arg s "$spec_dir" --argjson c "$count" --arg d "$dsha" --arg at "$(now)" \
    '{outcome: "gave-up", reason: $r, task_id: $t, spec_dir: $s, repeats: $c, digest_sha256: $d, at: $at}' > "$evidence/audit.json"
  rm -f "$counter"
  echo "$reason" >&2
  jq -cn --arg m "$reason. The orchestrator must treat the 3.6 gate as failed." '{systemMessage: $m}'
  exit 0
fi

jq -cn --arg r "$digest" '{decision: "block", reason: $r}'
exit 0
