# Report: Sub-agents can write their own result file

Spec: [spec.md](spec.md) · Verification plan: [verification-plan.md](verification-plan.md) · Baseline: `e049f4dde93474aca594212026144ed7006a917f` · Head: `ce8edb0`

## Summary

Implementation, integration and mini-review agents now write their result file straight to the main checkout. Phase 1 and integration agents run in agent worktrees the orchestrator makes, with no isolation. An artifacts gate guards every merge, read-only commands pass the worktree guard, and `install.sh` resolves a differing hook matcher per group on upgrade. All 7 tasks passed review, the full harness passes (3475/0), and review pass 2 was clean.

The most important gap is JRN-010. No live Phase 1 or integration launch without isolation has run yet, so the next spec's first such launch confirms the path end to end.

## Capabilities

| Capability | Result | Evidence |
| --- | --- | --- |
| CAP-007 Sub-agents file their own result file | PASS (harness); JRN-010 live launch not verified | [E1] [E2] |
| CAP-008 Read-only commands pass the worktree guard | PASS, with sed reads narrowed to print-only scripts by stakeholder decision D31 (the success line lists `sed -n`) | [E1] [E3] |

## Tests and CI

| Suite | Command | Result | Evidence |
| --- | --- | --- | --- |
| Unit and integration (3.9) | `tests/run-all.sh` | 3475 passed, 0 failed, 60 suites; exit 0 | [E1] |
| CI | none (no CI; the run by hand is the whole gate) | not applicable | |

Tool audit (3.5) per task:

| Task | Result | Output |
| --- | --- | --- |
| T1 | clean (4 fix rounds; mini-review pass round 3) | [artifacts/T1/](artifacts/T1/) |
| T2 | clean (1 fix round) | [artifacts/T2/](artifacts/T2/) |
| T3 | clean (rework 1 for F1) | [artifacts/T3/](artifacts/T3/) |
| T4 | clean (3 fix rounds; D31) | [artifacts/T4/](artifacts/T4/) |
| T5 | clean (1 wording round; rework 1 for F2) | [artifacts/T5/](artifacts/T5/) |
| T6 | clean (5 fix rounds; D32) | [artifacts/T6/](artifacts/T6/) |
| T7 | clean | [artifacts/T7/](artifacts/T7/) |

## Targets vs measured

| Target | Threshold | Measured | Result | Command | Raw output |
| --- | --- | --- | --- | --- | --- |
| Script lint clean | exit 0; 0 findings | 0 shellcheck findings, exit 0 | PASS | `script-lint` | [E4] |
| Harness lint clean | exit 0; 0 findings | 0 shellcheck findings, exit 0 | PASS | `harness-lint` | [E4] |
| Agent-docs lint clean | each suite 0 failed | 0 failed in all four suites | PASS | `agent-docs-lint` | [E4] |
| Every script this spec adds or changes has a suite | 0 | 0 | PASS | `script-coverage` | [E4] |
| Every new `.agents/` asset is in the manifest and PROVENANCE.md | 0 | 0 | PASS | `asset-coverage` | [E4] |
| No `codex_enc` copy left in the hooks | 0 | 0 | PASS | `codex-enc-copies` | [E4] |
| Worktree scope check time on a long read-only chain | real ≤ 0.2 s, best of 3 | 0.04 s | PASS | `guard-time` (from the main checkout) | [E4] |
| Line coverage of changed shell code | not measured | not measured: no bash coverage tool, no new dependency (D17) | not measured | none | |

## Journeys

| Journey | Result | Artifacts |
| --- | --- | --- |
| JRN-001 Names agree across hosts | PASS | `tests/scripts/lib-workflow-paths.sh` [E1] |
| JRN-002 Phase 1 agent files its result | PASS | `tests/hooks/worktree-guard.sh` [E1] |
| JRN-003 Integration agent files its result | PASS | `tests/hooks/worktree-guard.sh` [E1] |
| JRN-004 Phase 3 result lands in the main checkout | PASS | `tests/hooks/worktree-guard.sh` [E1] |
| JRN-005 Stop audit finds the agent worktree | PASS | `tests/hooks/audit-agent-worktrees.sh` [E1] |
| JRN-006 Settings matcher upgrade | PASS | `tests/scripts/install-claude-settings.sh`, `install-upgrade.sh` [E1] |
| JRN-007 Artifacts merge gate | PASS; also run for real before the T7 and rework merges (exit 0) | `tests/scripts/check-merge-artifacts.sh` [E1] |
| JRN-008 Orchestrator text matches the design | PASS | `tests/lint/agent-worktree-docs.sh` [E1] |
| JRN-009 Read-only commands pass, writes do not | PASS | `tests/hooks/worktree-guard.sh` [E1] |
| JRN-010 A real launch files its own result | not exercised for Phase 1 and integration; every Phase 3 implementation and mini-review launch here wrote its result file to the main checkout with no copy | [artifacts/T1/](artifacts/T1/) to [artifacts/T7/](artifacts/T7/) |
| JRN-011 Upgrade resolves matchers without a terminal | PASS | `tests/scripts/install-upgrade.sh` [E1] |
| JRN-012 `--matchers` answers every group | PASS | `tests/scripts/install-upgrade.sh` [E1] |
| JRN-013 Terminal prompt | PASS (pseudo-terminal via `script` on macOS) | `tests/scripts/install-upgrade.sh` [E1] |
| JRN-014 Docs describe the rule | PASS | `tests/lint/install-matcher-docs.sh` [E1] |

Behaviour verification: the scaffold has no running application. Each journey runs the real hooks, scripts and `install.sh` against fixture repos in the harness. The artifacts gate also ran for real before three merges into this spec branch, and every Phase 3 agent's result file landed in the main checkout. A Phase 1 or integration launch without isolation has not run.

## Review outcome

- Review passes: 2 (rework 1 of 5 used). Findings: 2 patched (F1 high, F2 low), 3 filed as discovered work (F3 to F5), 0 deferred, 0 dismissed. See the design-log triage entries.
- Follow-up review recommended: no. Pass 2 was clean on all four lenses.
- Shipped differently from the agreed text: D31 narrows CAP-008's `sed -n` read to print-only scripts (an address or range plus `p`). Every other sed form needs the leading `cd`.

## Known gaps

- JRN-010: no live Phase 1 or integration launch without isolation, so Claude Code's acceptance of the heredoc result-file command from such an agent is unconfirmed. The next spec's first Phase 1 build or integration batch checks it.
- Line coverage of changed shell code: not measured (D17).
- Lens `not_checked` items: no `CODING_STANDARDS.md`, `CONTRIBUTING.md` or `GLOSSARY-MAP.md`; typecheck, format and boundary toolchain keys have no command, so module boundaries were checked by hand.

## Deferred

- Phase 0 shelf: [worktree-name-parser.md](../../../deferred/worktree-name-parser.md) (one Later request added at 3.7), [codex-spawn-profile-lookup.md](../../../deferred/codex-spawn-profile-lookup.md), [known-bad-evidence-path.md](../../../deferred/known-bad-evidence-path.md).
- Work backlog filed by this spec: `006-result-file-guard-disc-001` to `disc-010` (ruled at 5.5).

## How to verify

1. `tests/run-all.sh`: expect `TOTAL passed=3475 failed=0` (60 suites).
2. `tests/run-all.sh --suite hooks/worktree-guard --suite scripts/install-upgrade --suite scripts/check-merge-artifacts`: expect every case to pass.

## Evidence

- [E1] [artifacts/sign-off-5.4/toolchain.txt](artifacts/sign-off-5.4/toolchain.txt): `TOTAL passed=3475 failed=0 skipped=0 xfail=0 (60 suites)`; also [artifacts/gate-3.9-rework1/](artifacts/gate-3.9-rework1/).
- [E2] [artifacts/review/pass-2/review-end-state.yaml](artifacts/review/pass-2/review-end-state.yaml): F1 and F2 confirmed fixed.
- [E3] design-log.md "T4 mini-review round 2" (D31) and [artifacts/T4/mini-review.yaml](artifacts/T4/mini-review.yaml).
- [E4] [artifacts/review/pass-2/review-targets.yaml](artifacts/review/pass-2/review-targets.yaml) `measurements:`.
