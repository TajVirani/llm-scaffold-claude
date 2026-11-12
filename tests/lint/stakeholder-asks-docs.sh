#!/usr/bin/env bash
# Suite: lint over the feature-workflow text that decides when the stakeholder is asked: the "Asking the stakeholder"
#   rules in references/conventions.md, the one sign-off ask in modules/sign-off.md, the retrospective's draft and finish
#   modes, the Assumed, Breakdown quiz and Sign-off shapes in assets/design-log.md, and the step files that assume and log
#   or launch before asking.
# Covers: conventions holds the blocking test (scope or intent, or hard to reverse), the assume-and-log rule (a question with no one
#   answer to recommend blocks) with its
#   veto at the next blocking ask, and launch before asking; every link to that rule names an anchor the file has.
#   Sign-off asks one AskUserQuestion call before 5.8, inside 5.5, covering the work and the PR description, the
#   proposals, the backlog list and the retrospective's lessons; 5.5 sets its step and a resume after the answered ask
#   does not ask again; 5.3, 5.9 and 5.7 ask nothing; 5.8 asks nothing and
#   publishes on the 5.5 approval; a No applies nothing; the run order and steps.tsv put 5.3 after 5.5; no small-path note,
#   older backlog item file or Done-folder sweep is left in sign-off.md or the retrospective, and the one-task report keeps
#   its five lines. The retrospective drafts into retrospective-draft.md and reads at finish the lines the Sign-off shape
#   writes. The term gate, shelf match, Targets thresholds and agent decisions assume and log; the first questioning round
#   carries the deeper prompt's questions and may launch module-audit; Phase 1 asks the breakdown quiz while its build runs;
#   the hitl pause launches the rest of the wave first. The step files' tracker calls on the spec's own issues are not asked
#   (labels still are); a finished step or phase is not a stop; 2.3 assumes the test seams and the breakdown quiz offers them
#   for veto; 1.4 starts the e2e build itself. Reads the repo; writes nothing.
# shellcheck disable=SC2016,SC2034  # check expressions are single-quoted and eval'd on purpose, and read variables shellcheck cannot see
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

CONVENTIONS=$FW_SKILL/references/conventions.md
SIGN_OFF=$FW_SKILL/modules/sign-off.md
DESIGN_LOG=$FW_SKILL/assets/design-log.md
TSV=$FW_SKILL/references/steps.tsv
RETRO=$AGENTS_SRC/skills/retrospective/SKILL.md
DOMAIN=$AGENTS_SRC/skills/domain-modeling/SKILL.md
DEEPER=$AGENTS_SRC/skills/deeper-prompt/SKILL.md
MODULES=$FW_SKILL/modules

# section FILE TITLE : the text under the `## TITLE...` or `### TITLE...` heading whose title starts with TITLE, up to the
#   next heading of the same or a higher level. Empty when there is none.
section() {
  awk -v id="$2" '
    /^#+ / {
      level = length($1); t = $0; sub(/^#+ /, "", t)
      if (on && level <= on) exit
      if (!on && index(t, id) == 1) { on = level; next }
    }
    on' "$1"
}

# sign_off_step ID : the text of sign-off step ID (its `## ID ` section).
sign_off_step() { section "$SIGN_OFF" "$1 "; }

echo "== conventions: asking the stakeholder"
ASKING=$(section "$CONVENTIONS" "Asking the stakeholder")
check "conventions has an Asking the stakeholder section" '[ -n "$ASKING" ]'
check "a question blocks when its answer changes scope or intent" 'grep -q "changes the scope or intent" <<<"$ASKING"'
check "a question blocks when the action it gates is hard to reverse, naming merge, publish, delete, migration and outside the repo" \
  'grep "hard to reverse" <<<"$ASKING" | grep "merge" | grep "publish" | grep "delete" | grep "migration" | grep -q "outside the repo"'
check "any other question takes the recommended answer at once and is logged as Assumed" \
  'grep "recommended answer" <<<"$ASKING" | grep -q "Assumed"'
check "the Assumed entry records the question, the answer taken and why it was safe" \
  'grep "Assumed" <<<"$ASKING" | grep "question" | grep "answer taken" | grep -q "safe to assume"'
check "a question with no one answer to recommend blocks instead of being assumed" \
  'grep "Assume and log the rest" <<<"$ASKING" | grep -q "If you cannot recommend one answer, it blocks"'
check "the next blocking ask offers every assumption for veto" 'grep "next blocking ask" <<<"$ASKING" | grep -q "veto"'
check "launch before asking: every sub-agent whose input does not depend on the answer" \
  'grep "Launch before asking" <<<"$ASKING" | grep -q "does not depend on its answer"'
check "launch before asking launches nothing an answer could invalidate" 'grep -q "Launch nothing an answer could invalidate" <<<"$ASKING"'
check "the step files' tracker calls on the spec's own issues are not asked" \
  'grep "are not asked" <<<"$ASKING" | grep "create-task" | grep "fill" | grep -q "move"'
check "creating the spec's own issue (create-spec at 0.1.1) is not asked" \
  'grep "are not asked" <<<"$ASKING" | grep -q "create-spec. at 0.1.1 through .next-spec-number.sh."'
check "creating labels still asks, and a tracker call exiting 1 or 2 still stops" \
  'grep "creating labels still is" <<<"$ASKING" | grep -q "exits 1 or 2 still stops"'
check "the hard-to-reverse list no longer names a tracker" '! grep "hard to reverse" <<<"$ASKING" | grep -q "a tracker"'
check "a finished step or phase is not a stop" \
  'grep "A finished step or phase is not a stop" <<<"$ASKING" | grep -q "Go straight on to the next step file"'

echo "== every link to the rule names its anchor"
LINKS=$(grep -rhoE 'conventions\.md#[a-z0-9-]+' "$FW_SKILL" "$AGENTS_SRC/skills/domain-modeling" | sort -u)
check "step files link the asking rule" 'grep -q "conventions\.md#asking-the-stakeholder" <<<"$LINKS"'
check "the conventions heading gives the linked anchor" 'grep -qx "## Asking the stakeholder" "$CONVENTIONS"'

echo "== design-log shapes"
check "the Assumed shape has its step, question, answer taken and why safe" \
  'section "$DESIGN_LOG" "YYYY-MM-DD Assumed:" | grep -q "^- Question:" && section "$DESIGN_LOG" "YYYY-MM-DD Assumed:" | grep -q "^- Answer taken:" && section "$DESIGN_LOG" "YYYY-MM-DD Assumed:" | grep -q "^- Why safe to assume:" && section "$DESIGN_LOG" "YYYY-MM-DD Assumed:" | grep -q "^- Step:"'
check "the Breakdown quiz shape exists" 'section "$DESIGN_LOG" "YYYY-MM-DD Breakdown quiz" | grep -q "^- Asked at:"'
check "the Breakdown quiz shape offers the assumed seams for veto" \
  'section "$DESIGN_LOG" "YYYY-MM-DD Breakdown quiz" | grep "^- Offered for veto:" | grep -q "2.3 seams"'
check "the Breakdown quiz shape asks no seam question of its own" '! section "$DESIGN_LOG" "YYYY-MM-DD Breakdown quiz" | grep -q "^- Seams"'
SIGN_SHAPE=$(section "$DESIGN_LOG" "YYYY-MM-DD Sign-off")
for line in "Offered for veto" Approval "PR description" Proposals Ruling "Retrospective lessons" "Concerns for the retrospective"; do
  check "the Sign-off shape has a $line line" 'grep -q "^- $line:" <<<"$SIGN_SHAPE"'
done
check "the Sign-off shape has no Going-in concerns line" '! grep -q "Going-in concerns" "$DESIGN_LOG"'

echo "== sign-off: one ask before 5.8, none at 5.8"
BEFORE_58=""
for id in 5.1 5.2 5.4 5.5 5.6 5.3 5.9 5.7; do BEFORE_58="$BEFORE_58$(sign_off_step "$id")"$'\n'; done
S55=$(sign_off_step 5.5)
S58=$(sign_off_step 5.8)
eq "steps before 5.8 name exactly one AskUserQuestion call" "$(grep -c "AskUserQuestion" <<<"$BEFORE_58")" "1"
check "that call is in 5.5" 'grep -q "one AskUserQuestion call holding every question" <<<"$S55"'
check "5.5 asks about the work and the PR description together" 'grep -q "approve the work and this PR description" <<<"$S55"'
check "5.5 asks the proposals with P<n> exceptions" 'grep -q "Approve every proposal as written, or name exceptions" <<<"$S55" && grep -q "P<n>: reject" <<<"$S55"'
check "5.5 asks one question over the backlog list" 'grep -q "One question over the whole list" <<<"$S55"'
check "5.5 asks the retrospective lessons with L<n> exceptions" 'grep -q "Record these lessons as drafted" <<<"$S55" && grep -q "L<n>: reject" <<<"$S55"'
check "5.5 drafts the retrospective before asking" 'grep -q "Draft the retrospective" <<<"$S55" && grep -q "retrospective-draft.md" <<<"$S55"'
check "5.5 opens with the assumptions for veto" 'grep "assumptions" <<<"$S55" | grep -q "conventions.md#asking-the-stakeholder"'
check "a No applies nothing else" 'grep -q "Nothing else is applied" <<<"$S55"'
check "5.5 sets its own step, so a resume after the ask does not go back to 5.1" \
  'grep -q "status-transition.sh step .workflow/specs/NNN-slug 5.5" <<<"$S55"'
check "a resume at 5.5 whose last design-log entry is a Sign-off entry does not ask again" \
  'grep -q "When the last entry in \`design-log.md\` is a \"Sign-off\" entry" <<<"$S55" && grep -q "Do not ask again" <<<"$S55"'
check "5.3 asks nothing and reads the 5.5 answer" 'sign_off_step 5.3 | grep -q "so ask nothing here" && sign_off_step 5.3 | grep -q "Proposals:"'
check "5.9 carries out the rulings without asking again" 'sign_off_step 5.9 | grep -q "without asking again"'
check "5.7 asks nothing" 'sign_off_step 5.7 | grep -q "It asks nothing"'
check "5.8 names no AskUserQuestion call" '! grep -q "AskUserQuestion" <<<"$S58"'
check "5.8 asks for no go-ahead" '! grep -qiE "ask (for )?the (publish )?go-ahead|with the stakeholder.s go-ahead" <<<"$S58"' \
  "$(grep -iE "go-ahead" <<<"$S58")"
check "5.8 asks the stakeholder nothing" '! grep -qiE "ask the stakeholder|ask the 5\.5" <<<"$S58"' "$(grep -iE "ask the" <<<"$S58")"
check "5.8 publishes on the 5.5 approval" 'grep -q "The 5.5 approval of the work and the PR description is the go-ahead" <<<"$S58"'
check "the moved-body check is a guard that stops only on a fault" 'grep -q "This is a guard, not a question" <<<"$S58"'
check "the opening names the run order with 5.3 after 5.5" 'grep -q "5.1, 5.2, 5.4, 5.5, then 5.3, 5.9, 5.7, 5.8" "$SIGN_OFF"'
ORDER=$(awk -F'\t' '$2 == 5 && $3 != "phase" { printf "%s ", $1 }' "$TSV")
eq "steps.tsv lists phase 5 in run order" "$ORDER" "5.1 5.2 5.4 5.5 5.6 5.3 5.9 5.7 5.8 "

echo "== sign-off and retrospective: old branches gone"
check "sign-off.md has no small-path note" '! grep -qi "small path" "$SIGN_OFF"' "$(grep -ni "small path" "$SIGN_OFF")"
check "the retrospective has no small-path branch" '! grep -qi "small.path" "$RETRO"' "$(grep -ni "small.path" "$RETRO")"
check "sign-off.md names no older backlog item file" '! grep -qE "disc-|older item|older open item" "$SIGN_OFF"' \
  "$(grep -nE "disc-|older item|older open item" "$SIGN_OFF")"
check "sign-off.md runs no Done-folder sweep" '! grep -q -- "--sweep" "$SIGN_OFF"'
REPORT=$(awk '/^[[:space:]]*```markdown/ { block = ""; on = 1; next } on && /^[[:space:]]*```/ { if (block ~ /# Report: <feature title>/) { printf "%s", block; exit } on = 0; next } on { block = block $0 "\n" }' "$SIGN_OFF")
eq "the one-task report is five lines under its title" "$(grep -cE '^[[:space:]]*- \*\*[A-Za-z ]+:\*\*' <<<"$REPORT")" "5"
check "the five-line report is for a one-task spec" 'grep -q "For a one-task spec" "$SIGN_OFF"'

echo "== retrospective: draft before the ask, finish after it"
check "the retrospective names a draft mode writing retrospective-draft.md" 'grep "\*\*Draft\*\*" "$RETRO" | grep -q "retrospective-draft.md"'
check "the finish mode asks nothing" 'grep "\*\*Finish\*\*" "$RETRO" | grep -q "Ask nothing"'
for line in "Retrospective lessons" "Concerns for the retrospective"; do
  check "finish reads the $line line the Sign-off shape writes" 'grep -qF -- "^- $line:" "$RETRO" && grep -q "^- $line:" <<<"$SIGN_SHAPE"'
done
check "the retrospective's description names the draft before the 5.5 ask" \
  'yq --front-matter=extract ".description" "$RETRO" | grep -q "before the 5.5 ask"'

echo "== assume and log in the step files"
check "the term gate assumes a clear term and asks an open one" \
  'section "$DOMAIN" "Term gates" | grep "Clear:" | grep -q "assume and log"'
check "the shelf match at 0.2.6 assumes a clear match" 'grep "Shelf match" "$MODULES/discovery.md" | grep -q "assume and log"'
check "2.1 logs the seams as one Assumed entry before the quiz is sent" \
  'section "$MODULES/task-breakdown.md" "2.1 " | grep "Before you send it, pick each slice.s seam by the \[2.3\]" | grep -q "one \*\*Assumed\*\* entry"'
check "2.3 asks nothing and logs again only for a seam Phase 1 changed" \
  'section "$MODULES/task-breakdown.md" "2.3 " | grep "Do not ask: 2.1 picked the seams" | grep -q "only for a seam Phase 1 changed"'
check "verification-setup 1.2 logs the seams before its quiz is sent" \
  'section "$MODULES/verification-setup.md" "1.2 " | grep -q "the 2.3 seams logged as assumptions before it is sent"'
check "a seam that needs an interface change still loops back at 2.3" \
  'section "$MODULES/task-breakdown.md" "2.3 " | grep -q "draft --step 2.3"'
check "the 2.1 quiz carries the seams as assumptions, not a question" \
  'section "$MODULES/task-breakdown.md" "2.1 " | grep -q "the 2.3 seams come only as those assumptions"'
check "1.4 starts the e2e serve command itself and never asks who starts it" \
  'section "$MODULES/verification-setup.md" "1.4 " | grep "serve" | grep "serve_ready" | grep "120 s" | grep -q "Never ask who starts the build"'
check "1.4 starts nothing when serve_ready already answers" \
  'section "$MODULES/verification-setup.md" "1.4 " | grep -q "if it already answers, some other process would be tested, so start nothing"'
check "Targets thresholds are assumed and logged at 1.1" \
  'section "$MODULES/verification-setup.md" "1.1 " | grep "threshold" | grep -q "assume and log"'
check "an agent blocked on a decision that changes neither scope nor intent is resumed with an assumption" \
  'grep "blocked. on a decision" "$MODULES/implementation-waves.md" | grep -q "assume and log"'

echo "== launch before asking in the step files"
check "the first questioning round carries the deeper prompt's questions" \
  'section "$MODULES/questioning-loop.md" "Entry" | grep -q "asked in the first questioning ask"'
check "deeper-prompt leaves its questions to the first questioning ask inside the workflow" \
  'section "$DEEPER" "2. " | grep -q "ride on the questioning loop.s first ask"'
check "the first questioning round may launch module-audit before it is sent" \
  'grep "0.3.11" "$MODULES/questioning-loop.md" | grep "Before you send the round" | grep -q "module-audit"'
check "0.4.6 reuses an early module-audit return" 'grep "0.4.6 Launch" "$MODULES/discovery-impact.md" | grep -q "first questioning round"'
check "Phase 1 asks the breakdown quiz while the build runs" \
  'section "$MODULES/verification-setup.md" "1.2 " | grep -q "Ask the breakdown quiz while the build runs"'
check "task breakdown takes the quiz answers logged during Phase 1" 'grep -q "Breakdown quiz" "$MODULES/task-breakdown.md"'
check "the hitl pause launches the rest of the wave first" \
  'grep "Pause before a .hitl. task" "$MODULES/implementation-waves.md" | grep -q "Launch the wave.s other tasks first"'

finish
