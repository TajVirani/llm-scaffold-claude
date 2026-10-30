---
status: done # draft | ready-for-dev | in-progress | in-review | done | blocked. Changed only by scripts/status-transition.sh.
baseline_revision: "7b0ccebe3e9e0616e5897479915113897dc40fbe" # full SHA of the commit the work starts from; "" until captured, then never overwritten
spec_branch: spec/00013-validator-diagnostic # spec/NNN-slug, created off main at 1.1 (0.3.20 on the light path); "" until then
impl_base_revision: "7b0ccebe3e9e0616e5897479915113897dc40fbe" # full SHA of the spec-branch tip when Phase 3 starts (3.1); "" until then, never overwritten
light_path: true # true once the 0.3.20 light-path test passes
followup_review_recommended: false # true when triage recommends another review pass after this one
deferred: [.workflow/deferred/browser-suite.md] # repo-relative paths of the .workflow/deferred/ files this spec wrote, e.g. .workflow/deferred/csv-export.md
origin: 001-large-path-disc-002.md
budget: {max_tasks: 10, max_changed_files: 30}
---

# The single writers keep the validator's diagnostic

## Why

Origin: 001-large-path-disc-002.md, a validator diagnostic is lost in the single writers' refusals.

Both single writers, `status-transition.sh` (spec task records) and `initiative-transition.sh` (initiative and questions files), validate a prepared copy of the file before moving it into place, and both send the validator's output to `/dev/null`. A yq runtime error during that check (a bad expression, a missing binary feature) is reported as an ordinary refusal ("refusing to write ... fails the validator"), and yq's own diagnostic is lost, so the caller (the orchestrator, or a human reading the stop) cannot tell a refused write from a broken validator and chases the wrong cause. A refusal must say which of the two happened.

## Capabilities

- **CAP-009** Single writers report a broken validator
  - **intent:** A caller of `status-transition.sh set-task` or `initiative-transition.sh` can tell a write the template validator rejected from a validator that could not run, from the exit code and yq's own message.
  - **success:** With a PATH yq shim that fails only the validator call, each writer exits 1, its stderr includes the shim's diagnostic, the target file is byte-identical and no prepared copy is left; an ordinary rejection keeps today's message (with no `Error:` text from yq) and exit code (1 for status-transition, 2 for initiative-transition).

## Constraints

- Both writers run their validator without `-e`: printed `true` writes, printed `false` refuses with today's message, a non-zero yq exit or any other output is a validator error whose message includes yq's stderr (D1).
- A validator error exits 1 in both writers; an ordinary rejection keeps its exit code; each `# Exit:` header names the case (D2).
- The validator expressions do not change (`TASKS_VALIDATOR` stays equal to `assets/tasks.md`'s).
- The prepared copy is discarded on every refusal and error; the target file and the step marker are untouched.
- bash 3.2 and mikefarah yq v4 only.

## Non-goals

- Changing any validator expression or template.
- Changing the other yq calls in the writers (reads, the EXPR edit and its `cannot update` error).

## Success signal

A broken validator expression in either writer produces exit 1 and a message carrying yq's diagnostic, while an ordinary schema rejection prints exactly what it printed before.

## Links

- Codebase map: [codebase-map.md](codebase-map.md)
- Design log: [design-log.md](design-log.md)
- Tasks: [tasks.md](tasks.md)

## Known gaps

- Gate skipped (3.10 browser suite): no `e2e-browser` profile in this repo. Handoff: [.workflow/deferred/browser-suite.md](../../deferred/browser-suite.md)
