#!/usr/bin/env bash
# File: Shared test helpers (sourced by every suite; scaffold-only, see tests/README.md).
# Provides: repo paths, tool preflight, a scratch-dir factory, a fixture-project builder that copies
#   .agents/ from this repo, assertion helpers and a result footer. bash 3.2 compatible.
# Usage in a suite:
#   source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
#   preflight                      # exits 2 with a clear message if bash/git/jq/yq v4 are unusable
#   new_workdir                    # sets WORK to a fresh mktemp dir, removed on exit
#   copy_agents "$WORK/proj"       # copies .agents/ from the repo into the fixture
#   t "name" 0 cmd args...         # assert exit code
#   eq "name" "$got" "$want"       # assert equality
#   check "name" 'shell expr'      # assert an eval'd expression is true
#   finish                         # prints "RESULT passed=N failed=M skipped=K xfail=X", exits non-zero on failure

set -uo pipefail

TESTS_LIB_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TESTS_DIR=$(dirname "$TESTS_LIB_DIR")
REPO_ROOT=$(dirname "$TESTS_DIR")
AGENTS_SRC="$REPO_ROOT/.agents"
export REPO_ROOT TESTS_DIR AGENTS_SRC

# Tests must not inherit the caller's Claude project dir.
unset CLAUDE_PROJECT_DIR

PASS=0
FAIL=0
SKIP=0
XFAIL=0

ok() { PASS=$((PASS + 1)); printf 'ok   %s\n' "$1"; }
ko() {
  FAIL=$((FAIL + 1))
  printf 'FAIL %s\n' "$1"
  [ -z "${2:-}" ] || printf '       %s\n' "${2:0:600}"
}
skip() { SKIP=$((SKIP + 1)); printf 'skip %s (%s)\n' "$1" "${2:-}"; }

# xfail NAME REASON EXPR : a known script defect (reported, not fixed here). Counts as expected-fail while EXPR is
# false; fails the suite when EXPR starts passing, so the test is updated once the script is fixed.
xfail() {
  if eval "$3"; then
    ko "$1 (unexpectedly passes; drop the xfail)" "$2"
  else
    XFAIL=$((XFAIL + 1))
    printf 'xfail %s (%s)\n' "$1" "$2"
  fi
}

# t NAME EXPECTED_RC CMD... : run a command, compare its exit code.
t() {
  local name=$1 exp=$2 out rc
  shift 2
  out=$("$@" 2>&1)
  rc=$?
  if [ "$rc" = "$exp" ]; then ok "$name"; else ko "$name" "rc=$rc want=$exp: $out"; fi
}

# eq NAME GOT WANT
eq() {
  if [ "$2" = "$3" ]; then ok "$1"; else ko "$1" "got=$2 want=$3"; fi
}

# check NAME EXPR [DETAIL] : eval EXPR in the caller's shell; true means pass.
check() {
  if eval "$2"; then ok "$1"; else ko "$1" "${3:-}"; fi
}

# finish : footer that run-all.sh parses; non-zero when anything failed.
finish() {
  printf '\nRESULT passed=%s failed=%s skipped=%s xfail=%s\n' "$PASS" "$FAIL" "$SKIP" "$XFAIL"
  [ "$FAIL" -eq 0 ]
  exit $?
}

# preflight : require bash 3.2+, git, jq and mikefarah yq v4. Exit 2 with install hints otherwise.
preflight() {
  local missing=0 v
  if [ "${BASH_VERSINFO[0]}" -lt 3 ]; then
    echo "preflight: bash 3.2 or newer required (found $BASH_VERSION)" >&2
    missing=1
  fi
  command -v git >/dev/null 2>&1 || { echo "preflight: git not found on PATH" >&2; missing=1; }
  command -v jq >/dev/null 2>&1 || { echo "preflight: jq not found on PATH (brew install jq)" >&2; missing=1; }
  if ! command -v yq >/dev/null 2>&1; then
    echo "preflight: yq not found on PATH (mikefarah yq v4: https://github.com/mikefarah/yq)" >&2
    missing=1
  else
    v=$(yq --version 2>&1)
    case "$v" in
      *mikefarah*version\ v4.* | *mikefarah*version\ 4.*) ;;
      *) echo "preflight: yq is not mikefarah yq v4 (got: $v)" >&2; missing=1 ;;
    esac
  fi
  [ "$missing" -eq 0 ] || exit 2
}

# have_shellcheck : true when shellcheck is on PATH.
have_shellcheck() { command -v shellcheck >/dev/null 2>&1; }

# Lint helper: shellcheck_files NAME FILE... : one assertion; skipped with a message when shellcheck is missing.
shellcheck_files() {
  local name=$1 out
  shift
  if ! have_shellcheck; then skip "$name" "shellcheck not installed"; return; fi
  if out=$(shellcheck -x -P SCRIPTDIR "$@" 2>&1); then ok "$name"; else ko "$name" "$out"; fi
}

# new_workdir : sets WORK (physical path) to a fresh temp dir, removed when the suite exits.
new_workdir() {
  WORK=$(mktemp -d "${TMPDIR:-/tmp}/scaffold-test.XXXXXX") || exit 2
  WORK=$(cd "$WORK" && pwd -P)
  # shellcheck disable=SC2064
  trap "rm -rf '$WORK'" EXIT
  export WORK
}

# copy_agents DEST : copy this repo's .agents/ into DEST/.agents (DEST is created).
copy_agents() {
  mkdir -p "$1"
  cp -R "$AGENTS_SRC" "$1/.agents"
}

# git_init_repo DIR : git init (branch main) with a test identity.
git_init_repo() {
  mkdir -p "$1"
  git init -q -b main "$1"
  git -C "$1" config user.email t@t.invalid
  git -C "$1" config user.name tester
}

# git_commit_all DIR MESSAGE
git_commit_all() {
  git -C "$1" add -A >/dev/null
  git -C "$1" commit -q --allow-empty -m "$2"
}

# make_fixture_repo DIR : git repo with a committed copy of .agents/ (the standard hook/script fixture).
make_fixture_repo() {
  git_init_repo "$1"
  copy_agents "$1"
  git_commit_all "$1" init
}

# Exported locations of the components under test.
FW_SKILL="$AGENTS_SRC/skills/feature-workflow"
HOOKS_DIR="$AGENTS_SRC/hooks"
export FW_SKILL HOOKS_DIR
