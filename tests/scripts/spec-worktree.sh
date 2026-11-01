#!/usr/bin/env bash
# Suite: spec-worktree.sh (feature-workflow/scripts) and two specs running side by side in one clone, each in its own spec worktree
#   with a task worktree nested inside it.
# Covers: create carries the draft spec folder and discovery's other workflow data (a glossary edit) onto the spec branch's first
#   commit, leaves the main checkout on main with nothing of that spec behind, moves .step into the worktree and prints the worktree
#   and the baseline; a second spec created while the first runs; status-transition.sh, run-toolchain.sh, the implementation
#   brief's result-file command (its spec checkout taken from the worktree path), commit-workflow-data.sh, check-merge-artifacts.sh
#   and check-write.sh, each run from a spec worktree or its task worktree, read and write that spec's .step, artifacts and branch
#   only; session-start-resume.sh lists both specs from the main checkout and from a spec worktree, naming where each runs; the
#   sign-off local merge run from a spec worktree lands on main in the main checkout; remove refuses an unmerged branch and a nested
#   agent worktree, then removes the worktree and deletes the merged branch; create refusals (mid-merge, from another spec's
#   worktree, a checkout on the spec branch, no spec.md, usage) and a repeat create that changes nothing; shellcheck.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/result-briefs.sh
source "$TESTS_DIR/fixtures/result-briefs.sh"
preflight

new_workdir
P=$WORK/proj
make_fixture_repo "$P"
S=.agents/skills/feature-workflow/scripts
SW() { (cd "$P" && bash "$S/spec-worktree.sh" "$@"); }
# script NAME ARGS... : run a feature-workflow script from the main checkout's copy.
script() { local name=$1; shift; bash "$P/$S/$name" "$@"; }
step_of() { sed -n 's/^step: "\(.*\)"$/\1/p' "$1"; }

# The workflow block install.sh writes, a profile with a trivial toolchain and a committed glossary.
printf '%s\n' '.workflow/specs/*/.step' '.workflow/initiatives/*/.step' '.workflow/.cache-staging/' '.workflow/.worktrees/' \
  '.workflow/.spec-worktrees/' '.workflow/.handoff/' '.workflow/.standards-staging/' >"$P/.gitignore"
mkdir -p "$P/.workflow/profiles" "$P/src"
printf '# Profile: shell\n## Toolchain\n\n```yaml\nlint: "true"\ntypecheck: ""\nformat: ""\nboundary: ""\ntest: "true"\n```\n' \
  >"$P/.workflow/profiles/shell.md"
printf '# Glossary\n' >"$P/.workflow/GLOSSARY.md"
echo 'code' >"$P/src/app.sh"
git_commit_all "$P" "fixture: project"
MAIN_HEAD=$(git -C "$P" rev-parse HEAD)

# draft_spec NNN-SLUG STEP : a spec folder discovery left uncommitted in the main checkout, its .step at STEP.
draft_spec() {
  local d=.workflow/specs/$1
  mkdir -p "$P/$d"
  cp "$P/.agents/skills/feature-workflow/assets/spec.md" "$P/$d/spec.md"
  printf -- '---\ntasks:\n  - id: T1\n    title: "t"\n    status: pending\n    branch: task/%s/T01-a\n    work_type: shell\n---\n' "$1" \
    >"$P/$d/tasks.md"
  script status-transition.sh step "$d" "$2" --cwd "$P" >/dev/null 2>&1
}

echo "== create: spec 001-alpha leaves the main checkout"
draft_spec 001-alpha 1.1
echo 'alpha: a term' >>"$P/.workflow/GLOSSARY.md"
draft_spec 002-beta 0.3.20
out=$(SW create .workflow/specs/001-alpha 2>&1); rc=$?
WA=$P/.workflow/.spec-worktrees/001-alpha
eq "create exits 0" "$rc" 0
eq "create prints the worktree" "$(sed -n 's/^worktree //p' <<<"$out")" "$WA"
eq "the baseline is the spec branch's first commit" "$(sed -n 's/^baseline //p' <<<"$out")" "$(git -C "$P" rev-parse spec/001-alpha)"
eq "the spec worktree is on spec/001-alpha" "$(git -C "$WA" branch --show-current)" spec/001-alpha
eq "the main checkout stays on main" "$(git -C "$P" branch --show-current)" main
eq "main's tip is unchanged" "$(git -C "$P" rev-parse HEAD)" "$MAIN_HEAD"
eq "the spec branch forks from main" "$(git -C "$P" rev-parse spec/001-alpha^)" "$MAIN_HEAD"
files=$(git -C "$P" show --name-only --format= spec/001-alpha)
check "the first commit holds the spec folder and the glossary edit" \
  'grep -qx .workflow/specs/001-alpha/spec.md <<<"$files" && grep -qx .workflow/GLOSSARY.md <<<"$files"' "$files"
check "the first commit leaves out .step and the other spec's draft" '! grep -q -e "\.step$" -e 002-beta <<<"$files"' "$files"
check "the spec folder is gone from the main checkout" '[ ! -e "$P/.workflow/specs/001-alpha" ]'
eq "the glossary edit moved with the spec" "$(git -C "$P" status --porcelain -- .workflow/GLOSSARY.md)" ""
eq ".step moved into the spec worktree" "$(step_of "$WA/.workflow/specs/001-alpha/.step")" 1.1
eq "the other spec's draft stays in the main checkout, untouched" "$(step_of "$P/.workflow/specs/002-beta/.step")" 0.3.20
out=$(SW create .workflow/specs/001-alpha 2>&1); rc=$?
check "a repeat create changes nothing and prints the same worktree" '[ $rc -eq 0 ] && grep -qx "worktree $WA" <<<"$out"' "rc=$rc $out"
out=$(cd "$WA" && bash "$S/spec-worktree.sh" create .workflow/specs/001-alpha 2>&1); rc=$?
check "a repeat create from inside the spec worktree prints it too" \
  '[ $rc -eq 0 ] && grep -qx "worktree $WA" <<<"$out" && [ "$(step_of "$WA/.workflow/specs/001-alpha/.step")" = 1.1 ]' "rc=$rc $out"

echo "== create: spec 002-beta beside it"
out=$(SW create .workflow/specs/002-beta 2>&1); rc=$?
WB=$P/.workflow/.spec-worktrees/002-beta
eq "the second create exits 0" "$rc" 0
eq "spec/002-beta forks from main, not from the other spec" "$(git -C "$P" rev-parse spec/002-beta^)" "$MAIN_HEAD"
eq "the main checkout is clean once both specs moved out" "$(git -C "$P" status --porcelain)" ""
check "spec 002-beta's worktree holds no copy of spec 001-alpha" '[ ! -e "$WB/.workflow/specs/001-alpha" ]'

echo "== each spec's task worktree nests in its spec worktree"
TA=$WA/.workflow/.worktrees/s001_t1
TB=$WB/.workflow/.worktrees/s002_t1
git -C "$WA" worktree add -q "$TA" -b task/001-alpha/T01-a spec/001-alpha
git -C "$WB" worktree add -q "$TB" -b task/002-beta/T01-a spec/002-beta
script status-transition.sh step .workflow/specs/001-alpha 3.4 --cwd "$TA" >/dev/null 2>&1
script status-transition.sh step .workflow/specs/002-beta 3.3 --cwd "$WB" >/dev/null 2>&1
eq "a step set from 001's task worktree lands in 001's spec worktree" "$(step_of "$WA/.workflow/specs/001-alpha/.step")" 3.4
eq "a step set from 002's spec worktree lands there" "$(step_of "$WB/.workflow/specs/002-beta/.step")" 3.3
check "no .step in either task worktree or the main checkout" \
  '[ ! -e "$TA/.workflow/specs/001-alpha/.step" ] && [ ! -e "$TB/.workflow/specs/002-beta/.step" ] && [ -z "$(find "$P/.workflow/specs" -name .step)" ]'

echo "== evidence and result files land in the spec checkout"
for pair in "001-alpha|$TA|$WA" "002-beta|$TB|$WB"; do
  IFS='|' read -r spec task spec_wt <<<"$pair"
  script run-toolchain.sh --spec-dir ".workflow/specs/$spec" --task-id T1 --cwd "$task" --work-type shell >/dev/null 2>&1
  check "$spec: run-toolchain from the task worktree files toolchain.json in its spec worktree" \
    '[ -f "$spec_wt/.workflow/specs/$spec/artifacts/T1/toolchain.json" ] && [ ! -e "$task/.workflow/specs/$spec/artifacts" ]'
  # The brief's rule: the spec checkout is the worktree path less /.workflow/.worktrees/<name>.
  spec_checkout=$(cd "$task/../../.." && pwd -P)
  eq "$spec: the brief's spec-checkout rule names the spec worktree" "$spec_checkout" "$spec_wt"
  cmd=$(brief_result_command "$P/.agents/agents/implementation.md" implementation.yaml)
  cmd=${cmd//<worktree path>/$task}
  cmd=${cmd//<spec checkout>/$spec_checkout}
  cmd=${cmd//<spec_dir>/.workflow/specs/$spec}
  cmd=${cmd//<task_id>/T1}
  (cd "$P" && bash -c "$cmd"$'\nstatus: done\nEOF') >/dev/null 2>&1
  check "$spec: the brief's result-file command writes into its spec worktree" \
    '[ -f "$spec_wt/.workflow/specs/$spec/artifacts/T1/implementation.yaml" ] && [ ! -e "$task/.workflow/specs/$spec/artifacts/T1/implementation.yaml" ]'
done
check "no evidence reached the main checkout" '[ ! -e "$P/.workflow/specs/001-alpha" ] && [ ! -e "$P/.workflow/specs/002-beta" ]'
check "no evidence crossed between the specs" '[ ! -e "$WA/.workflow/specs/002-beta" ] && [ ! -e "$WB/.workflow/specs/001-alpha" ]'

echo "== the write guard reads the step of the spec checkout that holds the path"
out=$(script check-write.sh --cwd "$WA" --path "$WA/.workflow/specs/001-alpha/spec.md" --only spec 2>&1); rc=$?
check "spec.md of 001 at 001's step 3.4 -> denied" '[ $rc -eq 2 ]' "rc=$rc $out"
script status-transition.sh step .workflow/specs/001-alpha 3.1 --cwd "$WA" >/dev/null 2>&1
out=$(script check-write.sh --cwd "$TA" --path "$WA/.workflow/specs/001-alpha/spec.md" --only spec 2>&1); rc=$?
check "spec.md of 001 at 001's step 3.1, from its task worktree -> allowed" '[ $rc -eq 0 ]' "rc=$rc $out"
out=$(script check-write.sh --cwd "$WA" --path "$WB/.workflow/specs/002-beta/spec.md" --only spec 2>&1); rc=$?
check "spec.md of 002 at 002's step 3.3, from 001's worktree -> denied by 002's own step" '[ $rc -eq 2 ] && grep -q 3.3 <<<"$out"' "rc=$rc $out"

echo "== commits land on each spec's own branch"
echo 'alpha change' >"$TA/src/app.sh"
git -C "$TA" commit -qam "feat: alpha change"
check "the artifacts gate passes 001's task branch from the spec worktree" \
  'script check-merge-artifacts.sh --spec-dir .workflow/specs/001-alpha --rev task/001-alpha/T01-a --cwd "$WA" >/dev/null 2>&1'
git -C "$WA" merge -q --no-ff -m "Merge T1: t" task/001-alpha/T01-a
git -C "$WA" worktree remove "$TA"
git -C "$WA" branch -q -d task/001-alpha/T01-a
beta_tip=$(git -C "$P" rev-parse spec/002-beta)
out=$(script commit-workflow-data.sh .workflow/specs/001-alpha -m "Workflow data for 001-alpha" --cwd "$WA" 2>&1); rc=$?
check "commit-workflow-data from 001's spec worktree commits on spec/001-alpha" '[ $rc -eq 0 ] && [[ "$out" == committed* ]]' "rc=$rc $out"
files=$(git -C "$WA" show --name-only --format= HEAD)
check "001's commit holds its evidence and no .step" \
  'grep -q "^.workflow/specs/001-alpha/artifacts/T1/toolchain.json$" <<<"$files" && ! grep -q "\.step$" <<<"$files"' "$files"
eq "spec/002-beta did not move" "$(git -C "$P" rev-parse spec/002-beta)" "$beta_tip"
eq "main did not move" "$(git -C "$P" rev-parse main)" "$MAIN_HEAD"
out=$(script commit-workflow-data.sh .workflow/specs/002-beta -m "Workflow data for 002-beta" --cwd "$TB" 2>&1); rc=$?
check "commit-workflow-data from 002's task worktree commits on spec/002-beta" \
  '[ $rc -eq 0 ] && [ "$(git -C "$P" rev-parse spec/002-beta)" != "$beta_tip" ] && [ "$(git -C "$TB" rev-parse HEAD)" = "$beta_tip" ]' "rc=$rc $out"

echo "== the resume offer finds both specs"
offer() { jq -cn --arg c "$1" '{cwd:$c,hook_event_name:"SessionStart",source:"startup"}' |
  bash "$P/.agents/hooks/session-start-resume.sh" | jq -r '.hookSpecificOutput.additionalContext'; }
out=$(offer "$P")
check "from the main checkout: 001 listed as running in its spec worktree, with its step" \
  'grep -q "^- .workflow/specs/001-alpha (runs in $WA; continue the session there): status draft; current step 3.1" <<<"$out"' "$out"
check "from the main checkout: 002 listed as running in its spec worktree" 'grep -q "^- .workflow/specs/002-beta (runs in $WB" <<<"$out"' "$out"
out=$(offer "$WA")
check "from 001's spec worktree: 001 listed without a move, 002 with its worktree" \
  'grep -q "^- .workflow/specs/001-alpha: status draft" <<<"$out" && grep -q "^- .workflow/specs/002-beta (runs in $WB" <<<"$out"' "$out"

echo "== sign-off: the local merge from a spec worktree, then remove"
out=$(SW remove .workflow/specs/002-beta 2>&1); rc=$?
check "remove refuses an unmerged spec branch, exit 1" '[ $rc -eq 1 ] && grep -q "not merged" <<<"$out"' "rc=$rc $out"
check "the refused remove kept the worktree and the branch" '[ -d "$WB" ] && git -C "$P" show-ref -q --verify refs/heads/spec/002-beta'
mkdir -p "$WB/.workflow/specs/done/002-beta"
printf '## What changed\n\nBeta.\n' >"$WB/.workflow/specs/done/002-beta/pr-body.md"
git -C "$WB" add -A .workflow/specs/done && git -C "$WB" commit -qm "chore(workflow): pr body"
BLOCK=$(awk '/^<!-- 5\.8 publish commands -->$/ { armed = 1; next } armed && /^```bash$/ { infence = 1; next }
  infence && /^```$/ { exit } infence { print }' "$P/.agents/skills/feature-workflow/modules/sign-off.md")
LOCAL=$(grep -v -e "gh pr create" -e "glab mr create" <<<"$BLOCK")
beta_tip=$(git -C "$P" rev-parse spec/002-beta)
(cd "$WB" && env GIT_EDITOR=true SPEC_DIR=.workflow/specs/done/002-beta SPEC_BRANCH=spec/002-beta MAIN=main \
  SUBJECT="feat(beta): ship beta" bash -c "$LOCAL") >"$WORK/publish.out" 2>&1
eq "the 5.8 local merge run from the spec worktree lands on main" "$(git -C "$P" rev-parse -q --verify 'main^2')" "$beta_tip"
eq "the main checkout's working tree carries the merge" "$(git -C "$P" status --porcelain)" ""
out=$(SW remove .workflow/specs/done/002-beta 2>&1); rc=$?
check "remove refuses while an agent worktree is registered inside, exit 1" '[ $rc -eq 1 ] && grep -q "$TB" <<<"$out"' "rc=$rc $out"
git -C "$WB" worktree remove "$TB"
out=$(SW remove .workflow/specs/done/002-beta 2>&1); rc=$?
check "remove of the merged spec exits 0, naming what it removed" \
  '[ $rc -eq 0 ] && grep -qx "removed worktree $WB" <<<"$out" && grep -qx "deleted branch spec/002-beta" <<<"$out"' "rc=$rc $out"
check "the spec worktree and branch are gone" '[ ! -e "$WB" ] && ! git -C "$P" show-ref -q --verify refs/heads/spec/002-beta'
check "spec 001 still runs in its worktree" '[ "$(step_of "$WA/.workflow/specs/001-alpha/.step")" = 3.1 ]'

echo "== create refusals"
draft_spec 003-gamma 1.1
git -C "$P" rev-parse HEAD >"$P/.git/MERGE_HEAD"
out=$(SW create .workflow/specs/003-gamma 2>&1); rc=$?
check "mid-merge -> exit 1, nothing created" '[ $rc -eq 1 ] && ! git -C "$P" show-ref -q --verify refs/heads/spec/003-gamma' "rc=$rc $out"
rm -f "$P/.git/MERGE_HEAD"
out=$(cd "$WA" && bash "$S/spec-worktree.sh" create .workflow/specs/003-gamma 2>&1); rc=$?
check "from another spec's worktree -> exit 1" '[ $rc -eq 1 ] && grep -q "another spec" <<<"$out"' "rc=$rc $out"
eq "the refusals left spec 003 in the main checkout" "$(step_of "$P/.workflow/specs/003-gamma/.step")" 1.1
git -C "$P" switch -q -c spec/004-delta
out=$(SW create .workflow/specs/004-delta 2>&1); rc=$?
check "a checkout already on the spec branch -> exit 1" '[ $rc -eq 1 ] && grep -q "runs in that checkout" <<<"$out"' "rc=$rc $out"
git -C "$P" switch -q main
git -C "$P" branch -q -d spec/004-delta
out=$(SW create .workflow/specs/009-none 2>&1); rc=$?
check "no spec.md -> exit 2" '[ $rc -eq 2 ] && grep -q "spec.md not found" <<<"$out"' "rc=$rc $out"
t "no mode -> exit 2" 2 bash "$P/$S/spec-worktree.sh" .workflow/specs/003-gamma --cwd "$P"
t "an unknown mode -> exit 2" 2 bash "$P/$S/spec-worktree.sh" move .workflow/specs/003-gamma --cwd "$P"
t "not a spec folder -> exit 2" 2 bash "$P/$S/spec-worktree.sh" create docs/x --cwd "$P"
t "outside git -> exit 2" 2 bash "$P/$S/spec-worktree.sh" create .workflow/specs/003-gamma --cwd "$WORK"

shellcheck_files "shellcheck: spec-worktree.sh" "$AGENTS_SRC/skills/feature-workflow/scripts/spec-worktree.sh"
check "spec-worktree.sh is executable" '[ -x "$AGENTS_SRC/skills/feature-workflow/scripts/spec-worktree.sh" ]'
finish
