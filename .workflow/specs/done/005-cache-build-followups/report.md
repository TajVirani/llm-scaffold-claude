# Report: Cache build follow-ups from spec 003

Spec: [spec.md](spec.md) · Verification plan: [verification-plan.md](verification-plan.md) · Baseline: `1f59f20ee80efb50bfac85ba56afa22301eced56` · Head: `99801e5`

## Summary

The bash extractor no longer reports `case` patterns as calls. A boundary check that did not run now reads `Not checked`. The default test patterns and the folder-path checks each live in one `.agents/lib/` helper. The cache-regeneration agent calls only regenerate-caches scripts. The full harness passes (3072/0) and six of seven targets pass; TGT-007 (coverage) is not measurable. The main gap: the republished architecture cache still has one false unresolved entry. It comes from a single-quoted string that spans lines, which the extractor already misread before this spec.

## Capabilities

| Capability | Result | Evidence |
| --- | --- | --- |
| CAP-005 Bash graph extractor (case arm patterns are not calls) | PASS | [E1] [E3] [E5] |
| CAP-004 Graph extractor per work profile (Boundary violations says Not checked when depcruise did not run) | PASS | [E1] [E5] |
| Goal 3: one shared test-pattern helper | PASS | [E1] [E4] |
| Goal 4: six scripts validate folder paths through one helper | PASS | [E1] [E3] |
| Goal 5: cache-regeneration calls only regenerate-caches | PASS after P1 (until P1 is approved, rules.md Ownership still forbids agents → regenerate-caches) | [E3] |

## Tests and CI

| Suite | Command | Result | Evidence |
| --- | --- | --- | --- |
| Harness (3.9, sign-off 5.4) | `tests/run-all.sh` | `TOTAL passed=3072 failed=0 skipped=0 xfail=0 (56 suites)`; exit 0 | [E1] |
| CI | none (no CI; the harness run by hand is the gate) | n/a | n/a |

Tool audit (3.5) per task:

| Task | Result | Output |
| --- | --- | --- |
| T1 | clean (rework 1 re-audited clean) | [artifacts/T1/](artifacts/T1/) |
| T2 | clean except the cross-task leftover-copy grep that T1 owned, accepted at its gate; green at the wave 1 gate [E2] | [artifacts/T2/](artifacts/T2/) |
| T3 | clean | [artifacts/T3/](artifacts/T3/) |
| T4 | clean | [artifacts/T4/](artifacts/T4/) |
| T5 | clean | [artifacts/T5/](artifacts/T5/) |
| T6 | clean | [artifacts/T6/](artifacts/T6/) |

## Targets vs measured

| Target | Threshold | Measured | Result | Command | Raw output |
| --- | --- | --- | --- | --- | --- |
| TGT-001 architecture build wall time | real ≤ 2 s, best of 3 (raised from 1.2 s at 5.5; disc-002) | 1.17 s | PASS | `build-architecture.sh --cache architecture` (published scope), best of 3 | [E3] |
| TGT-002 false case-pattern entries | 0 lines | 0 | PASS | `build-architecture.sh ... \| grep -c -E 'install\.sh:(133\|187)'` | [E3] |
| TGT-003 shellcheck on changed .sh | exit 0, no output | no output | PASS | `git diff --name-only ... -- '*.sh' \| xargs shellcheck -x -P SCRIPTDIR` | [E3] |
| TGT-004 default test-pattern copies outside the lib | 0 files | 1 at review pass 1 (a header comment in budget-check.sh); 0 after rework 1 | PASS | `git grep -l -F '*_test.go' -- '.agents/*.sh' \| grep -v -x '.agents/lib/test-paths.sh' \| wc -l` | [E3] [E4] |
| TGT-005 local main_root / norm_* definitions | 0 matches | 0 | PASS | `git grep -c -E '^(main_root\|norm_spec_dir\|norm_initiative_dir)\(\)' ...` | [E3] |
| TGT-006 non-regenerate-caches skill paths in cache-regeneration.md | 0 lines | 0 | PASS | `grep -o -E '\.agents/skills/[a-z-]+' .agents/agents/cache-regeneration.md \| grep -v -c regenerate-caches` | [E3] |
| TGT-007 line coverage of changed shell code | not measured | not measured: no bash coverage tool, and the spec bans new dependencies | not measured | none | [E3] |

## Journeys

| Journey | Result | Artifacts |
| --- | --- | --- |
| JRN-001 `case` patterns are not calls | PASS (harness `scripts/extractor-bash`) | [E1] |
| JRN-002 this repo's architecture cache drops the false entries | PASS (harness `scripts/cache-repo-architecture`) | [E1] |
| JRN-003 depcruise did not run | PASS (harness `scripts/cache-boundary-check`) | [E1] |
| JRN-004 depcruise ran | PASS (harness `scripts/cache-boundary-check`) | [E1] |
| JRN-005 budget and flows agree on test files | PASS (harness `scripts/lib-test-paths`) | [E1] |
| JRN-006 folder paths validate the same everywhere | PASS (harness `scripts/lib-workflow-paths`, `scripts/task-breakdown`) | [E1] |
| JRN-007 cache-regeneration stays inside its ownership | PASS (harness `scripts/cache-scripts`) | [E1] |
| JRN-008 caches published after the change | PASS with one gap: `check-staged-cache.sh` printed `ok` for all three caches and all are `fresh`; against the oracle, one new false entry (`tests/scripts/extractor-bash.sh:205` `./x`, quoted text that spans lines) | [E5] |

Behaviour verification: a full regenerate-caches run at `99801e5` built and published all three caches for this repo [E5]. The Mermaid diagrams were checked by hand, because node cannot load mermaid and jsdom here.

## Review outcome

- Review passes: 1, rework used 1 of 5 · Findings: 2 patched (F1 low, F2 medium), 0 deferred, 0 dismissed; no failed lens (see design-log.md "Triage, review pass 1")
- Follow-up review recommended: no (no verified high finding)

## Known gaps

- TGT-007 line coverage not measured: no bash coverage tool. Handoff: [.workflow/deferred/bash-line-coverage.md](../../../deferred/bash-line-coverage.md)
- JRN-008: the published architecture cache has one false unresolved entry, `tests/scripts/extractor-bash.sh:205` `./x`. The bash extractor reads text inside a single-quoted string that spans lines as commands. This behaviour predates this spec. Offered as a backlog item at 5.5.
- Mermaid diagrams in flows and architecture were not machine-validated (node cannot load mermaid and jsdom); checked by hand against the checklist.
- Goal 5 holds only once proposal P1 is applied at 5.3.
- review-standards not_checked: typecheck, format and boundary keys have no command in the shell-scripts and agent-docs profiles; T2's per-task toolchain record is stale (the later gates pass).

## Deferred

- [.workflow/deferred/main-checkout-resolver.md](../../../deferred/main-checkout-resolver.md): the other main-checkout resolvers in hooks and agent docs
- [.workflow/deferred/bash-case-fallthrough.md](../../../deferred/bash-case-fallthrough.md): bash 4 `;&` and `;;&` case terminators
- [.workflow/deferred/bash-line-coverage.md](../../../deferred/bash-line-coverage.md): a bash coverage tool so coverage targets can be measured

## How to verify

1. `tests/run-all.sh`: expect `TOTAL passed=3072 failed=0`.
2. `.agents/skills/regenerate-caches/scripts/cache-stamp-check.sh`: expect all three caches `fresh`; `grep -c 'install.sh:1[38][37]' .workflow/cache/architecture.md` prints 0.

## Evidence

- [E1] [artifacts/sign-off-5.4/toolchain.txt](artifacts/sign-off-5.4/toolchain.txt) (harness at the current head), and [artifacts/gate-3.9-rework1/](artifacts/gate-3.9-rework1/)
- [E2] [artifacts/gate-3.9-w1/](artifacts/gate-3.9-w1/), [artifacts/gate-3.9-w2/](artifacts/gate-3.9-w2/)
- [E3] [artifacts/review/pass-1/review-targets.yaml](artifacts/review/pass-1/review-targets.yaml) and its `targets/` raw outputs
- [E4] [artifacts/sign-off-5.4/tgt-004-after-rework.txt](artifacts/sign-off-5.4/tgt-004-after-rework.txt) (prints 0)
- [E5] [artifacts/JRN-008/record.md](artifacts/JRN-008/record.md), with check-staged.txt, stamp-check.txt and oracle-diff.txt
