#!/usr/bin/env bash
# File: Helper script (not a hook): the single writer for initiative status, slice and question records, and the initiative step marker.
# Usage:
#   initiative-transition.sh status       <initiative-dir> <exploring|planned|done> [--step <node>]
#   initiative-transition.sh step         <initiative-dir> <node>
#   initiative-transition.sh set-slice    <initiative-dir> S<n> [--status <planned|emitted|done>] [--spec <NNN-slug>] [--step <node>]
#   initiative-transition.sh set-question <initiative-dir> IQ<n> [--state <open|researching|settled>] [--launched <task_type>|clear]
#                                         [--settled <text>] [--source <text>] [--step <node>]
#   initiative-transition.sh set-pr       <initiative-dir> <url>|null
#   <initiative-dir> is `.workflow/initiatives/NNN-slug`.
# Exit codes: 0 done; 1 usage or environment error; 2 illegal transition, with the reason on stderr.
# Notes: Phase 1 placeholder. It parses nothing, writes nothing and always exits 0, so the tests that drive it fail on their
#   assertions until the real script replaces this body.
# Sources: first-party.

set -euo pipefail

exit 0
