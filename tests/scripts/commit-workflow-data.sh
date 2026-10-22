#!/usr/bin/env bash
# Suite: commit-workflow-data.sh (feature-workflow/scripts), committing the main session's workflow data on the spec branch.
# Covers: the spec folder, gate evidence, deferred items, decisions and the work-backlog committed together; gitignored .step and
#   .worktrees/ left out; another spec's draft folder and an initiative folder left untracked; other staged work left staged and
#   uncommitted; a file name with spaces and non-ASCII committed; local state that is not gitignored refused;
#   a deleted workflow file committed as a deletion; nothing to commit; a run from a task worktree committing in the
#   main checkout; refusals off the spec branch and during a merge; usage errors.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

CW="$FW_SKILL/scripts/commit-workflow-data.sh"
SPECD=.workflow/specs/001-alpha
new_workdir

shellcheck_files "shellcheck commit-workflow-data.sh" "$CW"
check "commit-workflow-data.sh is executable" '[ -x "$CW" ]'

# Fixture: a project on its spec branch with a committed spec and the workflow gitignore block.
P=$WORK/proj
git_init_repo "$P"
mkdir -p "$P/$SPECD" "$P/src"
cp "$FW_SKILL/assets/spec.md" "$P/$SPECD/spec.md"
yq --front-matter=process -i '.spec_branch = "spec/001-alpha"' "$P/$SPECD/spec.md"
printf 'tasks: []\n' >"$P/$SPECD/tasks.md"
printf '.workflow/specs/*/.step\n.workflow/.worktrees/\n.workflow/.handoff/\n.workflow/.cache-staging/\n' >"$P/.gitignore"
echo 'code' >"$P/src/app.sh"
git_commit_all "$P" "Spec 001-alpha"
git -C "$P" switch -q -c spec/001-alpha

CWD() { bash "$CW" "$@" 2>&1; }

# Workflow writes made by the main session during Phase 3.
echo 'T1 in progress' >>"$P/$SPECD/tasks.md"
mkdir -p "$P/$SPECD/artifacts/T1" "$P/.workflow/deferred" "$P/.workflow/decisions/adr" "$P/.workflow/specs/work-backlog"
echo '{"status":"pass"}' >"$P/$SPECD/artifacts/T1/toolchain.json"
echo 'notes' >"$P/$SPECD/artifacts/T1/run notes é.txt"
mkdir -p "$P/.workflow/.cache-staging"
echo 'staged cache' >"$P/.workflow/.cache-staging/modules.md"
echo 'shelved' >"$P/.workflow/deferred/later.md"
echo 'adr' >"$P/.workflow/decisions/adr/0002-x.md"
echo 'item' >"$P/.workflow/specs/work-backlog/item.md"
printf 'step: "3.16"\n' >"$P/$SPECD/.step"
mkdir -p "$P/.workflow/.worktrees/s001_t1"
echo 'wip' >"$P/.workflow/.worktrees/s001_t1/x"
mkdir -p "$P/.workflow/specs/002-beta" "$P/.workflow/initiatives/001-big"
echo 'draft' >"$P/.workflow/specs/002-beta/spec.md"
echo 'ini' >"$P/.workflow/initiatives/001-big/initiative.md"
echo 'staged code' >>"$P/src/app.sh"
git -C "$P" add src/app.sh

mkdir -p "$P/.workflow/.standards-staging" && echo 'x' >"$P/.workflow/.standards-staging/rules.md"
out=$(CWD "$SPECD" -m "leak" --cwd "$P"); rc=$?
check "local state not gitignored: refused, exit 2" '[ $rc -eq 2 ] && [[ "$out" == *"not gitignored: .workflow/.standards-staging/"* ]]' "rc=$rc $out"
check "a refused run stages nothing" '[ "$(git -C "$P" diff --cached --name-only)" = src/app.sh ]'
rm -rf "$P/.workflow/.standards-staging"

out=$(CWD "$SPECD" -m "Wave 1 start for 001-alpha" --cwd "$P"); rc=$?
check "commits and exits 0" '[ $rc -eq 0 ] && [[ "$out" == "committed "* ]]' "rc=$rc $out"
files=$(git -C "$P" show --name-only --format= HEAD)
check "the commit holds the spec folder, evidence, deferred, decisions and work-backlog" \
  '(for f in $SPECD/tasks.md $SPECD/artifacts/T1/toolchain.json .workflow/deferred/later.md .workflow/decisions/adr/0002-x.md .workflow/specs/work-backlog/item.md; do grep -qx "$f" <<<"$files" || exit 1; done)' "$files"
check "a file name with spaces and non-ASCII is committed" \
  'git -C "$P" -c core.quotePath=false show --name-only --format= HEAD | grep -qx "$SPECD/artifacts/T1/run notes é.txt"' "$files"
check "the commit leaves out .step, .worktrees/ and .cache-staging/" \
  '! grep -q -e "\.step$" -e "\.worktrees/" -e "\.cache-staging/" <<<"$files"' "$files"
check "the commit leaves out another spec and an initiative" '! grep -q -e "002-beta" -e "initiatives/" <<<"$files"' "$files"
check "the commit leaves out staged code" '! grep -q "src/app.sh" <<<"$files"' "$files"
eq "the commit message is the one given" "$(git -C "$P" log -1 --format=%B)" "Wave 1 start for 001-alpha"
check "staged code stays staged" 'git -C "$P" diff --cached --name-only | grep -qx src/app.sh'
check "the other spec stays untracked" 'git -C "$P" status --porcelain | grep -q "^?? .workflow/specs/002-beta/"'

out=$(CWD "$SPECD" -m "again" --cwd "$P"); rc=$?
check "nothing new: exit 0, nothing to commit" '[ $rc -eq 0 ] && [ "$out" = "nothing to commit" ]' "rc=$rc $out"
git -C "$P" commit -q -m "code"

# A run from a task worktree commits in the main checkout; a deletion is committed.
git -C "$P" worktree add -q "$P/.workflow/.worktrees/s001_t2" -b task/001-alpha/T02-x spec/001-alpha
rm "$P/.workflow/deferred/later.md"
echo 'T1 done' >>"$P/$SPECD/tasks.md"
out=$(CWD "$SPECD" -m "Wave 1 merged for 001-alpha" --cwd "$P/.workflow/.worktrees/s001_t2"); rc=$?
check "from a task worktree: commits in the main checkout" '[ $rc -eq 0 ] && [[ "$out" == "committed "* ]]' "rc=$rc $out"
check "the deletion is committed" 'git -C "$P" show --name-status --format= HEAD | grep -q "^D.*\.workflow/deferred/later.md"'
eq "the task branch is unchanged" "$(git -C "$P" rev-parse task/001-alpha/T02-x)" "$(git -C "$P" rev-parse HEAD~1)"

# Refusals.
git -C "$P" worktree remove "$P/.workflow/.worktrees/s001_t2"
git -C "$P" switch -q main
out=$(CWD "$SPECD" -m "x" --cwd "$P"); rc=$?
check "off the spec branch: refused, exit 1" '[ $rc -eq 1 ] && [[ "$out" == *"not the spec branch spec/001-alpha"* ]]' "rc=$rc $out"
git -C "$P" switch -q --detach spec/001-alpha
out=$(CWD "$SPECD" -m "x" --cwd "$P"); rc=$?
check "on a detached HEAD: refused, exit 1" '[ $rc -eq 1 ] && [[ "$out" == *"a detached HEAD"* ]]' "rc=$rc $out"
git -C "$P" switch -q spec/001-alpha
echo 'main side' >"$P/src/conflict.sh"
git -C "$P" add src/conflict.sh && git -C "$P" commit -q -m "spec side"
git -C "$P" switch -q -c side HEAD~1 && echo 'other side' >"$P/src/conflict.sh"
git -C "$P" add src/conflict.sh && git -C "$P" commit -q -m "side"
git -C "$P" switch -q spec/001-alpha
git -C "$P" merge -q side >/dev/null 2>&1
out=$(CWD "$SPECD" -m "x" --cwd "$P"); rc=$?
check "during a merge: refused, exit 1" '[ $rc -eq 1 ] && [[ "$out" == *"merge, cherry-pick or revert is in progress"* ]]' "rc=$rc $out"
git -C "$P" merge --abort

# Usage errors.
t "no message is a usage error" 2 bash "$CW" "$SPECD" --cwd "$P"
t "no spec dir is a usage error" 2 bash "$CW" -m x --cwd "$P"
t "a bad spec dir is a usage error" 2 bash "$CW" .workflow/specs/alpha -m x --cwd "$P"
t "a missing spec.md is an error" 2 bash "$CW" .workflow/specs/009-none -m x --cwd "$P"
t "outside a git repository is an error" 2 bash "$CW" "$SPECD" -m x --cwd "$WORK"
t "--help exits 0" 0 bash "$CW" --help

finish
