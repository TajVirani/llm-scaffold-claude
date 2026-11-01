#!/usr/bin/env bash
# Suite: lint over the review and escalation text: the Phase 4 lens definitions, the new review-combined lens and where it is
#   listed, profile-mini-review, and the feature-workflow modules that route findings (discovered-work, review-triage,
#   deferred-handoff, sign-off 5.5 and 5.9, the orchestrator's discovered-work section) and the backlog list template.
# Covers: proof before escalation: the end-state, standards, lessons and combined lenses may run probes only in a scratch
#   worktree made with `git worktree add --detach` under `mktemp -d`, keep no read-only-only rule, keep no plain 80 drop rule,
#   and carry `reproduction` in their finding evidence; mini-review has the same scratch rule and a `not_checked` list;
#   review-lessons reads the spec's Assumptions and Non-goals and scores an accepted gap 0. Discovered work is assessed in
#   the order unproven, current work, blocker, for the stakeholder (convoluted, scope-expanding, out of scope), with one
#   batched ask and nothing filed without a ruling; triage has no defer route and no maybe-false verdict, and its 4.8 step
#   writes no shelf file; deferred-handoff appends to a matching shelf file without asking; sign-off 5.5 asks one question
#   over the list. One backlog list per spec: 00.26 appends a line to .workflow/specs/work-backlog/NNN-slug.md, and the line
#   check in assets/work-backlog.md accepts its own example and well-formed lines and names a line with another status, no
#   evidence or no id. The review-combined agent: frontmatter, description, its manifest line and agent count, PROVENANCE,
#   README, the resolve-launch row, the RC lens in check-review-findings.sh, the model-map tier table, and its generated
#   Codex toml. Reads the repo; writes only to a scratch dir.
# shellcheck disable=SC2016,SC2034,SC2329  # check expressions are single-quoted and eval'd on purpose, and read variables and call helpers shellcheck cannot see
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight
new_workdir

AGENTS=$AGENTS_SRC/agents
MODULES=$FW_SKILL/modules
DW=$MODULES/discovered-work.md
TRIAGE=$MODULES/review-triage.md
HANDOFF=$MODULES/deferred-handoff.md
SIGN_OFF=$MODULES/sign-off.md
ORCH=$MODULES/implementation-orchestrator.md
LIST_TEMPLATE=$FW_SKILL/assets/work-backlog.md
COMBINED=$AGENTS/review-combined.md
MANIFEST=$AGENTS_SRC/install-manifest.txt

# section FILE HEADING : print the `## HEADING...` section of FILE up to the next `## ` heading.
section() {
  awk -v h="## $2" 'index($0, h) == 1 { on = 1; next } on && /^## / { exit } on' "$1"
}

echo "== lenses prove their findings and may run code outside the checkout"
for lens in review-end-state review-standards review-lessons review-combined; do
  f=$AGENTS/$lens.md
  check "$lens has a Running code section with a detached scratch worktree under mktemp -d" \
    'section "$f" "Running code" | grep -q "git worktree add --detach" && section "$f" "Running code" | grep -q "mktemp -d"' "$f"
  check "$lens removes its scratch worktree" 'section "$f" "Running code" | grep -q "git worktree remove"'
  check "$lens keeps no read-only-only rule" '! grep -q "Run only read-only commands" "$f"'
  check "$lens keeps no plain 80 drop rule" '! grep -q "Drop every finding under 80" "$f"'
  check "$lens finding evidence has a reproduction field" 'grep -q "^      reproduction: " "$f"'
  check "$lens sends an unproven suspicion to one not_checked line" 'grep -q "could not prove" "$f"'
done
check "review-lessons reads the spec's Assumptions and Non-goals" \
  'grep -q "Accepted gaps.*Assumptions.*Non-goals" "$AGENTS/review-lessons.md"'
check "review-lessons scores a gap the spec accepted 0" \
  'grep -qE "^- 0: .*spec accepts this gap" "$AGENTS/review-lessons.md" && grep -q "Set accepted gaps aside" "$AGENTS/review-lessons.md"'
MINI=$AGENTS/profile-mini-review.md
check "profile-mini-review runs probes in a detached scratch worktree of the task" 'grep -q "worktree add --detach" "$MINI"'
check "profile-mini-review keeps no read-only paragraph" '! grep -q "^\*\*Read-only\.\*\*" "$MINI"'
check "profile-mini-review result has a not_checked list" 'grep -q "^not_checked: \[\]" "$MINI"'
check "profile-mini-review marks a proven problem on the task's own lines blocks-this-task" \
  'grep -q "blocks-this-task.*lines or files this diff changes" "$MINI"'

echo "== discovered work: proven first, the worker fixes current work, the stakeholder gets one batched ask"
ASSESS=$(section "$DW" "Assess each report first")
pos() { grep -n "$1" <<<"$ASSESS" | head -n 1 | cut -d: -f1; }
p_unproven=$(pos "Unproven?") p_current=$(pos "Current work?") p_blocker=$(pos "Blocker?") p_ask=$(pos "For the stakeholder")
check "the assessment asks unproven, current work, blocker, then for the stakeholder, in that order" \
  '[ -n "$p_unproven" ] && [ "$p_unproven" -lt "$p_current" ] && [ "$p_current" -lt "$p_blocker" ] && [ "$p_blocker" -lt "$p_ask" ]' \
  "unproven=$p_unproven current=$p_current blocker=$p_blocker ask=$p_ask"
check "the stakeholder classes are convoluted, scope-expanding and out of scope" \
  'grep -q "\*\*convoluted\*\*" <<<"$ASSESS" && grep -q "\*\*scope-expanding\*\*" <<<"$ASSESS" && grep -q "\*\*out of scope\*\*" <<<"$ASSESS"'
check "a waiting item is asked at the next ask or at 5.5 at the latest" 'grep -q "at 5.5 at the latest" "$DW"'
check "discovered-work has one batched ask with fold in, keep for later and drop" \
  'section "$DW" "00.25 Batched ask" | grep -q "fold in" && section "$DW" "00.25 Batched ask" | grep -qi "keep for later" && section "$DW" "00.25 Batched ask" | grep -q "Drop"'
check "nothing is filed without a ruling" '! grep -qi "filed without a ruling" "$DW" "$ORCH" "$TRIAGE" "$SIGN_OFF"'
check "00.26 appends one line to the spec's backlog list" \
  'section "$DW" "00.26 Add the backlog line" | grep -q "\.workflow/specs/work-backlog/NNN-slug\.md"'
check "00.26 writes no per-item file" '! section "$DW" "00.26 Add the backlog line" | grep -q "disc-<###>"'
check "a shelf match is appended without asking" 'grep -q "without asking" "$HANDOFF" && ! grep -q "Same item?" "$HANDOFF"'
check "the orchestrator routes current work back to the task" \
  'section "$ORCH" "Discovered work (00.21)" | grep -q "\*\*Current work\.\*\*"'

echo "== triage: no defer route, no maybe-false, 4.8 writes no shelf file"
check "triage routes have no defer bucket" '! grep -qE "^- \*\*defer" "$TRIAGE"'
check "triage verdicts have no maybe-false" '! grep -q "maybe-false" "$TRIAGE"'
check "triage verdicts include unproven" 'grep -q "\`unproven\`: no reproduction" "$TRIAGE"'
check "triage step 7 loads no deferred-handoff" '! section "$TRIAGE" "7. " | grep -q "deferred-handoff"'
check "triage step 7 writes the Gaps line" 'section "$TRIAGE" "7. " | grep -q "Gaps:"'
handoff_row=$(grep -F '| [deferred-handoff](modules/deferred-handoff.md) |' "$FW_SKILL/SKILL.md")
check "SKILL.md's module table enters deferred-handoff from no 4.8" '[ -n "$handoff_row" ] && ! grep -q "4\.8" <<<"$handoff_row"' "$handoff_row"

echo "== sign-off: one question over the list"
S55=$(section "$SIGN_OFF" "5.5 ")
check "5.5 asks one question over the whole list" 'grep -q "One question over the whole list" <<<"$S55"'
check "5.5 asks no question per backlog item" '! grep -qi "one question per open backlog item" <<<"$S55"'
check "5.5 sends a folded-in item to 5.6 as a change request" 'grep -q "fold in" <<<"$S55" && grep -q "5.6" <<<"$S55"'
check "5.9 writes a shelf file only on the stakeholder's request" 'section "$SIGN_OFF" "5.9 " | grep -q "only when the stakeholder asked"'

echo "== the backlog list template and its line check"
check "assets/work-backlog.md exists" '[ -f "$LIST_TEMPLATE" ]'
line_check=$(sed -n 's/^  \(grep -n .*\)$/\1/p' "$LIST_TEMPLATE")
check "the template carries one line-check command" '[ "$(grep -c . <<<"$line_check")" -eq 1 ]' "$line_check"
# run_line_check FILE : run the template's line check on FILE (its path replaces the example path) and print what it names.
run_line_check() {
  bash -c "${line_check//.workflow\/specs\/work-backlog\/NNN-slug.md/\"\$1\"}" _ "$1"
}
L=$WORK/list.md
sed -n '/^- \[/p' "$LIST_TEMPLATE" >"$L"
eq "the template's own example line passes its check" "$(run_line_check "$L")" ""
printf '%s\n' "# Work backlog: 012-alpha" "" \
  "- [open] B1 bug (4.4): A suite hangs on a terminal. Evidence: bash run-all.sh </dev/tty: no exit." \
  "- [promoted] B2 requirement (3.7): No export. Evidence: spec.md CAP-002. -> .workflow/specs/014-gamma" \
  "- [open] B3 budget-split (00.29, split out of T4): The export task. Evidence: budget-check.sh over by 2." >"$L"
eq "open, promoted and split lines pass" "$(run_line_check "$L")" ""
printf '%s\n' "- [dropped] B4 bug (4.4): x. Evidence: y." "- [open] B5 bug (4.4): no proof given." "- [open] bug (4.4): x. Evidence: y." >>"$L"
eq "a line with another status, no evidence or no id is named by number" "$(run_line_check "$L" | cut -d: -f1 | tr '\n' ' ')" "6 7 8 "

echo "== the review-combined agent and where it is listed"
check "agents/review-combined.md exists" '[ -f "$COMBINED" ]' "$COMBINED"
fm() { yq --front-matter=extract "$1" "$COMBINED" 2>/dev/null; }
eq "frontmatter keys are exactly name, description, tools" "$(fm 'keys | join(",")')" "name,description,tools"
eq "name is review-combined" "$(fm '.name')" "review-combined"
eq "tools are Read, Grep, Glob, Bash" "$(fm '.tools')" "Read, Grep, Glob, Bash"
check "description leads with its role and its step, 4.10 as steps.tsv numbers it" \
  '[[ $(fm ".description") == "Combined review lens (workflow step 4.10 "* ]] && grep -qx "4.10	4	light	Combined review" "$FW_SKILL/references/steps.tsv"' \
  "$(fm '.description')"
check "assetlist.md places review-combined at 4.10" 'grep -E "^\| \`review-combined\` \| agent" "$REPO_ROOT/assetlist.md" | grep -q "| 4.10 "'
check "it writes the review-combined pass file" 'grep -q "artifacts/review/pass-<n>/review-combined.yaml" "$COMBINED"'
check "install-manifest.txt lists agents/review-combined.md" 'grep -qx "agents/review-combined.md" "$MANIFEST"'
agents_header=$(grep -E '^# --- Agents \([0-9]+\)$' "$MANIFEST")
eq "the Agents header counts the agent lines" "$(grep -oE '[0-9]+' <<<"$agents_header")" "$(grep -c '^agents/' "$MANIFEST")"
eq "the manifest lists every agent definition" "$(grep -c '^agents/' "$MANIFEST")" "$(find "$AGENTS" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')"
check "PROVENANCE.md has a line for agents/review-combined.md" 'grep -q "agents/review-combined.md" "$REPO_ROOT/PROVENANCE.md"'
check "README.md names review-combined" 'grep -q "review-combined" "$REPO_ROOT/README.md"'
check "resolve-launch.sh has a review-combined row" 'grep -q "\"review-combined\":" "$FW_SKILL/scripts/resolve-launch.sh"'
check "check-review-findings.sh knows the review-combined lens with prefix RC" \
  'grep -q "\"review-combined\": *{prefix: \"RC\"" "$FW_SKILL/scripts/check-review-findings.sh"'
check "project-setup's model-map tier table names review-combined" \
  'grep -E "^\| strong \|" "$AGENTS_SRC/skills/project-setup/modules/model-map.md" | grep -q "review-combined"'
copy_agents "$WORK/codex"
t "generate-codex-agents.sh runs on a fixture copy" 0 "$WORK/codex/.agents/hooks/generate-codex-agents.sh"
check "the toml is named review_combined" 'grep -qx "name = \"review_combined\"" "$WORK/codex/.codex/agents/review_combined.toml" 2>/dev/null'

shellcheck_files "shellcheck: review-escalation-docs suite" "${BASH_SOURCE[0]}"
finish
