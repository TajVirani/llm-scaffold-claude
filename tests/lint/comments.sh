#!/usr/bin/env bash
# Suite: lint of the comments in this repo's tracked shell files with check-comments.sh: no body comment names a decision,
#   journey or task id or a .workflow/ path, and no header block names a decision or task id.
# Covers: the files the shell-scripts and test-harness profiles lint (hooks, lib, skill scripts, install.sh, scripts/ and
#   tests/). Reads the repo; writes nothing.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

LINT="$AGENTS_SRC/skills/feature-workflow/scripts/check-comments.sh"

out=$(cd "$REPO_ROOT" && git ls-files -z -- '.agents/hooks/*.sh' '.agents/lib/*.sh' '.agents/skills/*/scripts/*.sh' install.sh \
  'scripts/*.sh' 'tests/*.sh' | xargs -0 "$LINT" 2>&1)
rc=$?
check "every tracked shell file passes the comment lint" '[[ $rc == 0 ]]' "$out"
shellcheck_files "the comment lint suite is shellcheck clean" "${BASH_SOURCE[0]}"

finish
