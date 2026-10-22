#!/usr/bin/env bash
# Suite: check-write.sh (feature-workflow/scripts): Tier A.
# Covers: Tier A writes per step (the glossary, rules.md, capabilities.md, ADRs, profiles new and existing), sub-agent
#   denials, the newest marker across specs in flight, no feature in flight, and a missing yq; JRN-004: the review-lessons
#   file allowed at 5.7 only (denied at 0.3.7, 5.3, 4.9 and 0.1.4, and to a sub-agent at 5.7).
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

# 001-alpha has finished; 002-beta and 003-gamma are in flight with a marker each, so the newest marker has two candidates.
yq --front-matter=process -i '.status="done"' "$R/$A/spec.md"
B=.workflow/specs/002-beta
ST status $B draft >/dev/null; ST status $B ready-for-dev --step 0.3.20 >/dev/null
G=.workflow/specs/003-gamma
mkdir -p "$R/$G"; cp "$SRC/assets/spec.md" "$R/$G/spec.md"; cp "$R/$A/tasks.md" "$R/$G/tasks.md"
yq --front-matter=process -i '.status="in-progress"' "$R/$G/spec.md"
ST step $G 5.3 >/dev/null

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

echo "== JRN-004: the review-lessons file is written at 5.7 only"
# Its own repo with one spec in flight, so that spec's marker alone decides.
git_init_repo "$F/lessons-repo"
LR=$F/lessons-repo
LS=.workflow/specs/001-fixture
mkdir -p "$LR/$LS"
cp "$SRC/assets/spec.md" "$LR/$LS/spec.md"
echo '.workflow/specs/*/.step' >"$LR/.gitignore"
git_commit_all "$LR" init
t "JRN-004 setup: the spec is a draft" 0 ST status $LS draft --cwd "$LR"
# lessons_at STEP : set the fixture spec's marker to STEP through status-transition.sh.
lessons_at() { t "JRN-004 setup: .step set to $1" 0 ST step $LS "$1" --cwd "$LR"; }
lessons_at 5.7
t "JRN-004 review-lessons.md at 5.7 allow" 0 CW --cwd "$LR" --path .workflow/review-lessons.md
t "JRN-004 review-lessons.md at 5.7 sub-agent deny" 2 CW --cwd "$LR" --path .workflow/review-lessons.md --agent impl
for s in 0.3.7 5.3 4.9 0.1.4; do
  lessons_at $s
  t "JRN-004 review-lessons.md at $s deny" 2 CW --cwd "$LR" --path .workflow/review-lessons.md
  err=$(CW --cwd "$LR" --path .workflow/review-lessons.md 2>&1 >/dev/null)
  check "JRN-004 review-lessons.md at $s: a deny naming 5.7 on stderr" '[[ $err == "deny: "*5.7* ]]' "$err"
done

shellcheck_files "shellcheck: scripts under test" "$SRC/scripts/check-write.sh"
finish
