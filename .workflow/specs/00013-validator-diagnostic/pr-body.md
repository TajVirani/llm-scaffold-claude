## Link to issue

No tracker issue yet: the workflow does not create one when a spec starts.

## What changed

- `status-transition.sh set-task` and `initiative-transition.sh` (`write_validated`, used by every write it makes) run their template validator without `-e` and read the printed verdict.
- A `true` verdict writes; a `false` verdict refuses with today's message and exit code (1 for status-transition, 2 for initiative-transition).
- A validator yq cannot run, or any other output, now exits 1 with yq's own error text in the message; both `# Exit:` headers name this case.
- Both suites gain a yq-shim broken-validator case and checks that an ordinary rejection carries no yq `Error:` text.
- Tier A: new capability CAP-009.

## Why the change

- A yq runtime error in a writer's validator was reported as an ordinary refusal and yq's diagnostic was thrown away, so a caller could not tell a refused write from a broken validator (backlog item `001-large-path-disc-002.md`).
- CAP-009 intent: a caller can tell a write the template validator rejected from a validator that could not run, from the exit code and yq's own message.

## Why this approach

- Owning module: `feature-workflow`, with the suites in `tests`; no placement ADR.
- With `-e`, yq exits 1 and writes `Error: no matches found` both for a false verdict and for a real error, so appending stderr would put a misleading error on every ordinary refusal; reading the printed verdict without `-e` depends on no message wording (D1).
- A broken validator is an environment problem, so it exits 1 in both writers, as a missing yq does; ordinary rejections keep their codes (D2). The validator expressions are unchanged.

## Special things to note

- Report: [report.md](report.md). Task PRs: none (light path, T1 committed on the spec branch).
- Browser gate skipped: this repo has no browser suite ([.workflow/deferred/browser-suite.md](../../deferred/browser-suite.md)).
- initiative-transition's exit code for a broken validator moves from 2 to 1; an ordinary rejection still exits 2.
- A yq release that warned on stderr while exiting 0 would make a valid write fail loudly with the warning shown; no such output was seen on yq v4.54.1.

## How to test

1. Run `tests/run-all.sh --suite scripts/status-transition-tasks --suite scripts/initiative-transition`: expect both to pass (153 and 80 checks at sign-off).
2. Run `tests/run-all.sh`: expect `TOTAL passed=3623 failed=0`.

## Blast radius

- Reviewed files (tests excluded): `.agents/skills/feature-workflow/scripts/status-transition.sh`, `.agents/skills/feature-workflow/scripts/initiative-transition.sh`, `.workflow/deferred/browser-suite.md`.
- `status-transition.sh set-task` writes every task record in every spec (orchestrator 3.1-3.16, review-triage 4.7, discovered-work, sign-off 5.3, `open-task-pr.sh`); `initiative-transition.sh` writes every initiative and question change on the large path. A wrong verdict check would refuse or allow task and initiative writes in this repo and in every target project.
- The validator expressions, the step marker handling and the other yq calls are unchanged.

## Risk and reversibility

Risk: Low - the true and false paths behave as before and every writer suite passes (3623 of 3623); the new error path runs only when yq itself fails.
Reversibility: Easy - reverting the merge commit restores the old validator calls; no data or settings change.

## Areas, concepts and seams changed

- `status-transition.sh set-task` CLI: a validator yq cannot run exits 1 with yq's text (was exit 1 with the refusal message).
- `initiative-transition.sh` CLI and `write_validated`: a validator yq cannot run exits 1 with yq's text (was exit 2 with the refusal message).
- Concepts: CAP-009.

## How to undo this PR

Revert the merge commit on main (`git revert -m 1 <merge commit>`). Nothing else to restore.
