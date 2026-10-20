#!/usr/bin/env bash
# Suite: status-transition.sh, check-write.sh and budget-check.sh (feature-workflow/scripts).
# Covers: spec/task status transitions and the .step marker, blocked/discovered-work paths,
#   blocked -> draft at 00.24 / 00.29 only for the matching blocked_condition, no 3.16 merge while blocked,
#   worktree resolution, check-write rules per path class (Tier A/B incl. the glossary and Tier A steps, spec.md, tasks.md, work-backlog), size budget.
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
yq --front-matter=process -i '.tasks[1].capability="CAP-001"' "$R/$G/tasks.md"
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

echo "== check-write: Tier B and marker"
t ".workflow/cache main deny"                    2 CW --cwd "$R" --path .workflow/cache/modules.md
t ".workflow/cache abs deny"                     2 CW --cwd "$R" --path "$R/.workflow/cache/x/y.md"
t ".workflow/cache via .. deny"                  2 CW --cwd "$R" --path src/../.workflow/cache/flows.md
t ".Workflow/Cache case deny"                    2 CW --cwd "$R" --path .Workflow/Cache/a.md
t ".workflow/cache in worktree deny"             2 CW --cwd "$WT" --path "$WT/.workflow/cache/a.md" --agent abc
t ".workflow/cache via /tmp symlink path"        2 CW --cwd "$R" --path "${R#/private}/.workflow/cache/a.md"
t "--only spec ignores tier-b"              0 CW --cwd "$R" --path .workflow/cache/a.md --only spec
t "--only tier-b denies tier-b"             2 CW --cwd "$R" --path .workflow/cache/a.md --only tier-b
t "docs/cachex not tier-b"                  0 CW --cwd "$R" --path docs/cachex.md
t ".step deny (main)"                       2 CW --cwd "$R" --path .workflow/specs/002-beta/.step
t "unguarded src file"                      0 CW --cwd "$R" --path src/app.ts
t "unguarded, sub-agent"                    0 CW --cwd "$WT" --path "$WT/src/app.ts" --agent a1
t "outside repo"                            0 CW --cwd "$R" --path /etc/hosts
t "missing --path"                          1 CW --cwd "$R"
t "bad --only"                              1 CW --cwd "$R" --path x --only foo

echo "== check-write: .workflow/ prefixes"
# A sub-agent write is denied on every guarded path before any step check, so --agent isolates classification.
for p in .workflow/rules.md .workflow/capabilities.md .workflow/decisions .workflow/decisions/adr/0001-x.md \
  .workflow/profiles/web.md .workflow/GLOSSARY.md .workflow/GLOSSARY-MAP.md .workflow/cache .workflow/cache/modules.md \
  .workflow/specs/001-alpha/spec.md .workflow/specs/001-alpha/tasks.md .workflow/specs/work-backlog/001-alpha-disc-001.md \
  .WORKFLOW/Rules.md .workflow/Profiles/Web.md; do
  t "guarded: $p (sub-agent)"                2 CW --cwd "$R" --path "$p" --agent a1
done
t "guarded: .workflow/specs/*/.step (main)" 2 CW --cwd "$R" --path .workflow/specs/001-alpha/.step
for p in .workflow/specs-x/001-alpha/spec.md .workflow/specsx/001-alpha/tasks.md .workflow/cache2/a.md .workflow/cache.md \
  .workflow/profiles-old/web.md .workflow/profilesx.md .workflow/decisions-old/a.md .workflow/rules.md.bak .workflow/rules.mdx \
  .workflow/sub/rules.md .workflow/capabilities.md.orig .workflow/specs/001-alpha/sub/spec.md .workflow/specs/work-backlog-x/a.md \
  .workflow/.cache-staging/modules.md .workflow/.handoff/001-alpha.md .workflow/.standards-staging/baseline.md \
  workflow/specs/001-alpha/spec.md x.workflow/cache/a.md pkg/.workflow/cache/a.md pkg/.workflow/rules.md; do
  t "look-alike not guarded: $p"             0 CW --cwd "$R" --path "$p" --agent a1
done
t "look-alike .step not guarded"            0 CW --cwd "$R" --path .workflow/specs-x/001-alpha/.step
for p in docs/cache/modules.md docs/rules.md docs/capabilities.md docs/decisions/adr/0001-x.md profiles/web.md \
  specs/001-alpha/spec.md specs/001-alpha/tasks.md specs/work-backlog/001-alpha-disc-001.md; do
  t "old root path not special: $p"         0 CW --cwd "$R" --path "$p" --agent a1
done
t "old root .step not special"              0 CW --cwd "$R" --path specs/001-alpha/.step

echo "== check-write: spec.md"
ST step $B 0.3.19 >/dev/null
t "spec.md at 0.3.19 allow"                 0 CW --cwd "$R" --path .workflow/specs/002-beta/spec.md
t "spec.md sub-agent deny"                  2 CW --cwd "$R" --path .workflow/specs/002-beta/spec.md --agent a1
t "spec.md from worktree, main session"     0 CW --cwd "$WT" --path "$WT/.workflow/specs/002-beta/spec.md"
t "spec.md worktree sub-agent deny"         2 CW --cwd "$WT" --path "$WT/.workflow/specs/002-beta/spec.md" --agent a1
ST step $B 0.3.7 >/dev/null
t "spec.md at 0.3.7 deny"                   2 CW --cwd "$R" --path .workflow/specs/002-beta/spec.md
for s in 1.2 2.6 3.3 3.11 3.15 3.16 4.5 4.7 5.7 00.19 00.21 00.26 00.28; do ST step $B $s >/dev/null; t "spec.md at $s deny" 2 CW --cwd "$R" --path .workflow/specs/002-beta/spec.md; done
for s in 0.1.4 0.3.17 0.3.20 1.1 2.5 3.1 3.14 4.6 4.8 5.3 5.9 00.29; do ST step $B $s >/dev/null; t "spec.md at $s allow (widened)" 0 CW --cwd "$R" --path .workflow/specs/002-beta/spec.md; done
for s in 0.1.6 0.5.1 5.1; do ST step $B $s >/dev/null; t "spec.md at $s allow" 0 CW --cwd "$R" --path .workflow/specs/002-beta/spec.md; done
t "spec.md of feature without marker deny"  2 CW --cwd "$R" --path .workflow/specs/004-new/spec.md
cp "$R/$B/spec.md" "$F/proposed-ok.md"; echo "more" >> "$F/proposed-ok.md"
t "--proposed body edit allow"              0 CW --cwd "$R" --path .workflow/specs/002-beta/spec.md --proposed "$F/proposed-ok.md"
cp "$R/$B/spec.md" "$F/proposed-bad.md"; yq --front-matter=process -i '.status="done"' "$F/proposed-bad.md"
t "--proposed status edit deny"             2 CW --cwd "$R" --path .workflow/specs/002-beta/spec.md --proposed "$F/proposed-bad.md"
cp "$R/$B/spec.md" "$F/proposed-bc.md"; yq --front-matter=process -i '.blocked_condition="x"' "$F/proposed-bc.md"
t "--proposed blocked_condition edit deny"  2 CW --cwd "$R" --path .workflow/specs/002-beta/spec.md --proposed "$F/proposed-bc.md"

echo "== spec.md creation at 0.1.4"
mkdir -p "$R/.workflow/specs/005-new"
t "step 0.1.6 before spec.md exists refused" 1 ST step .workflow/specs/005-new 0.1.6
t "step 0.1.4 before spec.md exists"        0 ST step .workflow/specs/005-new 0.1.4
eq "marker 0.1.4 written" "$(step 005-new)" 0.1.4
t "step 0.1.4 needs the 0.1.3 folder"       1 ST step .workflow/specs/006-nofolder 0.1.4
cp "$SRC/assets/spec.md" "$F/new-spec.md"
t "create spec.md at 0.1.4 (Write)"         0 CW --cwd "$R" --path .workflow/specs/005-new/spec.md --proposed "$F/new-spec.md"
cp "$SRC/assets/spec.md" "$F/new-spec-bad.md"; yq --front-matter=process -i '.status="ready-for-dev"' "$F/new-spec-bad.md"
t "create spec.md with non-draft status deny" 2 CW --cwd "$R" --path .workflow/specs/005-new/spec.md --proposed "$F/new-spec-bad.md"
t "create spec.md sub-agent deny"           2 CW --cwd "$R" --path .workflow/specs/005-new/spec.md --agent a1
cp "$SRC/assets/spec.md" "$R/.workflow/specs/005-new/spec.md"
t "status draft after creation"             0 ST status .workflow/specs/005-new draft
yq --front-matter=process -i '.status="done"' "$R/.workflow/specs/005-new/spec.md"

echo "== check-write: tasks.md (set-task is the only record writer)"
for s in 2.5 0.3.20; do ST step $B $s >/dev/null; t "tasks.md at $s allow" 0 CW --cwd "$R" --path .workflow/specs/002-beta/tasks.md; t "tasks.md at $s sub-agent deny" 2 CW --cwd "$WT" --path "$WT/.workflow/specs/002-beta/tasks.md" --agent impl; done
t "tasks.md --only spec covers it"          0 CW --cwd "$R" --path .workflow/specs/002-beta/tasks.md --only spec
for s in 3.1 0.6 2.4 4.7 0.1.6; do ST step $B $s >/dev/null; t "tasks.md at $s deny" 2 CW --cwd "$R" --path .workflow/specs/002-beta/tasks.md; done
t "tasks.md --only spec denies at 3.1"      2 CW --cwd "$R" --path .workflow/specs/002-beta/tasks.md --only spec
t "tasks.md --only tier-a ignores it"       0 CW --cwd "$R" --path .workflow/specs/002-beta/tasks.md --only tier-a
t "tasks.md deny points at set-task"        0 bash -c "CW --cwd '$R' --path .workflow/specs/002-beta/tasks.md 2>&1 | grep -q 'status-transition.sh set-task'"
t "tasks.md no marker deny"                 2 CW --cwd "$R" --path .workflow/specs/007-x/tasks.md
t "tasks.md from worktree, main, at 3.1 deny" 2 CW --cwd "$WT" --path "$WT/.workflow/specs/002-beta/tasks.md"
t "set-task (Bash) unaffected by guard"     0 ST set-task $G T2 --status in-progress

echo "== check-write: Tier A"
sleep 1; ST step $B 5.1 >/dev/null
t "GLOSSARY at 5.1 deny (newest marker)"    2 CW --cwd "$R" --path .workflow/GLOSSARY.md
for s in 0.2.3 0.3.15 0.4.3 5.3; do ST step $B $s >/dev/null; t ".workflow/GLOSSARY.md at $s allow" 0 CW --cwd "$R" --path .workflow/GLOSSARY.md; t "deep .workflow/GLOSSARY-MAP.md at $s allow" 0 CW --cwd "$R" --path a/GLOSSARY-MAP.md; done
for s in 0.3.7 5.7; do ST step $B $s >/dev/null; t ".workflow/GLOSSARY.md at $s deny" 2 CW --cwd "$R" --path .workflow/GLOSSARY.md; t "src/x/GLOSSARY.md at $s deny" 2 CW --cwd "$R" --path src/x/GLOSSARY.md; t ".workflow/rules.md at $s allow" 0 CW --cwd "$R" --path .workflow/rules.md; t "adr at $s allow" 0 CW --cwd "$R" --path .workflow/decisions/adr/0002-y.md; t "existing profile edit at $s deny" 2 CW --cwd "$R" --path .workflow/profiles/frontend.md; t "new profile at $s deny" 2 CW --cwd "$R" --path .workflow/profiles/new.md; done
for s in 0.2.3 0.3.15 0.4.3; do ST step $B $s >/dev/null; t "existing profile edit at $s deny" 2 CW --cwd "$R" --path .workflow/profiles/frontend.md; t "new profile at $s deny" 2 CW --cwd "$R" --path .workflow/profiles/new.md; done
ST step $B 5.3 >/dev/null
t "existing profile edit at 5.3 allow" 0 CW --cwd "$R" --path .workflow/profiles/frontend.md
t "new profile at 5.3 allow"          0 CW --cwd "$R" --path .workflow/profiles/new.md
t "existing profile at 5.3 sub-agent deny"  2 CW --cwd "$WT" --path "$WT/.workflow/profiles/frontend.md" --agent impl
for s in 0.2.3 0.3.15 0.4.3; do
  ST step $B $s >/dev/null
  for p in .workflow/capabilities.md .workflow/rules.md .workflow/decisions/adr/0002-y.md; do t "$p at $s deny" 2 CW --cwd "$R" --path $p; done
done
t "deny message lists 0.3.7 5.3 5.7"    0 bash -c "CW --cwd '$R' --path .workflow/rules.md 2>&1 | grep -q '0.3.7 5.3 5.7'"
for s in 0.3.7 5.3 5.7; do
  ST step $B $s >/dev/null
  for p in .workflow/capabilities.md .workflow/rules.md .workflow/decisions/adr/0002-y.md; do t "$p at $s allow" 0 CW --cwd "$R" --path $p; done
done
for s in 0.2.2 0.3.14 0.4.2 3.1 5.2 00.19; do ST step $B $s >/dev/null; t ".workflow/GLOSSARY.md at $s deny" 2 CW --cwd "$R" --path .workflow/GLOSSARY.md; done
ST step $B 5.3 >/dev/null
for p in .workflow/capabilities.md .workflow/rules.md .workflow/decisions/adr/0001-x.md .workflow/decisions/pitfalls.md .workflow/profiles/frontend.md .workflow/GLOSSARY-MAP.md src/billing/GLOSSARY.md src/billing/GLOSSARY-MAP.md .agents/skills/project-setup/assets/GLOSSARY.md; do
  t "Tier A $p sub-agent deny" 2 CW --cwd "$WT" --path "$WT/$p" --agent impl
  t "Tier A $p main at 5.3 allow" 0 CW --cwd "$R" --path "$p"
done
ST step $B 3.1 >/dev/null
ST step $B 00.19 >/dev/null
t "new profile at 00.19 allow"        0 CW --cwd "$R" --path .workflow/profiles/backend.md
t "new nested profile at 00.19 allow"       0 CW --cwd "$WT" --path "$WT/.workflow/profiles/sub/new.md"
t "existing profile at 00.19 deny"    2 CW --cwd "$R" --path .workflow/profiles/frontend.md
t "deny message names 5.3"                  0 bash -c "CW --cwd '$R' --path .workflow/profiles/frontend.md 2>&1 | grep -q '5.3'"
t "new profile at 00.19 sub-agent deny"     2 CW --cwd "$WT" --path "$WT/.workflow/profiles/backend.md" --agent impl
t "rules.md at 00.19 deny"                  2 CW --cwd "$R" --path .workflow/rules.md
t ".workflow/GLOSSARY.md at 00.19 deny"               2 CW --cwd "$R" --path .workflow/GLOSSARY.md
ST step $B 3.1 >/dev/null
t "new profile at 3.1 deny"                 2 CW --cwd "$R" --path .workflow/profiles/backend.md
t "deep .workflow/GLOSSARY.md at 3.1 deny"      2 CW --cwd "$R" --path src/billing/GLOSSARY.md
t "deep .workflow/GLOSSARY-MAP.md at 3.1 deny"  2 CW --cwd "$R" --path a/b/c/GLOSSARY-MAP.md
t "deny message points at proposals.md"     0 bash -c "CW --cwd '$R' --path .workflow/rules.md 2>&1 | grep -q '.workflow/specs/002-beta/proposals.md'"
t "--only tier-a ignores spec.md"           0 CW --cwd "$R" --path .workflow/specs/002-beta/spec.md --only tier-a
t "--only spec ignores GLOSSARY"            0 CW --cwd "$R" --path .workflow/GLOSSARY.md --only spec
sleep 1; ST step $G 0.3.15 >/dev/null
t "newest marker (gamma 0.3.15) wins"       0 CW --cwd "$R" --path .workflow/GLOSSARY.md
unmark 003-gamma; unmark 002-beta
t "in flight but no markers deny"           2 CW --cwd "$R" --path .workflow/GLOSSARY.md
yq --front-matter=process -i '.status="done"' "$R/$B/spec.md"; yq --front-matter=process -i '.status="done"' "$R/$G/spec.md"
t "no feature in flight, main allow"        0 CW --cwd "$R" --path .workflow/rules.md
t "no feature in flight, profile edit allow" 0 CW --cwd "$R" --path .workflow/profiles/frontend.md
t "no feature in flight, new profile allow" 0 CW --cwd "$R" --path .workflow/profiles/other.md
t "no feature in flight, sub-agent deny"    2 CW --cwd "$R" --path .workflow/rules.md --agent x
t "empty --agent still counts as sub-agent" 2 CW --cwd "$R" --path .workflow/rules.md --agent ""
t "yq missing -> clear error (check-write)" 1 env PATH=/usr/bin:/bin /bin/bash "$SRC/scripts/check-write.sh" --cwd "$R" --path .workflow/rules.md
t "yq missing -> clear error (status-tr.)"  1 env PATH=/usr/bin:/bin /bin/bash "$SRC/scripts/status-transition.sh" step $B 0.1.6


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

echo "== check-write: .workflow/specs/work-backlog"
WB=.workflow/specs/work-backlog/006-delta-disc-001.md
ST step $D 00.26 >/dev/null
t "backlog item at 00.26 allow"             0 CW --cwd "$R" --path $WB
t "backlog item --only spec at 00.26 allow" 0 CW --cwd "$R" --path $WB --only spec
t "backlog --only tier-a ignores it"        0 CW --cwd "$R" --path $WB --only tier-a
t "backlog item sub-agent deny"             2 CW --cwd "$R" --path $WB --agent impl
t "backlog item worktree sub-agent deny"    2 CW --cwd "$WT" --path "$WT/$WB" --agent impl
t "backlog item from worktree, main allow"  0 CW --cwd "$WT" --path "$WT/$WB"
t "backlog case-insensitive class"          0 CW --cwd "$R" --path .Workflow/Specs/Work-Backlog/006-delta-disc-002.md
ST step $D 5.9 >/dev/null
t "backlog item at 5.9 allow"               0 CW --cwd "$R" --path $WB
for s in 3.1 3.4 4.4 00.21 00.25 00.27 5.7; do ST step $D $s >/dev/null; t "backlog item at $s deny" 2 CW --cwd "$R" --path $WB; t "backlog --only spec at $s deny" 2 CW --cwd "$R" --path $WB --only spec; done
t "backlog deny message names 00.26"        0 bash -c "CW --cwd '$R' --path $WB 2>&1 | grep -q '00.26'"
ST step $D 00.26 >/dev/null
t "backlog misnamed item deny"              2 CW --cwd "$R" --path .workflow/specs/work-backlog/notes.md
t "backlog nested path deny"                2 CW --cwd "$R" --path .workflow/specs/work-backlog/sub/006-delta-disc-001.md
t "backlog spec.md is not a spec file"      2 CW --cwd "$R" --path .workflow/specs/work-backlog/spec.md
t "backlog tasks.md is not a spec file"     2 CW --cwd "$R" --path .workflow/specs/work-backlog/tasks.md
t "backlog .step is not a marker (named msg)" 0 bash -c "CW --cwd '$R' --path .workflow/specs/work-backlog/.step 2>&1 | grep -q 'disc-'"
t "backlog origin without marker deny"      2 CW --cwd "$R" --path .workflow/specs/work-backlog/099-none-disc-001.md
t "backlog other origin's step not used"    2 CW --cwd "$R" --path .workflow/specs/work-backlog/002-beta-disc-001.md
mkdir -p "$R/.workflow/specs/work-backlog"; printf -- '---\nstatus: draft\n---\n' > "$R/.workflow/specs/work-backlog/spec.md"
yq --front-matter=process -i '.status="done"' "$R/$D/spec.md"
t "in-flight scan ignores work-backlog"     0 bash -c "CW --cwd '$R' --path .workflow/rules.md | grep -q 'no feature in flight'"
rm -f "$R/.workflow/specs/work-backlog/spec.md"
yq --front-matter=process -i '.status="in-progress"' "$R/$D/spec.md"

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
eq "no baseline: keys" "$(jq -r 'keys|sort|join(",")' <<<"$out")" "basis,changed_files,max_changed_files,max_tasks,note,over,source,tasks"
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
yq --front-matter=process -i ".baseline_revision = \"$BASE_SHA\"" "$R/$E/spec.md"
out=$(jb --spec-dir $E); eq "baseline=HEAD: 0 changed" "$(jq -r .changed_files <<<"$out")" 0
eq "baseline only: fallback note" "$(jq -r '.note' <<<"$out" | grep -c 'impl_base_revision is not set')" 1
eq "baseline only: basis" "$(jq -r .basis <<<"$out")" baseline_revision
yq --front-matter=process -i ".impl_base_revision = \"$BASE_SHA\"" "$R/$E/spec.md"
out=$(jb --spec-dir $E); eq "impl_base=HEAD: 0 changed" "$(jq -r .changed_files <<<"$out")" 0
eq "impl_base: no note" "$(jq -r 'has("note")' <<<"$out")" false
eq "impl_base: basis" "$(jq -r .basis <<<"$out")" impl_base_revision
mkdir -p "$R/src" "$R/.workflow/specs/work-backlog"
echo a > "$R/src/a.ts"; echo b > "$R/src/b.ts"; echo c > "$R/src/c.ts"; echo x > "$R/$E/notes.md"; echo w > "$R/.workflow/specs/work-backlog/007-eps-disc-001.md"
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

shellcheck_files "shellcheck: scripts under test" "$SRC/scripts/status-transition.sh" "$SRC/scripts/check-write.sh" "$SRC/scripts/budget-check.sh"
finish
