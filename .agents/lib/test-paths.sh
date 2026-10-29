#!/usr/bin/env bash
# File: Sourced helper (not a hook, not executable on its own): the one home for which repo paths count as tests.
# Purpose: The size-budget count and the flow entry candidates must agree on which files are tests, so the default test
#   patterns, the reading of each work profile's Toolchain `test_patterns` and the path matcher live here once.
# Usage (from a skill script): . "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../lib/test-paths.sh"
#   Use `cd -P` so a path reached through the .claude/skills symlink still resolves into .agents/.
# API:
#   wf_default_test_patterns            prints the default test patterns, one per line
#   wf_load_test_patterns <profiles>    prints the merged test patterns of the work profiles in the folder <profiles>, sorted
#                                       and unique; a profile whose test_patterns is [] or absent, and no profiles at all,
#                                       contribute the defaults. Returns 1 and prints the reason on stdout, in place of the
#                                       list, when a profile's test_patterns is invalid. Needs yq v4; the caller checks for it.
#   wf_is_test_path <path>              status 0 when the repo-relative <path> matches a pattern in WF_TEST_PATTERNS (one per
#                                       line), 1 when it does not. A pattern ending in / matches that folder at any depth, a
#                                       pattern holding another / the whole path, any other pattern the file name (shell globs).
#   No function exits: each caller turns status 1 into its own error message and exit code.
# Sources: first-party.

WF_DEFAULT_TEST_PATTERNS='*.test.*
*.spec.*
__tests__/
tests/
test/
e2e/
*_test.go
test_*.py
*_test.py'

# wf_default_test_patterns : print the default test patterns, one per line.
wf_default_test_patterns() {
  printf '%s\n' "$WF_DEFAULT_TEST_PATTERNS"
}

# wf_toolchain_block PROFILE : print the body of the yaml fence in PROFILE's Toolchain section; nothing when there is none.
wf_toolchain_block() {
  awk '
    /^## /{ if (intool) exit; intool = ($0 ~ /^## Toolchain[[:space:]]*$/); next }
    intool && !infence && /^```ya?ml[[:space:]]*$/ { infence=1; next }
    intool && infence && /^```[[:space:]]*$/ { exit }
    intool && infence { print }
  ' "$1"
}

# wf_profile_test_patterns PROFILE : print PROFILE's test_patterns, one per line, nothing when the key is absent or [];
#   status 1 and the reason on stdout when the block does not parse or the value is not a list of non-empty strings.
wf_profile_test_patterns() {
  local profile=$1 block tag invalid
  block=$(wf_toolchain_block "$profile")
  [[ -n "$block" ]] || return 0
  if ! tag=$(printf '%s\n' "$block" | yq '.test_patterns | tag' 2>/dev/null); then
    printf 'the Toolchain yaml block does not parse in %s\n' "$profile"
    return 1
  fi
  [[ "$tag" != "!!null" ]] || return 0
  invalid=1
  if [[ "$tag" == "!!seq" ]]; then
    invalid=$(printf '%s\n' "$block" | yq '[.test_patterns[] | select(tag != "!!str" or . == "")] | length')
  fi
  if [[ "$invalid" != 0 ]]; then
    printf 'test_patterns in %s must be a list of non-empty path patterns\n' "$profile"
    return 1
  fi
  printf '%s\n' "$block" | yq '.test_patterns[]'
}

# wf_load_test_patterns PROFILES_DIR : print the merged test patterns of the work profiles in PROFILES_DIR, sorted and
#   unique; status 1 and the reason on stdout when one profile's test_patterns is invalid.
wf_load_test_patterns() {
  local profile patterns merged=""
  for profile in "${1%/}"/*.md; do
    [[ -f "$profile" && "$(basename "$profile")" != TEMPLATE.md ]] || continue
    if ! patterns=$(wf_profile_test_patterns "$profile"); then
      printf '%s\n' "$patterns"
      return 1
    fi
    merged="$merged${patterns:-$WF_DEFAULT_TEST_PATTERNS}"$'\n'
  done
  printf '%s\n' "${merged:-$WF_DEFAULT_TEST_PATTERNS}" | sed '/^$/d' | LC_ALL=C sort -u
}

# wf_is_test_path PATH : status 0 when the repo-relative PATH matches a pattern in WF_TEST_PATTERNS, 1 when it does not.
wf_is_test_path() {
  local path=$1 pattern
  while IFS= read -r pattern; do
    [[ -n "$pattern" ]] || continue
    if [[ "$pattern" == */ ]]; then
      [[ "/$path" == *"/${pattern%/}/"* ]] && return 0
    elif [[ "$pattern" == */* ]]; then
      # shellcheck disable=SC2053 # the pattern is a glob on purpose
      [[ "$path" == $pattern ]] && return 0
    else
      # shellcheck disable=SC2053 # the pattern is a glob on purpose
      [[ "${path##*/}" == $pattern ]] && return 0
    fi
  done <<<"${WF_TEST_PATTERNS:-}"
  return 1
}
