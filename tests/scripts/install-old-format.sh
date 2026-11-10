#!/usr/bin/env bash
# Suite: install.sh (repo root): an upgrade from an old-format project ends as a fresh install plus the project's data.
# Covers: end to end, from fixtures. A project installed before the generated caches, the small path, the per-type model
#   map, per-item backlog files and the split write hooks were retired (old payload files in its VERSION list, the three
#   old write-hook commands in place of the merged one, allow and deny entries for the cache scripts and folder, the old
#   Codex permission blocks and agent files, the .cache-staging line in the .gitignore block, the cache and its staging
#   folder, a model-map folder and agent-overrides.yaml, an open per-item backlog file, graph_extractor in a profile,
#   small_path and cache_stamps in an in-flight spec), with the user's own settings entries, hook group, Codex text and
#   .gitignore line beside them, is upgraded. Its tree, outside .git, then equals a fresh install given the same user
#   entries and the same project data in its current form, byte for byte except the install date in .agents/VERSION and
#   the order of keys in model-map.yaml. The finished spec still at the top level and the unfinished task with no branch
#   are left as they were and reported. A second upgrade changes nothing and prints no summary.
# The scaffold under test is a copy of this repo's install.sh and .agents/ inside the fixture, so the repo is never written.
# Env: TEST_BASH=<bash binary> runs install.sh under another bash (default: bash).
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
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
MODEL_TPL=$SC/.agents/skills/project-setup/assets/model-map.yaml

# snap DIR : one line per file (cksum) and symlink (target) outside .git, sorted; .agents/VERSION without its install
#   date and model-map.yaml as sorted JSON, the two files whose bytes an upgrade and a fresh install may write differently.
snap() {
  (cd "$1" && find . -path ./.git -prune -o \( -type f -o -type l \) -print | LC_ALL=C sort | while IFS= read -r f; do
    if [ -L "$f" ]; then printf '%s -> %s\n' "$f" "$(readlink "$f")"
    elif [ "$f" = ./.agents/VERSION ]; then printf '%s %s\n' "$f" "$(grep -v '^installed: ' "$f" | cksum)"
    elif [ "$f" = ./.workflow/model-map.yaml ]; then printf '%s %s\n' "$f" "$(yq -o=json -I=0 'sort_keys(..)' "$f")"
    else cksum "$f"; fi
  done)
}

# user_entries DIR : the user's own settings entries, hook group, Codex text and .gitignore line, added after an install.
user_entries() {
  jq '.permissions.allow += ["Bash(npm test:*)"] | .permissions.deny += ["Edit(secrets/**)"]
    | .hooks.PreToolUse += [{"matcher": "Bash", "hooks": [{"type": "command", "command": "./my-hook.sh"}]}]' \
    "$1/.claude/settings.json" >"$1/s.tmp" && mv "$1/s.tmp" "$1/.claude/settings.json"
  printf '\n[profile.mine]\nmodel = "o3"\n' >>"$1/.codex/config.toml"
  printf 'node_modules/\n' >>"$1/.gitignore"
}

# project_data DIR FORM : the project's workflow data, FORM old (as the retired flow left it) or new (its current form).
project_data() {
  local w=$1/.workflow
  mkdir -p "$w/profiles" "$w/specs/005-live/tasks" "$w/specs/004-finished" "$w/specs/done/003-old" "$w/specs/work-backlog"
  printf '# Rules\n' >"$w/rules.md"
  {
    printf '# Profile: shell\n\n## Toolchain\n\n```yaml\nlint: "shellcheck x.sh"\ntest: "tests/run.sh"\n'
    [ "$2" = new ] || printf 'graph_extractor: bash # the graph extractor the Tier B cache build runs\n'
    printf 'rule_set: "defaults"\n```\n'
  } >"$w/profiles/shell.md"
  {
    printf -- '---\nstatus: in-progress\nlight_path: true\n'
    [ "$2" = new ] || printf 'small_path: true\n'
    printf -- '---\n\n# Live\n'
  } >"$w/specs/005-live/spec.md"
  {
    [ "$2" = new ] || printf -- '---\ncache_stamps:\n  modules: null\n  flows: null\n  architecture: null\n---\n\n'
    printf '# Codebase map: live\n'
  } >"$w/specs/005-live/codebase-map.md"
  printf -- '---\ntasks:\n  - id: T1\n    status: pending\n    file: tasks/T01-first.md\n    branch: null\n---\n' >"$w/specs/005-live/tasks.md"
  printf 'step: "3.4"\nupdated_at: "2026-11-01T10:00:00Z"\n' >"$w/specs/005-live/.step"
  printf -- '---\nstatus: done\nlight_path: true\n---\n\n# Finished\n' >"$w/specs/004-finished/spec.md"
  printf -- '---\nstatus: done\nlight_path: true\nsmall_path: true\n---\n\n# Old\n' >"$w/specs/done/003-old/spec.md"
  if [ "$2" = new ]; then
    yq '.' "$MODEL_TPL" >"$w/model-map.yaml"
    printf '# Work backlog: 003-old\n\n- [open] B1 bug (3.7): A hook copies a rule. Evidence: `a.sh:10`\n' >"$w/specs/work-backlog/003-old.md"
    return
  fi
  mkdir -p "$w/cache" "$w/.cache-staging/modules" "$w/model-map"
  for c in modules flows architecture; do printf -- '---\ngenerated_at_commit: %s\n---\n# %s\n' "$(printf 'a%.0s' $(seq 40))" "$c" >"$w/cache/$c.md"; done
  echo staged >"$w/.cache-staging/modules/modules.md"
  # One model map file holding the template's own values, so the converted table is the template's.
  printf -- '---\ntier: %s\nclaude: %s\ncodex: %s\n---\n# implementation\n\n## Why this model\n\n%s\n\n## Observations\n' \
    "$(yq '.implementation.tier' "$MODEL_TPL")" "$(yq '.implementation.claude' "$MODEL_TPL")" \
    "$(yq '.implementation.codex' "$MODEL_TPL")" "$(yq '.implementation.why' "$MODEL_TPL")" >"$w/model-map/implementation.md"
  printf '# comments only\n' >"$w/agent-overrides.yaml"
  printf -- '---\nstatus: open\nkind: bug\norigin_step: "3.7"\n---\n# A hook copies a rule\n\n## Problem\n\nA hook copies a rule.\n\n## Evidence\n\n- `a.sh:10`.\n' \
    >"$w/specs/work-backlog/003-old-disc-001.md"
}

# age_install DIR : turn a current install into one an earlier scaffold wrote.
age_install() {
  local d=$1
  mkdir -p "$d/.agents/skills/regenerate-caches" "$d/.agents/agents"
  echo old >"$d/.agents/skills/regenerate-caches/SKILL.md"
  echo old >"$d/.agents/agents/cache-regeneration.md"
  printf 'skills/regenerate-caches/SKILL.md\nagents/cache-regeneration.md\n' >>"$d/.agents/VERSION"
  jq '(.hooks.PreToolUse[] | select(any(.hooks[]; .command | endswith("/workflow-write-guard.sh")))).hooks =
        [ "spec-single-writer-guard.sh", "tier-a-write-guard.sh", "tier-b-write-guard.sh"
          | {type: "command", command: ("\"$CLAUDE_PROJECT_DIR\"/.agents/hooks/" + .), timeout: 10} ]
      | .permissions.allow += [ "cache-stamp-check.sh", "check-staged-cache.sh", "publish-cache.sh"
          | "Bash(.agents/skills/regenerate-caches/scripts/" + . + ":*)" ]
      | .permissions.deny |= (.[0:4] + ["Edit(.workflow/cache/**)"] + .[4:])' \
    "$d/.claude/settings.json" >"$d/s.tmp" && mv "$d/s.tmp" "$d/.claude/settings.json"
  local b='# >>> workflow-2.0 scaffold:' m='(managed by install.sh; edits inside are replaced) >>>' e='# <<< workflow-2.0 scaffold:'
  {
    head -n 1 "$d/.codex/config.toml"
    printf '%s default-permissions %s\ndefault_permissions = "workflow"\n%s default-permissions <<<\n\n' "$b" "$m" "$e"
    printf '%s permissions-workflow %s\n[permissions.workflow]\nextends = ":workspace"\n%s permissions-workflow <<<\n\n' "$b" "$m" "$e"
    tail -n +2 "$d/.codex/config.toml"
  } >"$d/c.tmp" && mv "$d/c.tmp" "$d/.codex/config.toml"
  for a in cache_regeneration:cache-regeneration review_lessons:review-lessons; do
    printf '# Generated by .agents/hooks/generate-codex-agents.sh from .agents/agents/%s.md\nname = "%s"\n' "${a#*:}" "${a#*:}" \
      >"$d/.codex/agents/${a%%:*}.toml"
  done
  awk '$0 == ".workflow/.worktrees/" { print ".workflow/.cache-staging/" } { print }' "$d/.gitignore" >"$d/g.tmp" && mv "$d/g.tmp" "$d/.gitignore"
}

echo "== the fresh install with the project's data in its current form"
F=$WORK/fresh
git_init_repo "$F"
t "a fresh install exits 0" 0 INST "$F"
user_entries "$F"
project_data "$F" new
want=$(snap "$F")

echo "== the old-format project, upgraded"
O=$WORK/old
git_init_repo "$O"
t "the install the fixture ages exits 0" 0 INST "$O"
user_entries "$O"
age_install "$O"
project_data "$O" old
git_commit_all "$O" "old-format project"
check "the fixture holds the retired items" '[ -d "$O/.workflow/cache" ] && grep -q tier-a-write-guard "$O/.claude/settings.json" && grep -q permissions-workflow "$O/.codex/config.toml"'
out=$(INST "$O" 2>&1)
eq "the upgrade exits 0" "$?" 0
eq "the upgraded tree equals the fresh install plus the project's data" "$(snap "$O")" "$want"
diff <(snap "$O") <(printf '%s\n' "$want") >&2 || true
check "the summary has a removed and a converted line" \
  'grep -q "^  removed: 2 payload file(s)" <<<"$out" && grep -q "^  converted: " <<<"$out"' "$out"
check "the finished spec at the top level is reported" 'grep -qF "move-to-done.sh .workflow/specs/004-finished" <<<"$out"' "$out"
check "the task with no branch is reported" 'grep -qF "task T1 (pending) has no task branch" <<<"$out"' "$out"

echo "== a second upgrade"
out=$(INST "$O" 2>&1)
eq "it exits 0" "$?" 0
eq "it changes nothing" "$(snap "$O")" "$want"
check "it prints no summary and no workflow-data section" '! grep -Eq "^(Upgrade from an older install|Workflow data)" <<<"$out"' "$out"

shellcheck_files "shellcheck: install-old-format suite" "$TESTS_DIR/scripts/install-old-format.sh"
finish
