#!/usr/bin/env bash
# Suite: conversion of a draft spec into an initiative; JRN-001 "Convert a draft spec into an initiative".
# Covers: the conversion sequence replayed as the large path fixes it (clean tree, initiative/NNN-slug off origin/main,
#   initiative-transition.sh step and status, templates filled, design log and codebase map moved, Origin entry, shelf item and
#   work item re-pointed, spec folder removed, folder-scoped commit pushed under task_review pr); the initiative.md frontmatter and
#   .step it leaves; session-start-resume.sh naming the initiative instead of the spec; the next spec number skipping the
#   converted one.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/initiative.sh
source "$TESTS_DIR/fixtures/initiative.sh"
preflight

new_workdir
P=$WORK/proj
large_path_repo "$P"
seed_draft_spec "$P" 001 billing-suite
SPEC=.workflow/specs/001-billing-suite
INI=.workflow/initiatives/001-billing-suite
BR=initiative/001-billing-suite
SHELF=$P/.workflow/deferred/shelved-idea.md
WORK_ITEM=$P/.workflow/specs/work-backlog/000-earlier-disc-001.md
IT() { initiative_transition "$P" "$@"; }

eq "JRN-001 fixture: the draft spec sits at the conversion node" "$(marker_step "$P/$SPEC/.step")" "$CONVERSION_STEP"
check "JRN-001 fixture: the offer lists the draft spec before conversion" 'offer_lines "$(resume_offer "$P")" "$SPEC" >/dev/null'

echo "== JRN-001 conversion, replayed"
check "JRN-001 the working tree is clean before switching" '[ -z "$(git -C "$P" status --porcelain --untracked-files=no)" ]'
git -C "$P" fetch -q origin
git -C "$P" switch -q --no-track -c "$BR" origin/main
mkdir -p "$P/$INI"
IT step "$INI" "$LARGE_ENTRY_STEP" >/dev/null 2>&1
cp "$P/$FW_ASSETS_REL/initiative.md" "$P/$FW_ASSETS_REL/questions.md" "$P/$INI/"
CONV_ORIGIN=001-billing-suite CONV_BRANCH=$BR yq --front-matter=process -i \
  '.origin = strenv(CONV_ORIGIN) | .created = "2026-10-21" | .branch = strenv(CONV_BRANCH) | .merge_pr = null | .slices = []' "$P/$INI/initiative.md"
IT status "$INI" exploring --step "$LARGE_ENTRY_STEP" >/dev/null 2>&1
mv "$P/$SPEC/design-log.md" "$P/$SPEC/codebase-map.md" "$P/$INI/"
sed -i.bak 's/^Spec: \[spec.md\](spec.md)$/Initiative: [initiative.md](initiative.md)/' "$P/$INI/design-log.md" && rm -f "$P/$INI/design-log.md.bak"
printf '\n## 2026-10-21 Origin: converted from spec 001-billing-suite\n\n- Spec: %s (draft, step %s)\n- Reason: discovery found several features.\n' \
  "$SPEC" "$CONVERSION_STEP" >>"$P/$INI/design-log.md"
NEW_REF=$INI yq --front-matter=process -i '.origin_spec = strenv(NEW_REF)' "$SHELF"
NEW_REF=$INI yq --front-matter=process -i '.promoted_to = strenv(NEW_REF)' "$WORK_ITEM"
rm -rf "${P:?}/$SPEC"
git -C "$P" add "$INI" && git -C "$P" commit -q -m "initiative 001-billing-suite: converted from spec 001-billing-suite"
eq "JRN-001 task_review is pr, so the commit point pushes" "$(bash "$P/.agents/skills/feature-workflow/scripts/rules-setting.sh" task_review --cwd "$P" 2>/dev/null)" pr
git -C "$P" push -q -u origin "$BR" 2>/dev/null

echo "== JRN-001 end state"
eq "JRN-001 the initiative branch exists" "$(git -C "$P" branch --list "$BR" --format='%(refname:short)')" "$BR"
eq "JRN-001 the checkout is on the initiative branch" "$(git -C "$P" branch --show-current)" "$BR"
check "JRN-001 the initiative branch is on origin" 'git -C "$P.origin.git" show-ref --verify --quiet "refs/heads/$BR"'
eq "JRN-001 initiative.md status is exploring" "$(fm "$P/$INI/initiative.md" .status)" exploring
eq "JRN-001 initiative.md origin names the spec" "$(fm "$P/$INI/initiative.md" .origin)" 001-billing-suite
eq "JRN-001 initiative.md branch" "$(fm "$P/$INI/initiative.md" .branch)" "$BR"
eq "JRN-001 initiative.md merge_pr is null" "$(fm "$P/$INI/initiative.md" .merge_pr)" null
eq "JRN-001 initiative.md slices is empty" "$(fm "$P/$INI/initiative.md" '.slices | length')" 0
eq "JRN-001 the initiative marker names the entry step" "$(marker_step "$P/$INI/.step")" "$LARGE_ENTRY_STEP"
check "JRN-001 questions.md is in the initiative" '[ -f "$P/$INI/questions.md" ]'
check "JRN-001 the design log moved in with its Deeper prompt entry" 'grep -q "^## 2026-10-21 Deeper prompt" "$P/$INI/design-log.md"'
check "JRN-001 the codebase map moved in" '[ -f "$P/$INI/codebase-map.md" ]'
check "JRN-001 the design log has an Origin entry naming the spec" 'grep -q "^## .* Origin: .*001-billing-suite" "$P/$INI/design-log.md"'
check "JRN-001 the design log no longer links the deleted spec.md" '! grep -q "^Spec: \[spec.md\]" "$P/$INI/design-log.md"'
check "JRN-001 the spec folder is gone" '[ ! -e "$P/$SPEC" ]'
eq "JRN-001 the shelf item points at the initiative" "$(fm "$SHELF" .origin_spec)" "$INI"
eq "JRN-001 the work item points at the initiative" "$(fm "$WORK_ITEM" .promoted_to)" "$INI"
eq "JRN-001 the conversion commit holds only the initiative folder" \
  "$(git -C "$P" show --name-only --format= HEAD | grep -v "^\.workflow/initiatives/001-billing-suite/")" ""

echo "== JRN-001 session start after conversion"
ctx=$(resume_offer "$P")
eq "JRN-001 the offer lists the initiative once" "$(offer_lines "$ctx" "$INI" | grep -c .)" 1
check "JRN-001 the offer shows the initiative exploring at the entry step" \
  'offer_lines "$ctx" "$INI" | grep -q "status exploring" && offer_lines "$ctx" "$INI" | grep -q "step $LARGE_ENTRY_STEP"' "$ctx"
check "JRN-001 the offer no longer names the spec" '! offer_lines "$ctx" "$SPEC" >/dev/null' "$ctx"

echo "== JRN-001 numbering after conversion"
eq "JRN-001 the next spec number skips the converted one" "$(next_spec_number "$P")" 002
git -C "$P" switch -q main
eq "JRN-001 from main the next spec number still skips it (read from the initiative branch)" "$(next_spec_number "$P")" 002

shellcheck_files "JRN-001 shellcheck conversion components" "$P/$IT_REL" "$P/.agents/hooks/session-start-resume.sh" "$P/$ST_REL"
finish
