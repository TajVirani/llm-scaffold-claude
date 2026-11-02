#!/usr/bin/env bash
# Suite: check-write.sh (feature-workflow/scripts): path classes and spec files.
# Covers: Tier B and the .step marker, the .workflow/ prefixes and their look-alikes, spec.md per step (widened steps,
#   --proposed edits, creation at 0.1.4), tasks.md (set-task is the only record writer) and .workflow/specs/work-backlog (older item
#   files and the per-spec backlog list <NNN-slug>.md: main session at the origin spec's 00.26 or 5.9 only).
#   JRN-004 (spec 007): every Write/Edit under .workflow/specs/done/** is denied for the main session and a sub-agent, from the
#   main checkout and a worktree, in any case and as an absolute path, including done/.step, done/spec.md beside a stray
#   done/.step at a spec writer step, and a glossary file inside a moved spec at a glossary step; one of the three hook classes
#   denies it; the reason names the Done folder; look-alike folders (done-x/, 012-done/, a done/ inside a spec) stay unguarded.
#   JRN-012 (spec 00014): a backlog list named old_NNN-slug.md, the list of a Done spec renamed with the old_ prefix, passes
#   the list-name rule a misnamed list fails, and malformed old_ list names still fail it; such a list is written at 00.26
#   or 5.9 of the step marker in its Done folder spec, and denied at another step or without one.
# Env: TEST_BASH=<bash binary> runs the scripts under another bash (default: bash).
# shellcheck disable=SC2329,SC1010,SC2016,SC2034  # helpers run indirectly via t and bash -c; "done" is a status word; backticks in printf fixtures; variables read inside check expressions
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

# 001-alpha has finished; 002-beta is ready for dev; 003-gamma is in progress for the set-task check under tasks.md.
yq --front-matter=process -i '.status="done"' "$R/$A/spec.md"
B=.workflow/specs/002-beta
ST status $B draft >/dev/null; ST status $B ready-for-dev --step 0.3.20 >/dev/null
G=.workflow/specs/003-gamma
mkdir -p "$R/$G"; cp "$SRC/assets/spec.md" "$R/$G/spec.md"; cp "$R/$A/tasks.md" "$R/$G/tasks.md"
yq --front-matter=process -i '.status="in-progress"' "$R/$G/spec.md"

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

# The work-backlog checks run with every other spec finished and 002-beta unmarked, so 006-delta is the only spec in flight.
yq --front-matter=process -i '.status="done"' "$R/$B/spec.md"; yq --front-matter=process -i '.status="done"' "$R/$G/spec.md"
unmark 002-beta
D=.workflow/specs/006-delta
mkdir -p "$R/$D"; cp "$SRC/assets/spec.md" "$R/$D/spec.md"; cp "$R/$A/tasks.md" "$R/$D/tasks.md"
ST status $D draft >/dev/null; ST status $D ready-for-dev --step 0.6 >/dev/null; ST status $D in-progress >/dev/null

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
# The spec's backlog list, one line per kept item: the same origin and step rules as an item file.
WL=.workflow/specs/work-backlog/006-delta.md
t "backlog list at 00.26 allow"             0 CW --cwd "$R" --path $WL
t "backlog list sub-agent deny"             2 CW --cwd "$R" --path $WL --agent impl
ST step $D 5.9 >/dev/null
t "backlog list at 5.9 allow"               0 CW --cwd "$R" --path $WL
for s in 3.7 4.4 5.5; do ST step $D $s >/dev/null; t "backlog list at $s deny" 2 CW --cwd "$R" --path $WL; done
t "backlog list deny message names the list" 0 bash -c "CW --cwd '$R' --path .workflow/specs/work-backlog/no-number.md 2>&1 | grep -q '<origin NNN-slug>.md'"
ST step $D 00.26 >/dev/null
t "backlog list of another spec deny"       2 CW --cwd "$R" --path .workflow/specs/work-backlog/002-beta.md
t "backlog list without a number deny"      2 CW --cwd "$R" --path .workflow/specs/work-backlog/no-number.md
t "backlog list nested deny"                2 CW --cwd "$R" --path .workflow/specs/work-backlog/006-delta/006-delta.md
# A Done spec renamed with the old_ prefix keeps its backlog list as old_NNN-slug.md. The list-name rule is judged by its own
# deny reason, the one a misnamed list gets, since no step lets anyone write a finished spec's list.
LIST_NAME_RULE='<origin NNN-slug>.md'
out_misnamed=$(CW --cwd "$R" --path .workflow/specs/work-backlog/no-number.md 2>&1)
out_old=$(CW --cwd "$R" --path .workflow/specs/work-backlog/old_012-alpha.md 2>&1)
check "JRN-012 (spec 00014) an old_NNN-slug.md backlog list passes the list-name rule a misnamed list fails" \
  'grep -qF "$LIST_NAME_RULE" <<<"$out_misnamed" && ! grep -qF "$LIST_NAME_RULE" <<<"$out_old"' "$out_old"
for bad in old_.md old_x01-short.md old-012-alpha.md old_old_012-alpha.md; do
  out_bad=$(CW --cwd "$R" --path ".workflow/specs/work-backlog/$bad" 2>&1)
  check "JRN-012 (spec 00014) the backlog list name $bad still fails the list-name rule while old_012-alpha.md passes it" \
    '! grep -qF "$LIST_NAME_RULE" <<<"$out_old" && grep -qF "$LIST_NAME_RULE" <<<"$out_bad"' "$out_bad"
done
# The origin of an old_ list is the Done folder spec of that name, so its step marker is read there.
OLD_DONE=.workflow/specs/done/old_012-alpha
mkdir -p "$R/$OLD_DONE"
for s in 00.26 5.9; do
  printf 'step: "%s"\nupdated_at: "2026-11-02T10:00:00Z"\n' "$s" >"$R/$OLD_DONE/.step"
  t "JRN-012 (spec 00014) backlog list old_012-alpha.md at its Done spec's $s allow" 0 CW --cwd "$R" --path .workflow/specs/work-backlog/old_012-alpha.md
done
printf 'step: "3.7"\nupdated_at: "2026-11-02T10:00:00Z"\n' >"$R/$OLD_DONE/.step"
t "JRN-012 (spec 00014) backlog list old_012-alpha.md at its Done spec's 3.7 deny" 2 CW --cwd "$R" --path .workflow/specs/work-backlog/old_012-alpha.md
t "JRN-012 (spec 00014) the old_ list deny names its Done spec" 0 bash -c "CW --cwd '$R' --path .workflow/specs/work-backlog/old_012-alpha.md 2>&1 | grep -qF 'origin spec $OLD_DONE is at step 3.7'"
rm -rf "${R:?}/$OLD_DONE"
t "JRN-012 (spec 00014) backlog list old_012-alpha.md without a Done spec marker deny" 2 CW --cwd "$R" --path .workflow/specs/work-backlog/old_012-alpha.md
mkdir -p "$R/.workflow/specs/work-backlog"; printf -- '---\nstatus: draft\n---\n' > "$R/.workflow/specs/work-backlog/spec.md"
yq --front-matter=process -i '.status="done"' "$R/$D/spec.md"
t "in-flight scan ignores work-backlog"     0 bash -c "CW --cwd '$R' --path .workflow/rules.md | grep -q 'no feature in flight'"
rm -f "$R/.workflow/specs/work-backlog/spec.md"
yq --front-matter=process -i '.status="in-progress"' "$R/$D/spec.md"

echo "== check-write: the Done folder .workflow/specs/done/** (JRN-004, spec 007)"
DN=.workflow/specs/done
# any_guard_denies PATH [ARG...] : true when one of the three guard classes (--only spec, tier-a, tier-b), as the write-guard
#   hooks call check-write.sh, denies PATH.
any_guard_denies() {
  local p=$1 only
  shift
  for only in spec tier-a tier-b; do
    CW --cwd "$R" --path "$p" --only "$only" "$@" >/dev/null 2>&1
    [ $? -eq 2 ] && return 0
  done
  return 1
}
# A stray marker in done/ itself would let done/spec.md through as a spec file at a writer step; the Done folder rule must win.
mkdir -p "$R/$DN"
printf 'step: "0.3.19"\nupdated_at: "2026-10-30T10:00:00Z"\n' >"$R/$DN/.step"
ST step $D 5.3 >/dev/null
t "control: .workflow/GLOSSARY.md at 5.3 allow"   0 CW --cwd "$R" --path .workflow/GLOSSARY.md
for p in $DN/012-x/spec.md $DN/012-x/tasks.md $DN/012-x/tasks/T01-a.md $DN/012-x/design-log.md $DN/012-x/pr-body.md \
  $DN/012-x/report.md $DN/012-x/codebase-map.md $DN/012-x/artifacts/T1/implementation.yaml $DN/00010-five/spec.md \
  $DN/012-x/GLOSSARY.md $DN/spec.md $DN/README.md $DN/.step; do
  t "done/** main session deny: $p"          2 CW --cwd "$R" --path "$p"
  t "done/** sub-agent deny: $p"             2 CW --cwd "$R" --path "$p" --agent impl
done
t "done/** case-insensitive deny"           2 CW --cwd "$R" --path .Workflow/Specs/Done/012-x/design-log.md
t "done/** absolute path deny"              2 CW --cwd "$R" --path "$R/$DN/012-x/pr-body.md"
t "done/** from worktree, main session deny" 2 CW --cwd "$WT" --path "$WT/$DN/012-x/spec.md"
t "done/** from worktree, sub-agent deny"   2 CW --cwd "$WT" --path "$WT/$DN/012-x/report.md" --agent impl
for p in $DN/012-x/design-log.md $DN/012-x/pr-body.md $DN/012-x/spec.md $DN/spec.md; do
  t "done/** a write-guard hook class denies: $p" 0 any_guard_denies "$p"
  t "done/** a write-guard hook class denies a sub-agent: $p" 0 any_guard_denies "$p" --agent impl
done
t "done/** deny reason names the Done folder" 0 bash -c "CW --cwd '$R' --path $DN/012-x/design-log.md 2>&1 >/dev/null | grep -qi 'done folder'"
for p in .workflow/specs/done-x/012-x/design-log.md .workflow/specs/012-done/design-log.md .workflow/specs/012-x/done/notes.md \
  .workflow/specs/donex.md docs/specs/done/012-x/spec.md; do
  t "done look-alike not guarded: $p"       0 CW --cwd "$R" --path "$p" --agent a1
done
rm -f "$R/$DN/.step"

shellcheck_files "shellcheck: scripts under test" "$SRC/scripts/check-write.sh"
finish
