#!/usr/bin/env bash
# Suite: hooks/session-start-resume.sh (SessionStart) listing initiatives; JRN-004 "Resume offer reads initiatives".
# Covers: an exploring initiative that exists only on its branch, read from the branch tip while the checkout is on main; the same
#   initiative after a local --no-ff merge, read from main; one line per initiative when it is on main and on a re-created branch;
#   status, current step from the gitignored .step and the pending research count on the line; a done initiative left out.
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
BR=initiative/001-storage-overhaul
SPEC=.workflow/specs/002-core-flow

# Fixture state written directly, so this suite depends on the hook alone and not on the initiative script.
yq --front-matter=process -i '(.questions[] | select(.id == "IQ1")) |= (.state = "researching" | .launched = {"task_type": "research", "at": "2026-10-21T11:00:00Z"})' \
  "$P/$INI/questions.md"
git -C "$P" commit -q -am "initiative 001-storage-overhaul: IQ1 launched"
git -C "$P" switch -q main

echo "== JRN-004 initiative only on its branch, checkout on main"
check "JRN-004 fixture: initiative.md is not in the main working tree" '[ ! -f "$P/$INI/initiative.md" ] && [ -f "$P/$INI/.step" ]'
ctx=$(resume_offer "$P")
line=$(offer_lines "$ctx" "$INI")
eq "JRN-004 the offer lists the branch-only initiative once" "$(printf '%s' "$line" | grep -c .)" 1
check "JRN-004 the branch-only line shows status exploring" 'grep -q "status exploring" <<<"$line"' "$ctx"
check "JRN-004 the branch-only line shows the current step" 'grep -q "step $LARGE_ENTRY_STEP" <<<"$line"' "$ctx"
check "JRN-004 the branch-only line shows one pending research question" 'grep -qF "$(offer_research_text 1)" <<<"$line"' "$ctx"
check "JRN-004 the offer names the large path for resuming" 'grep -qi "large path\|large-path" <<<"$ctx"' "$ctx"

echo "== JRN-004 planned initiative merged into main (task_review local)"
git -C "$P" switch -q "$BR"
yq --front-matter=process -i '.questions[] |= (.state = "settled" | .launched = null | .settled = "decided in round 2")' "$P/$INI/questions.md"
yq --front-matter=process -i '.status = "planned" | .slices[0].status = "emitted" | .slices[0].spec = "002-core-flow" | .slices[1].status = "emitted" | .slices[1].spec = "003-reports"' \
  "$P/$INI/initiative.md"
git -C "$P" commit -q -am "initiative 001-storage-overhaul: planned"
git -C "$P" switch -q main
mkdir -p "$P/$SPEC"
cp "$P/$FW_ASSETS_REL/spec.md" "$P/$SPEC/spec.md"
git -C "$P" add "$SPEC" && git -C "$P" commit -q -m "spec 002-core-flow: draft"
git -C "$P" merge -q --no-ff -m "Merge initiative 001-storage-overhaul (planned)" "$BR"
git -C "$P" branch -q -d "$BR"
ctx=$(resume_offer "$P")
line=$(offer_lines "$ctx" "$INI")
eq "JRN-004 after the merge the offer lists the initiative once, from main" "$(printf '%s' "$line" | grep -c .)" 1
check "JRN-004 the main line shows status planned" 'grep -q "status planned" <<<"$line"' "$ctx"
check "JRN-004 the main line shows the current step" 'grep -q "step $LARGE_ENTRY_STEP" <<<"$line"' "$ctx"
check "JRN-004 the main line shows no pending research" '[ -n "$line" ] && ! grep -qF "$(offer_research_text 1)" <<<"$line"' "$ctx"

echo "== JRN-004 initiative on main and on a re-created branch"
git -C "$P" branch -q "$BR" main
line=$(offer_lines "$(resume_offer "$P")" "$INI")
eq "JRN-004 an initiative on main and on its branch is listed once" "$(printf '%s' "$line" | grep -c .)" 1
git -C "$P" branch -q -D "$BR"

echo "== JRN-004 done initiative"
yq --front-matter=process -i '.status = "done"' "$P/$INI/initiative.md"
git -C "$P" commit -q -am "initiative 001-storage-overhaul: done"
check "JRN-004 a done initiative is not offered" '! offer_lines "$(resume_offer "$P")" "$INI" >/dev/null'
check "JRN-004 the draft spec is still offered beside it" 'offer_lines "$(resume_offer "$P")" "$SPEC" >/dev/null'

shellcheck_files "JRN-004 shellcheck session-start-resume.sh" "$P/.agents/hooks/session-start-resume.sh"
finish
