#!/usr/bin/env bash
# Suite: run-toolchain.sh (feature-workflow/scripts).
# Covers: toolchain key order and skipping, serve keys never run, --e2e, failure digest and --tail, evidence files,
#   missing profile / unclassified work type / usage errors, evidence in the checkout an agent worktree sits in, commands run in --cwd,
#   the tree hash (recorded, --tree-hash, untracked files, workflow data, the Tier A files nothing reads and the model map ignored, rules and profiles counted, a gitignored data folder present),
#   --reuse hits and misses (whole records across profile files, single keys by command), --reuse-check, test_scoped on the own list alone.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

new_workdir
copy_agents "$WORK/scaffold"
RT="$WORK/scaffold/.agents/skills/feature-workflow/scripts/run-toolchain.sh"
T=$WORK/fx
git_init_repo "$T/repo"
cd "$T/repo" || exit 1
mkdir -p .workflow/profiles .workflow/specs/001-x
cat > .workflow/profiles/fake.md <<'P'
# Profile: fake
## Toolchain
```yaml
lint: "echo linting; true"
typecheck: "true"
format: ""
boundary: "echo boundary-ok"
e2e: "echo e2e-ran"
test: "echo test-ran"
serve: "touch SERVE_RAN"
serve_ready: "touch SERVE_READY_RAN"
config:
  lint: "x"
rule_set: ""
```
## Mini-review checklist
- [ ] x
P
sed 's/typecheck: "true"/typecheck: "for i in 1 2 3; do echo err line $i; done; false"/' .workflow/profiles/fake.md > .workflow/profiles/bad.md
printf -- '---\ntasks:\n  - id: T1\n    work_type: fake\n  - id: T2\n    work_type: null\n---\n' > .workflow/specs/001-x/tasks.md
git_commit_all "$T/repo" i

out=$("$RT" --spec-dir .workflow/specs/001-x --task-id T1 --cwd . 2>/dev/null); rc=$?
eq allpass-rc "$rc" 0
eq allpass-status "$(jq -r .status <<<"$out")" pass
eq skipped "$(jq -r '[.results[]|select(.status=="skipped")|.key]|join(",")' <<<"$out")" format
eq ran "$(jq .ran <<<"$out")" 4
eq order "$(jq -r '[.results[].key]|join(",")' <<<"$out")" "lint,typecheck,format,boundary,test"
t test-key-ran 0 grep -q "test-ran" .workflow/specs/001-x/artifacts/T1/toolchain.txt
t serve-never-run 0 test ! -e SERVE_RAN -a ! -e SERVE_READY_RAN
t evidence 0 grep -q "linting" .workflow/specs/001-x/artifacts/T1/toolchain.txt
out=$("$RT" --spec-dir .workflow/specs/001-x --task-id T1 --e2e 2>/dev/null)
eq e2e-ran "$(jq .ran <<<"$out")" 5
eq e2e-last "$(jq -r '.results[-1].key' <<<"$out")" e2e
t serve-never-run-e2e 0 test ! -e SERVE_RAN
out=$("$RT" --spec-dir .workflow/specs/001-x --task-id T3 --work-type bad --tail 2 2>"$T/err"); rc=$?
eq fail-rc "$rc" 1
eq fail-status "$(jq -r .status <<<"$out")" fail
eq fail-others-ran "$(jq .ran <<<"$out")" 4
eq digest-tail "$(jq -r .digest <<<"$out" | grep -c '^err line')" 2
t stderr-digest 0 grep -q "typecheck" "$T/err"
t digest-file 0 test -f .workflow/specs/001-x/artifacts/T3/toolchain-digest.txt
# missing key (profile without lint)
grep -v '^lint' .workflow/profiles/fake.md > .workflow/profiles/nolint.md
out=$("$RT" --spec-dir .workflow/specs/001-x --task-id T4 --work-type nolint 2>/dev/null)
eq missing-key "$(jq -r '.results[0].status' <<<"$out")" skipped
# missing profile, unclassified task, usage
t noprofile-rc 2 "$RT" --spec-dir .workflow/specs/001-x --task-id T1 --work-type nope
t null-worktype-rc 2 "$RT" --spec-dir .workflow/specs/001-x --task-id T2
t usage-rc 2 "$RT" --task-id T1
# agent worktree: evidence goes to the checkout it sits in (kept out of git as the install block does)
echo '.workflow/.worktrees/' >> .git/info/exclude
WT=$T/repo/.workflow/.worktrees/wt
git worktree add -q "$WT" -b wt
rm -rf .workflow/specs/001-x/artifacts
"$RT" --spec-dir .workflow/specs/001-x --task-id T1 --cwd "$WT" >/dev/null 2>&1
eq wt-rc "$?" 0
MAIN=$(pwd -P)
t wt-evidence-main 0 test -f "$MAIN/.workflow/specs/001-x/artifacts/T1/toolchain.json"
t wt-no-local 0 test ! -e "$WT/specs/001-x/artifacts"
# commands run in the worktree
sed 's/boundary: "echo boundary-ok"/boundary: "pwd"/' .workflow/profiles/fake.md > .workflow/profiles/pwd.md
git_commit_all "$T/repo" p
(cd "$WT" && git merge -q main 2>/dev/null)
"$RT" --spec-dir .workflow/specs/001-x --task-id T5 --work-type pwd --cwd "$WT" >/dev/null 2>&1
t runs-in-cwd 0 grep -q "$(cd "$WT" && pwd -P)" .workflow/specs/001-x/artifacts/T5/toolchain.txt
grep -v '^test' .workflow/profiles/fake.md > .workflow/profiles/notest.md
out=$("$RT" --spec-dir .workflow/specs/001-x --task-id T6 --work-type notest 2>/dev/null)
eq missing-test-skipped "$(jq -r '.results[]|select(.key=="test")|.status' <<<"$out")" skipped
# --skip: repeatable, reported as skipped by caller; unknown key is a usage error
out=$("$RT" --spec-dir .workflow/specs/001-x --task-id T7 --work-type fake --skip test --skip lint 2>/dev/null)
eq skip-ran "$(jq .ran <<<"$out")" 2
eq skip-keys "$(jq -r '[.results[]|select(.status=="skipped")|.key]|join(",")' <<<"$out")" "lint,format,test"
eq skip-reason "$(jq -r '.results[]|select(.key=="test")|.reason' <<<"$out")" "skipped by caller"
t skip-not-run 0 grep -q "typecheck" .workflow/specs/001-x/artifacts/T7/toolchain.txt
t skip-test-absent 1 grep -q "test-ran" .workflow/specs/001-x/artifacts/T7/toolchain.txt
out=$("$RT" --spec-dir .workflow/specs/001-x --task-id T7 --work-type fake --e2e --skip e2e 2>/dev/null)
eq skip-e2e "$(jq -r '.results[-1]|.key+":"+.reason' <<<"$out")" "e2e:skipped by caller"
t skip-unknown-rc 2 "$RT" --spec-dir .workflow/specs/001-x --task-id T7 --work-type fake --skip serve
t skip-novalue-rc 2 "$RT" --spec-dir .workflow/specs/001-x --task-id T7 --work-type fake --skip

# tree hash: recorded in toolchain.json, stable, changed by an untracked file, not by workflow data
check tree-recorded 'jq -r .tree .workflow/specs/001-x/artifacts/T7/toolchain.json | grep -Eqx "[0-9a-f]{40}"'
h1=$("$RT" --tree-hash --cwd "$T/repo"); h2=$("$RT" --tree-hash --cwd "$T/repo")
check tree-hash-stable 'grep -Eqx "[0-9a-f]{40}" <<<"$h1" && [ "$h1" = "$h2" ]' "$h1 $h2"
eq tree-hash-matches-record "$(jq -r .tree .workflow/specs/001-x/artifacts/T7/toolchain.json)" "$h1"
mkdir -p .workflow/specs/001-x/notes && echo x > .workflow/specs/001-x/notes/new.md
eq tree-hash-ignores-specs "$("$RT" --tree-hash --cwd "$T/repo")" "$h1"
# Sign-off and the retrospective edit Tier A files and the model map that no command reads; the rules, the profiles and other workflow files count.
mkdir -p .workflow/decisions/adr .workflow/model-map
for f in capabilities.md review-lessons.md GLOSSARY.md decisions/adr/0001-x.md model-map/implementation.md; do echo tier-a > ".workflow/$f"; done
eq tree-hash-ignores-tier-a "$("$RT" --tree-hash --cwd "$T/repo")" "$h1"
echo rules > .workflow/rules.md
check tree-hash-counts-rules '[ "$("$RT" --tree-hash --cwd "$T/repo")" != "$h1" ]'
rm -f .workflow/rules.md
cp .workflow/profiles/fake.md "$T/fake.md.orig" && echo edited >> .workflow/profiles/fake.md
check tree-hash-counts-profiles '[ "$("$RT" --tree-hash --cwd "$T/repo")" != "$h1" ]'
mv "$T/fake.md.orig" .workflow/profiles/fake.md
mkdir -p .workflow/tools && echo x > .workflow/tools/config.txt
check tree-hash-counts-other-workflow-files '[ "$("$RT" --tree-hash --cwd "$T/repo")" != "$h1" ]'
rm -rf .workflow/tools .workflow/decisions .workflow/model-map .workflow/capabilities.md .workflow/review-lessons.md .workflow/GLOSSARY.md
echo x > untracked.txt
check tree-hash-untracked '[ "$("$RT" --tree-hash --cwd "$T/repo")" != "$h1" ]'
rm -f untracked.txt
h3=$("$RT" --tree-hash --cwd "$WT")
echo y > "$WT/untracked.txt"
check tree-hash-worktree 'grep -Eqx "[0-9a-f]{40}" <<<"$h3" && [ "$("$RT" --tree-hash --cwd "$WT")" != "$h3" ]' "$h3"
rm -f "$WT/untracked.txt"
printf '.workflow/.handoff/\n' > .gitignore && mkdir -p .workflow/.handoff
h4=$("$RT" --tree-hash --cwd "$T/repo" 2>/dev/null)
echo x > .workflow/.handoff/h.md
check tree-hash-ignored-data-folder 'grep -Eqx "[0-9a-f]{40}" <<<"$h4" && [ "$("$RT" --tree-hash --cwd "$T/repo" 2>/dev/null)" = "$h4" ]' "$h4"
rm -rf .gitignore .workflow/.handoff
mkdir -p "$T/nogit"
t tree-hash-no-repo-rc 2 "$RT" --tree-hash --cwd "$T/nogit"
t run-no-repo-rc 2 "$RT" --spec-dir .workflow/specs/001-x --task-id T1 --work-type fake --cwd "$T/nogit"

# --reuse: a passing record of the same tree, profile and keys is copied instead of running anything
M=$T/marker
cat > .workflow/profiles/mark.md <<P
## Toolchain
\`\`\`yaml
lint: "true"
test: "echo run >> '$M'"
\`\`\`
P
sed 's/lint: "true"/lint: "echo other"/' .workflow/profiles/mark.md > .workflow/profiles/mark2.md
printf 'echo run >> %s; exit 1\n' "'$M'" > "$T/fail.sh"
sed "s|test: .*|test: \"bash '$T/fail.sh'\"|" .workflow/profiles/mark.md > .workflow/profiles/markfail.md
# The profiles are part of the tree, so every one the reuse checks name exists before the first run.
cp .workflow/profiles/mark.md .workflow/profiles/markcopy.md
sed 's/lint: "true"/lint: "echo third"/' .workflow/profiles/mark.md > .workflow/profiles/mark3.md
git_commit_all "$T/repo" mark
EVR=.workflow/specs/001-x/artifacts
# lines : how many test commands have appended to the marker so far
lines() { if [ -f "$M" ]; then wc -l < "$M" | tr -d ' '; else echo 0; fi; }
"$RT" --spec-dir .workflow/specs/001-x --task-id R1 --work-type mark --reuse >/dev/null 2>&1
eq reuse-first-runs "$(lines)" 1
check reuse-first-no-reused-from '[ "$(jq -r ".reused_from // \"none\"" $EVR/R1/toolchain.json)" = none ]'
out=$("$RT" --spec-dir .workflow/specs/001-x --task-id R1 --work-type mark --reuse 2>/dev/null); rc=$?
eq reuse-hit-rc "$rc" 0
eq reuse-hit-ran-nothing "$(lines)" 1
eq reuse-hit-self "$(jq -r .reused_from $EVR/R1/toolchain.json)" R1
eq reuse-hit-stdout "$(jq -r '.status + ":" + .reused_from' <<<"$out")" pass:R1
out=$("$RT" --spec-dir .workflow/specs/001-x --task-id R2 --work-type mark --reuse 2>/dev/null); rc=$?
eq reuse-copy-rc "$rc" 0
eq reuse-copy-ran-nothing "$(lines)" 1
check reuse-copy-files 'cmp -s $EVR/R1/toolchain.txt $EVR/R2/toolchain.txt && [ "$(jq -r ".reused_from + \":\" + .task_id" $EVR/R2/toolchain.json)" = R1:R2 ]'
"$RT" --spec-dir .workflow/specs/001-x --task-id R3 --work-type mark >/dev/null 2>&1
eq reuse-off-runs "$(lines)" 2
# misses: changed tree, failing candidate, skipped key, scoped record of another task
echo change > changed.txt
"$RT" --spec-dir .workflow/specs/001-x --task-id R4 --work-type mark --reuse >/dev/null 2>&1
eq reuse-miss-tree "$(lines)" 3
check reuse-miss-tree-no-stamp '[ "$(jq -r ".reused_from // \"none\"" $EVR/R4/toolchain.json)" = none ]'
rm -f changed.txt
# another profile file with the same commands is a whole-record hit
out=$("$RT" --spec-dir .workflow/specs/001-x --task-id R6 --work-type markcopy --reuse 2>/dev/null)
eq reuse-hit-other-profile-file "$(lines)" 3
eq reuse-hit-other-profile-stamp "$(jq -r '.reused_from + ":" + .work_type' <<<"$out")" R1:markcopy
# another profile whose test command matches and lint differs: test is not run again, lint runs
out=$("$RT" --spec-dir .workflow/specs/001-x --task-id R5 --work-type mark2 --reuse 2>/dev/null); rc=$?
eq reuse-key-rc "$rc" 0
eq reuse-key-test-not-run "$(lines)" 3
eq reuse-key-test-stamp "$(jq -r '.results[] | select(.key=="test") | .status + ":" + .reused_from' <<<"$out")" pass:R1
eq reuse-key-lint-ran "$(jq -r '[.ran, (.results[] | select(.key=="lint") | .reused_from // "none")] | map(tostring) | join(":")' <<<"$out")" 1:none
check reuse-key-no-record-stamp '[ "$(jq -r ".reused_from // \"none\"" <<<"$out")" = none ] && grep -q "^other" $EVR/R5/toolchain.txt' "$out"
t reuse-key-txt-names-source 0 grep -q "not run: passed on this tree in .*R1/toolchain.txt" $EVR/R5/toolchain.txt
# --reuse-check reports a whole-record hit and writes nothing
out=$("$RT" --spec-dir .workflow/specs/001-x --task-id post-merge --work-type mark --reuse-check 2>/dev/null); rc=$?
eq reuse-check-hit "$rc:$out" 0:R1
t reuse-check-hit-no-evidence 0 test ! -e $EVR/post-merge
out=$("$RT" --spec-dir .workflow/specs/001-x --task-id post-merge --work-type mark3 --reuse-check 2>/dev/null); rc=$?
eq reuse-check-key-hit-is-a-miss "$rc:$out:$(lines)" 1::3
echo other change > changed2.txt
out=$("$RT" --spec-dir .workflow/specs/001-x --task-id post-merge --work-type mark --reuse-check 2>/dev/null); rc=$?
eq reuse-check-miss "$rc:$out:$(lines)" 1::3
t reuse-check-miss-no-evidence 0 test ! -e $EVR/post-merge
rm -f changed2.txt
t reuse-check-with-reuse-rc 2 "$RT" --spec-dir .workflow/specs/001-x --task-id post-merge --work-type mark --reuse-check --reuse
rm -rf "$EVR"
"$RT" --spec-dir .workflow/specs/001-x --task-id F1 --work-type markfail --reuse >/dev/null 2>&1
eq reuse-fail-first "$(lines)" 4
"$RT" --spec-dir .workflow/specs/001-x --task-id F1 --work-type markfail --reuse >/dev/null 2>&1
eq reuse-miss-failing "$(lines)" 5
t reuse-miss-failing-digest 0 test -f $EVR/F1/toolchain-digest.txt
rm -rf "$EVR"
"$RT" --spec-dir .workflow/specs/001-x --task-id S1 --work-type mark --skip test >/dev/null 2>&1
eq reuse-skip-first "$(lines)" 5
"$RT" --spec-dir .workflow/specs/001-x --task-id S2 --work-type mark --reuse >/dev/null 2>&1
eq reuse-miss-skipped "$(lines)" 6
"$RT" --spec-dir .workflow/specs/001-x --task-id S3 --work-type mark --skip test --reuse >/dev/null 2>&1
eq reuse-skipped-key-not-needed "$(jq -r .reused_from $EVR/S3/toolchain.json)" S1
rm -rf "$EVR"
"$RT" --spec-dir .workflow/specs/001-x --task-id P1 --work-type mark >/dev/null 2>&1
jq '(.results[] | select(.key == "test")) += {scoped: true, own: 1, excluded: 0}' $EVR/P1/toolchain.json > "$T/p1.json"
mv "$T/p1.json" $EVR/P1/toolchain.json
"$RT" --spec-dir .workflow/specs/001-x --task-id P2 --work-type mark --reuse >/dev/null 2>&1
eq reuse-miss-scoped-other-task "$(lines)" 8
rm -rf "$EVR"

# scoping: the task's own selectors alone switch to test_scoped; neither list runs test
cat > .workflow/profiles/scope.md <<P
## Toolchain
\`\`\`yaml
test: "echo full >> '$M'"
test_scoped: "echo scoped >> '$M'; cat \"\$WF_TASK_TESTS_FILE\" > '$T/own.txt'"
\`\`\`
P
printf -- '---\ntasks:\n  - {id: T1, status: done, work_type: scope, tests: [tests/scripts/a.sh, tests/scripts/b.sh]}\n  - {id: T2, status: in-progress, work_type: scope}\n  - {id: T3, status: done, work_type: scope, tests: [tests/scripts/c.sh]}\n---\n' > .workflow/specs/001-x/tasks.md
: > "$M"
out=$("$RT" --spec-dir .workflow/specs/001-x --task-id T1 2>/dev/null)
eq scope-own-only-scoped "$(tail -n 1 "$M")" scoped
eq scope-own-only-flags "$(jq -c '.results[] | select(.key=="test") | [.scoped, .own, .excluded]' <<<"$out")" '[true,2,0]'
eq scope-own-file "$(tr '\n' ' ' < "$T/own.txt")" "tests/scripts/a.sh tests/scripts/b.sh "
out=$("$RT" --spec-dir .workflow/specs/001-x --task-id T2 2>/dev/null)
eq scope-none-full "$(tail -n 1 "$M")" full
eq scope-none-no-flags "$(jq -c '.results[] | select(.key=="test") | has("scoped")' <<<"$out")" false

shellcheck_files "shellcheck: run-toolchain.sh" "$RT"
finish
