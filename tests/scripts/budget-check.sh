#!/usr/bin/env bash
# Suite: budget-check.sh (feature-workflow/scripts).
# Covers: the size budget source (spec, rules.md block, default) and its errors, the PR/MR file set (merge-base with the
#   target, origin/<target>, fallback to impl_base..HEAD), worktree --cwd, spec folder and backlog exclusion, harness and
#   test exclusion (profile test_patterns), --predicted, and refusals (unknown revisions, missing tasks.md, no git, no yq).
#   JRN-006: each spec folder form (relative, absolute in the main checkout or a worktree, run from a worktree, bare,
#   absolute elsewhere, outside git) gives the exit code and message it gave before the shared normaliser.
# Env: TEST_BASH=<bash binary> runs the scripts under another bash (default: bash).
# shellcheck disable=SC2329,SC1010,SC2016  # helpers run indirectly via t and bash -c; "done" is a status word; backticks in printf fixtures
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/workflow-folders.sh
source "$TESTS_DIR/fixtures/workflow-folders.sh"
preflight

TEST_BASH=${TEST_BASH:-bash}
new_workdir
F=$WORK
# The scripts under test come from a private copy of .agents/ so the fixture never touches the repo.
copy_agents "$F/scaffold"
SRC="$F/scaffold/.agents/skills/feature-workflow"
ST() { "$TEST_BASH" "$SRC/scripts/status-transition.sh" "$@"; }
CW() { "$TEST_BASH" "$SRC/scripts/check-write.sh" "$@"; }
BC() { "$TEST_BASH" "$SRC/scripts/budget-check.sh" "$@"; }
export -f ST CW BC
export TEST_BASH SRC

git_init_repo "$F/repo"
R=$F/repo
cd "$R" || exit 1
mkdir -p .workflow/specs/001-alpha .workflow/specs/002-beta .workflow/decisions/adr .workflow/profiles
cp "$SRC/assets/spec.md" .workflow/specs/001-alpha/spec.md
cp "$SRC/assets/spec.md" .workflow/specs/002-beta/spec.md
cp "$SRC/assets/tasks.md" .workflow/specs/001-alpha/tasks.md
# Fill the template placeholders the validator checks (file, branch).
sed -i.bak -e 's/<slug>/demo/g' -e 's#task/NNN-slug/#task/001-alpha/#' .workflow/specs/001-alpha/tasks.md && rm -f .workflow/specs/001-alpha/tasks.md.bak
yq --front-matter=process -i '.tasks += [{"id":"T2","title":"x","status":"pending","capability":"CAP-001","depends_on":["T1"],"touches_core":false,"work_type":null,"module":"m","seam":"s"}]' .workflow/specs/001-alpha/tasks.md
echo '.workflow/specs/*/.step' > .gitignore
touch .workflow/profiles/frontend.md
git add -A; git commit -qm init
git worktree add -q .claude/worktrees/agent-x -b wt-x
WT=$R/.claude/worktrees/agent-x

status() { yq --front-matter=extract '.status' "$R/.workflow/specs/$1/spec.md"; }
step() { sed -n 's/^step: "\(.*\)"$/\1/p' "$R/.workflow/specs/$1/.step"; }
unmark() { mv "$R/.workflow/specs/$1/.step" "$F/removed-$1.step"; }
A=.workflow/specs/001-alpha

# The work-backlog folder exists, so "not a spec dir" is checked against a real folder.
mkdir -p "$R/.workflow/specs/work-backlog"

echo "== budget-check.sh"
E=.workflow/specs/007-eps
mkdir -p "$R/$E"; cp "$SRC/assets/spec.md" "$R/$E/spec.md"; cp "$R/$A/tasks.md" "$R/$E/tasks.md"
jb() { BC "$@" 2>/dev/null; }
# The shipped spec.md template leaves `budget` commented out (written at 2.5), so give this spec an explicit one.
yq --front-matter=process -i '.budget = {"max_tasks": 10, "max_changed_files": 30}' "$R/$E/spec.md"
t "usage: no args"                          1 BC
t "bad spec dir"                            1 BC --spec-dir .workflow/specs/eps
t "work-backlog is not a spec dir"          1 BC --spec-dir .workflow/specs/work-backlog
t "missing spec"                            1 BC --spec-dir .workflow/specs/098-none
t "no baseline: within budget"              0 BC --spec-dir $E
out=$(jb --spec-dir $E)
eq "no baseline: source spec" "$(jq -r .source <<<"$out")" spec
eq "no baseline: tasks 2" "$(jq -r .tasks <<<"$out")" 2
eq "no baseline: changed_files null" "$(jq -r .changed_files <<<"$out")" null
eq "no baseline: note present" "$(jq -r 'has("note")' <<<"$out")" true
eq "no baseline: keys" "$(jq -r 'keys|sort|join(",")' <<<"$out")" "basis,changed_files,excluded,files,max_changed_files,max_tasks,merge_base,note,over,source,target,tasks,test_files"
eq "no baseline: breakdown null" "$(jq -c '[.target,.merge_base,.excluded,.files,.test_files]' <<<"$out")" "[null,null,null,null,null]"
eq "no baseline: over empty" "$(jq -c .over <<<"$out")" "[]"
yq --front-matter=process -i 'del(.budget)' "$R/$E/spec.md"
out=$(jb --spec-dir $E); eq "no budget, no rules: default" "$(jq -r '[.source,.max_tasks,.max_changed_files]|join(",")' <<<"$out")" "default,10,30"
printf '# Rules\n\n## Size budget\n\nText.\n\n```yaml\nsize_budget:\n  max_tasks: 1\n  max_changed_files: 5   # comment\n```\n\n## Other\n\n```yaml\nsize_budget: {max_tasks: 99, max_changed_files: 99}\n```\n' > "$R/.workflow/rules.md"
t "rules budget: tasks over -> 2"           2 BC --spec-dir $E
out=$(jb --spec-dir $E); eq "rules source + values" "$(jq -r '[.source,.max_tasks,.max_changed_files]|join(",")' <<<"$out")" "rules,1,5"
eq "over tasks" "$(jq -c .over <<<"$out")" '["tasks"]'
printf '## Size budget\n\n```yaml\nsize_budget: 5\n```\n' > "$R/.workflow/rules.md"
t "malformed rules block -> 1"              1 BC --spec-dir $E
printf '## Size budget\n\n```yaml\nsize_budget: {max_tasks: 4}\n```\n' > "$R/.workflow/rules.md"
t "rules block missing key -> 1"            1 BC --spec-dir $E
printf '## Size budget\n\nNo block yet.\n' > "$R/.workflow/rules.md"
out=$(jb --spec-dir $E); eq "heading without block: default" "$(jq -r .source <<<"$out")" default
rm -f "$R/.workflow/rules.md"
yq --front-matter=process -i '.budget = {"max_tasks": "ten", "max_changed_files": 30}' "$R/$E/spec.md"
t "malformed spec budget -> 1"              1 BC --spec-dir $E
yq --front-matter=process -i '.budget = {"max_tasks": 5, "max_changed_files": 2}' "$R/$E/spec.md"
BASE_SHA=$(git -C "$R" rev-parse HEAD)
# The feature works on its spec branch; main stays at the baseline as the PR/MR target.
git -C "$R" switch -q -c spec/007-eps
yq --front-matter=process -i ".baseline_revision = \"$BASE_SHA\"" "$R/$E/spec.md"
out=$(jb --spec-dir $E); eq "baseline=HEAD: 0 changed" "$(jq -r .changed_files <<<"$out")" 0
eq "baseline only: fallback note" "$(jq -r '.note' <<<"$out" | grep -c 'impl_base_revision is not set')" 1
eq "baseline only: basis" "$(jq -r .basis <<<"$out")" baseline_revision
yq --front-matter=process -i ".impl_base_revision = \"$BASE_SHA\"" "$R/$E/spec.md"
out=$(jb --spec-dir $E); eq "impl_base=HEAD: 0 changed" "$(jq -r .changed_files <<<"$out")" 0
eq "impl_base: no note" "$(jq -r 'has("note")' <<<"$out")" false
eq "impl_base: basis" "$(jq -r .basis <<<"$out")" impl_base_revision
mkdir -p "$R/src" "$R/.workflow/specs/work-backlog"
echo a > "$R/src/a.ts"; echo b > "$R/src/b.ts"; echo c > "$R/src/c.ts"; echo x > "$R/$E/notes.md"; echo w > "$R/.workflow/specs/work-backlog/007-eps.md"
git -C "$R" add src "$E/notes.md" .workflow/specs/work-backlog; git -C "$R" commit -qm wave1
t "3 changed > 2 -> 2"                      2 BC --spec-dir $E
out=$(jb --spec-dir $E)
eq "changed excludes spec folder + backlog" "$(jq -r .changed_files <<<"$out")" 3
eq "over changed_files" "$(jq -c .over <<<"$out")" '["changed_files"]'
eq "source spec" "$(jq -r .source <<<"$out")" spec
t "from worktree cwd (its HEAD: 0 changed)" 0 BC --spec-dir $E --cwd "$WT"
git -C "$WT" checkout -q --detach "$BASE_SHA" 2>/dev/null
echo z > "$WT/z.ts"; git -C "$WT" add z.ts; git -C "$WT" commit -qm wt1
out=$(jb --spec-dir $E --cwd "$WT"); eq "worktree count 1" "$(jq -r .changed_files <<<"$out")" 1
t "abs spec dir from worktree"              0 BC --spec-dir "$WT/$E" --cwd "$WT"
out=$(cd "$WT" && BC --spec-dir $E 2>/dev/null); eq "no --cwd from worktree PWD counts main HEAD" "$(jq -r .changed_files <<<"$out")" 3
yq --front-matter=process -i '.budget.max_tasks = 1' "$R/$E/spec.md"
out=$(jb --spec-dir $E); eq "both over" "$(jq -c .over <<<"$out")" '["tasks","changed_files"]'
yq --front-matter=process -i '.budget = {"max_tasks": 2, "max_changed_files": 3}' "$R/$E/spec.md"
t "equal to max is within budget"           0 BC --spec-dir $E
out=$(jb --spec-dir $E)
eq "target defaults to main" "$(jq -r .target <<<"$out")" main
eq "merge_base is main" "$(jq -r .merge_base <<<"$out")" "$BASE_SHA"
eq "counted files listed" "$(jq -r '.files|join(",")' <<<"$out")" "src/a.ts,src/b.ts,src/c.ts"
eq "spec folder + backlog reported" "$(jq -r .excluded.spec_backlog <<<"$out")" 2
git -C "$R" switch -q main
echo m > "$R/main-only.ts"; git -C "$R" add main-only.ts; git -C "$R" commit -qm "main moves on"
MAIN_SHA=$(git -C "$R" rev-parse HEAD)
git -C "$R" switch -q spec/007-eps
git -C "$R" merge -q --no-edit main
out=$(jb --spec-dir $E)
eq "merging main in: count unchanged" "$(jq -r .changed_files <<<"$out")" 3
eq "merging main in: dropped by merge-base" "$(jq -r .excluded.merge_base <<<"$out")" 1
eq "merging main in: merge_base moves to main" "$(jq -r .merge_base <<<"$out")" "$MAIN_SHA"
t "merging main in: still within budget"    0 BC --spec-dir $E
printf '## Workflow settings\n\n```yaml\nmain_branch: trunk\n```\n' > "$R/.workflow/rules.md"
out=$(jb --spec-dir $E)
eq "missing target: falls back to impl_base..HEAD" "$(jq -r .changed_files <<<"$out")" 4
eq "missing target: merge_base null" "$(jq -c '[.target,.merge_base,.excluded.merge_base]' <<<"$out")" '["trunk",null,null]'
eq "missing target: note names it" "$(jq -r .note <<<"$out" | grep -c 'target branch trunk not found')" 1
t "missing target: warning on stderr"       0 bash -c "BC --spec-dir $E 2>&1 >/dev/null | grep -q 'warning: target branch trunk not found'"
git -C "$R" update-ref refs/remotes/origin/trunk "$MAIN_SHA"
out=$(jb --spec-dir $E)
eq "origin/<target> alone is used" "$(jq -r '[.changed_files,.merge_base]|join(",")' <<<"$out")" "3,$MAIN_SHA"
eq "origin/<target>: no note" "$(jq -r 'has("note")' <<<"$out")" false
git -C "$R" update-ref -d refs/remotes/origin/trunk
printf '## Workflow settings\n\n```yaml\nmain_branch: "bad..name"\n```\n' > "$R/.workflow/rules.md"
t "invalid main_branch -> 1"                1 BC --spec-dir $E
rm -f "$R/.workflow/rules.md"
mkdir -p "$R/tests" "$R/harness"
echo t > "$R/src/a.test.ts"; echo u > "$R/tests/unit.ts"
git -C "$R" add src tests; git -C "$R" commit -qm "wave2 tests"
out=$(jb --spec-dir $E)
eq "tests excluded from the count" "$(jq -r .changed_files <<<"$out")" 3
eq "tests reported separately" "$(jq -r '[.excluded.tests, (.test_files|join(","))]|join(" ")' <<<"$out")" "2 src/a.test.ts,tests/unit.ts"
echo h > "$R/harness/setup.ts"; git -C "$R" add harness; git -C "$R" commit -qm "phase 1 harness"
yq --front-matter=process -i ".impl_base_revision = \"$(git -C "$R" rev-parse HEAD)\"" "$R/$E/spec.md"
out=$(jb --spec-dir $E)
eq "harness-only: nothing counts" "$(jq -r .changed_files <<<"$out")" 0
eq "harness-only: reported" "$(jq -r .excluded.harness_only <<<"$out")" 6
echo h2 >> "$R/harness/setup.ts"; echo u2 >> "$R/tests/unit.ts"
git -C "$R" add harness tests; git -C "$R" commit -qm "phase 3 touches the harness"
out=$(jb --spec-dir $E)
eq "harness changed again in Phase 3 counts" "$(jq -r '.files|join(",")' <<<"$out")" "harness/setup.ts"
eq "harness test changed again stays excluded" "$(jq -r '[.excluded.tests,.excluded.harness_only]|join(",")' <<<"$out")" "1,4"
yq --front-matter=process -i '.tasks[0].size = {"files": 4, "est_lines": 50, "points": "S"} | .tasks[0].predicted_files = ["src/x.ts", "src/x.test.ts", "tests/**", "src/y.ts"] | .tasks[1].size = {"files": 2, "est_lines": 20, "points": "S"} | .tasks[1].predicted_files = ["e2e/j.spec.ts", "src/z.ts"]' "$R/$E/tasks.md"
out=$(jb --spec-dir $E --predicted)
eq "predicted: tests excluded" "$(jq -r .changed_files <<<"$out")" 3
eq "predicted: tests reported" "$(jq -r '[.excluded.tests, (.test_files|join(","))]|join(" ")' <<<"$out")" "3 e2e/j.spec.ts,src/x.test.ts,tests/**"
eq "predicted: no git breakdown" "$(jq -c '[.excluded.merge_base,.files,.target]' <<<"$out")" "[null,null,null]"
printf '## Toolchain\n\n```yaml\ntest: "x"\ntest_patterns: ["*.check.ts"]\n```\n' > "$R/.workflow/profiles/frontend.md"
yq --front-matter=process -i '.tasks[1].predicted_files = ["src/z.check.ts", "src/z.ts"]' "$R/$E/tasks.md"
out=$(jb --spec-dir $E --predicted)
eq "profile test_patterns replace its defaults" "$(jq -r '.test_files|join(",")' <<<"$out")" "src/z.check.ts"
printf '## Toolchain\n\n```yaml\ntest: "x"\ntest_patterns: "*.check.ts"\n```\n' > "$R/.workflow/profiles/frontend.md"
t "malformed test_patterns -> 1"            1 BC --spec-dir $E --predicted
: > "$R/.workflow/profiles/frontend.md"
yq --front-matter=process -i 'del(.tasks[].size) | del(.tasks[].predicted_files)' "$R/$E/tasks.md"
yq --front-matter=process -i '.impl_base_revision = "deadbeef"' "$R/$E/spec.md"
t "unknown impl_base -> 1"                  1 BC --spec-dir $E
yq --front-matter=process -i 'del(.impl_base_revision) | .baseline_revision = "deadbeef"' "$R/$E/spec.md"
t "unknown baseline (fallback) -> 1"        1 BC --spec-dir $E
yq --front-matter=process -i ".baseline_revision = \"$BASE_SHA\" | .impl_base_revision = \"$BASE_SHA\"" "$R/$E/spec.md"
mv "$R/$E/tasks.md" "$F/eps-tasks.md"
t "missing tasks.md -> 1"                   1 BC --spec-dir $E
mv "$F/eps-tasks.md" "$R/$E/tasks.md"
t "not a git repo -> 1"                     1 BC --spec-dir $E --cwd /
t "yq missing -> 1 (budget-check)"          1 env PATH=/usr/bin:/bin /bin/bash "$SRC/scripts/budget-check.sh" --spec-dir $E
t "read-only: spec.md unchanged by check"   0 bash -c "a=\$(shasum '$R/$E/spec.md'); BC --spec-dir $E >/dev/null 2>&1; [ \"\$a\" = \"\$(shasum '$R/$E/spec.md')\" ]"

echo "== JRN-006 spec folder forms"
folder_fixture_repo "$F/folders"
while IFS='|' read -r form cwd arg; do
  eq "JRN-006 budget-check takes the $form spec folder as before" \
    "$(folder_outcome BC --spec-dir "$arg" --cwd "$cwd")" \
    "$(folder_expected "$form" "$cwd" "$arg" budget-check.sh 1 "spec dir must be .workflow/specs/NNN-slug" "0|")"
done < <(folder_inputs spec)

shellcheck_files "shellcheck: scripts under test" "$SRC/scripts/budget-check.sh"
finish
