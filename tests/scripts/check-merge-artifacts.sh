#!/usr/bin/env bash
# Suite: check-merge-artifacts.sh (feature-workflow/scripts), the gate the orchestrator runs before each merge into the spec branch.
# Covers: JRN-007: a spec branch with a committed artifacts/T1/implementation.yaml, and more artifacts committed after the task
#   branches forked; task branches that change only code (one of them with the newer spec branch merged in), add, modify or
#   delete a file under artifacts/, or do two of those; a look-alike folder beside artifacts/; detached light-path commits of each
#   kind. Code-only revisions pass with no output; each artifacts change is refused with exit 1 and one stdout line naming each
#   path. The gate gives the same verdict from a task worktree. Exit 2 for missing arguments, an unknown flag or revision, a
#   malformed spec dir and a spec with no spec branch.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

new_workdir
P=$WORK/proj
make_fixture_repo "$P"
GATE=$P/.agents/skills/feature-workflow/scripts/check-merge-artifacts.sh
SPEC=.workflow/specs/007-demo
ART=$SPEC/artifacts

git -C "$P" checkout -q -b spec/007-demo
mkdir -p "$P/$ART/T1" "$P/src"
printf '%s\n' '---' 'status: in-progress' 'spec_branch: spec/007-demo' '---' '# Demo' > "$P/$SPEC/spec.md"
printf '%s\n' 'task_id: T1' > "$P/$ART/T1/implementation.yaml"
printf '%s\n' 'echo app' > "$P/src/app.sh"
printf '%s\n' '.workflow/.worktrees/' > "$P/.gitignore"
git_commit_all "$P" "spec 007 with T1's result committed"
FORK=$(git -C "$P" rev-parse HEAD)

# change DIR KIND : make one kind of change in the checkout DIR. add, modify and delete touch artifacts/; code and lookalike do not.
change() {
  case "$2" in
    code) printf '%s\n' 'echo changed' >> "$1/src/app.sh" ;;
    add) mkdir -p "$1/$ART/T7" && printf '%s\n' 'task_id: T7' > "$1/$ART/T7/implementation.yaml" ;;
    modify) printf '%s\n' 'status: done' >> "$1/$ART/T1/implementation.yaml" ;;
    delete) rm "$1/$ART/T1/implementation.yaml" ;;
    lookalike) mkdir -p "$1/$SPEC/artifacts-old" && printf '%s\n' x > "$1/$SPEC/artifacts-old/notes.txt" ;;
  esac
}
# task_branch NAME KIND... : a branch task/007-demo/NAME forked from FORK in its own worktree, with each KIND of change committed.
task_branch() {
  local name=$1 dir=$WORK/wt-$1 kind
  shift
  git -C "$P" worktree add -q "$dir" -b "task/007-demo/$name" "$FORK"
  for kind in "$@"; do change "$dir" "$kind"; done
  git_commit_all "$dir" "$name"
}
task_branch code code
task_branch add code add
task_branch modify modify
task_branch delete delete
task_branch two add modify
task_branch lookalike lookalike
task_branch synced code

# The spec branch moves on after the forks: the orchestrator commits the wave's evidence there.
mkdir -p "$P/$ART/T2"
printf '%s\n' pass > "$P/$ART/T2/toolchain.txt"
git_commit_all "$P" "evidence for T2"
git -C "$WORK/wt-synced" merge -q --no-edit spec/007-demo

# Light path: commits on a worktree detached at the spec-branch tip, one per kind of change.
L=$P/.workflow/.worktrees/s007_t8
git -C "$P" worktree add -q --detach "$L" spec/007-demo
# light_commit KIND : prints the sha of a detached commit on the spec-branch tip carrying that change.
light_commit() {
  git -C "$L" checkout -q --detach spec/007-demo
  change "$L" "$1"
  git_commit_all "$L" "light $1"
  git -C "$L" rev-parse HEAD
}

# gate REV [CWD] : run the gate on REV; OUT is its stdout, RC its exit code.
gate() {
  OUT=$(bash "$GATE" --spec-dir "$SPEC" --rev "$1" --cwd "${2:-$P}" 2>/dev/null)
  RC=$?
}
# expect_pass NAME REV [CWD] : the gate exits 0 and prints nothing.
expect_pass() {
  gate "$2" "${3:-}"
  check "$1" '[ "$RC" = 0 ] && [ -z "$OUT" ]' "rc=$RC out=$OUT"
}
# expect_refused NAME REV PATH... : the gate exits 1 with exactly one stdout line per PATH, each naming it.
expect_refused() {
  local name=$1 rev=$2 p missing="" want
  shift 2
  gate "$rev"
  # shellcheck disable=SC2034 # read by the check expression, which check evals
  want=$#
  for p in "$@"; do grep -qF -- "$p" <<<"$OUT" || missing="$missing $p"; done
  check "$name" '[ "$RC" = 1 ] && [ -z "$missing" ] && [ "$(grep -c . <<<"$OUT")" = "$want" ]' "rc=$RC missing:$missing out=$OUT"
}

echo "== task branches (JRN-007)"
expect_pass "JRN-007 a code-only branch forked before the spec branch committed more artifacts passes" task/007-demo/code
expect_pass "JRN-007 a code-only branch that merged in the newer spec branch passes" task/007-demo/synced
expect_pass "JRN-007 a folder beside artifacts/ with a look-alike name passes" task/007-demo/lookalike
expect_refused "JRN-007 a branch adding a file under artifacts/ is refused, naming it" task/007-demo/add "$ART/T7/implementation.yaml"
expect_refused "JRN-007 a branch modifying a committed artifacts/ file is refused, naming it" task/007-demo/modify "$ART/T1/implementation.yaml"
expect_refused "JRN-007 a branch deleting a committed artifacts/ file is refused, naming it" task/007-demo/delete "$ART/T1/implementation.yaml"
expect_refused "JRN-007 a branch with two artifacts/ changes is refused with one line for each" task/007-demo/two \
  "$ART/T7/implementation.yaml" "$ART/T1/implementation.yaml"
gate task/007-demo/add "$WORK/wt-code"
check "JRN-007 the gate run from a task worktree still refuses the adding branch" '[ "$RC" = 1 ]' "rc=$RC out=$OUT"
expect_pass "JRN-007 the gate run from a task worktree still passes the code-only branch" task/007-demo/code "$WORK/wt-code"

echo "== light-path commits (JRN-007)"
expect_pass "JRN-007 a detached code-only commit passes" "$(light_commit code)"
expect_refused "JRN-007 a detached commit adding a file under artifacts/ is refused, naming it" "$(light_commit add)" "$ART/T7/implementation.yaml"
expect_refused "JRN-007 a detached commit modifying an artifacts/ file is refused, naming it" "$(light_commit modify)" "$ART/T1/implementation.yaml"
expect_refused "JRN-007 a detached commit deleting an artifacts/ file is refused, naming it" "$(light_commit delete)" "$ART/T1/implementation.yaml"

echo "== usage and environment errors (JRN-007)"
t "JRN-007 no arguments -> exit 2" 2 bash "$GATE" --cwd "$P"
t "JRN-007 no --rev -> exit 2" 2 bash "$GATE" --spec-dir "$SPEC" --cwd "$P"
t "JRN-007 no --spec-dir -> exit 2" 2 bash "$GATE" --rev task/007-demo/code --cwd "$P"
t "JRN-007 an unknown flag -> exit 2" 2 bash "$GATE" --spec-dir "$SPEC" --rev task/007-demo/code --cwd "$P" --force
t "JRN-007 an unknown revision -> exit 2" 2 bash "$GATE" --spec-dir "$SPEC" --rev task/007-demo/none --cwd "$P"
t "JRN-007 a spec dir that is not NNN-slug -> exit 2" 2 bash "$GATE" --spec-dir .workflow/specs/demo --rev task/007-demo/code --cwd "$P"
mkdir -p "$P/.workflow/specs/008-nobranch"
t "JRN-007 a spec with no spec branch -> exit 2" 2 bash "$GATE" --spec-dir .workflow/specs/008-nobranch --rev task/007-demo/code --cwd "$P"
t "JRN-007 a --cwd outside any git repository -> exit 2" 2 bash "$GATE" --spec-dir "$SPEC" --rev task/007-demo/code --cwd "$WORK"

echo "== lint"
check "the gate script is executable" '[ -x "$GATE" ]'
shellcheck_files "shellcheck: check-merge-artifacts.sh and this suite" "$GATE" "${BASH_SOURCE[0]}"
finish
