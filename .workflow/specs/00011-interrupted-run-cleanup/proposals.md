# Proposals: Interrupted harness runs clean up their background suites

Spec: [spec.md](spec.md) · Report: [report.md](report.md)

Status values: `proposed` · `approved` · `modified` · `rejected`

## Capabilities

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | `.workflow/capabilities.md` § CAP-001 row | replace: `CAP-001 \| Scoped and parallel harness runs: ... with the same report as a serial run \| [004]` -> `CAP-001 \| Scoped and parallel harness runs: ... with the same report as a serial run; an interrupted run (INT, TERM or HUP) stops every suite and its child processes and exits 130, 143 or 129 \| [.workflow/specs/004-scoped-test-runs](specs/004-scoped-test-runs/spec.md), [.workflow/specs/00011-interrupted-run-cleanup](specs/00011-interrupted-run-cleanup/spec.md)` | Without it, 0.3.1 of a later request about stopping or killing a harness run would not find that CAP-001 already covers it, and would mint a duplicate capability | spec.md § Capabilities (CAP-001 changed) | approved | |

## Pitfalls

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P2 | `.workflow/decisions/pitfalls.md` | `## Give a job started under set -m its own stdin` · What happened: turning job control on (`set -m`) to start each harness suite in its own process group also stopped bash from giving the background job `/dev/null` as stdin, so suites read the runner's stdin (a terminal read would stop the run with SIGTTIN; a pipe's input would be consumed). Found by review, fixed in rework 1. · Where: `tests/run-all.sh` `start_suite` · Spec: .workflow/specs/00011-interrupted-run-cleanup · Prevented by: the stdin end-of-file check in `tests/scripts/run-all-selection.sh` | Without it, the next script that borrows the `set -m` process-group pattern (as `review-targets.md` and the runner do) would again drop the implicit `/dev/null` stdin and could hang a terminal run | triage F1 (design-log.md, Triage, review pass 1) | approved | |
