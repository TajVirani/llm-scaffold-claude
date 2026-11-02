#!/usr/bin/env bash
# Suite: tracker-adoption.sh (issue-tracking/scripts): Tracker adoption on a project already under way, and the readers of a
#   Done spec renamed with the old_ prefix.
# Covers: against fake glab and gh (tests/fixtures/fake-trackers.sh) and the project tests/fixtures/tracker-adoption.sh
#   builds (a draft spec, a spec past 1.1 with a pushed spec branch and a spec worktree, a spec with a live task worktree,
#   two Done specs with backlog lists, review lessons and links), the fake handing out issue numbers from 101:
#   JRN-011 (spec 00014): adoption exits 1, naming 016-epsilon and its live task worktree, and leaves that spec, its branch
#   and both its worktrees as they were; the tracker gets exactly one issue per other active spec. The draft's folder,
#   step marker, backlog list and every .workflow/ reference move to the five-digit issue number, and its tracker_issue is
#   the issue URL. The spec past 1.1 gets a renamed local branch, spec worktree and folder, with spec_branch, the task
#   records' branch fields, its tracker_issue and its own references rewritten and its step marker kept; the renamed branch
#   is committed and pushed, the old remote branch is still there and the output reports it. The Done specs and their
#   backlog lists become done/old_NNN-slug and old_NNN-slug.md, with the retrospective's file name kept, the review lesson,
#   capabilities rows, shelf and links pointing at the new names; no old name is left and every relative link resolves.
#   review-lessons.sh validate and move-to-done.sh --check accept the renamed Done spec.
#   JRN-012: move-to-done.sh --check on a Done spec named old_NNN-slug reads its backlog list old_NNN-slug.md: it passes on
#   well-formed lines and names a malformed line by file and line number.
#   Errors and reruns: a second run files no second issue and reports the renamed specs as already adopted; an unknown
#   flag, --cwd without a value or naming no directory, no tracker settings and issue_tracker none exit 2 before anything
#   is filed or renamed; a commit refused in a spec worktree exits 2 and rolls back the folder move and the branch-name
#   edits, keeps tracker_issue and leaves the main checkout as it was; a push the local bare origin refuses exits 1 naming
#   the command to push by hand, leaves the old remote branch unchanged and still adopts the other specs.
#   The script is shellcheck-clean.
# shellcheck disable=SC2016,SC2329,SC1010,SC2034  # check expressions are single-quoted and eval'd on purpose and read variables and call helpers shellcheck cannot see; "done" is a status word
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/pr-template.sh
source "$TESTS_DIR/fixtures/pr-template.sh"
# shellcheck source=../fixtures/done-folder.sh
source "$TESTS_DIR/fixtures/done-folder.sh"
# shellcheck source=../fixtures/fake-trackers.sh
source "$TESTS_DIR/fixtures/fake-trackers.sh"
# shellcheck source=../fixtures/tracker-adoption.sh
source "$TESTS_DIR/fixtures/tracker-adoption.sh"
preflight

new_workdir
fake_trackers_install "$WORK/tracker"
TA_REL=.agents/skills/issue-tracking/scripts/tracker-adoption.sh
MTD_REL=.agents/skills/feature-workflow/scripts/move-to-done.sh
RLS_REL=.agents/skills/feature-workflow/scripts/review-lessons.sh
P=$WORK/project
BARE=$WORK/origin.git
SPECS=.workflow/specs
adoption_project "$P" "$BARE"

# fm FILE EXPR : one frontmatter value of FILE; empty when the file is missing.
fm() { [[ -f $1 ]] && yq --front-matter=extract "$2" "$1" 2>/dev/null; }
# step_of SPEC_FOLDER : the step its marker holds.
step_of() { sed -n 's/^step: "\(.*\)"$/\1/p' "$1/.step" 2>/dev/null; }
# renamed DIR SLUG : the name of the one spec folder under DIR named <five or more digits>-SLUG, the width a tracker number
#   is padded to; empty unless there is exactly one.
renamed() {
  local found
  found=$(cd "$1" 2>/dev/null && find . -mindepth 1 -maxdepth 1 -type d -name "[0-9][0-9][0-9][0-9][0-9]*-$2" | sed 's#^\./##')
  [[ $(printf '%s\n' "$found" | grep -c .) == 1 ]] && printf '%s' "$found"
}
# issue_of NAME : the issue number a renamed spec folder NAME carries, without its zero padding.
issue_of() { printf '%s' "$((10#${1%%-*}))"; }
# remote_branch NAME : the commit BARE holds for branch NAME; empty when it has none.
remote_branch() { git -C "$BARE" rev-parse -q --verify "refs/heads/$1" 2>/dev/null; }

echo "== fixture: the project before adoption"
check "fixture: every relative link in the main checkout's specs, shelf and decisions resolves" \
  '[[ -z $(unresolved_links "$P/$SPECS"; unresolved_links "$P/.workflow/deferred"; unresolved_links "$P/.workflow/decisions") ]]' \
  "$(unresolved_links "$P/$SPECS")"
check "fixture: spec/013-beta is pushed and the draft is untracked" \
  '[[ -n $(remote_branch spec/013-beta) && -n $(git -C "$P" status --porcelain -- "$SPECS/015-delta") ]]'
check "fixture: 016-epsilon has a live task worktree" '[[ -d $ADOPTION_EPSILON_TASK_WT/.git || -f $ADOPTION_EPSILON_TASK_WT/.git ]]'
EPSILON_TIP=$(git -C "$P" rev-parse spec/016-epsilon)
EPSILON_DIGEST=$(cd "$ADOPTION_EPSILON_WT/$SPECS/016-epsilon" && find . -type f -exec cksum {} + | LC_ALL=C sort)
BETA_OLD_TIP=$(remote_branch spec/013-beta)

echo "== JRN-011: run the adoption"
fake_trackers_reset
FAKE_ISSUE_NUMBER=101 fake_run "$(fake_path both)" bash "$P/$TA_REL" --cwd "$P"
REPORT="$OUT
$ERR"
check "JRN-011 adoption exits 1 and names 016-epsilon, refused for its live task worktree" \
  '[[ $RC == 1 ]] && grep -q "016-epsilon" <<<"$REPORT" && grep -qi "worktree" <<<"$REPORT"' "rc=$RC: $REPORT"
check "JRN-011 the refused spec keeps its folder, branch and both worktrees as they were" \
  '[[ $RC == 1 && $(git -C "$P" rev-parse -q --verify spec/016-epsilon) == "$EPSILON_TIP" && -d $ADOPTION_EPSILON_TASK_WT &&
     $(cd "$ADOPTION_EPSILON_WT/$SPECS/016-epsilon" 2>/dev/null && find . -type f -exec cksum {} + | LC_ALL=C sort) == "$EPSILON_DIGEST" ]]'
eq "JRN-011 the tracker gets one issue per adopted active spec and none for the refused or Done specs" \
  "$(fake_issue_numbers | tr '\n' ' ')" "101 102 "

DELTA=$(renamed "$P/$SPECS" delta)
# The spec worktree takes the renamed spec's name, so the renamed folder is found through it.
BETA=$(renamed "$P/.workflow/.spec-worktrees" beta)
BETA_WT=$P/.workflow/.spec-worktrees/$BETA
check "JRN-011 the draft and the spec past 1.1 are renamed to the two issue numbers, five digits wide" \
  '[[ " $DELTA $BETA " == *" 00101-delta "* || " $DELTA $BETA " == *" 00102-delta "* ]] &&
   [[ $DELTA != "${BETA%-beta}-delta" && ${BETA%-beta} =~ ^0010[12]$ ]]' "draft=$DELTA beta=$BETA"

echo "== JRN-011: the draft spec"
check "JRN-011 the draft's old folder is gone and its renamed folder keeps its step marker" \
  '[[ ! -e $P/$SPECS/015-delta && -n $DELTA && $(step_of "$P/$SPECS/$DELTA") == 0.1.6 ]]' "draft=$DELTA"
eq "JRN-011 the draft's tracker_issue is its issue URL" "$(fm "$P/$SPECS/${DELTA:-none}/spec.md" .tracker_issue)" \
  "$(fake_url glab "$(issue_of "${DELTA:-0-none}")")"
check "JRN-011 the draft's backlog list is renamed with it" \
  '[[ ! -e $P/$SPECS/work-backlog/015-delta.md && -f $P/$SPECS/work-backlog/${DELTA:-none}.md ]]'
eq "JRN-011 the draft's shelf file names the renamed folder" \
  "$(fm "$P/.workflow/deferred/delta-shelf.md" .origin_spec)" "$SPECS/${DELTA:-none}"

echo "== JRN-011: the spec past 1.1"
check "JRN-011 the spec branch is renamed locally" \
  '[[ -n $BETA ]] && git -C "$P" rev-parse -q --verify "spec/$BETA" >/dev/null && ! git -C "$P" rev-parse -q --verify spec/013-beta >/dev/null'
check "JRN-011 the spec worktree moved to the new name and holds the renamed folder, checked out on the renamed branch" \
  '[[ -n $BETA && ! -e $ADOPTION_BETA_WT && -f $BETA_WT/$SPECS/$BETA/spec.md && $(git -C "$BETA_WT" branch --show-current) == "spec/$BETA" ]]' \
  "beta=$BETA; $(git -C "$P" worktree list)"
eq "JRN-011 spec_branch names the renamed branch" "$(fm "$BETA_WT/$SPECS/${BETA:-none}/spec.md" .spec_branch)" "spec/${BETA:-none}"
eq "JRN-011 the task records' branch fields name the renamed spec" \
  "$(fm "$BETA_WT/$SPECS/${BETA:-none}/tasks.md" '[.tasks[].branch] | join(" ")')" \
  "task/${BETA:-none}/T01-build task/${BETA:-none}/T02-wire"
eq "JRN-011 the spec's tracker_issue is its issue URL" "$(fm "$BETA_WT/$SPECS/${BETA:-none}/spec.md" .tracker_issue)" \
  "$(fake_url glab "$(issue_of "${BETA:-0-none}")")"
check "JRN-011 the spec keeps its step marker and its design log names the new folder" \
  '[[ $(step_of "$BETA_WT/$SPECS/${BETA:-none}") == 3.16 ]] && grep -qx -- "- Folder: $SPECS/${BETA:-none}" "$BETA_WT/$SPECS/${BETA:-none}/design-log.md"'
check "JRN-011 the renamed branch is committed with the renamed folder and pushed" \
  '[[ -n $BETA && -n $(remote_branch "spec/$BETA") && $(remote_branch "spec/$BETA") == $(git -C "$P" rev-parse "spec/$BETA") ]] &&
   git -C "$BARE" cat-file -e "spec/$BETA:$SPECS/$BETA/spec.md" 2>/dev/null' "remote branches: $(git -C "$BARE" branch | tr '\n' ' ')"
check "JRN-011 the old remote branch is left in place and reported" \
  '[[ $(remote_branch spec/013-beta) == "$BETA_OLD_TIP" ]] && grep -q "spec/013-beta" <<<"$REPORT"' "$REPORT"

echo "== JRN-011: the Done specs"
check "JRN-011 the Done specs are renamed with the old_ prefix" \
  '[[ -f $P/$SPECS/done/old_012-alpha/spec.md && -f $P/$SPECS/done/old_014-gamma/spec.md && ! -e $P/$SPECS/done/012-alpha && ! -e $P/$SPECS/done/014-gamma ]]'
check "JRN-011 their backlog lists are renamed with the old_ prefix" \
  '[[ -f $P/$SPECS/work-backlog/old_012-alpha.md && -f $P/$SPECS/work-backlog/old_014-gamma.md &&
     ! -e $P/$SPECS/work-backlog/012-alpha.md && ! -e $P/$SPECS/work-backlog/014-gamma.md ]]'
check "JRN-011 the retrospective keeps its file name and points at the renamed folder" \
  '[[ $(fm "$P/.workflow/decisions/retrospectives/012-alpha.md" .spec) == "$SPECS/done/old_012-alpha" ]]'
check "JRN-011 the review lesson's origin_spec names the renamed folder and the lessons still validate" \
  'grep -q "origin_spec: $SPECS/done/old_012-alpha\$" "$P/.workflow/review-lessons.md" && bash "$P/$RLS_REL" validate "$P/.workflow/review-lessons.md" >/dev/null 2>&1'
check "JRN-011 capabilities.md links the renamed folders" \
  'grep -qF "(specs/done/old_012-alpha/spec.md)" "$P/.workflow/capabilities.md" && grep -qF "(specs/done/old_014-gamma/spec.md)" "$P/.workflow/capabilities.md"'
check "JRN-011 move-to-done.sh --check accepts the renamed Done spec" \
  'bash "$P/$MTD_REL" --check "$SPECS/done/old_012-alpha" --cwd "$P" >/dev/null 2>&1'

echo "== JRN-011: no old name is left"
check "JRN-011 no .workflow/ file in the main checkout still names a spec or backlog list by its old name" \
  '[[ -z $(adoption_old_refs "$P") ]]' "$(adoption_old_refs "$P" | head -5)"
check "JRN-011 the renamed spec's files no longer name 013-beta" \
  '[[ -n $BETA ]] && ! grep -rqE "(specs|spec|task)/013-beta([^A-Za-z0-9._-]|$)" "$BETA_WT/$SPECS/$BETA"' \
  "$(grep -rnE "(specs|spec|task)/013-beta" "$BETA_WT/$SPECS/${BETA:-none}" 2>/dev/null | head -3)"
check "JRN-011 after the renames every relative link in the main checkout's specs, shelf and decisions resolves" \
  '[[ -n $DELTA && -d $P/$SPECS/done/old_012-alpha ]] &&
   [[ -z $(unresolved_links "$P/$SPECS"; unresolved_links "$P/.workflow/deferred"; unresolved_links "$P/.workflow/decisions") ]]' \
  "draft=$DELTA; $(unresolved_links "$P/$SPECS"; unresolved_links "$P/.workflow/deferred" | head -5)"

echo "== JRN-012: the backlog lookup of a Done spec renamed old_"
Q=$WORK/old-done
tracker_project "$Q" gitlab
mkdir -p "$Q/$SPECS/done/old_020-zeta" "$Q/$SPECS/work-backlog"
printf -- '---\nstatus: done\nspec_branch: spec/020-zeta\n---\n\n# Zeta\n' >"$Q/$SPECS/done/old_020-zeta/spec.md"
printf -- '---\ntasks:\n  - id: T1\n    title: "Zeta"\n    status: done\n---\n' >"$Q/$SPECS/done/old_020-zeta/tasks.md"
printf -- '- [open] B1 bug (3.4): Retry the flaky fetch. Evidence: tests/fetch.sh:12\n' >"$Q/$SPECS/work-backlog/old_020-zeta.md"
git_commit_all "$Q" "fixture: a Done spec renamed old_"
fake_run "$(fake_path both)" bash "$Q/$MTD_REL" --check "$SPECS/done/old_020-zeta" --cwd "$Q"
eq "JRN-012 move-to-done.sh --check passes an old_ Done spec whose backlog list is well formed" "$RC" 0
printf -- '- [maybe] B2 bug (3.4): A line out of shape. Evidence: tests/fetch.sh:13\n' >>"$Q/$SPECS/work-backlog/old_020-zeta.md"
fake_run "$(fake_path both)" bash "$Q/$MTD_REL" --check "$SPECS/done/old_020-zeta" --cwd "$Q"
check "JRN-012 move-to-done.sh --check reads the old_ backlog list and names its malformed line" \
  '[[ $RC == 1 && $OUT == *"work-backlog/old_020-zeta.md:2"* ]]' "rc=$RC out=$OUT err=$ERR"

echo "== a second run on the adopted project"
fake_run "$(fake_path both)" bash "$P/$TA_REL" --cwd "$P"
check "a second run files no second issue and reports both renamed specs as already adopted" \
  '[[ $(fake_issue_numbers | tr "\n" " ") == "101 102 " && $OUT == *"already adopted: $SPECS/${DELTA:-none}"* &&
     $OUT == *"already adopted: $SPECS/${BETA:-none}"* ]]' "rc=$RC out=$OUT issues=$(fake_issue_numbers | tr '\n' ' ')"
check "a second run still refuses 016-epsilon and exits 1" '[[ $RC == 1 ]] && grep -q "016-epsilon" <<<"$ERR"' "rc=$RC err=$ERR"

echo "== usage and environment errors"
fake_run "$(fake_path both)" bash "$P/$TA_REL" --bogus
check "an unknown flag exits 2 with the usage line" '[[ $RC == 2 && $ERR == *"usage: tracker-adoption.sh"* ]]' "rc=$RC err=$ERR"
fake_run "$(fake_path both)" bash "$P/$TA_REL" --cwd
check "--cwd without a value exits 2 with the usage line" '[[ $RC == 2 && $ERR == *"usage: tracker-adoption.sh"* ]]' \
  "rc=$RC err=$ERR"
fake_run "$(fake_path both)" bash "$P/$TA_REL" --cwd "$WORK/missing"
check "--cwd naming no directory exits 2" '[[ $RC == 2 && $ERR == *"not a directory"* ]]' "rc=$RC err=$ERR"
N=$WORK/no-tracker
tracker_project "$N" gitlab
mkdir -p "$N/$SPECS/015-delta"
printf -- '---\nstatus: draft\nspec_branch: ""\n---\n\n# Delta feature\n' >"$N/$SPECS/015-delta/spec.md"
fake_trackers_reset
fake_run "$(fake_path both)" bash "$N/$TA_REL" --cwd "$N"
check "with no tracker settings adoption exits 2 before it files or renames anything" \
  '[[ $RC == 2 && $ERR == *"no tracker is set up"* && $(fake_call_count) == 0 && -f $N/$SPECS/015-delta/spec.md ]]' \
  "rc=$RC err=$ERR calls=$(fake_call_count)"
tracker_settings "$N" none
fake_run "$(fake_path both)" bash "$N/$TA_REL" --cwd "$N"
check "with issue_tracker none adoption exits 2 before it files or renames anything" \
  '[[ $RC == 2 && $ERR == *"not gitlab or github"* && $(fake_call_count) == 0 && -f $N/$SPECS/015-delta/spec.md ]]' \
  "rc=$RC err=$ERR calls=$(fake_call_count)"

echo "== a commit failing in a spec worktree"
R=$WORK/commit-fails
adoption_project "$R" "$WORK/commit-fails.git"
R_BETA_WT=$ADOPTION_BETA_WT
R_BETA_TIP=$(git -C "$R" rev-parse spec/013-beta)
# The main checkout's draft gets its tracker_issue before any rename, so its folder is left out of the comparison.
R_MAIN_DIGEST=$(cd "$R/.workflow" && find . -path ./.spec-worktrees -prune -o -path ./specs/015-delta -prune -o -type f \
  -exec cksum {} + | LC_ALL=C sort)
printf '#!/bin/sh\necho "pre-commit: refused by the test" >&2\nexit 1\n' >"$R/.git/hooks/pre-commit"
chmod +x "$R/.git/hooks/pre-commit"
fake_trackers_reset
FAKE_ISSUE_NUMBER=201 fake_run "$(fake_path both)" bash "$R/$TA_REL" --cwd "$R"
check "a failed commit in the spec worktree exits 2 and says the renames were rolled back" \
  '[[ $RC == 2 && $ERR == *"cannot commit the rename"* && $ERR == *"rolled back"* ]]' "rc=$RC err=$ERR"
check "the spec folder is back under its old name in its spec worktree, on its old branch at its old commit" \
  '[[ -f $R_BETA_WT/$SPECS/013-beta/spec.md && -z $(renamed "$R_BETA_WT/$SPECS" beta) &&
     $(git -C "$R_BETA_WT" branch --show-current) == spec/013-beta && $(git -C "$R" rev-parse spec/013-beta) == "$R_BETA_TIP" ]]' \
  "$(ls "$R_BETA_WT/$SPECS" 2>&1)"
eq "the rollback gives spec_branch its old branch name back" "$(fm "$R_BETA_WT/$SPECS/013-beta/spec.md" .spec_branch)" \
  "spec/013-beta"
eq "the rollback gives the task records' branch fields their old names back" \
  "$(fm "$R_BETA_WT/$SPECS/013-beta/tasks.md" '[.tasks[].branch] | join(" ")')" "task/013-beta/T01-build task/013-beta/T02-wire"
check "the rolled-back spec keeps the issue it was given in tracker_issue" \
  '[[ $(fm "$R_BETA_WT/$SPECS/013-beta/spec.md" .tracker_issue) == "$(fake_url glab 201)" ||
     $(fm "$R_BETA_WT/$SPECS/013-beta/spec.md" .tracker_issue) == "$(fake_url glab 202)" ]]' \
  "tracker_issue=$(fm "$R_BETA_WT/$SPECS/013-beta/spec.md" .tracker_issue)"
check "the main checkout is left as it was: no Done spec, draft or reference renamed" \
  '[[ -d $R/$SPECS/done/012-alpha && -d $R/$SPECS/015-delta && ! -e $R/$SPECS/done/old_012-alpha &&
     $(cd "$R/.workflow" && find . -path ./.spec-worktrees -prune -o -path ./specs/015-delta -prune -o -type f -exec cksum {} + |
       LC_ALL=C sort) == "$R_MAIN_DIGEST" ]]' "$(git -C "$R" status --porcelain)"

echo "== a push the remote refuses"
U=$WORK/push-fails
U_BARE=$WORK/push-fails.git
adoption_project "$U" "$U_BARE"
git -C "$ADOPTION_EPSILON_WT" worktree remove --force "$ADOPTION_EPSILON_TASK_WT"
U_OLD_TIP=$(git -C "$U_BARE" rev-parse refs/heads/spec/013-beta)
printf '#!/bin/sh\necho "pre-receive: refused by the test" >&2\nexit 1\n' >"$U_BARE/hooks/pre-receive"
chmod +x "$U_BARE/hooks/pre-receive"
fake_trackers_reset
FAKE_ISSUE_NUMBER=301 fake_run "$(fake_path both)" bash "$U/$TA_REL" --cwd "$U"
U_BETA=$(renamed "$U/.workflow/.spec-worktrees" beta)
check "a refused push exits 1 and names the command that pushes the renamed branch by hand" \
  '[[ $RC == 1 && -n $U_BETA && $ERR == *"git push -u origin spec/$U_BETA"* ]]' "rc=$RC beta=$U_BETA err=$ERR"
check "the renamed branch stays committed locally and the remote keeps only the old branch, unchanged" \
  'git -C "$U" rev-parse -q --verify "spec/$U_BETA" >/dev/null &&
   ! git -C "$U_BARE" rev-parse -q --verify "refs/heads/spec/$U_BETA" >/dev/null &&
   [[ $(git -C "$U_BARE" rev-parse refs/heads/spec/013-beta) == "$U_OLD_TIP" ]]' "$(git -C "$U_BARE" branch)"
check "the other specs are still adopted when the push is refused" \
  '[[ -n $(renamed "$U/$SPECS" delta) && -n $(renamed "$U/.workflow/.spec-worktrees" epsilon) && -d $U/$SPECS/done/old_012-alpha ]]' \
  "$OUT"

shellcheck_files "shellcheck: tracker-adoption.sh" "$P/$TA_REL"
finish
