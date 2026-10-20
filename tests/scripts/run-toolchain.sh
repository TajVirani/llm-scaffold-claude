#!/usr/bin/env bash
# Suite: run-toolchain.sh (feature-workflow/scripts).
# Covers: toolchain key order and skipping, serve keys never run, --e2e, failure digest and --tail, evidence files,
#   missing profile / unclassified work type / usage errors, worktree evidence location (D18), commands run in --cwd.
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
# worktree: evidence goes to the main checkout
git worktree add -q "$T/wt" -b wt
rm -rf .workflow/specs/001-x/artifacts
"$RT" --spec-dir .workflow/specs/001-x --task-id T1 --cwd "$T/wt" >/dev/null 2>&1
eq wt-rc "$?" 0
MAIN=$(pwd -P)
t wt-evidence-main 0 test -f "$MAIN/.workflow/specs/001-x/artifacts/T1/toolchain.json"
t wt-no-local 0 test ! -e "$T/wt/specs/001-x/artifacts"
# commands run in the worktree
sed 's/boundary: "echo boundary-ok"/boundary: "pwd"/' .workflow/profiles/fake.md > .workflow/profiles/pwd.md
git_commit_all "$T/repo" p
(cd "$T/wt" && git merge -q main 2>/dev/null)
"$RT" --spec-dir .workflow/specs/001-x --task-id T5 --work-type pwd --cwd "$T/wt" >/dev/null 2>&1
t runs-in-cwd 0 grep -q "$(cd "$T/wt" && pwd -P)" .workflow/specs/001-x/artifacts/T5/toolchain.txt
grep -v '^test' .workflow/profiles/fake.md > .workflow/profiles/notest.md
out=$("$RT" --spec-dir .workflow/specs/001-x --task-id T6 --work-type notest 2>/dev/null)
eq missing-test-skipped "$(jq -r '.results[]|select(.key=="test")|.status' <<<"$out")" skipped
# --skip (D70): repeatable, reported as skipped by caller; unknown key is a usage error
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

shellcheck_files "shellcheck: run-toolchain.sh" "$RT"
finish
