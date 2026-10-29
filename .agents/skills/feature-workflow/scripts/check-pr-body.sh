#!/usr/bin/env bash
# File: Helper script (not a hook): check the shape of a filled Sign-off PR description (`pr-body.md`).
# Purpose: Sign-off fills `.workflow/specs/NNN-slug/pr-body.md` at 5.4 and publishes it unchanged at 5.8. This script checks
#   its shape both times, so a body with a missing, misplaced or empty section, or a risk score off its scale, never
#   reaches the PR. The script only reads the file.
#   Workflow mode (the default): the body follows assets/pr-template.md, the ten `##` sections in order (Link to issue,
#   What changed, Why the change, Why this approach, Special things to note, How to test, Blast radius, Risk and
#   reversibility, Areas, concepts and seams changed, How to undo this PR), each non-empty; the Risk and reversibility
#   section holds `Risk: Low|Medium|High` and `Reversibility: Easy|Moderate|Hard|Irreversible`, and Irreversible needs
#   Risk: High.
#   Project mode (--project-template): every `##` heading of the project's own PR/MR template is present in the body and
#   non-empty; no order or score checks.
# Usage:
#   check-pr-body.sh <file> [--project-template <template file>]
#     <file>                a filled PR body.
#     --project-template    the project's PR/MR template (e.g. .github/pull_request_template.md) when `pr_template` is project.
# stdout: nothing when the body is valid; otherwise one `<field>: <problem>` line per fault, the field being the section
#   heading, `Risk` or `Reversibility`.
# Exit: 0 the body is valid; 1 one or more faults (one line each on stdout, nothing else); 2 usage error, missing or
#   unreadable file (message on stderr).
# Called by: modules/sign-off.md (5.4 after filling pr-body.md, 5.8 before publishing it).
# Notes: bash 3.2 compatible. Interface stub: the checks are not written yet, so every call exits 3.
# Sources: first-party.

set -euo pipefail

echo "check-pr-body.sh: not implemented" >&2
exit 3
