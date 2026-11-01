# Report: Worktree guard and upgrade follow-ups

Spec: [spec.md](spec.md) · Verification plan: [verification-plan.md](verification-plan.md) · Baseline: `1c5e46d` · Head: `f276ea1`

## Summary

The worktree guard now fails closed. A confined implementation or integration agent whose agent worktree cannot be established is denied every call, and the guard also denies on an unparsable payload or a missing jq. Single-quoted `$` reads pass the guard without the `cd`, guard messages say "agent worktree", the shipped settings deny an in-place `yq --front-matter=extract` (confirmed live), the upgrade re-run checks assert exit 0, and the asset record matches what spec 006 built. The full harness passes (3678 checks, 62 suites). The main gap: other in-place spellings such as `-Pi` still pass the extract allow (deferred, medium).

## Capabilities

| Capability | Result | Evidence |
| --- | --- | --- |
| CAP-007 Sub-agents file their own result file (changed: fail closed) | PASS | [E1], [E2], [E5] |
| CAP-008 Read-only commands pass the worktree guard (changed: quoted `$`) | PASS | [E1], [E2] |
| CAP-010 In-place frontmatter extract denied | PASS | [E1], [E3], [E4] |

## Tests and CI

| Suite | Command | Result | Evidence |
| --- | --- | --- | --- |
| Unit and integration (3.9) | `tests/run-all.sh` | `TOTAL passed=3678 failed=0 skipped=0 xfail=0 (62 suites)`; exit 0 | [E1] |
| CI | none (no CI; the run by hand is the whole gate) | not applicable | |

Tool audit (3.5) per task:

| Task | Result | Output |
| --- | --- | --- |
| T1 | clean | [artifacts/T1/](artifacts/T1/) |
| T2 | clean (round 1, wording fix round, rework 1 and its wording fix round) | [artifacts/T2/](artifacts/T2/) |
| T3 | clean | [artifacts/T3/](artifacts/T3/) |
| T4 | clean | [artifacts/T4/](artifacts/T4/) |

## Targets vs measured

Measured by review-targets at pass 1 (before rework 1, which changed only comments and test labels).

| Target | Threshold | Measured | Result | Command | Raw output |
| --- | --- | --- | --- | --- | --- |
| Script lint clean | exit 0; 0 shellcheck findings | 0 findings (45 files) | PASS | `script-lint` | [E6] |
| Harness lint clean | exit 0; 0 shellcheck findings | 0 findings (72 files) | PASS | `harness-lint` | [E7] |
| Agent-docs lint clean | 0 failed in each of four suites | failed=0 in each | PASS | `agent-docs-lint` | [E8] |
| Every script this spec changes has a suite | 0 | 0 | PASS | `script-coverage` | [E9] |
| No "task worktree" in the guard scripts | 0 | 0 | PASS | `task-worktree-wording` | [E10] |
| Extract in-place deny rules in both settings files | 8 | 8 | PASS | `extract-deny-rules` | [E11] |
| Scope check time, long read-only chain with single-quoted `$` | ≤ 0.5 s best of 3 | 0.19 s | PASS | `guard-time` | [E12] |
| Line coverage of changed shell code | not measured | not measured: no bash coverage tool, no new dependency allowed (D14) | not measured | none | |

Commands are in [verification-plan.md](verification-plan.md) § Targets.

## Journeys

| Journey | Result | Artifacts |
| --- | --- | --- |
| JRN-001 Unconfinable agent denied | PASS | [E1] (`hooks/worktree-guard`, JRN-001 checks) |
| JRN-002 Isolation launch still confined | PASS | [E1] (`hooks/worktree-guard`, JRN-002 checks) |
| JRN-003 Guard fails closed on its own errors | PASS | [E1] (`hooks/worktree-guard`, JRN-003 checks) |
| JRN-004 Scope check CLI contract | PASS | [E1] (`hooks/worktree-guard`, JRN-004 checks) |
| JRN-005 Agent worktree wording | PASS | [E1] (`hooks/worktree-guard`, JRN-005 checks) |
| JRN-006 Quoted `$` reads pass | PASS | [E1] (`hooks/worktree-guard`, JRN-006 checks) |
| JRN-007 Extract in-place denied in installed settings | PASS | [E1] (`scripts/install-claude-settings`); live check [E4] |
| JRN-008 Upgrade re-run checks catch a refusing re-run | PASS | [E1] (`scripts/install-upgrade`); red under a refusing installer [E3] |
| JRN-009 Asset record matches 006 | PASS | [E1] (`lint/agent-worktree-docs`) |

Behaviour verification: the harness drives the guard and scope check through real payloads, fixture repos and agent worktrees; there is no running build. In this Claude Code session `yq --front-matter=extract -i` on a scratch file was refused by the new deny rule and a plain extract read still ran [E4]. A live sub-agent payload with a missing transcript was not exercised (known gap).

## Review outcome

- Review passes: 1 (rework used 1 of 5) · Findings: 2 patched (F1, F2), 1 deferred (F3), 1 discovered work filed (F4), 0 dismissed (see design-log.md "Triage, review pass 1")
- Failed lenses: none
- Follow-up review recommended: no; no patch was verified high, and the rework changed wording only

## Known gaps

- F3 (medium): in-place extract spellings the text rules miss (`-Pi`, `--inplace=true`, a call through a variable) pass the prefix allow. Handoff: [.workflow/deferred/frontmatter-extract-write-guard.md](../../deferred/frontmatter-extract-write-guard.md)
- The missing-transcript deny is proven on fixture payloads only (review-end-state `not_verifiable`). Handoff: [.workflow/deferred/subagent-missing-transcript-path.md](../../deferred/subagent-missing-transcript-path.md)
- Line coverage not measured (D14). Recorded on [.workflow/deferred/bash-line-coverage.md](../../deferred/bash-line-coverage.md)
- review-standards `not_checked` (6 items) and review-lessons `not_checked` (6 items): listed in their pass files [E13].

## Deferred

- [.workflow/deferred/frontmatter-extract-write-guard.md](../../deferred/frontmatter-extract-write-guard.md): refuse every in-place extract spelling, not only the four text forms (medium)
- [.workflow/deferred/subagent-missing-transcript-path.md](../../deferred/subagent-missing-transcript-path.md): confirm the live sub-agent payload when its transcript is missing

## How to verify

1. Run `tests/run-all.sh --suite hooks/worktree-guard` and `tests/run-all.sh --suite scripts/install-claude-settings`.
2. Both report `failed=0`.
3. In a Claude Code session in this repo, run `yq --front-matter=extract '.status' .workflow/specs/00010-worktree-guard-followups/spec.md` (runs) and `yq --front-matter=extract -i '.a = 1' <scratch>.md` (refused).

## Evidence

- [E1] [artifacts/sign-off-5.4/toolchain.txt](artifacts/sign-off-5.4/toolchain.txt): `TOTAL passed=3678 failed=0 skipped=0 xfail=0 (62 suites)`; also [artifacts/gate-3.9-rework1/](artifacts/gate-3.9-rework1/)
- [E2] [artifacts/phase-1-known-bad/record.md](artifacts/phase-1-known-bad/record.md) Run 1: the same checks red at the baseline (79 failures, all assertions)
- [E3] [artifacts/phase-1-known-bad/record.md](artifacts/phase-1-known-bad/record.md) Run 2: JRN-008 checks red under a re-run-refusing installer
- [E4] design-log.md "Triage, review pass 1", F3: live permission check, 2026-10-30
- [E5] [artifacts/T1/mini-review.yaml](artifacts/T1/mini-review.yaml), [artifacts/T2/mini-review.yaml](artifacts/T2/mini-review.yaml): pass
- [E6] [artifacts/review/pass-1/targets/script-lint-clean.txt](artifacts/review/pass-1/targets/script-lint-clean.txt)
- [E7] [artifacts/review/pass-1/targets/harness-lint-clean.txt](artifacts/review/pass-1/targets/harness-lint-clean.txt)
- [E8] [artifacts/review/pass-1/targets/agent-docs-lint-clean.txt](artifacts/review/pass-1/targets/agent-docs-lint-clean.txt)
- [E9] [artifacts/review/pass-1/targets/every-script-this-spec-changes-has-a-suite.txt](artifacts/review/pass-1/targets/every-script-this-spec-changes-has-a-suite.txt)
- [E10] [artifacts/review/pass-1/targets/no-task-worktree-in-the-guard-scripts.txt](artifacts/review/pass-1/targets/no-task-worktree-in-the-guard-scripts.txt)
- [E11] [artifacts/review/pass-1/targets/extract-in-place-deny-rules-in-both-settings-files.txt](artifacts/review/pass-1/targets/extract-in-place-deny-rules-in-both-settings-files.txt)
- [E12] [artifacts/review/pass-1/targets/worktree-scope-check-time-on-a-long-read-only-chain-with-single-quoted.txt](artifacts/review/pass-1/targets/worktree-scope-check-time-on-a-long-read-only-chain-with-single-quoted.txt)
- [E13] [artifacts/review/pass-1/](artifacts/review/pass-1/)
