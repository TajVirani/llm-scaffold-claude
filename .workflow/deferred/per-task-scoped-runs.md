---
origin_spec: .workflow/specs/004-scoped-test-runs
created: 2026-10-22
---

# Per-task scoped harness runs

**Summary:** The runner can now run a task's own suites, but no work profile asks it to yet, so a task's toolchain and stop audit still run the whole harness.
**Mode:** HITL
**Origin:** [004-scoped-test-runs](../specs/004-scoped-test-runs/spec.md), 4.8 review gap (review-end-state, not verifiable), design-log entry 2026-10-22 Triage, review pass 1

## Goal

On a spec with unfinished tasks, each implementation agent's 3.5 toolchain and stop audit run only that task's own suites (or every suite minus the unfinished tasks' suites when it owns none), finishing in seconds; the full harness runs once, after every task is done.

## Background

004-scoped-test-runs built the runner side (selector files, parallel runs). The profile side is a Tier A change, which happens only at sign-off 5.3 (proposals P1-P3 in that spec), and the duplicate toolchain run in the stop audit belongs to a separate spec. Until both land, the success signal "an agent's toolchain runs its own suites in seconds" cannot be observed.

**Current behaviour:** every work profile has an empty `test_scoped`, so a task's `test` key runs the whole harness (about 2.5 minutes in parallel) and a failure is reported `unscoped`.

**Desired behaviour:** with unfinished tasks, the toolchain runs the profile's `test_scoped` line, which passes the task's own and the excluded selector files to the runner; with nothing excluded, the full `test` runs.

## Decisions already made

- Own suites are the task record's Phase 1 `tests` list only; an empty list means every suite minus the excluded ones (D5, D6 in [.workflow/specs/004-scoped-test-runs/design-log.md](../specs/004-scoped-test-runs/design-log.md)).

## Evidence

- `test_scoped: ""` in `.workflow/profiles/shell-scripts.md`, `test-harness.md`, `agent-docs.md` as of commit `9fe4e82d5435bd769bfe58f9e39b65d63ae3b662`.
- review-end-state pass 1, `not_verifiable`: the success signal depends on P1-P3 at 5.3 and on the stop-audit spec.

## Acceptance criteria

- [ ] All three profiles carry the agreed `test_scoped` line.
- [ ] On a spec with an unfinished task, a task's `toolchain.json` shows `scoped: true` and only its own suites (or full minus excluded) in `toolchain.txt`.

## Out of scope

- Removing the stop audit's second toolchain run, and the implementation brief wording (the stop-audit spec).
