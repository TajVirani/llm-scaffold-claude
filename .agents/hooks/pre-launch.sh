#!/usr/bin/env bash
# File: Hook (Claude adapter): resolve, validate and complete every sub-agent launch (D33). Replaces pre-launch-validate.sh and the SubagentStart backstop subagent-start-profile.sh; earlier also pre-launch-model-selection and pre-launch-profile-injection (D13).
# Goals:
#   - Read tool_input (description, prompt, subagent_type, run_in_background; model/isolation only when set) and take the task type from subagent_type
#   - Call skills/feature-workflow/scripts/resolve-launch.sh, which holds the rules (D9): it parses the fenced ```yaml launch-header block on the first line of the prompt (task_type + fields; D37) and checks it against the fields required for the task type (D31) and returns the model alias and profile text:
#       implementation: spec_dir, task_id; work_type optional, looked up from tasks.md; a mismatch is denied (Phase 1 verification-setup launches: spec_dir, work_type, no task_id; D14)
#       integration: spec_dir, work_type (a batch with one work type, no task_id; D28)
#       profile-mini-review: spec_dir, task_id; work_type optional, looked up from tasks.md; a mismatch is denied (one task under one profile)
#       retrieval, library-evaluation, fact-lookup, module-audit, review-standards, review-end-state, review-targets: spec_dir
#       cache-regeneration: spec_dir when launched inside a feature (0.2.8); no header for bulk regenerate-caches runs
#   - Deny with reason when a required header field is missing, no model resolves for this host (no agent-overrides.yaml entry, no definition `models.<host>`, no model-map entry: surface 00.14), or a coding launch (implementation, integration, profile-mini-review) has no profile (surface 00.19)
#   - Otherwise allow and return updatedInput: the FULL tool_input (all original keys kept) with the profile text inserted into `prompt` right after the launch-header block, so the header stays first (D37) (whole for implementation/integration, Mini-review checklist section only for profile-mini-review, none for other types) and `model` set to the value resolve-launch.sh resolved by precedence: agent-overrides.yaml[type][host] > definition `models.<host>` > model-map/<type>.md [host] > none (00.14) (D35). Claude Code does not read the definition's `models:` key natively, so this hook is what applies it
# Codex equivalent: codex-pre-spawn.sh (PreToolUse `.*spawn_agent`; validates agent_type and task_name only, the message is encrypted).
# Behaviour:
#   - tool_name other than Agent (or legacy Task): exit 0, no output.
#   - subagent_type not one of the workflow task types (resolve-launch.sh --requirements): exit 0, no output. Built-in and other agents
#     (Explore, general-purpose, ...) are untouched.
#   - Project root without .agents/skills/feature-workflow: exit 0, no output (workflow not installed). A project that has the workflow but
#     no model-map/, agent-overrides.yaml or profiles/ is denied by resolve-launch.sh (00.14 / 00.19), which says what to set up.
#   - resolve-launch.sh exit 0: allow + updatedInput; exit 2: deny with its stderr reason; any other failure (exit 1, bad JSON, no model,
#     jq missing, unreadable payload): deny, fail closed, with an environment-error reason.
# Triggers/inputs: PreToolUse JSON on stdin for the Agent tool. Paths from the payload `cwd`, not $CLAUDE_PROJECT_DIR (D18); $CLAUDE_PROJECT_DIR
#   and then the hook's working directory are used only when the payload has no usable cwd. The root is normalised to the main checkout
#   (git rev-parse --git-common-dir), so a worktree cwd works.
# Outputs/handoff: stdout is exactly one JSON object or nothing:
#   {"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","updatedInput":{...}}}
#   {"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"pre-launch: ..."}}
#   Exit code is always 0.
# Wiring: claude-settings.template.json (merged into <target>/.claude/settings.json by install.sh, D36): PreToolUse, matcher "Agent", timeout 30.
# Plan refs: 00.11-00.14, 00.18-00.20; reference "Hooks", "Model selection"; assetlist D9, D13, D14, D18, D31, D32, D33, D34, D35, D37.
# Notes: Verified on Claude Code 2.1.300 (PLAN/hook-verification.md): updatedInput can rewrite prompt and model; 2.1.300 validates it, dropping unknown keys and denying the call on invalid input, so always send the complete, valid input. Known risk (D33): a large profile could make the launch fail on a prompt-size limit; no mitigation now, handle it if hit. SubagentStart carries no prompt or model, so it cannot serve as a backstop (D33). No nested launches in v1 (D32). Codex: the spawn message is encrypted, so no hook can rewrite it; the orchestrator calls resolve-launch.sh itself and places model and profile in the launch (advisory, D9), and codex-pre-spawn.sh checks the plaintext agent_type and task_name.
# Sources: first-party; PLAN/hook-verification/hooks/pre_agent_rewrite.sh (full tool_input rewrite, output shape), PLAN/hook-verification.md T2/T5/T7; hooks/block-destructive-git.sh (deny JSON).
# Requires: bash, jq; resolve-launch.sh additionally needs mikefarah yq v4 (D38) and optionally git.

set -euo pipefail

# Deny without jq (hand-written JSON; the reason is a fixed string).
deny_raw() {
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"pre-launch: environment error: jq not found; install jq to launch sub-agents in this project (fail closed)"}}'
  exit 0
}
deny() {
  jq -cn --arg r "pre-launch: $1" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
  exit 0
}
env_deny() { deny "environment error (fail closed): $1"; }

command -v jq >/dev/null 2>&1 || deny_raw

payload=$(cat)
jq -e 'type == "object"' <<<"$payload" >/dev/null 2>&1 || env_deny "PreToolUse payload on stdin is not a JSON object"

tool_name=$(jq -r '.tool_name // "" | strings' <<<"$payload")
case "$tool_name" in Agent|Task) ;; *) exit 0 ;; esac

subagent_type=$(jq -r '.tool_input.subagent_type // "" | strings' <<<"$payload")
[ -n "$subagent_type" ] || exit 0

# ── Project root: payload cwd > $CLAUDE_PROJECT_DIR > $PWD, normalised to the main checkout (D18) ──
root=$(jq -r '.cwd // "" | strings' <<<"$payload")
[ -n "$root" ] && [ -d "$root" ] || root=${CLAUDE_PROJECT_DIR:-}
[ -n "$root" ] && [ -d "$root" ] || root=$PWD
root=$(cd "$root" && pwd)
if common=$(git -C "$root" rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then
  root=$(dirname "$common")
fi

[ -d "$root/.agents/skills/feature-workflow" ] || exit 0
resolver=$root/.agents/skills/feature-workflow/scripts/resolve-launch.sh
[ -f "$resolver" ] || env_deny "${resolver#"$root"/} not found although .agents/skills/feature-workflow exists; reinstall the scaffold"

# ── Workflow task types (D31 table, owned by resolve-launch.sh) ──
types=$(bash "$resolver" --requirements 2>/dev/null | jq -r 'keys[]' 2>/dev/null) \
  || env_deny "could not read the task-type table from resolve-launch.sh --requirements"
[ -n "$types" ] || env_deny "resolve-launch.sh --requirements returned no task types"
grep -qxF -- "$subagent_type" <<<"$types" || exit 0

# ── Resolve ──
errfile=$(mktemp "${TMPDIR:-/tmp}/pre-launch.XXXXXX")
trap 'rm -f "$errfile"' EXIT
rc=0
result=$(jq -j '.tool_input.prompt // "" | strings' <<<"$payload" \
  | bash "$resolver" --host claude --task-type "$subagent_type" --project-dir "$root" 2>"$errfile") || rc=$?
reason=$(sed -e 's/^resolve-launch\.sh: //' "$errfile" | tr '\n' ' ' | sed -e 's/[[:space:]]*$//')

case "$rc" in
  0) ;;
  2) deny "launch of '$subagent_type' refused: ${reason:-resolve-launch.sh denied without a reason}" ;;
  *) env_deny "resolve-launch.sh exited $rc${reason:+: $reason}" ;;
esac

jq -e '(.prompt | type) == "string"' <<<"$result" >/dev/null 2>&1 \
  || env_deny "resolve-launch.sh returned no prompt"
model=$(jq -r '.model // "" | strings' <<<"$result")
[ -n "$model" ] || env_deny "resolve-launch.sh resolved no model for '$subagent_type'"

# updatedInput: the FULL tool_input (2.1.300 validates it; unknown keys dropped, invalid input denies), with prompt and model replaced.
jq -cn --argjson p "$payload" --argjson r "$result" '
  {hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "allow",
    updatedInput: ($p.tool_input + {prompt: $r.prompt, model: $r.model})}}'
