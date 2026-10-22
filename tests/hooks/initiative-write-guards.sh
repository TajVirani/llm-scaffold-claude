#!/usr/bin/env bash
# Suite: the write guards for initiative files; JRN-006 "Write guards for initiative files".
# Covers: hooks/spec-single-writer-guard.sh, hooks/tier-a-write-guard.sh and hooks/tier-b-write-guard.sh (thin adapters over
#   feature-workflow/scripts/check-write.sh) on PreToolUse Write payloads: initiative.md denied at a 6.x step that does not write it
#   and allowed at a writer step; questions.md allowed at any step; a sub-agent write to initiative.md and any Write to the initiative
#   .step denied; a glossary write with no spec in flight allowed at a 6.x term-gate step and denied at another 6.x step; edge
#   cases: questions.md unguarded for sub-agents, a non-6.x or missing initiative marker, a done initiative not in flight. Every
#   guard runs on every payload: the decision is a deny when any guard denies, so the suite does not depend on which guard owns the
#   initiative class.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/initiative.sh
source "$TESTS_DIR/fixtures/initiative.sh"
preflight

new_workdir
P=$WORK/proj
large_path_repo "$P"
seed_initiative "$P" 001 storage-overhaul
INI=.workflow/initiatives/001-storage-overhaul
H=$P/.agents/hooks
GUARDS="spec-single-writer-guard tier-a-write-guard tier-b-write-guard"
at() { initiative_transition "$P" step "$INI" "$1" >/dev/null 2>&1 || echo "setup failed: initiative step $1" >&2; }

# payload PATH [EXTRA_JSON] : PreToolUse Write payload from the main session; EXTRA merges into the top level.
payload() {
  local extra=${2:-}
  [ -n "$extra" ] || extra='{}'
  jq -cn --arg p "$1" --arg c "$P" --argjson x "$extra" \
    '{session_id:"s",transcript_path:"/x",cwd:$c,hook_event_name:"PreToolUse",tool_name:"Write",tool_use_id:"u",tool_input:{file_path:$p,content:"x"}} + $x'
}
SUB='{"agent_id":"a1","agent_type":"research"}'

# decide PAYLOAD : runs every guard; sets decision (allow|deny|error) and reason (the first deny's reason).
decide() {
  local g out rc
  decision=allow reason=""
  for g in $GUARDS; do
    out=$(printf '%s' "$1" | (cd "$P" && bash "$H/$g.sh" 2>/dev/null))
    rc=$?
    if [ "$rc" != 0 ]; then decision=error reason="$g exited $rc"; return; fi
    [ -n "$out" ] || continue
    if [ "$(jq -r '.hookSpecificOutput.permissionDecision // empty' <<<"$out" 2>/dev/null)" = deny ]; then
      decision=deny reason=$(jq -r '.hookSpecificOutput.permissionDecisionReason // empty' <<<"$out")
      return
    fi
  done
}
# expect NAME allow|deny PAYLOAD [REASON_REGEX]
expect() {
  decide "$3"
  if [ "$decision" != "$2" ]; then ko "$1" "decision=$decision want=$2 reason=$reason"; return; fi
  if [ "$2" = deny ] && [ -n "${4:-}" ] && ! grep -qE -- "$4" <<<"$reason"; then ko "$1" "reason lacks /$4/: $reason"; return; fi
  ok "$1"
}

echo "== JRN-006 initiative.md and questions.md"
at "$INITIATIVE_READONLY_STEP"
eq "JRN-006 the initiative marker is at the read-only step" "$(marker_step "$P/$INI/.step")" "$INITIATIVE_READONLY_STEP"
expect "JRN-006 initiative.md at a 6.x step that does not write it is denied" deny "$(payload "$INI/initiative.md")" "initiative\.md"
expect "JRN-006 questions.md at that step is allowed" allow "$(payload "$INI/questions.md")"
at "$INITIATIVE_WRITER_STEP"
eq "JRN-006 the initiative marker is at the writer step" "$(marker_step "$P/$INI/.step")" "$INITIATIVE_WRITER_STEP"
expect "JRN-006 initiative.md at a writer step is allowed" allow "$(payload "$INI/initiative.md")"
expect "JRN-006 questions.md at the writer step is allowed" allow "$(payload "$INI/questions.md")"
expect "JRN-006 initiative.md from a sub-agent is denied" deny "$(payload "$INI/initiative.md" "$SUB")" "sub-agent"
expect "JRN-006 the initiative .step is never written by Write" deny "$(payload "$INI/.step")" "initiative-transition"

echo "== JRN-006 glossary writes from an initiative, no spec in flight"
check "JRN-006 fixture: no spec is in flight" '[ -z "$(ls -d "$P"/.workflow/specs/[0-9]*/ 2>/dev/null)" ]'
at "$LARGE_TERM_GATE_STEP"
expect "JRN-006 glossary at a 6.x term-gate step is allowed" allow "$(payload .workflow/GLOSSARY.md)"
at "$INITIATIVE_READONLY_STEP"
expect "JRN-006 glossary at another 6.x step is denied" deny "$(payload .workflow/GLOSSARY.md)" "$INITIATIVE_READONLY_STEP"
expect "JRN-006 rules.md at the term-gate step is denied" deny "$(payload .workflow/rules.md)" "Tier A"

echo "== JRN-006 edge and negative cases"
at "$INITIATIVE_WRITER_STEP"
expect "JRN-006 questions.md from a sub-agent is not guarded" allow "$(payload "$INI/questions.md" "$SUB")"
expect "JRN-006 the initiative .step from a sub-agent is denied" deny "$(payload "$INI/.step" "$SUB")" "initiative-transition"
expect "JRN-006 a differently cased path to initiative.md from a sub-agent is denied" deny \
  "$(payload ".workflow/Initiatives/001-storage-overhaul/initiative.md" "$SUB")" "sub-agent"
printf 'step: "3.1"\nupdated_at: "2026-10-22T10:00:00Z"\n' >"$P/$INI/.step"
expect "JRN-006 initiative.md with the marker at a non-6.x step is denied" deny "$(payload "$INI/initiative.md")" "step 3\.1"
expect "JRN-006 glossary with the initiative marker at a non-6.x step is denied" deny "$(payload .workflow/GLOSSARY.md)" "3\.1"
rm -f "$P/$INI/.step"
expect "JRN-006 initiative.md with no initiative marker is denied" deny "$(payload "$INI/initiative.md")" "<none>"
expect "JRN-006 glossary with no initiative marker and no spec in flight is allowed" allow "$(payload .workflow/GLOSSARY.md)"
at "$INITIATIVE_READONLY_STEP"
yq --front-matter=process -i '.status = "done"' "$P/$INI/initiative.md"
expect "JRN-006 glossary with only a done initiative is allowed" allow "$(payload .workflow/GLOSSARY.md)"

shellcheck_files "JRN-006 shellcheck guard components" "$P/.agents/skills/feature-workflow/scripts/check-write.sh" \
  "$H/spec-single-writer-guard.sh" "$H/tier-a-write-guard.sh" "$H/tier-b-write-guard.sh" "$H/_guard-common.sh"
finish
