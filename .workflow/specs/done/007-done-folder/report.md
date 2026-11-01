# Report: Done folder for finished specs

Spec: [spec.md](spec.md) · Verification plan: [verification-plan.md](verification-plan.md) · Baseline: `9e971ade158b5e92da93bf2b150fd68dd55d7e9e` · Head: `da7cf2d`

## Summary

Sign-off now closes a finished spec into the Done folder. 5.7 refuses `done` while a task or backlog item is open. 5.8 moves the spec to `.workflow/specs/done/NNN-slug`, rewrites every link to it and publishes the Sign-off PR from there. Nothing can write under `done/` afterwards. All 3951 harness tests pass on the spec branch with `main` merged in, and every measured target passes. The one-time sweep of this repo (JRN-005) runs at this sign-off's 5.8, so its result is checked there.

## Capabilities

| Capability | Result | Evidence |
| --- | --- | --- |
| CAP-011 Close a finished spec into the Done folder | PASS on fixture projects (JRN-001-004, 006, 007); this repo's sweep (JRN-005) runs at 5.8 | [E1] [E2] |

## Tests and CI

| Suite | Command | Result | Evidence |
| --- | --- | --- | --- |
| Unit and integration (3.9, 5.4) | `tests/run-all.sh` | 3951 passed, 0 failed, 64 suites; exit 0 | [E1] |
| CI | none (no CI; the run by hand is the whole gate) | not applicable | AGENTS.md "No CI" |

Tool audit (3.5) per task:

| Task | Result | Output |
| --- | --- | --- |
| T1 | clean (round 2, wording fix) | [artifacts/T1/](artifacts/T1/) |
| T2 | clean (round 2, behaviour fix) | [artifacts/T2/](artifacts/T2/) |
| T3 | clean | [artifacts/T3/](artifacts/T3/) |
| T4 | clean (rework 2) | [artifacts/T4/](artifacts/T4/) |
| T5 | clean (rework 2, fix round 2) | [artifacts/T5/](artifacts/T5/) |
| integration-shell-scripts | clean | [artifacts/integration-shell-scripts/](artifacts/integration-shell-scripts/) |

## Targets vs measured

| Target | Threshold | Measured | Result | Command | Raw output |
| --- | --- | --- | --- | --- | --- |
| TGT-001 Script lint clean | exit 0; 0 shellcheck findings | 0 findings across 46 files | PASS | `script-lint` | [E3] |
| TGT-002 Harness lint clean | exit 0; 0 shellcheck findings | 0 findings across 75 files | PASS | `harness-lint` | [E3] |
| TGT-003 Agent-docs lint clean | each lint suite reports 0 failed | not measured by the pass-3 lens (its command runs the harness); the 5.4 harness run shows frontmatter 40/0, step-list 36/0, symlinks 45/0, upstream-lineage 13/0 | PASS (from the 5.4 run) | `agent-docs-lint` | [E1] |
| TGT-004 Literal Done folder paths in scripts | 0 printed | 0 | PASS | `done-literal` | [E3] |
| TGT-005 Changed scripts no suite names | 0 printed | 0 (6 scripts checked) | PASS | `script-coverage` | [E3] |
| TGT-006 New `.agents/` files missing from manifest or PROVENANCE | 0 printed | 0 (1 file checked) | PASS | `asset-coverage` | [E3] |
| TGT-007 `move-to-done.sh --sweep` wall time | real ≤ 30 s, best of 3 | 12.86 s | PASS | `sweep-time` | [E3] |
| TGT-008 Line coverage of changed shell code | not measured | not measured: no bash coverage tool, no new dependencies; TGT-005 and the 3.7 checklist stand in | not measured | none | [E3] |

## Journeys

| Journey | Result | Artifacts |
| --- | --- | --- |
| JRN-001 Check refuses an open task | PASS | `tests/scripts/move-to-done.sh` in [E1] |
| JRN-002 Sign-off move with links | PASS | `tests/scripts/move-to-done.sh` in [E1] |
| JRN-003 Sweep | PASS | `tests/scripts/move-to-done.sh` in [E1] |
| JRN-004 Readers after the move | PASS | `move-to-done`, `check-write-paths`, `lib-workflow-paths`, `review-lessons`, `session-start-initiatives` in [E1] |
| JRN-005 This repo swept | not exercised yet: runs at this sign-off's 5.8 (D16), followed by `tests/run-all.sh` | none yet |
| JRN-006 Sign-off PR body after the move | PASS | `move-to-done`, `sign-off-pr`, `lint/done-folder-docs` in [E1] |
| JRN-007 Any-digit spec numbers | PASS | `tests/scripts/move-to-done.sh` in [E1] |

Behaviour verification: every journey except JRN-005 runs as a harness suite against a fixture project in a temp git repo; the sweep was also run three times on scratch clones of this repo at the baseline for TGT-007 [E3].

## Review outcome

- Review passes: 3 (rework 2 of 5) · Findings: 4 patched (F1, F4, F5, F6), 0 deferred, 3 dismissed with reason (F2, F7, F8), 1 filed as discovered work (F3); see design-log.md triage entries.
- Follow-up review recommended: no (pass 3 clean, no verified high open).

## Known gaps

- JRN-005 and the Success signal: the sweep of this repo runs at 5.8, after this report.
- "The next spec to finish sign-off lands there by itself": seen only on a later real sign-off.
- No harness suite runs the large-path 6.13 rewrite loop; recorded in [work-backlog/007-done-folder-disc-001.md](../../work-backlog/007-done-folder-disc-001.md).
- TGT-008 line coverage not measured (no tool).
- TGT-007 is load-sensitive: one implementer run at load average 23 took 33.86 s.

## Deferred

- [.workflow/deferred/sign-off-scoped-commit.md](../../../deferred/sign-off-scoped-commit.md): 5.8 stages every untracked folder (Later requests line).
- [.workflow/deferred/launch-against-done-spec.md](../../../deferred/launch-against-done-spec.md): a sub-agent launch with a Done folder `spec_dir` is refused.

## How to verify

1. `tests/run-all.sh`: expect `TOTAL ... failed=0` across 64 suites.
2. `tests/run-all.sh --suite scripts/move-to-done`: expect every case to pass (check, move, rewrite, sweep, rollback).
3. After this merge, `ls .workflow/specs/done/`: expect 001-006, 007, 008 and 00010-00013; `ls .workflow/specs/`: expect only 009, `work-backlog/` and `done/`.

## Evidence

- [E1] `artifacts/sign-off-5.4/toolchain.txt` and `toolchain.json` (`tests/run-all.sh` at `da7cf2d`: 3951 passed, 0 failed, 64 suites)
- [E2] `artifacts/gate-3.9-rework2/toolchain.txt` (last-wave gate after rework 2: 3796 passed, 0 failed)
- [E3] `artifacts/review/pass-3/review-targets.yaml` (`measurements:` table)
