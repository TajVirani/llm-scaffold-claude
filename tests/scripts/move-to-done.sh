#!/usr/bin/env bash
# Suite: move-to-done.sh (feature-workflow/scripts) and the readers that look in the Done folder, .workflow/specs/done/.
# Covers: the interface: the script is executable, and no argument or an unknown option exits 2.
#   JRN-001: --check on a spec whose task record T2 is pending exits 1, names T2 and not the done tasks, and changes no file,
#   ref or index entry; two open records are both named; a backlog item from the spec with a status outside open, promoted,
#   moved-to-deferred and dismissed is named, while one from another spec is not; the 5.7 sequence (the check, then
#   status-transition.sh status done --step 5.7) leaves the spec in-review; once every record is done or split-out the check
#   exits 0, changes nothing, and the 5.7 sequence reaches done; a missing spec folder exits 2.
#   JRN-002: moving the done spec 012-alpha puts it at .workflow/specs/done/012-alpha with no step marker, the same
#   spec_branch and status, and the old folder gone, committed as one Conventional Commits commit on the spec branch with a
#   clean tree; every back-link form is rewritten (shelf, retrospective, capabilities row, review lesson, backlog items,
#   sibling spec, the spec's own path strings, pr-body.md); the cache file, the initiative file, docs/notes.md and the
#   look-alike 012-alpha-two and 012-alphabet references are byte-identical; no other file changed (the expected-tree
#   oracle); no old-path reference remains outside cache/ and initiatives/; the word-level diff changes only path words;
#   every relative link in the moved spec resolves; refusals that change nothing: a spec not done, an existing
#   done/012-alpha, a pending task record, a missing folder, a folder that is not a spec.
#   JRN-006 (the move half): the moved pr-body.md differs from the approved one only in the spec path, and check-pr-body.sh
#   exits 0 on it.
#   JRN-003: --sweep moves 012-alpha and 014-gamma, keeps 013-beta, 015-delta and work-backlog/ at the top level with their
#   step markers, leaves the tree the swept oracle describes, commits on the checked-out branch, and a second sweep changes
#   nothing.
#   JRN-007 and JRN-004 (numbering): with 00010-wide and 009-narrow done, --check passes on the five-digit spec, --sweep
#   moves both and rewrites their links, and the 0.1.1 scan read from modules/discovery.md counts the Done folder, so the
#   next number is 00011.
#   JRN-004 (done on main): the spec_done_on_main helper read from modules/large-path.md is true for a done spec on main at
#   the top level and in done/, and false for one that is not done.
#   Edge cases: a path ending a sentence and two paths one space apart are all rewritten; a link back into the spec through
#   its parent and a reference-style link resolve after the move; a spec already in done/ cannot move (2) but passes --check;
#   the main branch and a detached HEAD are refused with nothing changed; an untracked done spec moves and is committed; a
#   sweep with a done spec failing the check exits 1, names it and its open task, leaves it in place and commits the rest.
#   The sweep on a done spec's own branch (sign-off 5.8) leaves that spec at the top level, says so, exits 0 and commits the
#   other done spec alone; the spec's own move then succeeds and the tree matches the swept oracle; when that spec is the
#   only done one the sweep prints nothing to sweep, exits 0 and changes nothing.
#   Failing reads (git stubbed on PATH, or a file or folder made unreadable): the checked-out branch, the list of workflow
#   files, the tracked check, the search of an unreadable file and the listing of an unreadable spec subfolder each exit 2
#   with their message and leave nothing changed; so does a search whose list of matching files cannot be written (a stubbed
#   mktemp puts a folder in its place). Rollback: a commit that fails after the move and a sweep that cannot write
#   a read-only file for its second spec both exit 2 and leave the tree, the step markers, the refs and the index exactly as
#   they were.
# Fixtures: tests/fixtures/done-folder.sh (the project, its expected trees and the oracles), tests/fixtures/pr-template.sh.
# shellcheck disable=SC2016,SC2034,SC2329,SC1010  # check expressions are single-quoted and eval'd on purpose, read variables and call helpers shellcheck cannot see; "done" is a status word
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/pr-template.sh
source "$TESTS_DIR/fixtures/pr-template.sh"
# shellcheck source=../fixtures/done-folder.sh
source "$TESTS_DIR/fixtures/done-folder.sh"
preflight

new_workdir
DONE=.workflow/specs/done
MOVED=$DONE/012-alpha

# mtd DIR ARG... : run the project's own move-to-done.sh from the project root DIR; sets OUT (stdout and stderr) and RC.
mtd() {
  local dir=$1
  shift
  OUT=$(cd "$dir" && bash "$dir/$DONE_MTD_REL" "$@" 2>&1)
  RC=$?
}

# sign_off_5_7 DIR SPEC : the 5.7 sequence in the project root DIR: the sub-item check, and only when it passes, done.
sign_off_5_7() {
  (cd "$1" && bash "$1/$DONE_MTD_REL" --check "$2" && bash "$1/.agents/skills/feature-workflow/scripts/status-transition.sh" \
    status "$2" done --step 5.7) >/dev/null 2>&1
}

# failing_git DIR PATTERN : write DIR/git, a stand-in that fails a git call whose arguments, joined with spaces and padded
#   with one space each side, match the glob PATTERN, and runs the real git otherwise; prints DIR to put first on PATH.
failing_git() {
  mkdir -p "$1"
  printf '#!/bin/bash\npattern=%q\n[[ " $* " == $pattern ]] && { echo "git: refused by the test" >&2; exit 1; }\nexec %q "$@"\n' \
    "$2" "$(command -v git)" >"$1/git"
  chmod +x "$1/git"
  printf '%s\n' "$1"
}

# scratch_with_folder_at DIR NAME : write DIR/mktemp, a stand-in whose `mktemp -d` makes the temporary folder with a
#   folder called NAME already in it, so a script cannot write its scratch file NAME there; prints DIR to put first on PATH.
scratch_with_folder_at() {
  mkdir -p "$1"
  printf '#!/bin/bash\nif [[ $# == 1 && $1 == -d ]]; then dir=$(%q -d) && mkdir "$dir"/%q && echo "$dir"; exit; fi\nexec %q "$@"\n' \
    "$(command -v mktemp)" "$2" "$(command -v mktemp)" >"$1/mktemp"
  chmod +x "$1/mktemp"
  printf '%s\n' "$1"
}

# fm FILE EXPR : one frontmatter value.
fm() { yq --front-matter=extract "$2" "$1" 2>/dev/null; }

# set_task DIR SPEC ID STATUS : write a task record's status straight into tasks.md, standing in for earlier steps.
set_task() {
  TASK_ID=$3 TASK_STATUS=$4 yq --front-matter=process -i \
    '(.tasks[] | select(.id == strenv(TASK_ID))).status = strenv(TASK_STATUS)' "$1/$2/tasks.md"
}

# set_status FILE STATUS : write a frontmatter status straight into FILE.
set_status() { NEW_STATUS=$2 yq --front-matter=process -i '.status = strenv(NEW_STATUS)' "$1"; }

# word_changes REPO FROM TO OLD NEW : the words removed or added between commits FROM and TO under the workflow folder and docs/, one
#   per line with its - or + sign. A file under the folder NEW in TO is compared with the same file under OLD in FROM. Git's
#   own rename detection is not used because it misses a small file whose path strings changed.
word_changes() {
  local repo=$1 from=$2 to=$3 old=$4 new=$5 file src
  while IFS= read -r file; do
    src=$file
    case "$file" in "$new"/*) src=$old/${file#"$new"/} ;; esac
    git -C "$repo" show "$from:$src" >"$WORK/words-before" 2>/dev/null || : >"$WORK/words-before"
    git -C "$repo" show "$to:$file" >"$WORK/words-after"
    git diff --no-index --word-diff=porcelain --word-diff-regex='[^[:space:]]+' "$WORK/words-before" "$WORK/words-after" \
      | grep -E '^[-+]' | grep -vE '^(---|\+\+\+) '
  done < <(git -C "$repo" ls-tree -r --name-only "$to" -- .workflow docs)
}

# fenced_block_after FILE PATTERN : print the first fenced bash block after the first line matching PATTERN, unindented.
fenced_block_after() {
  awk -v pat="$2" '
    !armed && index($0, pat) { armed = 1; next }
    armed && !infence && /^[[:space:]]*```bash[[:space:]]*$/ { infence = 1; match($0, /^[[:space:]]*/); indent = RLENGTH; next }
    infence && /^[[:space:]]*```[[:space:]]*$/ { exit }
    infence { print substr($0, indent + 1) }
  ' "$1"
}

# fenced_block_with FILE PATTERN : print the first fenced bash block holding a line that contains PATTERN, unindented.
fenced_block_with() {
  awk -v pat="$2" '
    !infence && /^[[:space:]]*```bash[[:space:]]*$/ { infence = 1; match($0, /^[[:space:]]*/); indent = RLENGTH; buf = ""; hit = 0; next }
    infence && /^[[:space:]]*```[[:space:]]*$/ { infence = 0; if (hit) { printf "%s", buf; exit } next }
    infence { buf = buf substr($0, indent + 1) "\n"; if (index($0, pat)) hit = 1 }
  ' "$1"
}

echo "== interface"
P=$WORK/check
done_folder_repo "$P"
check "move-to-done.sh is executable" '[[ -x "$P/$DONE_MTD_REL" ]]'
mtd "$P"
eq "no argument exits 2" "$RC" 2
mtd "$P" --frobnicate "$DONE_SPEC"
eq "an unknown option exits 2" "$RC" 2
mtd "$P" --check
eq "--check without a spec folder exits 2" "$RC" 2

echo "== JRN-001: the check refuses an open task"
set_status "$P/$DONE_SPEC/spec.md" in-review
set_task "$P" "$DONE_SPEC" T2 pending
git_commit_all "$P" "fixture: 012-alpha in review with T2 pending"
step_marker "$P/$DONE_SPEC" 5.7
BEFORE=$(tree_digest "$P")
mtd "$P" --check "$DONE_SPEC"
eq "JRN-001 --check with T2 pending exits 1" "$RC" 1
check "JRN-001 --check names the open task T2" '[[ $OUT == *T2* ]]' "$OUT"
check "JRN-001 --check does not name the done task T1 or the split-out T3" '[[ $OUT != *T1* && $OUT != *T3* ]]' "$OUT"
check "JRN-001 --check changes no file, ref or index entry" '[[ $(tree_digest "$P") == "$BEFORE" ]]'
sign_off_5_7 "$P" "$DONE_SPEC"
eq "JRN-001 the 5.7 sequence leaves the spec in-review" "$(fm "$P/$DONE_SPEC/spec.md" .status)" in-review

set_task "$P" "$DONE_SPEC" T1 in-progress
mtd "$P" --check "$DONE_SPEC"
check "JRN-001 --check names both open records, T1 and T2" '[[ $RC == 1 && $OUT == *T1* && $OUT == *T2* ]]' "rc=$RC: $OUT"
set_task "$P" "$DONE_SPEC" T1 done
set_task "$P" "$DONE_SPEC" T2 done

set_status "$P/.workflow/specs/work-backlog/012-alpha-disc-002.md" in-progress
set_status "$P/.workflow/specs/work-backlog/013-beta-disc-001.md" in-progress
mtd "$P" --check "$DONE_SPEC"
check "JRN-001 --check names a backlog item from the spec whose status is not a closed or open one" \
  '[[ $RC == 1 && $OUT == *012-alpha-disc-002* ]]' "rc=$RC: $OUT"
check "JRN-001 --check does not name a backlog item from another spec" '[[ $OUT != *013-beta-disc-001* ]]' "$OUT"
set_status "$P/.workflow/specs/work-backlog/012-alpha-disc-002.md" dismissed

git_commit_all "$P" "fixture: every record of 012-alpha closed"
BEFORE=$(tree_digest "$P")
mtd "$P" --check "$DONE_SPEC"
eq "JRN-001 --check passes with records done or split-out and backlog items open, dismissed, promoted or moved" "$RC" 0
check "JRN-001 a passing --check changes nothing" '[[ $(tree_digest "$P") == "$BEFORE" ]]'
sign_off_5_7 "$P" "$DONE_SPEC"
eq "JRN-001 after a passing check the 5.7 sequence sets done" "$(fm "$P/$DONE_SPEC/spec.md" .status)" done
mtd "$P" --check .workflow/specs/099-missing
eq "JRN-001 --check on a missing spec folder exits 2" "$RC" 2

echo "== JRN-002: the move rewrites every link"
P=$WORK/move
done_folder_repo "$P"
EXPECTED=$WORK/expected-moved
done_expected "$EXPECTED" moved
APPROVED_BODY=$WORK/approved-pr-body.md
cp "$P/$DONE_SPEC/pr-body.md" "$APPROVED_BODY"
check "fixture: every relative link in the spec resolves before the move" '[[ -z $(unresolved_links "$P/$DONE_SPEC") ]]' \
  "$(unresolved_links "$P/$DONE_SPEC")"
check "fixture: every relative link in the expected moved spec resolves" '[[ -z $(unresolved_links "$EXPECTED/$MOVED") ]]' \
  "$(unresolved_links "$EXPECTED/$MOVED")"
check "fixture: the old path is referenced before the move" '[[ -n $(old_spec_refs "$P" 012-alpha) ]]'
for kept in .workflow/cache/modules.md .workflow/initiatives/001-ini/initiative.md docs/notes.md .workflow/deferred/alpha-two-shelf.md; do
  cp "$P/$kept" "$WORK/kept-$(basename "$kept")"
done
TIP=$(git -C "$P" rev-parse HEAD)
MAIN_TIP=$(git -C "$P" rev-parse main)

mtd "$P" "$DONE_SPEC"
eq "JRN-002 the move exits 0" "$RC" 0
check "JRN-002 the spec sits at .workflow/specs/done/012-alpha" '[[ -f "$P/$MOVED/spec.md" ]]' "$OUT"
check "JRN-002 the old folder is gone" '[[ ! -e "$P/$DONE_SPEC" ]]'
check "JRN-002 the moved spec has no step marker" '[[ -f "$P/$MOVED/spec.md" && ! -e "$P/$MOVED/.step" && -z $(find "$P/$DONE" -name .step 2>/dev/null) ]]'
eq "JRN-002 spec_branch is unchanged" "$(fm "$P/$MOVED/spec.md" .spec_branch)" spec/012-alpha
eq "JRN-002 the moved spec is still done" "$(fm "$P/$MOVED/spec.md" .status)" done
eq "JRN-002 the move leaves the spec branch checked out" "$(git -C "$P" branch --show-current)" spec/012-alpha
eq "JRN-002 the move is one commit on the spec branch" "$(git -C "$P" rev-parse -q --verify HEAD~1 2>/dev/null)" "$TIP"
eq "JRN-002 main is untouched" "$(git -C "$P" rev-parse main)" "$MAIN_TIP"
eq "JRN-002 the working tree is clean after the commit" "$(git -C "$P" status --porcelain)" ""
check "JRN-002 the commit subject is a Conventional Commits subject" \
  '[[ $(git -C "$P" rev-parse HEAD) != "$TIP" ]] && git -C "$P" log -1 --format=%s | grep -Eq "^[a-z]+(\([^)]+\))?!?: .+"' "subject: $(git -C "$P" log -1 --format=%s)"
check "JRN-002 the commit holds the spec in done/ and not at the old path" \
  '[[ -n $(git -C "$P" ls-tree -r --name-only HEAD -- "$MOVED") && -z $(git -C "$P" ls-tree -r --name-only HEAD -- "$DONE_SPEC") ]]'

while IFS='|' read -r form rel; do
  check "JRN-002 rewritten: $form ($rel)" 'cmp -s "$EXPECTED/$rel" "$P/$rel"' \
    "$(diff "$EXPECTED/$rel" "$P/$rel" 2>&1 | head -6)"
done <<'FORMS'
shelf origin_spec and ../specs/ link|.workflow/deferred/alpha-shelf.md
retrospective spec key and ../../specs/ links|.workflow/decisions/retrospectives/012-alpha.md
capabilities row specs/ link|.workflow/capabilities.md
review lesson origin_spec|.workflow/review-lessons.md
open backlog item origin_spec and ../NNN-slug/ link|.workflow/specs/work-backlog/012-alpha-disc-001.md
dismissed backlog item origin_spec|.workflow/specs/work-backlog/012-alpha-disc-002.md
sibling spec ../NNN-slug/ link and path string|.workflow/specs/013-beta/spec.md
moved spec outbound links, one more ../|.workflow/specs/done/012-alpha/spec.md
moved task file link out of tasks/, one more ../|.workflow/specs/done/012-alpha/tasks/T01-move.md
moved design log own path strings|.workflow/specs/done/012-alpha/design-log.md
moved report own path string|.workflow/specs/done/012-alpha/report.md
moved pr-body.md own path string|.workflow/specs/done/012-alpha/pr-body.md
FORMS
for kept in .workflow/cache/modules.md .workflow/initiatives/001-ini/initiative.md docs/notes.md .workflow/deferred/alpha-two-shelf.md; do
  check "JRN-002 byte-identical: $kept" 'cmp -s "$WORK/kept-$(basename "$kept")" "$P/$kept"'
done
check "JRN-002 no other file under .workflow/ or docs/ changed (expected-tree oracle)" \
  '[[ -z $(tree_differences "$EXPECTED" "$P") ]]' "$(tree_differences "$EXPECTED" "$P" 2>/dev/null | head -8)"
check "JRN-002 no old-path reference remains outside cache/ and initiatives/" '[[ -z $(old_spec_refs "$P" 012-alpha) ]]' \
  "$(old_spec_refs "$P" 012-alpha | head -5)"
check "JRN-002 the word-level diff changes only path words" \
  '[[ -n $(word_changes "$P" "$TIP" HEAD "$DONE_SPEC" "$MOVED") && -z $(word_changes "$P" "$TIP" HEAD "$DONE_SPEC" "$MOVED" | grep -vE "012-alpha|\.\./") ]]' \
  "$(word_changes "$P" "$TIP" HEAD "$DONE_SPEC" "$MOVED" | grep -vE '012-alpha|\.\./' | head -5)"
check "JRN-002 every relative Markdown link in the moved spec resolves" \
  '[[ -f "$P/$MOVED/spec.md" && -z $(unresolved_links "$P/$MOVED") ]]' "$(unresolved_links "$P/$MOVED" 2>&1 | head -5)"

echo "== JRN-006: the moved PR description"
check "JRN-006 the moved pr-body.md differs from the approved one only in the spec path" \
  '[[ -f "$P/$MOVED/pr-body.md" ]] && ! cmp -s "$APPROVED_BODY" "$P/$MOVED/pr-body.md" && cmp -s "$EXPECTED/$MOVED/pr-body.md" "$P/$MOVED/pr-body.md"' \
  "$(diff "$APPROVED_BODY" "$P/$MOVED/pr-body.md" 2>&1 | head -6)"
t "JRN-006 check-pr-body.sh exits 0 on the moved pr-body.md" 0 \
  bash "$P/.agents/skills/feature-workflow/scripts/check-pr-body.sh" "$P/$MOVED/pr-body.md"

echo "== JRN-002: refusals change nothing"
P=$WORK/refuse
done_folder_repo "$P"
set_status "$P/$DONE_SPEC/spec.md" in-review
git_commit_all "$P" "fixture: 012-alpha in review"
BEFORE=$(tree_digest "$P")
mtd "$P" "$DONE_SPEC"
eq "JRN-002 moving a spec that is not done exits 1" "$RC" 1
check "JRN-002 the refused move of a spec not done changes nothing" '[[ $(tree_digest "$P") == "$BEFORE" ]]'

set_status "$P/$DONE_SPEC/spec.md" done
set_task "$P" "$DONE_SPEC" T2 pending
git_commit_all "$P" "fixture: 012-alpha done with T2 pending"
BEFORE=$(tree_digest "$P")
mtd "$P" "$DONE_SPEC"
check "JRN-002 moving a done spec with a pending task exits 1 naming the task" '[[ $RC == 1 && $OUT == *T2* ]]' "rc=$RC: $OUT"
check "JRN-002 the refused move with a pending task changes nothing" '[[ $(tree_digest "$P") == "$BEFORE" ]]'

set_task "$P" "$DONE_SPEC" T2 done
mkdir -p "$P/$MOVED"
printf '# Already here\n' >"$P/$MOVED/spec.md"
git_commit_all "$P" "fixture: done/012-alpha already exists"
BEFORE=$(tree_digest "$P")
mtd "$P" "$DONE_SPEC"
eq "JRN-002 moving onto an existing done/012-alpha exits 1" "$RC" 1
check "JRN-002 the refused move onto an existing target changes nothing" '[[ $(tree_digest "$P") == "$BEFORE" ]]'
mtd "$P" .workflow/specs/099-missing
eq "JRN-002 moving a missing spec folder exits 2" "$RC" 2
mtd "$P" .workflow/specs/work-backlog
eq "JRN-002 moving a folder that is not a spec exits 2" "$RC" 2
check "JRN-002 the usage refusals change nothing" '[[ $(tree_digest "$P") == "$BEFORE" ]]'

echo "== JRN-003: the sweep"
P=$WORK/sweep
done_folder_repo "$P"
git -C "$P" switch -q -c spec/013-beta
EXPECTED=$WORK/expected-swept
done_expected "$EXPECTED" swept
TIP=$(git -C "$P" rev-parse HEAD)
DRAFT_DIGEST=$(cd "$P/$DONE_DRAFT" && find . -type f -exec cksum {} + | LC_ALL=C sort)
mtd "$P" --sweep
eq "JRN-003 --sweep exits 0" "$RC" 0
check "JRN-003 both done specs sit in done/" '[[ -f "$P/$MOVED/spec.md" && -f "$P/$DONE/014-gamma/spec.md" ]]' "$OUT"
check "JRN-003 neither done spec is left at the top level" '[[ ! -e "$P/$DONE_SPEC" && ! -e "$P/$DONE_SECOND" ]]'
eq "JRN-003 the top level holds only the in-flight specs, work-backlog/ and done/" \
  "$(find "$P/.workflow/specs" -mindepth 1 -maxdepth 1 -exec basename {} \; | LC_ALL=C sort | tr '\n' ' ')" "013-beta 015-delta done work-backlog "
check "JRN-003 no step marker under done/" '[[ -d "$P/$DONE" && -z $(find "$P/$DONE" -name .step) ]]'
check "JRN-003 the draft spec is byte-identical, its step marker included" \
  '[[ $(cd "$P/$DONE_DRAFT" && find . -type f -exec cksum {} + | LC_ALL=C sort) == "$DRAFT_DIGEST" ]]'
check "JRN-003 the in-progress spec keeps its step marker" '[[ -f "$P/$DONE_SIBLING/.step" ]]'
check "JRN-003 the tree is what the swept oracle describes" '[[ -z $(tree_differences "$EXPECTED" "$P") ]]' \
  "$(tree_differences "$EXPECTED" "$P" 2>/dev/null | head -8)"
check "JRN-003 no old-path reference to either moved spec remains" \
  '[[ -z $(old_spec_refs "$P" 012-alpha) && -z $(old_spec_refs "$P" 014-gamma) ]]' \
  "$(old_spec_refs "$P" 012-alpha | head -3; old_spec_refs "$P" 014-gamma | head -3)"
check "JRN-003 the sweep is committed on the checked-out branch with a clean tree" \
  '[[ $(git -C "$P" branch --show-current) == spec/013-beta && $(git -C "$P" rev-parse HEAD) != "$TIP" && -z $(git -C "$P" status --porcelain) ]]'
BEFORE=$(tree_digest "$P")
mtd "$P" --sweep
check "JRN-003 a second sweep exits 0 and changes nothing" '[[ $RC == 0 && $(tree_digest "$P") == "$BEFORE" ]]' "rc=$RC: $OUT"

echo "== JRN-007 and JRN-004: any-digit spec numbers and the 0.1.1 scan"
P=$WORK/digits
done_digits_repo "$P"
EXPECTED=$WORK/expected-digits
done_digits_expected "$EXPECTED"
SCAN=$(fenced_block_after "$FW_SKILL/modules/discovery.md" "**0.1.1 Scan.**")
check "fixture: modules/discovery.md holds the 0.1.1 scan block" '[[ -n $SCAN ]]'
eq "JRN-007 fixture: before the sweep the 0.1.1 scan's highest number is 00010" "$(cd "$P" && bash -c "$SCAN" 2>/dev/null)" 00010
mtd "$P" --check .workflow/specs/00010-wide
eq "JRN-007 --check passes on the five-digit spec" "$RC" 0
mtd "$P" --sweep
eq "JRN-007 --sweep exits 0" "$RC" 0
check "JRN-007 the five-digit and three-digit specs both sit in done/" \
  '[[ -f "$P/$DONE/00010-wide/spec.md" && -f "$P/$DONE/009-narrow/spec.md" ]]' "$OUT"
check "JRN-007 the in-progress spec stays at the top level" '[[ -f "$P/.workflow/specs/005-current/spec.md" ]]'
check "JRN-007 the tree is what the any-digit oracle describes" '[[ -z $(tree_differences "$EXPECTED" "$P") ]]' \
  "$(tree_differences "$EXPECTED" "$P" 2>/dev/null | head -8)"
HIGHEST=$(cd "$P" && bash -c "$SCAN" 2>/dev/null)
check "JRN-007 after the sweep the 0.1.1 scan still finds 00010, now in done/" \
  '[[ -f "$P/$DONE/00010-wide/spec.md" && $HIGHEST == 00010 ]]' "highest=$HIGHEST"

echo "== JRN-004: readers of the Done folder"
# Only specs in done/ carry the high numbers, and no spec branch exists, so a reader that skips done/ gives a different answer.
P=$WORK/readers
git_init_repo "$P"
copy_agents "$P"
mkdir -p "$P/$DONE/00010-wide" "$P/$DONE/009-narrow" "$P/.workflow/specs/005-top" "$P/.workflow/specs/006-open"
printf -- '---\nstatus: done\n---\n# Wide\n' >"$P/$DONE/00010-wide/spec.md"
printf -- '---\nstatus: done\n---\n# Narrow\n' >"$P/$DONE/009-narrow/spec.md"
printf -- '---\nstatus: done\n---\n# Top\n' >"$P/.workflow/specs/005-top/spec.md"
printf -- '---\nstatus: in-progress\n---\n# Open\n' >"$P/.workflow/specs/006-open/spec.md"
git_commit_all "$P" "fixture: specs done on main, two of them in the Done folder"
HIGHEST=$(cd "$P" && bash -c "$SCAN" 2>/dev/null)
eq "JRN-004 the 0.1.1 scan counts the children of done/: highest is 00010" "$HIGHEST" 00010
eq "JRN-007 the next spec number is 00011" "$(printf '%05d' $((10#${HIGHEST:-0} + 1)))" 00011

DONE_ON_MAIN=$(fenced_block_with "$FW_SKILL/modules/large-path.md" "spec_done_on_main()")
check "fixture: modules/large-path.md defines spec_done_on_main in a bash block" '[[ -n $DONE_ON_MAIN ]]'
# done_on_main SPEC : run the large-path helper block in the fixture, then ask it about SPEC.
done_on_main() { (cd "$P" && bash -c "$DONE_ON_MAIN"$'\n''spec_done_on_main "$1"' _ "$1" >/dev/null 2>&1); }
check "JRN-004 spec_done_on_main is true for a done spec at the top level" 'done_on_main 005-top'
check "JRN-004 spec_done_on_main is true for a done spec in done/" 'done_on_main 009-narrow'
check "JRN-004 spec_done_on_main is true for a five-digit done spec in done/" 'done_on_main 00010-wide'
check "JRN-004 spec_done_on_main is false for a spec that is not done" '! done_on_main 006-open'
check "JRN-004 spec_done_on_main is false for a spec on no branch" '! done_on_main 099-missing'

echo "== edge cases: path forms the fixture project does not plant"
P=$WORK/edges
done_folder_repo "$P"
printf '%s\n' "Closed in .workflow/specs/012-alpha. See specs/012-alpha specs/012-alpha for both." \
  "Last line names .workflow/specs/012-alpha." >"$P/.workflow/deferred/edge-notes.md"
printf '%s\n' "Self: [report](../012-alpha/report.md)" "" "[shelf]: ../../deferred/alpha-shelf.md" \
  >>"$P/$DONE_SPEC/report.md"
git_commit_all "$P" "fixture: sentence-end, adjacent, self and reference-style forms"
mtd "$P" "$DONE_SPEC"
eq "edge the move with extra path forms exits 0" "$RC" 0
eq "edge a path ending a sentence and two paths one space apart are all rewritten" \
  "$(cat "$P/.workflow/deferred/edge-notes.md")" \
  "Closed in .workflow/specs/done/012-alpha. See specs/done/012-alpha specs/done/012-alpha for both."$'\n'"Last line names .workflow/specs/done/012-alpha."
check "edge a link back into the spec through its parent and a reference-style link both resolve after the move" \
  '[[ -z $(unresolved_links "$P/$MOVED") ]] && grep -q "^\[shelf\]: \.\./\.\./\.\./deferred/alpha-shelf\.md$" "$P/$MOVED/report.md"' \
  "$(unresolved_links "$P/$MOVED"; tail -3 "$P/$MOVED/report.md")"
mtd "$P" "$MOVED"
eq "edge moving a spec already in the Done folder exits 2" "$RC" 2
mtd "$P" --check "$MOVED"
eq "edge --check accepts a spec already in the Done folder" "$RC" 0

echo "== refusals: the branch and an untracked spec"
P=$WORK/branch
done_folder_repo "$P"
git -C "$P" switch -q main
BEFORE=$(tree_digest "$P")
mtd "$P" "$DONE_SPEC"
check "moving on the main branch exits 1 and changes nothing" '[[ $RC == 1 && $(tree_digest "$P") == "$BEFORE" ]]' "rc=$RC: $OUT"
git -C "$P" switch -q --detach spec/012-alpha
BEFORE=$(tree_digest "$P")
mtd "$P" --sweep
check "sweeping on a detached HEAD exits 1 and changes nothing" '[[ $RC == 1 && $(tree_digest "$P") == "$BEFORE" ]]' "rc=$RC: $OUT"
git -C "$P" switch -q spec/012-alpha
git -C "$P" rm -rq --cached "$DONE_SPEC"
git_commit_all "$P" "fixture: 012-alpha untracked"
mkdir -p "$P/.workflow/specs/016-seeded"
printf -- '---\nstatus: done\n---\n# Seeded\n' >"$P/.workflow/specs/016-seeded/spec.md"
mtd "$P" .workflow/specs/016-seeded
check "an untracked done spec moves and is committed" \
  '[[ $RC == 0 && -n $(git -C "$P" ls-tree -r --name-only HEAD -- "$DONE/016-seeded") && -z $(git -C "$P" status --porcelain -- .workflow/specs) ]]' \
  "rc=$RC: $OUT"

echo "== the sweep leaves a done spec that fails the check"
P=$WORK/sweep-open
done_folder_repo "$P"
git -C "$P" switch -q -c spec/013-beta
set_task "$P" "$DONE_SECOND" T1 blocked
git_commit_all "$P" "fixture: 014-gamma done with T1 blocked"
TIP=$(git -C "$P" rev-parse HEAD)
mtd "$P" --sweep
eq "the sweep with one done spec failing the check exits 1" "$RC" 1
check "the sweep names the spec it left and its open task" '[[ $OUT == *"left in place: $DONE_SECOND"* && $OUT == *"task T1 (blocked)"* ]]' "$OUT"
check "the failing spec stays at the top level with its step marker" '[[ -f "$P/$DONE_SECOND/spec.md" && -f "$P/$DONE_SECOND/.step" ]]'
check "the passing spec still moves and is committed" \
  '[[ -f "$P/$MOVED/spec.md" && $(git -C "$P" rev-parse HEAD~1) == "$TIP" && -z $(git -C "$P" status --porcelain) ]]' "$OUT"

echo "== the sweep leaves the spec on the checked-out branch to its own move"
P=$WORK/sweep-own
done_folder_repo "$P"
EXPECTED=$WORK/expected-own
done_expected "$EXPECTED" swept
TIP=$(git -C "$P" rev-parse HEAD)
mtd "$P" --sweep
check "the sweep on the spec branch of a done spec exits 0 and says that spec is left for its own move step" \
  '[[ $RC == 0 && $OUT == *"skipped: $DONE_SPEC (moved by its own sign-off step)"* ]]' "rc=$RC: $OUT"
check "the done spec on the checked-out branch stays at the top level with its step marker" \
  '[[ -f "$P/$DONE_SPEC/spec.md" && -f "$P/$DONE_SPEC/.step" && ! -e "$P/$MOVED" ]]' "$OUT"
check "the other done spec moves, committed alone on the checked-out branch" \
  '[[ -f "$P/$DONE/014-gamma/spec.md" && ! -e "$P/$DONE_SECOND" && $(git -C "$P" rev-parse HEAD~1) == "$TIP" && -z $(git -C "$P" status --porcelain) ]]' "$OUT"
mtd "$P" "$DONE_SPEC"
check "the spec's own move after the sweep exits 0 and commits it into done/" \
  '[[ $RC == 0 && -f "$P/$MOVED/spec.md" && ! -e "$P/$DONE_SPEC" && -z $(git -C "$P" status --porcelain) ]]' "rc=$RC: $OUT"
check "after the sweep and the own move the tree is what the swept oracle describes" \
  '[[ -z $(tree_differences "$EXPECTED" "$P") ]]' "$(tree_differences "$EXPECTED" "$P" 2>/dev/null | head -8)"

P=$WORK/sweep-own-only
done_folder_repo "$P"
set_status "$P/$DONE_SECOND/spec.md" in-progress
git_commit_all "$P" "fixture: 014-gamma back in progress"
BEFORE=$(tree_digest "$P")
mtd "$P" --sweep
check "a sweep whose only done spec is on the checked-out branch prints nothing to sweep, exits 0 and changes nothing" \
  '[[ $RC == 0 && $OUT == *"nothing to sweep"* && $(tree_digest "$P") == "$BEFORE" ]]' "rc=$RC: $OUT"

echo "== a failing read is an error, not a clean result"
P=$WORK/read-branch
done_folder_repo "$P"
BEFORE=$(tree_digest "$P")
PATH="$(failing_git "$WORK/git-branch" '* branch --show-current *'):$PATH" mtd "$P" "$DONE_SPEC"
check "a failing read of the checked-out branch exits 2 and changes nothing" \
  '[[ $RC == 2 && $(tree_digest "$P") == "$BEFORE" && $OUT == *"cannot read the checked-out branch"* ]]' "rc=$RC: $OUT"

P=$WORK/read-list
done_folder_repo "$P"
BEFORE=$(tree_digest "$P")
PATH="$(failing_git "$WORK/git-list" '* ls-files -c -o *'):$PATH" mtd "$P" "$DONE_SPEC"
check "a failing list of the workflow files exits 2, rolls back and commits nothing" \
  '[[ $RC == 2 && $(tree_digest "$P") == "$BEFORE" && $OUT == *"cannot list the workflow files"* ]]' "rc=$RC: $OUT"

P=$WORK/read-tracked
done_folder_repo "$P"
BEFORE=$(tree_digest "$P")
PATH="$(failing_git "$WORK/git-tracked" '* ls-files -c -- *'):$PATH" mtd "$P" "$DONE_SPEC"
check "a failing check for the tracked spec files exits 2, rolls back and commits nothing" \
  '[[ $RC == 2 && $(tree_digest "$P") == "$BEFORE" && $OUT == *"cannot list the tracked files"* ]]' "rc=$RC: $OUT"

P=$WORK/read-grep
done_folder_repo "$P"
BEFORE=$(tree_digest "$P")
chmod 000 "$P/.workflow/capabilities.md"
mtd "$P" "$DONE_SPEC"
chmod 644 "$P/.workflow/capabilities.md"
check "an unreadable workflow file that names the spec exits 2, rolls back and commits nothing" \
  '[[ $RC == 2 && $(tree_digest "$P") == "$BEFORE" && $OUT == *"cannot search .workflow/capabilities.md"* ]]' "rc=$RC: $OUT"

P=$WORK/read-find
done_folder_repo "$P"
BEFORE=$(tree_digest "$P")
chmod 000 "$P/$DONE_SPEC/tasks"
mtd "$P" "$DONE_SPEC"
chmod 755 "$P/$DONE_SPEC/tasks"
check "an unreadable folder inside the spec exits 2, rolls back and commits nothing" \
  '[[ $RC == 2 && $(tree_digest "$P") == "$BEFORE" && $OUT == *"cannot list the Markdown files"* ]]' "rc=$RC: $OUT"

P=$WORK/scratch-matches
done_folder_repo "$P"
BEFORE=$(tree_digest "$P")
PATH="$(scratch_with_folder_at "$WORK/mktemp-matches" matches):$PATH" mtd "$P" "$DONE_SPEC"
check "a search list that cannot be written exits 2, rolls back and commits nothing" \
  '[[ $RC == 2 && $(tree_digest "$P") == "$BEFORE" && $OUT == *"cannot write the list of workflow files that name the spec"* ]]' "rc=$RC: $OUT"

echo "== an error after the move rolls the run back"
P=$WORK/rollback-commit
done_folder_repo "$P"
BEFORE=$(tree_digest "$P")
PATH="$(failing_git "$WORK/git-commit" '* commit *'):$PATH" mtd "$P" "$DONE_SPEC"
eq "a failing commit after the move exits 2" "$RC" 2
check "a failing commit after the move leaves the spec, its step marker, every rewritten file and the index as they were" \
  '[[ $(tree_digest "$P") == "$BEFORE" && ! -d "$P/$DONE" && $OUT == *"rolled back"* ]]' "$OUT"

P=$WORK/rollback-sweep
done_folder_repo "$P"
git -C "$P" switch -q -c spec/013-beta
printf '%s\n' "Gamma closed in .workflow/specs/014-gamma." >"$P/.workflow/deferred/gamma-read-only.md"
git_commit_all "$P" "fixture: a read-only file naming 014-gamma"
chmod 444 "$P/.workflow/deferred/gamma-read-only.md"
BEFORE=$(tree_digest "$P")
mtd "$P" --sweep
chmod 644 "$P/.workflow/deferred/gamma-read-only.md"
eq "a sweep that cannot rewrite a file for its second spec exits 2" "$RC" 2
check "the failed sweep puts the first spec it moved back too, and commits nothing" \
  '[[ $(tree_digest "$P") == "$BEFORE" && -f "$P/$DONE_SPEC/.step" && ! -d "$P/$DONE" && $OUT == *"cannot write"* ]]' "$OUT"

shellcheck_files "shellcheck: move-to-done.sh, its suite and fixture" "$REPO_ROOT/$DONE_MTD_REL" \
  "$TESTS_DIR/scripts/move-to-done.sh" "$TESTS_DIR/fixtures/done-folder.sh"
finish
