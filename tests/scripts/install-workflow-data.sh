#!/usr/bin/env bash
# Suite: install.sh (repo root): the conversion of older workflow data an upgrade finds under .workflow/.
# Covers: a .workflow/model-map/ folder (one <type>.md per task type) and agent-overrides.yaml become one
#   .workflow/model-map.yaml: each row keeps the folder's tier, claude, codex, its "Why this model" text as why and its
#   Observations lines as observations; a filled override wins over the folder's value and a placeholder override does not;
#   the template's rows for task types the folder lacks (research) are added, and a retired task type (cache-regeneration,
#   review-lessons) gets no row from its file or its override; the folder and the overrides file are
#   removed, and resolve-launch.sh then resolves from the new file. Per-item backlog files: an open one becomes the next
#   B<n> line on its spec's list (an existing list kept and extended, a missing one created) in the list's line shape, a
#   closed one is dropped, and every item file is removed. --dry-run previews and writes nothing; a re-run changes nothing;
#   an existing model-map.yaml beside an old folder is kept with a warning; a project with neither changes nothing there.
#   Retired items: the generated cache and its staging folder are removed (a look-alike folder and docs/cache kept);
#   graph_extractor leaves a profile's yaml block (the same text outside it stays); small_path leaves in-flight specs, a
#   small-path draft keeping its route as light_path: true; cache_stamps leaves an in-flight codebase map with its
#   frontmatter; specs in the Done folder are untouched; a done spec at the top level, an unfinished task with no branch, a
#   lesson not yet retired with a retired path and a shelf item naming one are reported with their commands and left as
#   they are (a retired lesson, a project lesson, an archived and an unrelated shelf item are not); --dry-run writes
#   nothing; a re-run changes nothing and prints no summary.
# The scaffold under test is a copy of this repo's install.sh and .agents/ inside the fixture, so the repo is never written.
# Env: TEST_BASH=<bash binary> runs install.sh under another bash (default: bash).
# shellcheck disable=SC2016,SC2034  # check expressions are single-quoted and eval'd on purpose, and read variables shellcheck cannot see
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight
TEST_BASH=${TEST_BASH:-bash}

new_workdir
SC=$WORK/scaffold
mkdir -p "$SC"
cp "$REPO_ROOT/install.sh" "$SC/install.sh"
copy_agents "$SC"
git_init_repo "$SC"
git_commit_all "$SC" scaffold
# INST ARGS... : runs the scaffold's install.sh with no input.
INST() { "$TEST_BASH" "$SC/install.sh" "$@" </dev/null; }
# snap DIR : one line per file under DIR/.workflow (cksum), sorted.
snap() { (cd "$1" && find .workflow -type f | LC_ALL=C sort | while IFS= read -r f; do cksum "$f"; done); }
LINE_RE='^- \[(open|promoted)\] B[0-9]+ (bug|requirement|refactor|scope-expansion|decision|budget-split) \([0-9.]+[^)]*\): .+ Evidence: .+'

# old_project DIR : a target installed before the one model table and the per-spec backlog list.
old_project() {
  local p=$1
  rm -rf "$p"
  git_init_repo "$p"
  mkdir -p "$p/.workflow/model-map" "$p/.workflow/specs/work-backlog"
  cat >"$p/.workflow/model-map/implementation.md" <<'M'
---
# Lowest-precedence model source.
tier: strong
claude: opus
codex: gpt-6-sol
---
# implementation

## Why this model

Writes code across files.

## Observations

<!-- Appended at 5.7 by the retrospective skill. -->
- 2026-10-22 (claude opus, spec 002-x): six tasks done. No change.
- 2026-10-26 (claude, spec 003-y): one fix round. No alias change.
M
  cat >"$p/.workflow/model-map/retrieval.md" <<'M'
---
tier: cheap
claude: haiku
codex: gpt-6-luna
---
# retrieval

## Why this model

Bounded reading task.

## Observations

<!-- Appended at 5.7 by the retrospective skill. -->
M
  printf -- '---\ntier: strong\nclaude: opus\ncodex: gpt-6-sol\n---\n# cache-regeneration\n' >"$p/.workflow/model-map/cache-regeneration.md"
  cat >"$p/.workflow/model-map/TEMPLATE.md" <<'M'
---
tier: cheap
claude: <alias>
---
M
  cat >"$p/.workflow/agent-overrides.yaml" <<'M'
# comments only header
retrieval:
  claude: sonnet
implementation:
  codex: "<alias>"
review-lessons:
  claude: haiku
M
  cat >"$p/.workflow/specs/work-backlog/001-alpha-disc-001.md" <<'M'
---
origin_spec: .workflow/specs/done/001-alpha
origin_step: "3.7"
discovered_at: 2026-10-22
status: open
kind: refactor
---

# One helper for two copies

## Problem

Two hooks carry their own copy
of the same rule.

## Evidence

- `a.sh:10` (`one`).
- `b.sh:20` (`two`).

## Why not a blocker

Both copies agree.
M
  printf -- '---\nstatus: dismissed\nkind: bug\norigin_step: "4.4"\n---\n# Dropped\n' >"$p/.workflow/specs/work-backlog/001-alpha-disc-002.md"
  printf -- '---\nstatus: open\nkind: bug\norigin_step: "4.4"\n---\n# A title only\n' >"$p/.workflow/specs/work-backlog/002-beta-disc-004.md"
  printf '%s\n' "# Work backlog: 002-beta" "" "- [open] B2 bug (4.4): Kept. Evidence: k." >"$p/.workflow/specs/work-backlog/002-beta.md"
  git_commit_all "$p" "old workflow data"
}

echo "== dry run"
P=$WORK/proj
old_project "$P"
before=$(snap "$P")
out=$(INST "$P" --dry-run 2>&1)
eq "dry run exits 0" "$?" 0
eq "dry run writes nothing under .workflow/" "$(snap "$P")" "$before"
check "dry run previews the model map conversion" 'grep -q "would convert .workflow/model-map/ and .workflow/agent-overrides.yaml into .workflow/model-map.yaml" <<<"$out"' "$out"
check "dry run previews the backlog moves" 'grep -q "would move .workflow/specs/work-backlog/001-alpha-disc-001.md onto .workflow/specs/work-backlog/001-alpha.md#B1" <<<"$out"' "$out"

echo "== the conversion"
out=$(INST "$P" --host claude 2>&1)
eq "the upgrade exits 0" "$?" 0
MM=$P/.workflow/model-map.yaml
check "the old folder is gone" '[ ! -e "$P/.workflow/model-map" ]'
check "the overrides file is gone" '[ ! -e "$P/.workflow/agent-overrides.yaml" ]'
eq "implementation keeps its row" "$(yq -o=json -I=0 '.implementation | [.tier, .claude, .codex, .why]' "$MM")" '["strong","opus","gpt-6-sol","Writes code across files."]'
eq "implementation keeps its observations in order" "$(yq '.implementation.observations | length' "$MM")" 2
eq "the first observation line" "$(yq '.implementation.observations[0]' "$MM")" "2026-10-22 (claude opus, spec 002-x): six tasks done. No change."
eq "a filled override wins over the folder" "$(yq '.retrieval.claude' "$MM")" sonnet
eq "a placeholder override leaves the folder's value" "$(yq '.implementation.codex' "$MM")" gpt-6-sol
check "a row with no observations has no observations key" '[ "$(yq ".retrieval | has(\"observations\")" "$MM")" = false ]'
check "a retired task type's file and override leave no row" \
  '[ "$(yq "has(\"cache-regeneration\") or has(\"review-lessons\")" "$MM")" = false ]' "$(yq 'keys' "$MM")"
check "the folder's TEMPLATE.md is not a task type" '[ "$(yq "has(\"TEMPLATE\")" "$MM")" = false ]'
eq "the template's research row is added" "$(yq '.research.claude' "$MM")" opus
check "the upgrade says it added research" 'grep -q "add the template.s row for .*research" <<<"$out"' "$out"
check "the file opens with the template's header" 'head -n 1 "$MM" | grep -q "^# File: the project.s model table"'
RL=$P/.agents/skills/feature-workflow/scripts/resolve-launch.sh
mkdir -p "$P/.workflow/specs/001-alpha"
model=$(printf '```yaml launch-header\ntask_type: retrieval\nspec_dir: .workflow/specs/001-alpha\n```\nq\n' |
  bash "$RL" --host claude --task-type retrieval --project-dir "$P" 2>&1 | jq -r '.model // empty')
eq "resolve-launch reads the converted table" "$model" sonnet
rmdir "$P/.workflow/specs/001-alpha"

BL=$P/.workflow/specs/work-backlog
check "every per-item file is removed" '[ -z "$(find "$BL" -name "*-disc-*")" ]' "$(ls "$BL")"
eq "a new list holds the open item as B1" "$(grep -c '^- ' "$BL/001-alpha.md")" 1
eq "the new list's title" "$(head -n 1 "$BL/001-alpha.md")" "# Work backlog: 001-alpha"
eq "the line carries kind, origin step, problem and evidence" "$(grep '^- ' "$BL/001-alpha.md")" \
  '- [open] B1 refactor (3.7): Two hooks carry their own copy of the same rule. Evidence: `a.sh:10` (`one`); `b.sh:20` (`two`)'
eq "an existing list keeps its line and gains the next number" "$(grep '^- ' "$BL/002-beta.md" | cut -c1-14 | tr '\n' ' ')" "- [open] B2 bu - [open] B3 bu "
check "an item with no Problem section uses its title" 'grep -q "^- \[open\] B3 bug (4.4): A title only\. Evidence: " "$BL/002-beta.md"'
check "every list line has the backlog line shape" '! grep -h "^- " "$BL"/*.md | grep -vE "$LINE_RE"' "$(grep -h '^- ' "$BL"/*.md)"
check "the closed item left no line" '! grep -q "Dropped" "$BL"/*.md'

echo "== re-run"
after=$(snap "$P")
INST "$P" --host claude >/dev/null 2>&1
eq "a re-run changes nothing under .workflow/" "$(snap "$P")" "$after"

echo "== an existing model-map.yaml beside an old folder"
K=$WORK/kept
old_project "$K"
printf 'retrieval:\n  tier: cheap\n  claude: opus\n' >"$K/.workflow/model-map.yaml"
out=$(INST "$K" --host claude 2>&1)
eq "the upgrade exits 0" "$?" 0
eq "model-map.yaml is kept as it was" "$(yq '.retrieval.claude' "$K/.workflow/model-map.yaml")" opus
check "the old folder is left for the human" '[ -d "$K/.workflow/model-map" ]'
check "a warning names the folder" 'grep -q "model-map/ is no longer read and .workflow/model-map.yaml already exists" <<<"$out"' "$out"

# retired_project DIR : a target whose workflow folder still holds what the flow retired: the generated cache and its
#   staging folder, profiles with graph_extractor, an in-flight spec with small_path, cache_stamps and an unfinished task
#   with no branch, a draft small-path spec whose light_path was false, a done spec still at the top level, a spec in the
#   Done folder with the same keys, a review lesson and a shelf item that name retired paths, and neighbours of the user's.
retired_project() {
  local p=$1 w=$1/.workflow
  rm -rf "$p"
  git_init_repo "$p"
  mkdir -p "$w/cache" "$w/.cache-staging/modules" "$w/profiles" "$w/deferred/archive" "$w/cachex" "$p/docs/cache" \
    "$w/specs/005-live/tasks" "$w/specs/006-draft" "$w/specs/004-finished" "$w/specs/done/003-old"
  for c in modules flows architecture; do
    printf -- '---\ngenerated_at_commit: %s\n---\n# %s\n' "$(printf 'a%.0s' $(seq 40))" "$c" >"$w/cache/$c.md"
  done
  echo staged >"$w/.cache-staging/modules/modules.md"
  echo mine >"$w/cachex/notes.md"
  echo mine >"$p/docs/cache/notes.md"
  printf '# Rules\n' >"$w/rules.md"
  cat >"$w/profiles/shell.md" <<'M'
# Profile: shell

## Toolchain

```yaml
lint: "shellcheck x.sh"
test: "tests/run.sh"
graph_extractor: bash # the graph extractor the Tier B cache build runs
rule_set: "defaults"
```

graph_extractor: prose outside the block stays
M
  cat >"$w/specs/005-live/spec.md" <<'M'
---
status: in-progress # draft | ready-for-dev
light_path: true
small_path: true
deferred: []
---

# Live
M
  cat >"$w/specs/005-live/codebase-map.md" <<'M'
---
cache_stamps:
  modules: null
  flows: null
  architecture: null
---

# Codebase map: live
M
  cat >"$w/specs/005-live/tasks.md" <<'M'
---
tasks:
  - id: T1
    status: in-progress
    file: tasks/T01-first.md
    branch: null
  - id: T2
    status: done
    file: tasks/T02-second.md
    branch: null
  - id: T3
    status: pending
    file: tasks/T03-third.md
    branch: task/005-live/T03-third
---
M
  printf -- '---\nstatus: draft\nlight_path: false # set at 0.3.20\nsmall_path: true\n---\n\n# Draft\n' >"$w/specs/006-draft/spec.md"
  printf -- '---\nstatus: done\nlight_path: true\nsmall_path: true\n---\n\n# Finished\n' >"$w/specs/004-finished/spec.md"
  printf -- '---\nstatus: done\nlight_path: true\nsmall_path: true\n---\n\n# Old\n' >"$w/specs/done/003-old/spec.md"
  printf -- '---\ncache_stamps:\n  modules: null\n  flows: null\n  architecture: null\n---\n\n# Map\n' >"$w/specs/done/003-old/codebase-map.md"
  cat >"$w/review-lessons.md" <<'M'
# Review lessons

```yaml
lessons:
  - id: RL-001
    symptom: "An extractor drops a call."
    paths: [".agents/skills/regenerate-caches/scripts/extractors/**"]
    origin_spec: .workflow/specs/done/003-old
    date: 2026-10-22
  - id: RL-002
    symptom: "A cache is stale."
    paths: [".workflow/cache/**"]
    origin_spec: .workflow/specs/done/003-old
    date: 2026-10-22
    retired: 2026-11-01
    enforced_by: "a test"
  - id: RL-003
    symptom: "Code of the project."
    paths: ["src/**"]
    origin_spec: .workflow/specs/done/003-old
    date: 2026-10-22
```
M
  printf -- '---\norigin_spec: .workflow/specs/done/003-old\ncreated: 2026-10-01\n---\n# Scope\n\nSee `.workflow/cache/modules.md`.\n' >"$w/deferred/cache-scope.md"
  printf -- '---\norigin_spec: .workflow/specs/done/003-old\ncreated: 2026-10-01\n---\n# Export\n\nSee `src/export.ts`.\n' >"$w/deferred/export.md"
  printf -- '# Old\n\nSee `.workflow/cache/flows.md`.\n' >"$w/deferred/archive/old.md"
  git_commit_all "$p" "retired workflow data"
  printf 'step: "3.4"\nupdated_at: "2026-11-01T10:00:00Z"\n' >"$w/specs/005-live/.step"
}

echo "== retired items: dry run"
R=$WORK/retired
retired_project "$R"
before=$(snap "$R")
out=$(INST "$R" --host claude --dry-run 2>&1)
eq "dry run exits 0" "$?" 0
eq "dry run writes nothing under .workflow/" "$(snap "$R")" "$before"
check "dry run previews the cache removal" 'grep -q "would remove .workflow/cache/, which nothing reads" <<<"$out"' "$out"
check "dry run prints the summary" 'grep -q "^Upgrade from an older install:" <<<"$out"' "$out"

echo "== retired items: the upgrade"
out=$(INST "$R" --host claude 2>&1)
eq "the upgrade exits 0" "$?" 0
W=$R/.workflow
check "the generated cache is removed" '[ ! -e "$W/cache" ]'
check "the cache staging folder is removed" '[ ! -e "$W/.cache-staging" ]'
eq "a look-alike workflow folder of the user's is kept" "$(cat "$W/cachex/notes.md")" mine
eq "the project's docs/cache is kept" "$(cat "$R/docs/cache/notes.md")" mine
eq "rules.md is untouched" "$(cat "$W/rules.md")" "# Rules"
check "graph_extractor is gone from the profile's yaml block" '! awk "/^\`\`\`yaml/{f=1;next}/^\`\`\`/{f=0}f" "$W/profiles/shell.md" | grep -q graph_extractor'
eq "the profile's other toolchain keys stay in order" "$(awk '/^```yaml/{f=1;next}/^```/{f=0}f' "$W/profiles/shell.md" | cut -d: -f1 | tr '\n' ' ')" "lint test rule_set "
check "the same text outside the yaml block stays" 'grep -q "^graph_extractor: prose outside the block stays" "$W/profiles/shell.md"'
eq "small_path is gone from the in-flight spec, the rest kept" "$(sed -n '2,/^---$/p' "$W/specs/005-live/spec.md")" \
  "$(printf 'status: in-progress # draft | ready-for-dev\nlight_path: true\ndeferred: []\n---')"
eq "a small-path draft keeps its route as light_path: true, with its comment" \
  "$(sed -n '2,/^---$/p' "$W/specs/006-draft/spec.md")" "$(printf 'status: draft\nlight_path: true # set at 0.3.20\n---')"
eq "the codebase map loses its cache_stamps frontmatter and the blank line after it" \
  "$(cat "$W/specs/005-live/codebase-map.md")" "# Codebase map: live"
check "the spec in the Done folder is untouched" 'grep -q "^small_path: true" "$W/specs/done/003-old/spec.md" && grep -q "^cache_stamps:" "$W/specs/done/003-old/codebase-map.md"'
check "the done spec at the top level is not rewritten" 'grep -q "^small_path: true" "$W/specs/004-finished/spec.md"'
check "it is reported with its move-to-done command" \
  'grep -qF "run: .agents/skills/feature-workflow/scripts/move-to-done.sh .workflow/specs/004-finished" <<<"$out"' "$out"
want_cmd="yq --front-matter=process -i '(.tasks[] | select(.id == \"T1\")).branch = \"task/005-live/T01-first\"' .workflow/specs/005-live/tasks.md"
check "the unfinished task with no branch is reported with the command that gives it one" \
  'grep -qF "task T1 (in-progress) has no task branch" <<<"$out" && grep -qF "$want_cmd" <<<"$out"' "$out"
check "a done task with no branch and a task with one are not reported" '! grep -Eq "task T(2|3) " <<<"$out"' "$out"
check "tasks.md is not rewritten" 'grep -q "branch: null" "$W/specs/005-live/tasks.md"'
check "the lesson naming a retired path is reported" 'grep -qF "RL-001 names .agents/skills/regenerate-caches/scripts/extractors/**" <<<"$out"' "$out"
check "a retired lesson and a project lesson are not" '! grep -Eq "RL-00(2|3)" <<<"$out"' "$out"
check "the shelf item naming the cache is reported with its git rm" 'grep -qF "git rm .workflow/deferred/cache-scope.md" <<<"$out"' "$out"
check "an archived item and an unrelated item are not" '! grep -Eq "deferred/(archive|export)" <<<"$out"' "$out"
check "the summary names what was removed" 'grep -q "^  removed: .*\.workflow/cache/; \.workflow/\.cache-staging/" <<<"$out"' "$out"
check "the summary counts the converted keys" 'grep -q "^  converted: 5 retired key" <<<"$out"' "$out"

echo "== retired items: re-run"
after=$(snap "$R")
out=$(INST "$R" --host claude 2>&1)
eq "a re-run exits 0" "$?" 0
eq "a re-run changes nothing under .workflow/" "$(snap "$R")" "$after"
check "a re-run prints no summary and no workflow-data section" '! grep -Eq "^(Upgrade from an older install|Workflow data)" <<<"$out"' "$out"

echo "== a project with neither"
N=$WORK/none
rm -rf "$N"
git_init_repo "$N"
mkdir -p "$N/.workflow"
printf 'x: 1\n' >"$N/.workflow/rules.md"
git_commit_all "$N" "new data"
out=$(INST "$N" --host claude 2>&1)
check "no workflow-data section" '! grep -q "^Workflow data" <<<"$out"' "$out"
eq "only rules.md under .workflow/" "$(find "$N/.workflow" -type f | wc -l | tr -d ' ')" 1

shellcheck_files "shellcheck: install-workflow-data suite" "$TESTS_DIR/scripts/install-workflow-data.sh"
finish
