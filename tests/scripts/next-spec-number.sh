#!/usr/bin/env bash
# Suite: next-spec-number.sh (feature-workflow/scripts) with no tracker set up: the 0.1.1 numbering it took over.
# Covers: JRN-001 (spec 00014): with no .workflow/issue-tracking.yaml, and again with `issue_tracker: none`, the script
#   prints the next spec number the old 0.1.1 scan block gave, one line, and fake gh and glab on PATH see no call. The
#   project is built up one place at a time, each holding a higher number than the last, so every place the old scan
#   counted is shown to count: none (00001), top-level specs of three and five digits beside work-backlog/ (00006), the
#   Done folder (00011, the number tests/scripts/move-to-done.sh pins after its sweep), a spec worktree (00012), an
#   initiative's origin and emitted slice in the working tree (00014) and an initiative on its own branch only (00016);
#   run from inside the spec worktree it gives the same number, as tests/scripts/spec-worktree.sh pins for the old block.
#   The origin remote is on GitLab throughout, so a script that wrongly asks the tracker has a host to ask. A settings
#   file naming an unknown tracker, or a tracker without its issue flow, exits 2 with nothing on stdout and no call.
#   The script is shellcheck-clean.
# Oracle: each expected number is a literal: the highest number the old 0.1.1 block (modules/discovery.md at the spec's
#   baseline revision) finds in that fixture, plus one, zero-padded to five digits.
# shellcheck disable=SC2016,SC2329,SC1010,SC2034  # check expressions are single-quoted and eval'd on purpose and read variables and call helpers shellcheck cannot see; "done" is a stage and a status word
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/fake-trackers.sh
source "$TESTS_DIR/fixtures/fake-trackers.sh"
preflight

new_workdir
fake_trackers_install "$WORK/tracker"
P=$WORK/project
tracker_project "$P" gitlab
NSN_REL=.agents/skills/feature-workflow/scripts/next-spec-number.sh

# spec_folder DIR NAME STATUS : a spec folder NAME in DIR's specs folder, with a spec.md holding STATUS and a title.
spec_folder() {
  mkdir -p "$1/.workflow/specs/$2"
  printf -- '---\nstatus: %s\n---\n\n# %s\n' "$3" "$2" >"$1/.workflow/specs/$2/spec.md"
}

# initiative_file FILE ORIGIN SLICE_SPEC : an initiative.md whose origin and one emitted slice name those spec folders.
initiative_file() {
  mkdir -p "$(dirname "$1")"
  printf -- '---\nstatus: planned\norigin: %s\nslices:\n  - {id: S1, title: Slice, status: emitted, spec: %s}\n---\n\n# Initiative\n' \
    "$2" "$3" >"$1"
}

# next_number_from DIR : run the script from DIR with both fakes on PATH; sets OUT, ERR and RC.
next_number_from() { fake_run "$(fake_path both)" bash "$P/$NSN_REL" --cwd "$1"; }

# expect_next NAME WANT [DIR] : the script, run from DIR (default the project), prints WANT and calls no tracker.
expect_next() {
  local want=$2
  fake_trackers_reset
  next_number_from "${3:-$P}"
  check "$1" '[[ $RC == 0 && $OUT == "$want" && $(fake_call_count) == 0 ]]' \
    "rc=$RC out=$OUT want=$want calls=$(fake_call_count): $ERR $(fake_calls)"
}

echo "== JRN-001: no settings file, every place a spec number is taken"
expect_next "JRN-001 with no spec anywhere the next number is 00001 and no tracker is called" 00001

spec_folder "$P" 002-two done
spec_folder "$P" 005-current in-progress
mkdir -p "$P/.workflow/specs/work-backlog"
printf -- '- 002-two B1 open: an item\n' >"$P/.workflow/specs/work-backlog/002-two.md"
expect_next "JRN-001 top-level specs of any digit count give 00006 and no tracker call" 00006

mkdir -p "$P/.workflow/specs/done"
spec_folder "$P" done/00010-wide done
spec_folder "$P" done/009-narrow done
expect_next "JRN-001 the Done folder counts: 00011 and no tracker call" 00011

git_commit_all "$P" "fixture: specs before the spec worktree"
git -C "$P" worktree add -q "$P/.workflow/.spec-worktrees/00011-elsewhere" -b spec/00011-elsewhere
spec_folder "$P/.workflow/.spec-worktrees/00011-elsewhere" 00011-elsewhere in-progress
expect_next "JRN-001 a spec worktree counts: 00012 and no tracker call" 00012

initiative_file "$P/.workflow/initiatives/001-ini/initiative.md" 00012-converted 00013-sliced
expect_next "JRN-001 an initiative's origin and emitted slices count: 00014 and no tracker call" 00014

git_commit_all "$P" "fixture: initiative in the working tree"
git -C "$P" switch -q -c initiative/002-branchy
initiative_file "$P/.workflow/initiatives/002-branchy/initiative.md" 00014-branch-origin 00015-branch-slice
git_commit_all "$P" "fixture: initiative only on its branch"
git -C "$P" switch -q main
check "fixture: the branch-only initiative is absent from the working tree" '[[ ! -e $P/.workflow/initiatives/002-branchy ]]'
expect_next "JRN-001 an initiative on its own branch counts: 00016 and no tracker call" 00016
expect_next "JRN-001 run from inside the spec worktree the next number is the same 00016, with no tracker call" 00016 \
  "$P/.workflow/.spec-worktrees/00011-elsewhere"

echo "== JRN-001: issue_tracker: none"
tracker_settings "$P" none
expect_next "JRN-001 with issue_tracker: none the next number is still 00016 and no tracker is called" 00016

echo "== bad settings files"
printf 'issue_tracker: jira\n' >"$P/.workflow/issue-tracking.yaml"
fake_trackers_reset
next_number_from "$P"
check "JRN-001 a settings file naming an unknown tracker exits 2 with nothing on stdout and no call" \
  '[[ $RC == 2 && -z $OUT && $(fake_call_count) == 0 ]]' "rc=$RC out=$OUT: $ERR"
printf 'issue_tracker: gitlab\n' >"$P/.workflow/issue-tracking.yaml"
fake_trackers_reset
next_number_from "$P"
check "JRN-001 a tracker without its issue flow exits 2 with nothing on stdout and no call" \
  '[[ $RC == 2 && -z $OUT && $(fake_call_count) == 0 ]]' "rc=$RC out=$OUT: $ERR"

shellcheck_files "shellcheck: next-spec-number.sh" "$P/$NSN_REL"
finish
