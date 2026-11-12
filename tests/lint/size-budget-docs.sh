#!/usr/bin/env bash
# Suite: lint over the feature-workflow text for the size budget: the breakdown quiz, 2.5, 2.6 and 3.15 in the step files,
#   the 5.4 report, the design-log, report and spec templates, the router, the discovered-work module, the step list and
#   the shipped rules text.
# Covers: the budget is never asked (2.5 and 0.3.20 write the project defaults, the Breakdown quiz shape has no Budget line);
#   a breakdown predicted over budget is a split proposal inside the quiz ("Split as proposed" or "Keep as one spec", the
#   pieces going to the backlog list through 00.26); 2.6 runs only budget-check.sh --predicted and an exit 2 returns to the
#   quiz, never blocks; the task issues are filed only on a 2.6 exit 0, before the commit, under step 2.5 for the Tracker
#   issue line and then 2.6 again, and never in 2.5, so a split never leaves an issue for a removed task; 3.15 logs an overrun once as a Size budget overrun entry and goes on; sign-off reports the figures;
#   no size-budget block route or 00.29 step is left, while the router still resumes an older size-budget block and an
#   older 00.29 re-scope. Reads the repo; writes nothing.
# shellcheck disable=SC2016,SC2034  # check expressions are single-quoted and eval'd on purpose, and read variables shellcheck cannot see
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

MODULES=$FW_SKILL/modules
BREAKDOWN=$MODULES/task-breakdown.md
WAVES=$MODULES/implementation-waves.md
DESIGN_LOG=$FW_SKILL/assets/design-log.md
SKILL=$FW_SKILL/SKILL.md

# section FILE TITLE : the text under the heading whose title starts with TITLE, up to the next heading of the same or a
#   higher level. Empty when there is none.
section() {
  awk -v id="$2" '
    /^#+ / {
      level = length($1); t = $0; sub(/^#+ /, "", t)
      if (on && level <= on) exit
      if (!on && index(t, id) == 1) { on = level; next }
    }
    on' "$1"
}

echo "== the budget is never asked"
S21=$(section "$BREAKDOWN" "2.1 ")
S25=$(section "$BREAKDOWN" "2.5 ")
check "2.1 says the size budget is never asked" 'grep -q "The size budget is never asked" <<<"$S21"'
check "2.1 no longer proposes or agrees a budget" '! grep -qiE "agree other values|propose the project defaults|agreed budget" <<<"$S21"'
check "2.5 writes the project defaults without asking" 'grep "Write the budget" <<<"$S25" | grep "project defaults" | grep -q "without asking"'
check "0.3.20 writes the defaults without asking" \
  'grep "budget: {max_tasks" "$MODULES/discovery-impact.md" | grep -q "without asking" && ! grep -q "stakeholder agreed other values" "$MODULES/discovery-impact.md"'
check "verification-setup 1.2 asks no budget in the quiz" '! grep -q "the budget with it" "$MODULES/verification-setup.md"'
QUIZ=$(section "$DESIGN_LOG" "YYYY-MM-DD Breakdown quiz")
check "the Breakdown quiz shape has no Budget line" '! grep -q "^- Budget:" <<<"$QUIZ"'
check "the Breakdown quiz shape has a Size line for the split answer" \
  'grep "^- Size:" <<<"$QUIZ" | grep "split as proposed" | grep -q "kept as one spec"'

echo "== a predicted overrun is a split proposal in the quiz"
check "the quiz offers Split as proposed (Recommended) and Keep as one spec" \
  'grep -q "\"Split as proposed (Recommended)\"" <<<"$S21" && grep -q "\"Keep as one spec\"" <<<"$S21"'
check "a split piece goes to the backlog list through 00.26 as budget-split" \
  'grep "Split as proposed" <<<"$S21" | grep "0026-add-the-backlog-line" | grep -q "budget-split"'
check "the orchestrator totals the draft itself before the quiz" 'grep -q "total the draft yourself" <<<"$S21"'
check "Keep raises the budget at 2.5 for this spec only" 'grep "raise each limit" <<<"$S25" | grep -q "for this spec only"'

echo "== 2.6: predicted only, never a block"
S26=$(section "$BREAKDOWN" "2.6 ")
eq "2.6 runs budget-check.sh once" "$(grep -c "scripts/budget-check.sh" <<<"$S26")" "1"
check "that run is --predicted" 'grep "scripts/budget-check.sh" <<<"$S26" | grep -q -- "--predicted"'
check "2.6 exit 2 returns to the quiz and never blocks" 'grep "Exit 2" <<<"$S26" | grep "never block" | grep -q "2.1 quiz"'
check "2.6 exit 2 after a recorded Keep raises the budget without asking again" \
  'grep "Exit 2" <<<"$S26" | grep "already says kept as one spec, do not ask again" | grep -q "raise .budget. in .spec.md. to the JSON figures"'
check "only a 2.6 overrun with no recorded Keep returns to the quiz" 'grep "Exit 2" <<<"$S26" | grep -q "Otherwise take the figures back to the"'
check "the split's origin node names every step that asks the quiz" 'grep -q "origin node the step you are at (1.2, 2.1 or 2.6)" <<<"$S21"'
check "2.6 loads no discovered-work" '! grep -q "discovered-work" <<<"$S26"'

echo "== task issues are filed only once 2.6 passes"
EXIT0=$(awk '/^- \*\*Exit 0/{on=1} /^- \*\*Exit 2/{on=0} on' <<<"$S26")
check "2.5 files no task issue" '! grep -qE "create-task|--issue" <<<"$S25"' "$(grep -nE "create-task|--issue" <<<"$S25")"
check "2.5's done line no longer needs an issue" '! grep "^\*\*Done when" <<<"$S25" | grep -q "issue"'
check "2.6 exit 0 files each task issue and records it" \
  'grep -q "issue-tracker.sh create-task" <<<"$EXIT0" && grep -q "set-task .* --issue" <<<"$EXIT0"'
check "2.6 exit 0 files the issues before the commit" \
  '[ "$(grep -n "create-task" <<<"$EXIT0" | cut -d: -f1)" -lt "$(grep -n "git commit" <<<"$EXIT0" | cut -d: -f1)" ]'
check "2.6 exit 0 sets step 2.5 for the Tracker issue line, then 2.6 again" \
  '[ "$(grep -n "status-transition.sh step .* 2.5$" <<<"$EXIT0" | cut -d: -f1)" -lt "$(grep -n "create-task" <<<"$EXIT0" | cut -d: -f1)" ] &&
   [ "$(grep -n "create-task" <<<"$EXIT0" | cut -d: -f1)" -lt "$(grep -n "status-transition.sh step .* 2.6$" <<<"$EXIT0" | cut -d: -f1)" ]'
check "2.6 keeps the no-tracker and already-filed rules" \
  'grep -q "skipped: no tracker" <<<"$EXIT0" && grep -q "already holds an .issue. is not filed again" <<<"$EXIT0"'
check "2.6's done line needs every task issue with a tracker" \
  'grep "^\*\*Done when" <<<"$S26" | grep -q "with a tracker every task record holds its .issue."'

echo "== 3.15: logged once, never a stop"
S315=$(section "$WAVES" "3.15 ")
check "3.15 exit 2 is not a stop and asks nothing" 'grep "Exit 2" <<<"$S315" | grep -q "not a stop, and nothing is asked"'
check "3.15 appends one Size budget overrun entry per spec" 'grep "Exit 2" <<<"$S315" | grep "Size budget overrun" | grep -q "a later wave adds nothing"'
check "3.15 exit 1 is never within budget" 'grep "Exit 1" <<<"$S315" | grep -q "never treat it as within budget"'
check "3.15 loads no discovered-work" '! grep -q "discovered-work" <<<"$S315"'
check "3.15 names no baseline_revision fallback" '! grep -q "baseline_revision" <<<"$S315"'
check "the design log has a Size budget overrun shape" 'section "$DESIGN_LOG" "YYYY-MM-DD Size budget overrun" | grep -q "^- Wave <n>:"'
check "the design log has no Approved budget overrun record" '! grep -q "Approved budget overrun" "$DESIGN_LOG"'
check "sign-off 5.4 reports the size budget figures" 'section "$MODULES/sign-off.md" "5.4 " | grep -q "^- \*\*Size budget\*\*"'
check "the report template has a Size budget line" 'grep -q "^- Size budget:" "$FW_SKILL/assets/report.md"'
check "the 5.5 summary shows a size budget the report shows over" 'section "$MODULES/sign-off.md" "5.5 " | grep -q "a size budget the report shows over"'

echo "== no size-budget block or 00.29 step left"
check "steps.tsv has no 00.29 row" '! grep -q "^00\.29	" "$FW_SKILL/references/steps.tsv"'
check "discovered-work has no 00.29 section and no size-budget condition" \
  '! grep -qE "00\.29|size budget:" "$MODULES/discovered-work.md"' "$(grep -nE "00\.29|size budget:" "$MODULES/discovered-work.md")"
check "no step file blocks with a size budget condition" \
  '! grep -rq -- "--blocked \"size budget" "$MODULES"' "$(grep -rn -- "--blocked \"size budget" "$MODULES")"
check "the router sends no size budget condition to discovered-work" \
  '! grep "^| .blocked. |" "$SKILL" | grep "size budget" | grep -q "discovered-work"'
check "the router has a row for an older size budget block that needs no ruling" \
  'grep "^| .blocked. | .blocked_condition. starts .size budget:." "$SKILL" | grep "no ruling needed" | grep -q "00.28"'
check "that row comes before the any-other-condition row" \
  '[ "$(grep -n "^| .blocked. | .blocked_condition. starts .size budget:." "$SKILL" | cut -d: -f1)" -lt "$(grep -n "^| .blocked. | any other condition" "$SKILL" | cut -d: -f1)" ]'
check "the Blocked section gives the exact 00.28 return command for an older size budget block" \
  'section "$SKILL" "Blocked" | grep "size budget:" | grep -q "status-transition.sh status .workflow/specs/NNN-slug <blocked_from> --step 00.28"'
check "the session-start hook says an older size budget block resumes without a ruling" \
  'grep -q "\"size budget:\"\*) entry+=\"; size-budget block from an older version: resumes without a ruling\"" "$AGENTS_SRC/hooks/session-start-resume.sh"'
check "the router still routes an older 00.29 re-scope to the questioning loop" 'grep "^| .draft. | step in 0.3.8" "$SKILL" | grep -q "00.29 from an older version"'
check "the shipped rules text no longer pauses the work" \
  '! grep -q "pauses the work" "$AGENTS_SRC/skills/project-setup/assets/docs/rules.md"'

finish
