#!/usr/bin/env bash
# Suite: lint over the project-standards coverage list (assets/coverage.md), the "Every work type" row of C1.
# Covers: spec 00015: the row asks, each in its own sentence that names where the answer is written, for the Worktree setup
#   command (`worktree_setup`, the `## Workflow settings` block of `.workflow/rules.md`), the gitignored files a new worktree
#   needs copied (`.worktreeinclude`), the commands that start and stop the services tests need (`services_up` and
#   `services_down`, the same block), how ports, container names and database names derive from the isolation values (the
#   work profile), and that tests use a throwaway database, never the dev one (the work profile).
#   Reads the repo; writes nothing.
# shellcheck disable=SC2016,SC2034,SC2329  # check expressions are single-quoted and eval'd on purpose, so shellcheck cannot see what they call or read
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

COVERAGE=$AGENTS_SRC/skills/project-standards/assets/coverage.md
SETTINGS='`## Workflow settings` block of `.workflow/rules.md`'
PROFILE='work profile'

# Each item: a label, then the fixed strings one sentence of the row must all hold: what is asked, then where it goes.
ITEMS=(
  "the Worktree setup command|Worktree setup|\`worktree_setup\`|$SETTINGS"
  "the gitignored files a worktree needs copied|gitignored files|\`.worktreeinclude\`"
  "the commands that start and stop the services tests need|\`services_up\`|\`services_down\`|$SETTINGS"
  "how ports, container names and database names derive from the isolation values|ports|container names|database names|isolation values|$PROFILE"
  "that tests use a throwaway database, never the dev one|throwaway database|never the dev one|$PROFILE"
)

# every_work_type_row FILE : the "Every work type" table row of FILE, one sentence per line (split on ". ").
every_work_type_row() {
  grep '^| Every work type |' "$1" | awk '{ gsub(/\. /, ".\n"); print }'
}

# has_item SENTENCES ITEM : true when one line of SENTENCES holds every fixed string the ITEM lists after its label.
has_item() {
  local sentences=$1 item=$2 needles needle line hit
  IFS='|' read -r -a needles <<<"$item"
  while IFS= read -r line; do
    hit=1
    for needle in "${needles[@]:1}"; do
      case "$line" in *"$needle"*) ;; *) hit=0 && break ;; esac
    done
    [ "$hit" -eq 1 ] && return 0
  done <<<"$sentences"
  return 1
}

ROW=$(every_work_type_row "$COVERAGE")

echo "== the Every work type row asks each worktree and test-isolation item, with its destination"
check "coverage.md has one Every work type row" '[ "$(grep -c "^| Every work type |" "$COVERAGE")" = 1 ]'
for item in "${ITEMS[@]}"; do
  check "the row asks ${item%%|*} and names where it goes" 'has_item "$ROW" "$item"'
done

shellcheck_files "shellcheck: this suite" "${BASH_SOURCE[0]}"
finish
