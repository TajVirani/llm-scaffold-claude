#!/usr/bin/env bash
# File: Sourced helper (not a hook, not executable on its own): the one home for which repo paths count as tests.
# Purpose: The size-budget count and the flow entry candidates must agree on which files are tests, so the default test
#   patterns, the reading of each work profile's Toolchain `test_patterns` and the path matcher live here once.
# Usage (from a skill script): . "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../lib/test-paths.sh"
#   Use `cd -P` so a path reached through the .claude/skills symlink still resolves into .agents/.
# API:
#   wf_default_test_patterns            prints the default test patterns, one per line
#   wf_load_test_patterns <profiles>    prints the merged test patterns of the work profiles in the folder <profiles>, sorted
#                                       and unique; returns 1 and prints the reason when a profile's test_patterns is invalid
#   wf_is_test_path <path>              status 0 when the repo-relative <path> matches a pattern in WF_TEST_PATTERNS (one per
#                                       line), 1 when it does not
# Sources: first-party.
# Placeholders until the shared rules move here: each function keeps the contract above but does no work yet.

wf_default_test_patterns() {
  return 0
}

wf_load_test_patterns() {
  return 0
}

wf_is_test_path() {
  return 1
}
