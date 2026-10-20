#!/usr/bin/env bash
# File: Hook (Claude and Codex adapter): offer to resume in-flight work.
# Goals:
#   - If .workflow/specs/ exists, scan .workflow/specs/*/spec.md frontmatter for features that are not done (no .workflow/decisions/status.md; D22)
#   - Offer to resume at the recorded step via feature-workflow
#   - List session handoffs in .workflow/.handoff/*.md (written by the handoff skill) so a fresh session can pick one up
# Triggers/inputs: SessionStart JSON on stdin (any `source`: startup, resume, clear, compact; all get the offer, since a cleared or compacted
#   context has lost it). Paths from the payload `cwd` (D18), normalised to the main checkout (git rev-parse --git-common-dir), where .workflow/specs/
#   and the gitignored .step markers live.
# Behaviour:
#   - No spec.md with a status other than `done`, no open backlog item and no session handoff: exit 0, no output.
#   - Each non-done spec (draft, ready-for-dev, in-progress, in-review, blocked; sorted by folder name) is listed with its status,
#     blocked_condition (while blocked), and the current step from .workflow/specs/NNN-slug/.step (step, updated_at, blocked_from), or "no .step marker".
#     A spec.md whose frontmatter cannot be read is listed as unreadable rather than skipped.
#   - The text ends with the next action: load the feature-workflow skill for the chosen spec, which routes by spec.md status; a blocked spec
#     needs its blocked_condition resolved by a human first.
#   - A blocked spec whose blocked_condition starts with `discovered work:` or `size budget:` is flagged "discovered-work prompt pending" (D56).
#   - .workflow/specs/work-backlog/ is not a spec folder and is skipped by the scan; its *.md items with `status: open` are summarised as a count plus
#     up to 5 filenames (D57), and alone are enough to produce output.
#   - Session handoffs (.workflow/.handoff/*.md at the main checkout, newest first by mtime): up to 3 listed with frontmatter created, spec and goal
#     (or "frontmatter unreadable"), the rest counted; alone they are enough to produce output, and the text names the handoff skill's Resume.
#   - The text is capped below the 10,000-character additionalContext limit: specs past the cap are counted, not listed.
# Outputs/handoff: {"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"<resume offer>"}} or nothing; exit 0 always.
# Wiring: claude-settings.template.json (merged into <target>/.claude/settings.json by install.sh, D36): SessionStart.
#   codex-hooks.template.json (<target>/.codex/hooks.json): SessionStart, no matcher; Codex also reads additionalContext.
# Plan refs: 5.6; assetlist D16, D22.
# Notes: feature-workflow also performs the same scan on entry (D9), for hosts where this hook is not installed. The list includes draft and ready-for-dev specs as well as the
#   in-progress, in-review and blocked ones named in the plan's hooks row, so a feature paused in discovery is also offered.
# Sources: first-party; PLAN/hook-verification.md (SessionStart payload with source); hooks reference https://code.claude.com/docs/en/hooks
#   (SessionStart additionalContext); spec.md frontmatter contract in skills/feature-workflow/assets/spec.md; .step format in
#   skills/feature-workflow/scripts/status-transition.sh; handoff frontmatter in skills/handoff/assets/handoff.md; assetlist D16, D22, D38, D77.
# Requires: bash, jq, mikefarah yq v4 (D38), git (optional).

set -euo pipefail

# Workflow paths (D81).
# shellcheck source=../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/workflow-paths.sh"

LIMIT=9000      # characters of list text; leaves room for the header and footer under the 10,000 cap
TIME_BUDGET=6   # seconds spent reading specs before the rest are only counted (hook timeout 10 s)

command -v jq >/dev/null 2>&1 || exit 0
payload=$(cat)
cwd=$(jq -r 'if type == "object" then .cwd // "" | strings else "" end' <<<"$payload" 2>/dev/null || true)
[ -n "$cwd" ] && [ -d "$cwd" ] || cwd=${CLAUDE_PROJECT_DIR:-$PWD}
root=$(cd "$cwd" && pwd)
if common=$(git -C "$root" rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then
  root=$(dirname "$common")
fi

shopt -s nullglob
specs=("$root/$WF_SPECS"/*/spec.md)
backlog=("$root/$WF_WORK_BACKLOG"/*.md)
handoffs=("$root/$WF_HANDOFF"/*.md)
[ "${#specs[@]}" -gt 0 ] || [ "${#backlog[@]}" -gt 0 ] || [ "${#handoffs[@]}" -gt 0 ] || exit 0
command -v yq >/dev/null 2>&1 || exit 0

# Fast prefilter (no yq): the raw `status:` value of the frontmatter, quotes and comment stripped. Used to skip `done` specs cheaply and
# to count specs past the cap; every listed spec is read with yq (D38).
raw_status() {
  awk 'NR == 1 { if ($0 !~ /^---[[:space:]]*$/) exit; next }
       /^---[[:space:]]*$/ { exit }
       /^status:/ { v = $0; sub(/^status:[[:space:]]*/, "", v); sub(/[[:space:]]+#.*$/, "", v); gsub(/["\047]/, "", v); sub(/[[:space:]]+$/, "", v); print v; exit }' "$1"
}

# JSON array on stdin (from yq) -> one value per line; null -> "", whitespace runs folded so each value stays on one line.
lines() { jq -r 'if type == "array" then .[] else error("not an array") end | if . == null then "" else tostring | gsub("\\s+"; " ") end'; }

# Session handoffs (.workflow/.handoff/*.md, from the handoff skill): newest first, 3 listed, the rest counted. Read first so the spec list
# cap leaves room for them.
htext="" h_n=0
if [ "${#handoffs[@]}" -gt 0 ]; then
  # shellcheck disable=SC2012  # names come from the handoff skill (kebab-case); ls -t is the portable mtime sort
  while IFS= read -r h; do
    h_n=$((h_n + 1))
    [ "$h_n" -le 3 ] || continue
    entry="- $WF_HANDOFF/$(basename "$h")"
    if hf=$(yq --front-matter=extract -o=json -I=0 '[.goal, .spec, .created]' "$h" 2>/dev/null | lines); then
      goal="" hspec="" created=""
      { IFS= read -r goal; IFS= read -r hspec; IFS= read -r created; } <<<"$hf" || true
      [ -z "$created" ] || entry+=" (created $created)"
      [ -z "$hspec" ] || entry+="; spec $hspec"
      [ -z "$goal" ] || entry+=": $goal"
    else
      entry+=": frontmatter unreadable; open it to read the handoff."
    fi
    htext+=${entry:0:300}$'\n'
  done < <(ls -1t "${handoffs[@]}")
  [ "$h_n" -le 3 ] || htext+="- ... and $((h_n - 3)) older not listed.
"
  LIMIT=$((LIMIT - ${#htext}))
fi

list="" listed=0 omitted=0
for spec in ${specs[@]+"${specs[@]}"}; do
  [ "$(basename "$(dirname "$spec")")" != "work-backlog" ] || continue # the discovered-work backlog is not a spec (D57)
  [ "$(raw_status "$spec")" != "done" ] || continue
  dir=$(dirname "$spec")
  slug=$WF_SPECS/$(basename "$dir")
  # Past the character cap or the time budget (the hook timeout is 10 s): count, do not list.
  if [ "${#list}" -ge "$LIMIT" ] || [ "$SECONDS" -ge "$TIME_BUDGET" ]; then
    omitted=$((omitted + 1))
    continue
  fi
  if ! fm=$(yq --front-matter=extract -o=json -I=0 '[.status, .blocked_condition]' "$spec" 2>/dev/null | lines) \
    || [ -z "$fm" ]; then
    entry="- $slug: spec.md frontmatter unreadable; open it to check its status."
  else
    { IFS= read -r status; IFS= read -r bc; } <<<"$fm" || true
    if [ "$status" = "done" ]; then continue; fi
    [ -n "$status" ] || status="(none)"
    entry="- $slug: status $status"
    step="" at="" from=""
    if [ -f "$dir/.step" ] && st=$(yq -o=json -I=0 '[.step, .updated_at, .blocked_from]' "$dir/.step" 2>/dev/null | lines); then
      { IFS= read -r step; IFS= read -r at; IFS= read -r from; } <<<"$st" || true
      entry+="; current step ${step:-unknown}"
      [ -z "$at" ] || entry+=" (since $at)"
      [ -z "$from" ] || entry+="; blocked from $from"
    else
      entry+="; no .step marker"
    fi
    case "$bc" in
      "discovered work:"* | "size budget:"*) entry+="; discovered-work prompt pending (D56: the user has not yet answered it)" ;;
    esac
    [ -z "$bc" ] || entry+="; blocked_condition: $bc"
  fi
  entry=${entry:0:600}
  if [ $(( ${#list} + ${#entry} + 1 )) -gt "$LIMIT" ]; then
    omitted=$((omitted + 1))
    LIMIT=${#list} # list is full: later specs are only counted
    continue
  fi
  list+=$entry$'\n'
  listed=$((listed + 1))
done

# Open discovered-work backlog items (.workflow/specs/work-backlog/*.md with status open): a count and up to 5 filenames.
open_n=0 open_names=""
for item in ${backlog[@]+"${backlog[@]}"}; do
  [ "$SECONDS" -lt 8 ] || break
  [ "$(raw_status "$item")" = "open" ] || continue
  open_n=$((open_n + 1))
  [ "$open_n" -gt 5 ] || open_names+="${open_names:+, }$(basename "$item")"
done

[ $((listed + omitted + open_n + h_n)) -gt 0 ] || exit 0

text=""
if [ $((listed + omitted)) -gt 0 ]; then
  text="In-flight features in this project (from $WF_SPECS/*/spec.md frontmatter; status and .step are written only by status-transition.sh):
$list"
fi
[ "$omitted" -eq 0 ] || text+="- ... and $omitted more not listed (character or time limit); scan $WF_SPECS/*/spec.md for the rest.
"
if [ "$open_n" -gt 0 ]; then
  text+="Open discovered-work backlog items in $WF_WORK_BACKLOG/: $open_n (${open_names}$([ "$open_n" -le 5 ] || echo ", ...")); each is offered as a next feature at sign-off (5.9) or can be started through discovery.
"
fi
if [ "$h_n" -gt 0 ]; then
  text+="Session handoffs in $WF_HANDOFF/ (newest first, written by the handoff skill):
$htext"
fi
if [ $((listed + omitted)) -eq 0 ]; then
  [ "$h_n" -eq 0 ] || text+="Offer the user to resume a handoff: load the handoff skill and follow its Resume steps. Do not resume unasked."
  jq -cn --arg c "$text" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $c}}'
  exit 0
fi
text+="Offer the user to resume one of these. To resume, load the feature-workflow skill for that spec: it reads the spec.md status and loads the module for that phase, continuing from the current step. A blocked spec needs its blocked_condition resolved by a human first; for a discovered work or size budget condition, the pending prompt is answered in the feature-workflow discovered-work module. Do not resume unasked."
[ "$h_n" -eq 0 ] || text+=" To resume a session handoff instead, load the handoff skill and follow its Resume steps; a handoff that names a spec continues through feature-workflow."

jq -cn --arg c "$text" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $c}}'
exit 0
