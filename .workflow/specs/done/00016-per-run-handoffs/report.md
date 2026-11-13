# Report: Per-run session handoffs

Spec: [spec.md](spec.md) · Verification plan: [verification-plan.md](verification-plan.md) · Baseline: `0900278de2857d40567e08e21a3d9c2ba10f94b0` · Head: `a486359921afd6158bcf7b549a2c449f595aa7d8`

## Summary

The handoff skill now writes each session handoff as a new, per-run file in `.workflow/.handoff/` of the checkout the session works in, in a folder that ignores itself, and the session-start offer lists the session's own checkout's handoffs first and the other checkouts' by absolute path. The whole harness passes on the merged spec branch [E1]. The most important gap: no one has checked in a live session started inside a spec worktree that the offer lists that worktree's handoffs first; the suite proves it only against a built fixture.

## Capabilities

| Capability | Result | Evidence |
| --- | --- | --- |
| CAP-015 Per-run session handoffs | PASS | [E1], [E2] |

## Tests and CI

| Suite | Command | Result | Evidence |
| --- | --- | --- | --- |
| Unit and integration (3.9) | `tests/run-all.sh` | `TOTAL passed=4700 failed=0 skipped=0 xfail=0 (77 suites)`; exit 0 | [E1] |
| CI | none: the project has no CI | not applicable | - |

Tool audit (3.5) per task:

| Task | Result | Output |
| --- | --- | --- |
| T1 | clean (first run failed on `lint/step-list` in the task worktree, see Open items; clean once the ignored folder existed, and clean on the rework round) | [artifacts/T1/](artifacts/T1/) |
| T2 | clean | [artifacts/T2/](artifacts/T2/) |

## Targets vs measured

| Target | Threshold | Measured | Result | Command | Raw output |
| --- | --- | --- | --- | --- | --- |
| Session-start offer size with handoffs in several checkouts | under 10,000 characters of `additionalContext` | not measured: needs a repo with spec worktrees and handoffs, which only the suite builds | not measured | none | [E3] |
| Errors | the hook exits 0 for every input | not measured: asserted per case by the suite, no numeric command | not measured | none | [E3] |
| Coverage | none set | not measured: no bash line-coverage tool installed | not measured | none | [E3] |

## Journeys

| Journey | Result | Artifacts |
| --- | --- | --- |
| JRN-001 Hand off from a spec worktree | PASS | `JRN-001` checks, `scripts/handoff-skill` in [E1] |
| JRN-002 Handoff stays out of git with no ignore block | PASS | `JRN-002` check, `scripts/handoff-skill` in [E1] |
| JRN-003 Two runs, one spec, same second | PASS | `JRN-003` checks with a fixed clock, `scripts/handoff-skill` in [E1] |
| JRN-004 Offer from a spec worktree | PASS | `JRN-004` checks, `hooks/audit-sync-resume` in [E1] |
| JRN-005 Offer from the main checkout | PASS | `JRN-005` checks, `hooks/audit-sync-resume` in [E1] |
| JRN-006 Resume rules are written down | PASS | `JRN-006` checks, `scripts/handoff-skill` in [E1] |

Behaviour verification: Runtime behaviour was not exercised in a live session: the journeys ran in the harness against temp repositories, with the skill's Locate block run as written and the hook run with a payload `cwd`. Every new check failed on an assertion before the feature was built [E2].

## Review outcome

- Review passes: 1 (rework ceiling 5; rework used 1) · Findings: 3 patched (F1, F2, F3, all low), 0 left open as known gaps, 0 dismissed, 0 proposals, 0 discovered work from review (see design-log.md triage entry) · Failed lenses: none
- Follow-up review recommended: no; no finding was verified high
- Size budget: 2 of 10 tasks, 6 of 30 changed files (budget-check.sh at 5.4) · within

## Known gaps

- Gate skipped (3.10 browser suite): this repo has no browser suite; every journey is a harness check. Handoff: [.workflow/deferred/browser-suite.md](../../../deferred/browser-suite.md)
- Targets: none of the three Targets rows could be measured by a command (table above).
- Not verifiable by the review: whether a live SessionStart payload's `cwd` for a session started in a spec worktree is the worktree path. Settled by starting a real session there and reading the offer.
- Not checked by the review: a session in an agent worktree lists its own handoffs and the main checkout's, not its spec worktree's; the spec does not ask for that case.
- Task PRs were not opened: `gh` is not installed, so T1 and T2 were merged locally.

## Deferred

- [.workflow/deferred/browser-suite.md](../../../deferred/browser-suite.md): the missing browser suite; this spec added one Later requests line.

## Open items

- step-list-lint-in-agent-worktree (out of scope, found at 3.4): `lint/step-list` fails in any agent or scratch worktree because `checklist.md:328` names `.workflow/.worktrees/`, an ignored folder that exists only in a checkout that holds agent worktrees. Recommended: keep for later.

## How to verify

1. Run `tests/run-all.sh --suite scripts/handoff-skill --suite hooks/audit-sync-resume`. Expected: both suites pass, 12 and 66 checks.
2. In a spec worktree, set `stem=demo` and run the bash block under "### 1. Locate" of `.agents/skills/handoff/SKILL.md`, then `echo "$file"`. Expected: a path under that worktree's `.workflow/.handoff/` named `demo--<UTC time>-<4 chars>.md`, a `.gitignore` holding `*` beside it, and nothing new in the main checkout.
3. Create that file with any frontmatter, start a fresh session in the same folder and read the session-start offer. Expected: the handoff is listed first as `.workflow/.handoff/<name>`.

## Evidence

- [E1] [artifacts/sign-off-5.4/toolchain.txt](artifacts/sign-off-5.4/toolchain.txt), reused from the `gate-3.9-r1` run on the same tree: `TOTAL passed=4700 failed=0 skipped=0 xfail=0 (77 suites)`
- [E2] [artifacts/phase-1-known-bad/record.md](artifacts/phase-1-known-bad/record.md): the 18 new checks failing on assertions before the feature was built
- [E3] [artifacts/review/pass-1/review-targets.yaml](artifacts/review/pass-1/review-targets.yaml): the `measurements` table, all `not_measurable`
