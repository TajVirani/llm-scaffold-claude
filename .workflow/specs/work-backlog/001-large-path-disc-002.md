---
origin_spec: .workflow/specs/001-large-path
origin_step: "3.7"
discovered_at: 2026-10-22
status: open
kind: bug
---

# Keep the validator's diagnostic in the single writers' refusals

## Problem

Both single writers validate a prepared copy of the file before moving it into place, and both send the validator's stderr to `/dev/null`. A yq runtime error during that check (a bad expression, a missing binary feature) is therefore reported as a validator refusal, "refusing to write ... fails the validator", and yq's own diagnostic is lost. The caller cannot tell a refused write from a broken validator.

## Evidence

- `.agents/skills/feature-workflow/scripts/initiative-transition.sh:189` (`write_validated`, on the T4 task branch at commit a5024b9, merged into `spec/001-large-path` at wave 2).
- `.agents/skills/feature-workflow/scripts/status-transition.sh:344`, the same pattern in the spec single writer.
- Reported by the T4 profile-mini-review return (`out_of_scope_noticed`, kind bug, can-wait).

## Why not a blocker

No file is ever corrupted: the prepared copy is discarded before the move, so a misreported cause costs a diagnostic, not data. No capability or journey of 001-large-path depends on the wording of the refusal.

## Suggested scope and size

- Scope: in both writers, capture the validator's stderr and append it to the refusal message (or print it after the refusal line), with one suite case per writer that feeds a broken validator expression and expects the diagnostic. Leaves out any change to the validators themselves.
- Size: one task in the feature-workflow module touching two scripts and two suites, well inside the 10-task and 30-file defaults.

## Links

- Origin spec: [spec.md](../001-large-path/spec.md)
- Design log entry: [design-log.md](../001-large-path/design-log.md) (section 2026-10-22 Discovered work: validator-stderr-hidden)
