#!/usr/bin/env bash
# Suite: install.sh (repo root): the conversion of older workflow data an upgrade finds under .workflow/.
# Covers: a .workflow/model-map/ folder (one <type>.md per task type) and agent-overrides.yaml become one
#   .workflow/model-map.yaml: each row keeps the folder's tier, claude, codex, its "Why this model" text as why and its
#   Observations lines as observations; a filled override wins over the folder's value and a placeholder override does not;
#   the template's rows for task types the folder lacks (research) are added; the folder and the overrides file are
#   removed, and resolve-launch.sh then resolves from the new file. Per-item backlog files: an open one becomes the next
#   B<n> line on its spec's list (an existing list kept and extended, a missing one created) in the list's line shape, a
#   closed one is dropped, and every item file is removed. --dry-run previews and writes nothing; a re-run changes nothing;
#   an existing model-map.yaml beside an old folder is kept with a warning; a project with neither changes nothing there.
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
