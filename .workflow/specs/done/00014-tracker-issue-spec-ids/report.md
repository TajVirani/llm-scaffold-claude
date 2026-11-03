# Report: Tracker issues as spec IDs

Spec: [spec.md](spec.md) · Verification plan: [verification-plan.md](verification-plan.md) · Baseline: `e8162a94fb923cdae2496f4db5c8d9231abcabfc` · Head: `c6b0055`

## Summary

With a GitLab or GitHub tracker set up, a spec's number now comes from a new tracker issue, its tasks become child issues or sub-issues, and the issues move through a three-label issue flow up to the Sign-off PR that closes them; with no tracker, numbering is unchanged. The full harness passes (4,770 tests, 81 suites) and every measurable target passes. The most important gap is that the tracker calls are proven only against fake gh and glab, never a live GitLab or GitHub.

## Capabilities

| Capability | Result | Evidence |
| --- | --- | --- |
| CAP-013 Specs and tasks filed as tracker issues | PASS against fake CLIs (JRN-001 to JRN-009, JRN-015, JRN-016) | [E1], [E2] |
| CAP-014 Tracker setup and adoption | PASS against fake CLIs and a local bare origin (JRN-010 to JRN-014) | [E1], [E2] |

## Tests and CI

| Suite | Command | Result | Evidence |
| --- | --- | --- | --- |
| Unit and integration (3.9, 5.4) | `tests/run-all.sh` | TOTAL passed=4770 failed=0 skipped=0 xfail=0 (81 suites); exit 0 | [E1] |
| CI | none (this repo has no CI; the run by hand is the whole gate) | not applicable | - |

Tool audit (3.5) per task, newest round:

| Task | Result | Output |
| --- | --- | --- |
| T1 | clean | [artifacts/T1/](artifacts/T1/) |
| T2 | clean | [artifacts/T2/](artifacts/T2/) |
| T3 | clean (round 3 after rework 1) | [artifacts/T3/](artifacts/T3/) |
| T4 | clean (round 3 after rework 1) | [artifacts/T4/](artifacts/T4/) |
| T5 | clean (round 3 after rework 1) | [artifacts/T5/](artifacts/T5/) |
| T6 | clean | [artifacts/T6/](artifacts/T6/) |
| T7 | clean | [artifacts/T7/](artifacts/T7/) |
| T8 | clean (round 4 after rework 2) | [artifacts/T8/](artifacts/T8/) |
| T9 | clean | [artifacts/T9/](artifacts/T9/) |
| T10 | clean (round 2 after rework 1) | [artifacts/T10/](artifacts/T10/) |

## Targets vs measured

| Target | Threshold | Measured | Result | Command | Raw output |
| --- | --- | --- | --- | --- | --- |
| New-feature start load | ≤ 45,000 bytes | 44,286 bytes | PASS | `load-new-start` | [E3] |
| Implementation resume load | ≤ 55,000 bytes | 54,967 bytes | PASS | `load-impl-resume` | [E3] |
| Script lint clean | exit 0; 0 shellcheck findings | 0 findings across 53 files | PASS | `script-lint` | [E3] |
| Harness lint clean | exit 0; 0 shellcheck findings | 0 findings across 94 files | PASS | `harness-lint` | [E3] |
| Agent-docs lint clean | exit 0; each suite 0 failed | 4 of 4 suites 0 failed | PASS | `agent-docs-lint` | [E3] |
| Every script this spec adds or changes has a suite | 0 | 0 | PASS | `script-coverage` | [E3] |
| Every new `.agents/` file is in `PROVENANCE.md` | 0 | 0 | PASS | `asset-coverage` | [E3] |
| Line coverage of changed shell code | not measured | not measured: no bash coverage tool is installed | not measured | - | [E3] |

## Journeys

| Journey | Result | Artifacts |
| --- | --- | --- |
| JRN-001 No tracker, unchanged numbering | PASS | `scripts/next-spec-number`, `scripts/issue-tracking`, `lint/issue-tracking-docs` [E1] |
| JRN-002 Spec number from a GitLab issue | PASS | `scripts/issue-tracking` [E1] |
| JRN-003 Spec number from a GitHub issue | PASS | `scripts/issue-tracking` [E1] |
| JRN-004 Two starts, two numbers | PASS (fake tracker) | `scripts/issue-tracking` [E1] |
| JRN-005 Spec synced into the issue | PASS | `scripts/issue-tracking`, `lint/issue-tracking-docs` [E1] |
| JRN-006 Task issues under the spec issue | PASS | `scripts/issue-tracking`, `scripts/status-transition-tasks`, `lint/issue-tracking-docs` [E1] |
| JRN-007 Issue flow moves | PASS | `scripts/issue-tracking`, `lint/issue-tracking-docs` [E1] |
| JRN-008 Unreachable tracker stops | PASS | `scripts/issue-tracking` [E1] |
| JRN-009 Sign-off PR link | PASS | `scripts/sign-off-pr` [E1] |
| JRN-010 Setup check and save | PASS | `scripts/issue-tracking-setup` [E1] |
| JRN-011 Tracker adoption | PASS | `scripts/tracker-adoption` [E1] |
| JRN-012 `old_` names accepted | PASS | `scripts/lib-workflow-paths`, `scripts/review-lessons`, `scripts/check-write-paths`, `scripts/tracker-adoption`, `hooks/audit-sync-resume` [E1] |
| JRN-013 Shared lib, no copies | PASS | `scripts/move-to-done` and siblings, `lint/shared-tracker-logic` [E1] |
| JRN-014 Setup step and packaging | PASS | `lint/issue-tracking-docs`, `lint/frontmatter`, `lint/symlinks` [E1] |
| JRN-015 Load budget | PASS | `lint/workflow-load-size` [E1], [E3] |
| JRN-016 Full suite green | PASS | `tests/run-all.sh` [E1] |

Behaviour verification: runtime behaviour was exercised only against fake gh and glab on PATH and a local bare git origin, as the spec requires (D17); no live tracker was called.

## Review outcome

- Review passes: 2 (rework used 2 of 5). Findings over 12 triaged: 8 patched (F1, F2, F3, F5, F6, F8, F9, F12), 2 discovered work waiting for a ruling (F4, F10), 1 proposal (F7, applied as P2), 1 dismissed with reason (F11). Failed lenses: none. See the design-log triage entries.
- Follow-up review recommended: no; pass 2 had no verified high finding.

## Known gaps

- The GitLab child-task GraphQL call, the `relates_to` fallback and the `glab api :fullpath` calls are proven against the fake glab only (D17). One run against a real GitLab project settles it.
- A real `gh issue close` or GitLab `state_event=close` on an issue that `Closes #<n>` already closed is expected to be a no-op, but this is unverified.
- The gh 2.94.0 and glab 1.115.0 minimum versions are unverified against a real install.
- Two simultaneous spec starts on a real tracker are proven only against the fake's increasing numbers.
- On a GitLab served over plain http, an issue is filed before `issue-tracker.sh` refuses its URL (F11, dismissed).
- Line coverage of changed shell code is not measurable.
- Not checked by review, for the stakeholder:
  - Whether adoption should move an already-started spec's issue to in progress.
  - Whether the new `tracker_issue: ""` and `issue: null` template keys count as "templates unchanged" with no tracker.
  - The https URL rule still has several copies of slightly different shape.

## Deferred

- [.workflow/deferred/done-spec-branch-fallback.md](../../../deferred/done-spec-branch-fallback.md): the fallback branch name for a Done spec.
- [.workflow/deferred/initiative-tracker-issues.md](../../../deferred/initiative-tracker-issues.md): tracker issues and numbering for initiatives and converted specs.

Waiting for the stakeholder's ruling:
- F4 (scope-expanding): Tracker adoption does not rewrite initiative files. Recommended: fold in, as a refusal.
- F10 (out of scope): step files prescribe commit subjects that are not Conventional Commits. Recommended: keep for later.

## How to verify

1. `tests/run-all.sh`: expect 81 suites, 0 failed.
2. `bash tests/lint/workflow-load-size.sh`: expect new-feature start ≤ 45,000 bytes and implementation resume ≤ 55,000.
3. `.agents/skills/feature-workflow/scripts/next-spec-number.sh` in a repo with no `.workflow/issue-tracking.yaml`: expect the next local number and no gh or glab call.

## Evidence

- [E1] [artifacts/sign-off-5.4/toolchain.txt](artifacts/sign-off-5.4/toolchain.txt): `TOTAL passed=4770 failed=0 skipped=0 xfail=0 (81 suites)`; also [artifacts/gate-3.9-rework2/](artifacts/gate-3.9-rework2/).
- [E2] [artifacts/phase-1-known-bad/record.md](artifacts/phase-1-known-bad/record.md): every new test failed on an assertion before the feature was built.
- [E3] [artifacts/review/pass-2/review-targets.yaml](artifacts/review/pass-2/review-targets.yaml): the measurements table.
