#!/usr/bin/env bash
# Suite: status-transition.sh (feature-workflow/scripts): task records and spec keys.
# Covers: set-task transitions, work_type and capability rules, the tasks.md validator and its copy in assets/tasks.md,
#   a validator yq cannot run (exit 1 with yq's diagnostic, nothing written),
#   split-out tasks and backlog seeding at 0.1.4, task bodies under tasks/, record fields, set-task --pr, set-spec
#   (spec_branch, impl_base_revision) and budget-check.sh --predicted over the task records.
#   JRN-006 (spec 00014): set-task --issue records an https URL as the task's issue, refuses a non-URL with exit 2 keeping the
#   recorded value, clears it with null, and the tasks.md validator refuses an issue field that is not a URL.
#   Tracker issue keys: --issue refuses a plain http URL, the spec.md template validator accepts tracker_issue as "", absent
#   or an https URL and refuses anything else.
# Env: TEST_BASH=<bash binary> runs the scripts under another bash (default: bash).
# shellcheck disable=SC2329,SC1010,SC2016  # helpers run indirectly via t and bash -c; "done" is a status word; backticks in printf fixtures
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
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
mkdir -p .workflow/specs/001-alpha .workflow/specs/002-beta .workflow/cache .workflow/decisions/adr .workflow/profiles
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

# The set-task checks need a finished spec (001-alpha); the backlog-seeding checks need 006-delta in progress.
ST status $A draft >/dev/null; ST status $A ready-for-dev --step 0.6 >/dev/null; ST status $A in-progress >/dev/null
ST status $A in-review --step 3.14 >/dev/null; ST status $A done >/dev/null
D=.workflow/specs/006-delta
mkdir -p "$R/$D"; cp "$SRC/assets/spec.md" "$R/$D/spec.md"; cp "$R/$A/tasks.md" "$R/$D/tasks.md"
ST status $D draft >/dev/null; ST status $D ready-for-dev --step 0.6 >/dev/null; ST status $D in-progress >/dev/null
WB=.workflow/specs/work-backlog/006-delta-disc-001.md
jb() { BC "$@" 2>/dev/null; }
# A second commit, so the impl_base check below has a commit older than the baseline to refuse.
git -C "$R" commit -q --allow-empty -m second

echo "== status-transition: set-task"
mkdir -p "$R/.workflow/specs/003-gamma"; cp "$SRC/assets/spec.md" "$R/.workflow/specs/003-gamma/spec.md"; cp "$R/$A/tasks.md" "$R/.workflow/specs/003-gamma/tasks.md"
G=.workflow/specs/003-gamma
yq --front-matter=process -i '.status="in-progress"' "$R/$G/spec.md"
t "set-task needs a field"                  1 ST set-task $G T1
t "T1 pending->done illegal"                2 ST set-task $G T1 --status done
t "T1 pending->in-progress + work_type"     0 ST set-task $G T1 --status in-progress --work-type frontend --step 3.1
eq "T1 status" "$(yq --front-matter=extract '.tasks[0].status' "$R/$G/tasks.md")" in-progress
eq "T1 work_type" "$(yq --front-matter=extract '.tasks[0].work_type' "$R/$G/tasks.md")" frontend
eq "T2 untouched" "$(yq --front-matter=extract '.tasks[1].status' "$R/$G/tasks.md")" pending
eq ".step set by --step" "$(step 003-gamma)" 3.1
t "T1 reclassify illegal"                   2 ST set-task $G T1 --work-type backend
t "T1 same work_type ok"                    0 ST set-task $G T1 --work-type frontend
t "work_type bad name"                      1 ST set-task $G T2 --work-type "Front End"
t "work_type missing profile (warn, ok)"    0 ST set-task $G T2 --work-type backend
t "T1 in-progress->in-progress"             0 ST set-task $G T1 --status in-progress
t "T1 in-progress->blocked"                 0 ST set-task $G T1 --status blocked
t "T1 blocked->done illegal"                2 ST set-task $G T1 --status done
t "T1 blocked->in-progress"                 0 ST set-task $G T1 --status in-progress
t "T1 in-progress->done"                    0 ST set-task $G T1 --status done
t "T1 done->in-progress illegal"            2 ST set-task $G T1 --status in-progress
t "T1 done->in-progress at 3.3 illegal"     2 ST set-task $G T1 --status in-progress --step 3.3
t "T1 done->in-progress at 4.7 (rework)"    0 ST set-task $G T1 --status in-progress --step 4.7
eq "rework sets .step 4.7" "$(step 003-gamma)" 4.7
t "T1 back to done"                         0 ST set-task $G T1 --status done
t "T2 pending->done still illegal at 4.7"   2 ST set-task $G T2 --status done --step 4.7
eq "T1 capability is provisional" "$(yq --front-matter=extract '.tasks[0].capability' "$R/$G/tasks.md")" CAP-NEW-example
t "capability without --step"         2 ST set-task $G T1 --capability CAP-042
t "capability at 5.1 illegal"         2 ST set-task $G T1 --capability CAP-042 --step 5.1
t "capability bad id CAP-12"                1 ST set-task $G T1 --capability CAP-12 --step 5.3
t "capability bad id CAP-NEW-Bad"           1 ST set-task $G T1 --capability CAP-NEW-Bad --step 5.3
t "provisional -> provisional illegal"      2 ST set-task $G T1 --capability CAP-NEW-other --step 5.3
t "provisional -> CAP-042 at 5.3"     0 ST set-task $G T1 --capability CAP-042 --step 5.3
eq "T1 capability rewritten" "$(yq --front-matter=extract '.tasks[0].capability' "$R/$G/tasks.md")" CAP-042
eq ".step = 5.3" "$(step 003-gamma)" 5.3
t "same capability again ok"                0 ST set-task $G T1 --capability CAP-042 --step 5.3
t "assigned -> other assigned illegal"      2 ST set-task $G T1 --capability CAP-043 --step 5.3
t "--capability refused in status mode"     1 ST status $G in-review --step 3.11 --capability CAP-001
t "unknown task status"                     1 ST set-task $G T2 --status review
t "unknown task id"                         1 ST set-task $G T9 --status in-progress
t "bad task id"                             1 ST set-task $G task1 --status in-progress
t "--blocked refused in set-task"           1 ST set-task $G T2 --status blocked --blocked x
t "--status refused in status mode"         1 ST status $G in-review --step 3.11 --status done
yq --front-matter=process -i '.tasks[1].capability="nope"' "$R/$G/tasks.md"
before=$(shasum "$R/$G/tasks.md")
t "invalid tasks.md -> write refused"       1 ST set-task $G T2 --status in-progress
eq "tasks.md unchanged after refusal" "$(shasum "$R/$G/tasks.md")" "$before"
err=$(ST set-task $G T2 --status in-progress 2>&1 >/dev/null)
check "a rejection keeps the schema-validator message" 'grep -q "^status-transition.sh: refusing to write .*tasks.md: the result fails the tasks.md schema validator" <<<"$err"' "$err"
check "a rejection carries no yq error text" '! grep -q "Error:" <<<"$err"' "$err"
yq --front-matter=process -i '.tasks[1].capability="CAP-001"' "$R/$G/tasks.md"

# A yq that fails only the validator call, the one expression that names touches_core, as a broken validator would.
mkdir -p "$F/failing-validator-yq"
cat >"$F/failing-validator-yq/yq" <<EOF
#!/usr/bin/env bash
case "\$*" in *touches_core*) echo "Error: simulated validator failure" >&2; exit 1 ;; esac
exec "$(command -v yq)" "\$@"
EOF
chmod +x "$F/failing-validator-yq/yq"
tasks_before=$(shasum "$R/$G/tasks.md")
step_before=$(cat "$R/$G/.step")
err=$(PATH="$F/failing-validator-yq:$PATH" ST set-task $G T2 --status in-progress --step 3.9 2>&1 >/dev/null); rc=$?
eq "a validator yq cannot run exits 1" "$rc" 1
check "a validator error reports yq's diagnostic" 'grep -q "simulated validator failure" <<<"$err"' "$err"
eq "a validator error leaves tasks.md byte-identical" "$(shasum "$R/$G/tasks.md")" "$tasks_before"
eq "a validator error leaves .step unchanged" "$(cat "$R/$G/.step")" "$step_before"
t "a validator error leaves no tasks.md copy" 1 bash -c "ls '$R/$G' | grep -q 'tasks.md\.'"
# A validator that runs but prints neither true nor false is broken too, not a rejection.
mkdir -p "$F/non-boolean-validator-yq"
cat >"$F/non-boolean-validator-yq/yq" <<EOF
#!/usr/bin/env bash
case "\$*" in *touches_core*) echo "null"; exit 0 ;; esac
exec "$(command -v yq)" "\$@"
EOF
chmod +x "$F/non-boolean-validator-yq/yq"
err=$(PATH="$F/non-boolean-validator-yq:$PATH" ST set-task $G T2 --status in-progress 2>&1 >/dev/null); rc=$?
eq "a non-boolean validator result exits 1" "$rc" 1
check "a non-boolean validator result is reported as a validator error" 'grep -q "cannot run the tasks.md schema validator.*: null$" <<<"$err"' "$err"
eq "a non-boolean validator result leaves tasks.md byte-identical" "$(shasum "$R/$G/tasks.md")" "$tasks_before"
for c in CAP-007 CAP-NEW-guest-checkout CAP-1234 CAP-NEW-x; do
  yq --front-matter=process -i ".tasks[1].capability=\"$c\"" "$R/$G/tasks.md"
  t "capability $c passes validator"     0 ST set-task $G T2 --work-type backend
done
for c in CAP-12 CAP-NEW-Bad CAP-NEW- CAP-NEW-a--b cap-001; do
  yq --front-matter=process -i ".tasks[1].capability=\"$c\"" "$R/$G/tasks.md"
  t "capability $c fails validator"      1 ST set-task $G T2 --work-type backend
done
yq --front-matter=process -i '.tasks[1].capability="CAP-001"' "$R/$G/tasks.md"
t "set-task from worktree"                  0 ST set-task $G T2 --status in-progress --cwd "$WT"
eq "worktree set-task wrote main" "$(yq --front-matter=extract '.tasks[1].status' "$R/$G/tasks.md")" in-progress
t "set-task on done spec illegal"           2 ST set-task $A T2 --status in-progress
t "tasks.md body preserved"                 0 grep -q '^# Tasks: <feature title>' "$R/$G/tasks.md"
t "no temp files left"                      1 bash -c "ls '$R/$G' | grep -q 'tasks.md\.'"

echo "== split-out and backlog seeding"
K=.workflow/specs/009-kappa
mkdir -p "$R/$K"; cp "$SRC/assets/spec.md" "$R/$K/spec.md"; cp "$R/$A/tasks.md" "$R/$K/tasks.md"
ST status $K draft >/dev/null; ST status $K ready-for-dev --step 0.6 >/dev/null
# The validator in assets/tasks.md ("Read and validate with yq") and TASKS_VALIDATOR in status-transition.sh must stay identical.
asset_validator() { awk '/yq --front-matter=extract -e .$/{f=1; next} f && /^  . \.workflow\/specs/{exit} f' "$SRC/assets/tasks.md" | sed 's/^  //'; }
script_validator() { awk "/^TASKS_VALIDATOR='\$/{f=1; next} f && /^'\$/{exit} f" "$SRC/scripts/status-transition.sh"; }
eq "validator: assets/tasks.md == status-transition.sh" "$(asset_validator | sed 's/[[:space:]]*$//')" "$(script_validator | sed 's/[[:space:]]*$//')"
t "template tasks.md passes validator w/ split-out" 0 yq --front-matter=extract -e "$(script_validator)" "$R/$K/tasks.md"
t "kappa budget block"                      0 ST status $K blocked --step 00.21 --blocked "size budget: 12 tasks > 10"
t "T2 pending->split-out without step"      2 ST set-task $K T2 --status split-out
t "T2 pending->split-out at 2.6 illegal"    2 ST set-task $K T2 --status split-out --step 2.6
t "T2 pending->split-out at 00.29"    0 ST set-task $K T2 --status split-out --step 00.29
eq "T2 split-out written" "$(yq --front-matter=extract '.tasks[1].status' "$R/$K/tasks.md")" split-out
if grep -q '^blocked_from: "ready-for-dev"$' "$R/$K/.step"; then eq "blocked_from kept by split" ok ok; else eq "blocked_from kept by split" bad ok; fi
t "split-out terminal (->pending)"          2 ST set-task $K T2 --status pending --step 00.29
t "split-out terminal (->in-progress)"      2 ST set-task $K T2 --status in-progress --step 3.9
t "kappa T1 pending->in-progress"           0 ST set-task $K T1 --status in-progress
t "in-progress->split-out at 00.29 illegal" 2 ST set-task $K T1 --status split-out --step 00.29
t "kappa resume 00.28"                      0 ST status $K ready-for-dev --step 00.28
cp "$R/$K/tasks.md" "$F/kappa-tasks.md"
yq --front-matter=process -i '.tasks += [{"id":"T3","title":"x","status":"split-out","capability":"CAP-001","depends_on":[],"touches_core":false,"work_type":null,"module":"m","seam":"s"}]' "$R/$K/tasks.md"
yq --front-matter=process -i '.budget = {"max_tasks": 1, "max_changed_files": 30}' "$R/$K/spec.md"
t "budget: split-out tasks not counted"     0 BC --spec-dir $K
out=$(jb --spec-dir $K); eq "task count excludes split-out" "$(jq -r .tasks <<<"$out")" 1
yq --front-matter=process -i '.tasks[2].status = "pending"' "$R/$K/tasks.md"
t "budget: pending counted -> over"         2 BC --spec-dir $K
t "origin: key in spec.md accepted"         0 bash -c "yq --front-matter=process -i '.origin = \".workflow/specs/work-backlog/006-delta-disc-001.md\"' '$R/$K/spec.md' && BC --spec-dir $K >/dev/null; [ \$? -eq 2 ]"
ST step $D 3.4 >/dev/null
t "backlog at origin 3.4 deny (pre-seed)"   2 CW --cwd "$R" --path $WB
sleep 1; mkdir -p "$R/.workflow/specs/010-seeded"; ST step .workflow/specs/010-seeded 0.1.4 >/dev/null
t "backlog at new spec 0.1.4 allow"   0 CW --cwd "$R" --path $WB
t "backlog at 0.1.4 sub-agent deny"         2 CW --cwd "$R" --path $WB --agent impl
sleep 1; ST step $D 3.4 >/dev/null
t "backlog: 0.1.4 no longer newest deny"    2 CW --cwd "$R" --path $WB
ST step $D 5.9 >/dev/null
t "spec.md at 5.9 allow (deferred[])"   0 CW --cwd "$R" --path $D/spec.md

echo "== task bodies, record fields, set-task --pr, set-spec, budget --predicted"
M=.workflow/specs/011-mu
mkdir -p "$R/$M/tasks"; cp "$SRC/assets/spec.md" "$R/$M/spec.md"; cp "$R/$A/tasks.md" "$R/$M/tasks.md"
ST status $M draft >/dev/null
ST step $M 2.5 >/dev/null
t "tasks/T01-x.md at 2.5 allow"             0 CW --cwd "$R" --path $M/tasks/T01-x.md
t "tasks/ nested at 2.5 allow"              0 CW --cwd "$R" --path $M/tasks/sub/T02.md
t "tasks/ at 2.5 sub-agent deny"            2 CW --cwd "$R" --path $M/tasks/T01-x.md --agent impl
ST step $M 0.3.20 >/dev/null
t "tasks/ at 0.3.20 allow"                  0 CW --cwd "$R" --path $M/tasks/T01-x.md
ST step $M 3.3 >/dev/null
t "tasks/ at 3.3 deny"                      2 CW --cwd "$R" --path $M/tasks/T01-x.md
t "TASKS/ upper-case at 3.3 deny"           2 CW --cwd "$R" --path .workflow/specs/011-mu/TASKS/T01-x.md
t "tasks/ only spec class"                  2 CW --cwd "$R" --path $M/tasks/T01-x.md --only spec
t "tasks/ not tier-a"                       0 CW --cwd "$R" --path $M/tasks/T01-x.md --only tier-a
t "look-alike tasks-x/ allow"               0 CW --cwd "$R" --path $M/tasks-x/T01.md
t "look-alike tasks.md.bak allow"           0 CW --cwd "$R" --path $M/tasks.md.bak
t "look-alike src/tasks/ allow"             0 CW --cwd "$R" --path src/tasks/T01.md
t "look-alike specs-x/<s>/tasks/ allow"     0 CW --cwd "$R" --path .workflow/specs-x/011-mu/tasks/T01.md
t "tasks dir itself at 3.3 allow (no file)" 0 CW --cwd "$R" --path $M/tasks
t "dotdot into tasks/ deny"                 2 CW --cwd "$R" --path $M/other/../tasks/T01-x.md
out=$(CW --cwd "$R" --path $M/tasks/T01-x.md 2>&1); check "tasks/ deny names set-task" 'grep -q "set-task" <<<"$out"' "$out"

ST status $M ready-for-dev --step 0.6 >/dev/null; ST status $M in-progress >/dev/null
fm() { yq --front-matter=extract "$1" "$R/$M/tasks.md"; }
t "--pr https url"                          0 ST set-task $M T1 --pr https://github.com/o/r/pull/7 --step 3.16
eq "pr written" "$(fm '.tasks[0].pr')" https://github.com/o/r/pull/7
eq "--pr --step writes .step" "$(step 011-mu)" 3.16
t "--pr not a url"                          1 ST set-task $M T1 --pr notaurl
t "--pr in status mode refused"             1 ST status $M in-progress --pr https://x.y/1
t "--pr replace warns, ok"                  0 ST set-task $M T1 --pr https://gitlab.com/o/r/-/merge_requests/3
t "--pr null clears"                        0 ST set-task $M T1 --pr null
eq "pr cleared" "$(fm '.tasks[0].pr')" null
cp "$R/$M/tasks.md" "$F/mu-tasks.md"
bad_field() { # name yq-assignment
  cp "$F/mu-tasks.md" "$R/$M/tasks.md"
  yq --front-matter=process -i "$2" "$R/$M/tasks.md"
  t "validator rejects $1" 1 ST set-task $M T2 --pr https://x.y/1
}
bad_field "mode auto"            '.tasks[0].mode = "auto"'
bad_field "size.points XL"       '.tasks[0].size.points = "XL"'
bad_field "size.files negative"  '.tasks[0].size.files = -1'
bad_field "size.files string"    '.tasks[0].size.files = "3"'
bad_field "branch pattern"       '.tasks[0].branch = "feature/x"'
bad_field "branch other task id" '.tasks[0].branch = "task/011-mu/T2-demo"'
bad_field "file other task id"   '.tasks[0].file = "tasks/T2-demo.md"'
bad_field "parallel_with id"     '.tasks[0].parallel_with = ["x"]'
bad_field "predicted_files int"  '.tasks[0].predicted_files = [1]'
bad_field "tests empty string"   '.tasks[0].tests = [""]'
bad_field "pr not url"           '.tasks[0].pr = "x"'
good_field() {
  cp "$F/mu-tasks.md" "$R/$M/tasks.md"
  yq --front-matter=process -i "$2" "$R/$M/tasks.md"
  t "validator accepts $1" 0 ST set-task $M T1 --pr null
}
good_field "branch null (light path)" '.tasks[0].branch = null'
good_field "branch unpadded T1"       '.tasks[0].branch = "task/011-mu/T1-demo"'
good_field "mode hitl"                '.tasks[0].mode = "hitl"'
good_field "tests list"               '.tasks[0].tests = ["src/a.test.ts"]'
good_field "legacy record (no task-breakdown keys)" 'del(.tasks[0].file, .tasks[0].branch, .tasks[0].predicted_files, .tasks[0].size, .tasks[0].mode, .tasks[0].parallel_with, .tasks[0].pr)'
cp "$F/mu-tasks.md" "$R/$M/tasks.md"

# set-spec
yq --front-matter=process -i '.status = "ready-for-dev"' "$R/$M/spec.md"
t "set-spec needs a key"                    1 ST set-spec $M --step 1.1
t "set-spec needs --step"                   1 ST set-spec $M --spec-branch spec/011-mu
t "spec_branch missing branch"              1 ST set-spec $M --spec-branch spec/011-mu --step 1.1
git -C "$R" branch spec/011-mu
t "spec_branch wrong name"                  1 ST set-spec $M --spec-branch spec/012-nu --step 1.1
t "spec_branch at 3.1 illegal"              2 ST set-spec $M --spec-branch spec/011-mu --step 3.1
t "spec_branch at 1.1"                      0 ST set-spec $M --spec-branch spec/011-mu --step 1.1
eq "spec_branch written" "$(yq --front-matter=extract .spec_branch "$R/$M/spec.md")" spec/011-mu
eq "status untouched by set-spec" "$(status 011-mu)" ready-for-dev
t "spec_branch at 0.3.20 (same value)"      0 ST set-spec $M --spec-branch spec/011-mu --step 0.3.20
yq --front-matter=process -i '.spec_branch = "spec/011-old"' "$R/$M/spec.md"
t "spec_branch differs from existing"       2 ST set-spec $M --spec-branch spec/011-mu --step 1.1
yq --front-matter=process -i '.spec_branch = "spec/011-mu"' "$R/$M/spec.md"
HEAD_SHA=$(git -C "$R" rev-parse HEAD)
t "impl_base at 1.1 illegal"                2 ST set-spec $M --impl-base HEAD --step 1.1
t "impl_base not a commit"                  1 ST set-spec $M --impl-base deadbeef --step 3.1
FIRST_SHA=$(git -C "$R" rev-list --max-parents=0 HEAD | head -1)
yq --front-matter=process -i ".baseline_revision = \"$HEAD_SHA\"" "$R/$M/spec.md"
if [ "$FIRST_SHA" != "$HEAD_SHA" ]; then
  t "impl_base before baseline refused"     1 ST set-spec $M --impl-base "$FIRST_SHA" --step 3.1
fi
t "impl_base HEAD at 3.1"                   0 ST set-spec $M --impl-base HEAD --step 3.1
eq "impl_base full sha" "$(yq --front-matter=extract .impl_base_revision "$R/$M/spec.md")" "$HEAD_SHA"
eq "set-spec .step 3.1" "$(step 011-mu)" 3.1
t "impl_base same value ok"                 0 ST set-spec $M --impl-base "$HEAD_SHA" --step 3.1
git -C "$R" commit -q --allow-empty -m later
t "impl_base never overwritten"             2 ST set-spec $M --impl-base HEAD --step 3.1
t "--impl-base in set-task refused"         1 ST set-task $M T1 --impl-base HEAD

# budget --predicted
yq --front-matter=process -i '.budget = {"max_tasks": 5, "max_changed_files": 10}' "$R/$M/spec.md"
yq --front-matter=process -i '.tasks[0].size.files = 4 | .tasks[1].size = {"files": 5, "est_lines": 50, "points": "M"}' "$R/$M/tasks.md"
out=$(jb --spec-dir $M --predicted); eq "predicted sum 9" "$(jq -r .changed_files <<<"$out")" 9
eq "predicted basis" "$(jq -r .basis <<<"$out")" predicted
t "predicted within budget"                 0 BC --spec-dir $M --predicted
yq --front-matter=process -i '.tasks[1].size.files = 7' "$R/$M/tasks.md"
t "predicted 11 > 10 -> 2"                  2 BC --spec-dir $M --predicted
out=$(jb --spec-dir $M --predicted); eq "predicted over" "$(jq -c .over <<<"$out")" '["changed_files"]'
yq --front-matter=process -i '.tasks[1].status = "split-out"' "$R/$M/tasks.md"
out=$(jb --spec-dir $M --predicted); eq "predicted skips split-out" "$(jq -r .changed_files <<<"$out")" 4
yq --front-matter=process -i '.tasks[1].status = "pending" | del(.tasks[1].size)' "$R/$M/tasks.md"
t "predicted: record without size -> 1"     1 BC --spec-dir $M --predicted

echo "== JRN-006 (spec 00014): set-task --issue records the task's tracker issue"
cp "$F/mu-tasks.md" "$R/$M/tasks.md"
ISSUE_URL=https://gitlab.com/acme/widget/-/issues/43
t "JRN-006 (spec 00014) set-task --issue with an https URL exits 0" 0 ST set-task $M T1 --issue "$ISSUE_URL"
eq "JRN-006 (spec 00014) set-task --issue records the URL as the task's issue" "$(fm '.tasks[0].issue')" "$ISSUE_URL"
ST set-task $M T1 --issue not-a-url >/dev/null 2>&1; rc=$?
check "JRN-006 (spec 00014) set-task --issue with a non-URL exits 2 and keeps the recorded issue" \
  '[[ $rc == 2 && $(fm ".tasks[0].issue") == "$ISSUE_URL" ]]' "rc=$rc issue=$(fm '.tasks[0].issue')"
ST set-task $M T1 --issue null >/dev/null 2>&1; rc=$?
check "JRN-006 (spec 00014) set-task --issue null exits 0 and clears the issue" '[[ $rc == 0 && $(fm ".tasks[0].issue") == null ]]' \
  "rc=$rc issue=$(fm '.tasks[0].issue')"
cp "$F/mu-tasks.md" "$R/$M/tasks.md"
yq --front-matter=process -i '.tasks[0].issue = "x"' "$R/$M/tasks.md"
t "JRN-006 (spec 00014) the tasks.md validator rejects an issue that is not a URL" 1 ST set-task $M T2 --pr https://x.y/1
cp "$F/mu-tasks.md" "$R/$M/tasks.md"

echo "== tracker issue keys: refused values and the spec.md validator"
t "set-task --issue with a plain http URL exits 2" 2 ST set-task $M T1 --issue http://gitlab.com/acme/widget/-/issues/43
eq "a refused --issue leaves the record without an issue" "$(fm '.tasks[0].issue')" null
t "set-task --issue with a URL holding a space exits 2" 2 ST set-task $M T1 --issue "https://gitlab.com/acme/widget/-/issues/4 3"
t "--issue in status mode refused" 1 ST status $M in-progress --issue "$ISSUE_URL"
t "a task record without an issue key passes the tasks.md validator" 0 ST set-task $M T1 --pr https://x.y/2
cp "$F/mu-tasks.md" "$R/$M/tasks.md"
awk '/yq --front-matter=extract -e .$/ { on = 1; next } on && /^  . \.workflow\/specs/ { exit } on' "$SRC/assets/spec.md" >"$F/spec-validator.yq"
# spec_valid_with NAME YQ-EXPR : runs the spec.md template validator on a copy of the template with YQ-EXPR applied.
spec_valid_with() {
  cp "$SRC/assets/spec.md" "$F/$1.md" && yq --front-matter=process -i "$2" "$F/$1.md" &&
    yq --front-matter=extract -e "$(cat "$F/spec-validator.yq")" "$F/$1.md" >/dev/null 2>&1
}
eq "the spec.md template ships tracker_issue as an empty string" "$(yq --front-matter=extract '.tracker_issue | tag' "$SRC/assets/spec.md")" '!!str'
t "a spec with tracker_issue \"\" passes the spec.md validator" 0 spec_valid_with no-tracker '.tracker_issue = ""'
t "a spec without tracker_issue (written before trackers) passes" 0 spec_valid_with older 'del(.tracker_issue)'
t "a spec with an https tracker_issue passes" 0 spec_valid_with tracked ".tracker_issue = \"$ISSUE_URL\""
t "a spec with a non-URL tracker_issue fails" 1 spec_valid_with not-url '.tracker_issue = "issue 43"'
t "a spec with a plain http tracker_issue fails" 1 spec_valid_with http '.tracker_issue = "http://gitlab.com/acme/widget/-/issues/43"'
t "a spec with a numeric tracker_issue fails" 1 spec_valid_with number '.tracker_issue = 43'

shellcheck_files "shellcheck: scripts under test" "$SRC/scripts/status-transition.sh" "$SRC/scripts/check-write.sh" "$SRC/scripts/budget-check.sh"
finish
