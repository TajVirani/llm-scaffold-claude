#!/usr/bin/env bash
# Suite: status-transition.sh (feature-workflow/scripts): spec status transitions.
# Covers: spec status transitions and the .step marker, blocked/discovered-work paths,
#   blocked -> draft at 00.24 / 00.29 only for the matching blocked_condition, no 3.16 merge while blocked,
#   a fresh clone with no blocked_from, worktree resolution, a merged task reopened at 3.9 / 3.11.
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

echo "== status-transition: spec transitions"
t "draft->draft at 0.1.4 (init)"            0 ST status $A draft
eq ".step after init" "$(step 001-alpha)" 0.1.4
if grep -q '^updated_at: "20[0-9-]*T[0-9:]*Z"$' "$R/$A/.step"; then eq "timestamp UTC format" ok ok; else eq "timestamp UTC format" bad ok; fi
t "draft->in-progress illegal"              2 ST status $A in-progress
t "draft->done illegal"                     2 ST status $A done
t "draft->ready-for-dev without --step"     1 ST status $A ready-for-dev
t "draft->ready-for-dev at 3.1 illegal"     2 ST status $A ready-for-dev --step 3.1
t "draft->ready-for-dev at 0.6"             0 ST status $A ready-for-dev --step 0.6
t "ready->ready now illegal"          2 ST status $A ready-for-dev --step 0.3.20
t "ready->draft without --step"       1 ST status $A draft
t "ready->draft at 0.1.4 illegal"           2 ST status $A draft --step 0.1.4
t "ready->draft at 2.2"               0 ST status $A draft --step 2.2
t "draft->ready again at 0.3.20"            0 ST status $A ready-for-dev --step 0.3.20
t "ready->draft at 2.3"               0 ST status $A draft --step 2.3
t "draft->ready again at 0.6"               0 ST status $A ready-for-dev --step 0.6
t "ready->in-review illegal"                2 ST status $A in-review --step 3.11
t "ready->in-progress (default 3.1)"        0 ST status $A in-progress
eq ".step = 3.1" "$(step 001-alpha)" 3.1
t "in-progress->ready illegal"              2 ST status $A ready-for-dev --step 0.6
t "blocked without --blocked"               1 ST status $A blocked
t "--blocked with non-blocked status"       1 ST status $A in-review --step 3.11 --blocked x
t "in-progress->blocked"                    0 ST status $A blocked --blocked "no profile for work type x"
eq "blocked_condition written" "$(yq --front-matter=extract '.blocked_condition' "$R/$A/spec.md")" "no profile for work type x"
if grep -q '^blocked_from: "in-progress"$' "$R/$A/.step"; then eq "blocked_from recorded" ok ok; else eq "blocked_from recorded" bad ok; fi
t "template validator passes while blocked" 0 yq --front-matter=extract -e '(.status | test("^(draft|ready-for-dev|in-progress|in-review|done|blocked)$")) and ((.baseline_revision | tag) == "!!str") and ((.light_path | tag) == "!!bool") and ((.followup_review_recommended | tag) == "!!bool") and ((.deferred | tag) == "!!seq") and ((.status == "blocked") == ((.blocked_condition // "") != ""))' "$R/$A/spec.md"
t "step-only while blocked"                 0 ST step $A 0.3.7
if grep -q '^blocked_from: "in-progress"$' "$R/$A/.step"; then eq "blocked_from kept by step mode" ok ok; else eq "blocked_from kept by step mode" bad ok; fi
t "blocked->blocked illegal"                2 ST status $A blocked --blocked y
t "blocked->in-review (not prior) illegal"  2 ST status $A in-review --step 3.11
t "blocked->done illegal"                   2 ST status $A done
t "blocked->in-progress (prior)"            0 ST status $A in-progress --step 3.3
eq "blocked_condition removed" "$(yq --front-matter=extract 'has("blocked_condition")' "$R/$A/spec.md")" false
if grep -q blocked_from "$R/$A/.step"; then eq "blocked_from cleared" bad ok; else eq "blocked_from cleared" ok ok; fi
t "in-progress->in-review at 3.14"          0 ST status $A in-review --step 3.14
t "in-review->in-review at 3.11 (rework)"   0 ST status $A in-review --step 3.11
t "in-review->ready now illegal"      2 ST status $A ready-for-dev --step 0.6
t "in-review->draft at 2.2 illegal"         2 ST status $A draft --step 2.2
for n in 4.5 4.6 5.6; do
  t "in-review->draft at $n"          0 ST status $A draft --step $n
  t "draft->ready-for-dev at 0.6"           0 ST status $A ready-for-dev --step 0.6
  t "ready->in-progress"                    0 ST status $A in-progress
  t "in-progress->in-review at 3.11"        0 ST status $A in-review --step 3.11
done
t "in-review->draft at 5.6 (5.5 change requested)" 0 ST status $A draft --step 5.6
t "draft->ready-for-dev at 0.3.20"          0 ST status $A ready-for-dev --step 0.3.20
t "ready->in-progress"                      0 ST status $A in-progress
t "in-progress->in-progress (resume 3.1)"   0 ST status $A in-progress
t "in-progress->in-review at 3.11"          0 ST status $A in-review --step 3.11
t "in-review->done at 5.6 illegal"          2 ST status $A done --step 5.6
t "in-review->blocked (4.7 ceiling)"        0 ST status $A blocked --blocked "rework ceiling" --step 4.7
t "blocked->in-review without step"   1 ST status $A in-review
t "blocked->in-review at 4.7 illegal" 2 ST status $A in-review --step 4.7
t "blocked->in-review at 5.1"         0 ST status $A in-review --step 5.1
eq ".step = 5.1 after unblock" "$(step 001-alpha)" 5.1
t "in-review->done (default 5.7)"           0 ST status $A done
t "template validator passes when done"     0 yq --front-matter=extract -e '(.status == "blocked") == ((.blocked_condition // "") != "")' "$R/$A/spec.md"
t "done->in-review illegal (terminal)"      2 ST status $A in-review --step 3.11
t "done->blocked illegal"                   2 ST status $A blocked --blocked z --step 5.8
t "step on done spec illegal"               2 ST step $A 5.7
t "unknown status"                          1 ST status .workflow/specs/002-beta shipped
t "bad spec dir"                            1 ST status .workflow/specs/beta draft
t "bad node id"                             1 ST step .workflow/specs/002-beta 0.3.x
t "missing spec dir"                        1 ST step .workflow/specs/009-none 0.1.6
t "unknown mode"                            1 ST frob .workflow/specs/002-beta
t "body preserved after edits"              0 diff <(sed -n '/^<!--$/,$p' "$SRC/assets/spec.md") <(sed -n '/^<!--$/,$p' "$R/$A/spec.md")

echo "== status-transition: fresh clone (no blocked_from)"
B=.workflow/specs/002-beta
t "beta draft"                              0 ST status $B draft
t "beta blocked"                            0 ST status $B blocked --blocked "intent gap"
unmark 002-beta
t "blocked, no marker, no --step"           1 ST status $B draft
t "blocked, no marker, --step -> draft"     0 ST status $B draft --step 0.3.8
t "beta blocked again"                      0 ST status $B blocked --blocked "x" --step 0.3.8
unmark 002-beta
t "unknown from -> in-review at 3.11 illegal" 2 ST status $B in-review --step 3.11
t "unknown from -> in-review at 5.1 (warn)" 0 ST status $B in-review --step 5.1
yq --front-matter=process -i '.status="draft"' "$R/$B/spec.md"

echo "== status-transition: worktree resolution"
t "step from worktree cwd"                  0 ST step $B 0.1.6 --cwd "$WT"
eq "marker written in main checkout" "$(step 002-beta)" 0.1.6
if [[ -e "$WT/$B/.step" ]]; then eq "no marker in worktree" bad ok; else eq "no marker in worktree" ok ok; fi
t "status from worktree (cd)"               0 bash -c "cd '$WT' && ST status $B ready-for-dev --step 0.3.20"
eq "main spec.md updated" "$(status 002-beta)" ready-for-dev
eq "worktree spec.md untouched" "$(yq --front-matter=extract .status "$WT/$B/spec.md")" draft
t "absolute spec dir (worktree path)"       0 ST step "$WT/$B" 0.3.19 --cwd "$WT"
eq "abs path maps to main" "$(step 002-beta)" 0.3.19
t "not a git repo"                          1 ST step $B 0.1.6 --cwd /

echo "== status-transition: discovered work and size budget"
D=.workflow/specs/006-delta
mkdir -p "$R/$D"; cp "$SRC/assets/spec.md" "$R/$D/spec.md"; cp "$R/$A/tasks.md" "$R/$D/tasks.md"
t "delta init"                              0 ST status $D draft
t "delta ready at 0.6"                      0 ST status $D ready-for-dev --step 0.6
t "delta in-progress"                       0 ST status $D in-progress
for n in 00.24 00.29 0.3.8 2.2 4.5; do t "in-progress->draft at $n illegal" 2 ST status $D draft --step $n; done
t "00.21 free-text condition refused"       1 ST status $D blocked --step 00.21 --blocked "found a bug"
t "00.21 empty slug refused"                1 ST status $D blocked --step 00.21 --blocked "discovered work: "
t "00.21 discovered work"                   0 ST status $D blocked --step 00.21 --blocked "discovered work: csv-export"
eq "00.21 condition" "$(yq --front-matter=extract '.blocked_condition' "$R/$D/spec.md")" "discovered work: csv-export"
eq ".step = 00.21" "$(step 006-delta)" 00.21
if grep -q '^blocked_from: "in-progress"$' "$R/$D/.step"; then eq "00.21 blocked_from" ok ok; else eq "00.21 blocked_from" bad ok; fi
for n in 00.22 00.23 00.25 00.26 00.27; do t "step-only $n while blocked" 0 ST step $D $n; done
if grep -q '^blocked_from: "in-progress"$' "$R/$D/.step"; then eq "blocked_from kept through 00.22-00.27" ok ok; else eq "blocked_from kept through 00.22-00.27" bad ok; fi
t "blocked->draft at 3.3 illegal (from in-progress)" 2 ST status $D draft --step 3.3
t "blocked->ready at 00.28 illegal"         2 ST status $D ready-for-dev --step 00.28
t "blocked->in-progress at 00.28 (resume)"  0 ST status $D in-progress --step 00.28
eq ".step = 00.28" "$(step 006-delta)" 00.28
eq "condition removed at 00.28" "$(yq --front-matter=extract 'has("blocked_condition")' "$R/$D/spec.md")" false
t "00.21 size budget"                       0 ST status $D blocked --step 00.21 --blocked "size budget: changed files 34 > 30"
t "step 00.29 while blocked"                0 ST step $D 00.29
t "spec.md write at 00.29 allow (budget)"   0 CW --cwd "$R" --path $D/spec.md
t "blocked(size budget)->draft at 00.24 refused" 2 ST status $D draft --step 00.24
t "00.24 refusal names the condition"       0 bash -c "ST status $D draft --step 00.24 2>&1 | grep -q \"discovered work: \""
eq "still blocked after refused 00.24" "$(status 006-delta)" blocked
t "blocked->draft at 00.29 (re-scope)"      0 ST status $D draft --step 00.29
eq "status draft after re-scope" "$(status 006-delta)" draft
t "draft->draft at 00.24 illegal (not blocked)" 2 ST status $D draft --step 00.24
t "delta ready again"                       0 ST status $D ready-for-dev --step 0.6
t "ready->blocked at 2.6 budget"            0 ST status $D blocked --step 00.21 --blocked "size budget: 12 tasks > 10"
if grep -q '^blocked_from: "ready-for-dev"$' "$R/$D/.step"; then eq "blocked_from ready-for-dev" ok ok; else eq "blocked_from ready-for-dev" bad ok; fi
t "blocked->ready at 00.28 (approve)"       0 ST status $D ready-for-dev --step 00.28
t "delta in-progress"                       0 ST status $D in-progress
t "00.21 again"                             0 ST status $D blocked --step 00.21 --blocked "discovered work: auth-bug"
t "blocked(discovered work)->draft at 00.29 refused" 2 ST status $D draft --step 00.29
t "00.29 refusal names the condition"       0 bash -c "ST status $D draft --step 00.29 2>&1 | grep -q \"size budget: \""
t "blocked->draft at 00.24 (to discovery)"  0 ST status $D draft --step 00.24
eq ".step = 00.24" "$(step 006-delta)" 00.24
if grep -q blocked_from "$R/$D/.step"; then eq "blocked_from cleared at 00.24" bad ok; else eq "blocked_from cleared at 00.24" ok ok; fi
t "delta ready"                             0 ST status $D ready-for-dev --step 0.6
t "delta in-progress"                       0 ST status $D in-progress
t "delta in-review"                         0 ST status $D in-review --step 3.11
t "in-review->blocked at 00.21"             0 ST status $D blocked --step 00.21 --blocked "discovered work: review-find"
t "blocked(in-review)->in-progress 00.28 illegal" 2 ST status $D in-progress --step 00.28
t "blocked(in-review)->in-review at 4.7 illegal"  2 ST status $D in-review --step 4.7
t "blocked(in-review)->in-review at 00.28"  0 ST status $D in-review --step 00.28
t "in-review->blocked (4.7 ceiling)"        0 ST status $D blocked --step 4.7 --blocked "rework ceiling"
for n in 00.24 00.29; do t "blocked(rework ceiling)->draft at $n refused" 2 ST status $D draft --step $n; done
t "blocked(in-review)->in-review at 5.1"    0 ST status $D in-review --step 5.1
t "in-review->blocked 00.21"                0 ST status $D blocked --step 00.21 --blocked "discovered work: x"
t "blocked(in-review)->draft at 00.24"      0 ST status $D draft --step 00.24
t "delta ready"                             0 ST status $D ready-for-dev --step 0.6
t "delta in-progress"                       0 ST status $D in-progress
for n in 00.21 00.22 00.23 00.24 00.25 00.26 00.27 00.28 00.29 2.6 3.15 3.16 5.9; do t "step-only accepts $n" 0 ST step $D $n; eq "marker $n" "$(step 006-delta)" "$n"; done
t "fresh clone: blocked"                    0 ST status $D blocked --step 00.21 --blocked "discovered work: y"
unmark 006-delta
t "fresh clone: in-review at 00.28 (warn)"  0 ST status $D in-review --step 00.28
yq --front-matter=process -i '.status="in-progress"' "$R/$D/spec.md"
t "status on .workflow/specs/work-backlog refused"    1 ST step .workflow/specs/work-backlog 00.26

echo "== status-transition: set-task reopening a merged task, and 3.16"
t "T1 pending->in-progress"                 0 ST set-task $D T1 --status in-progress --step 3.1
t "T1 done at 3.16 (wave merge)"            0 ST set-task $D T1 --status done --step 3.16
eq ".step = 3.16" "$(step 006-delta)" 3.16
for g in 3.9 3.11; do
  t "T1 done->in-progress at $g"      0 ST set-task $D T1 --status in-progress --step $g
  t "T1 back to done"                       0 ST set-task $D T1 --status done
  t "T1 done->blocked at $g"          0 ST set-task $D T1 --status blocked --step $g
  t "T1 blocked->in-progress"               0 ST set-task $D T1 --status in-progress
  t "T1 done again"                         0 ST set-task $D T1 --status done --step 3.16
done
t "T1 done->in-progress at 4.7 still ok"    0 ST set-task $D T1 --status in-progress --step 4.7
t "T1 done (no --step)"                     0 ST set-task $D T1 --status done
t "T1 done->blocked at 4.7 illegal"         2 ST set-task $D T1 --status blocked --step 4.7
t "T1 done->blocked without step illegal"   2 ST set-task $D T1 --status blocked
t "T1 done->in-progress at 3.10 illegal"    2 ST set-task $D T1 --status in-progress --step 3.10
t "T1 done->pending illegal"                2 ST set-task $D T1 --status pending --step 3.9

echo "== coordinator contract: blocked mid-wave"
H=.workflow/specs/008-eta
mkdir -p "$R/$H"; cp "$SRC/assets/spec.md" "$R/$H/spec.md"; cp "$R/$A/tasks.md" "$R/$H/tasks.md"
ST status $H draft >/dev/null; ST status $H ready-for-dev --step 0.6 >/dev/null; ST status $H in-progress >/dev/null
t "eta T1 in-progress"                      0 ST set-task $H T1 --status in-progress --step 3.1
t "eta 00.21 mid-wave"                      0 ST status $H blocked --step 00.21 --blocked "discovered work: mid-wave"
t "set-task done at 3.16 while blocked refused" 2 ST set-task $H T1 --status done --step 3.16
t "3.16 refusal says the merge waits"       0 bash -c "ST set-task $H T1 --status done --step 3.16 2>&1 | grep -q 'merge waits'"
eq "T1 not marked done" "$(yq --front-matter=extract '.tasks[0].status' "$R/$H/tasks.md")" in-progress
eq ".step left at 00.21" "$(step 008-eta)" 00.21
eq "spec still blocked" "$(status 008-eta)" blocked
t "set-task gate relaunch while blocked"    0 ST set-task $H T1 --status in-progress --step 3.7
if grep -q '^blocked_from: "in-progress"$' "$R/$H/.step"; then eq "blocked_from kept by set-task --step" ok ok; else eq "blocked_from kept by set-task --step" bad ok; fi
for n in 00.26 00.29; do t "step $n while blocked" 0 ST step $H $n; if grep -q '^blocked_from: "in-progress"$' "$R/$H/.step"; then eq "blocked_from kept at $n" ok ok; else eq "blocked_from kept at $n" bad ok; fi; done
t "eta resume 00.28"                        0 ST status $H in-progress --step 00.28
t "set-task done at 3.16 after unblock"     0 ST set-task $H T1 --status done --step 3.16
t "eta in-review"                           0 ST status $H in-review --step 3.11
t "eta 00.21 at 4.4 (review)"               0 ST status $H blocked --step 00.21 --blocked "discovered work: from-review"
t "eta in-review at 00.28"                  0 ST status $H in-review --step 00.28
ST status $H draft --step 4.5 >/dev/null; ST status $H ready-for-dev --step 0.6 >/dev/null
t "eta budget block from ready (2.6)"       0 ST status $H blocked --step 00.21 --blocked "size budget: 12 tasks > 10"
t "size budget re-scope via 00.24 refused"  2 ST status $H draft --step 00.24
t "re-scope via draft --step 00.29 (2.6)"   0 ST status $H draft --step 00.29
ST status $H ready-for-dev --step 0.6 >/dev/null; ST status $H in-progress >/dev/null
t "eta budget block at 3.15"                0 ST status $H blocked --step 00.21 --blocked "size budget: changed files 31 > 30"
t "re-scope via draft --step 00.29 (3.15)"  0 ST status $H draft --step 00.29
eq "eta draft" "$(status 008-eta)" draft

shellcheck_files "shellcheck: scripts under test" "$SRC/scripts/status-transition.sh" "$SRC/scripts/check-write.sh"
finish
