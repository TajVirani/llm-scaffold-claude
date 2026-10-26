# Report: Tier B caches for bash projects

Spec: [spec.md](spec.md) · Verification plan: [verification-plan.md](verification-plan.md) · Baseline: `86609a64711682747a07bea99a7ed442cf5a827c` · Head: `e530f63f7103b9286d32d21f6b9f75055ef8c5d8`

## Summary

Each work profile now names its graph extractor, a bash extractor joins dependency-cruiser, and this repo has all three Tier B caches, published and fresh, for the first time. The change request is in: a bash-only project with a committed boundary config builds architecture without depcruise, and Boundary violations reads "Not checked" instead of a false `None.`. The most important gap: the same false `None.` still appears for a JS/TS project whose depcruise fails to run (backlog item disc-004, predates this spec).

## Capabilities

| Capability | Result | Evidence |
| --- | --- | --- |
| CAP-004 Graph extractor per work profile | PASS | [E1], [E3] (JRN-002, JRN-003, JRN-004, JRN-006) |
| CAP-005 Bash graph extractor | PASS | [E1] (JRN-001), [E4] (JRN-005) |

## Tests and CI

| Suite | Command | Result | Evidence |
| --- | --- | --- | --- |
| Unit and integration (3.9) | `tests/run-all.sh` | 2891 passed, 0 failed, 53 suites; exit 0 | [E1] |
| CI | none (no CI; the run by hand is the whole gate) | not applicable | - |

Tool audit (3.5) per task:

| Task | Result | Output |
| --- | --- | --- |
| T1 | clean | [artifacts/T1/](artifacts/T1/) |
| T2 | clean | [artifacts/T2/](artifacts/T2/) |
| T3 | clean (rework 1, rework 2) | [artifacts/T3/](artifacts/T3/) |
| T4 | clean | [artifacts/T4/](artifacts/T4/) |
| T5 | clean | [artifacts/T5/](artifacts/T5/) |
| T6 | clean | [artifacts/T6/](artifacts/T6/) |
| T7 | clean | [artifacts/T7/](artifacts/T7/) |
| T8 | clean | [artifacts/T8/](artifacts/T8/) |
| T9 | clean | [artifacts/T9/](artifacts/T9/) |
| T10 | clean | [artifacts/T10/](artifacts/T10/) |

## Targets vs measured

| Target | Threshold | Measured | Result | Command | Raw output |
| --- | --- | --- | --- | --- | --- |
| Script lint clean | exit 0; 0 shellcheck findings | exit 0, no findings | PASS | `script-lint` in verification-plan.md | [E2] |
| Harness lint clean | exit 0; 0 shellcheck findings | exit 0, no findings | PASS | `harness-lint` | [E2] |
| Agent-docs lint clean | exit 0; each suite 0 failed | frontmatter 40/0, symlinks 45/0, upstream-lineage 13/0 | PASS | `agent-docs-lint` | [E2] |
| Every script this spec adds or changes has a suite | `0` | 0 | PASS | `script-coverage` | [E2] |
| Every new `.agents/` asset is in the manifest and PROVENANCE.md | `0` | 0 | PASS | `asset-coverage` | [E2] |
| Bash graph extractor wall time on this repo | under 30 s | 0.47 s (real) | PASS | `extractor-time` | [E2] |

Measured at review pass 2, before rework 2 and the P14 edit; the 5.4 harness run [E1] covers the code at Head.

## Journeys

| Journey | Result | Artifacts |
| --- | --- | --- |
| JRN-001 Bash project builds all three caches | PASS | `scripts/cache-bash-project` in [E1] |
| JRN-002 JS/TS project unchanged once keyed | PASS | `scripts/cache-js-unchanged` in [E1] |
| JRN-003 Missing key is a breaking-change error | PASS | `scripts/cache-missing-extractor-key` in [E1] |
| JRN-004 Mixed extractors merge | PASS | `scripts/cache-mixed-extractors` in [E1] |
| JRN-006 Bash project with a boundary config builds architecture without depcruise | PASS | `scripts/cache-boundary-check` in [E1]; red before the fix [E3] |
| JRN-005 This repo's caches are fresh | PASS | [E4] |

Behaviour verification: on this repo at Head, regenerate-caches built modules, flows and architecture through three cache-regeneration launches; each passed `check-staged-cache.sh` and was published with `publish-cache.sh` (architecture with generator `bash`, its scope including the boundary config). `cache-stamp-check.sh` then exited 0 with all three `fresh`. Architecture's Boundary violations reads `Not checked: no boundary checker for this project's graph extractors (bash).`; flows lists 18 entry points, none under `tests/`.

## Review outcome

- Review passes: 2 (pass 1 before the change request, pass 2 after; rework used 2 of 5) · Findings: 5 patched (F3, F4, F5, F9, F10), 2 routed to proposals and applied at 5.3 (F7 as P13, F11 as P14), 2 filed as discovered work (F1, F8), 2 dismissed with reason (F2, F6). See design-log.md "Triage, review pass 1" and "Triage, review pass 2".
- Failed lenses: none.
- Follow-up review recommended: no; no patch was verified `high`.

## Known gaps

- Mermaid diagrams in flows.md and architecture.md were checked by hand, not machine-validated: `node_modules/mermaid` and `jsdom` are not installed (cache-regeneration returns).
- review-targets measured before rework 2; no target was re-measured after it.
- review-standards `not_checked`: typecheck, format and boundary toolchain keys have no command for bash; module ownership was checked by hand.
- With every profile naming `none`, no architecture cache can be published: [work-backlog/003-bash-cache-extractor-disc-001.md](../work-backlog/003-bash-cache-extractor-disc-001.md).
- `case` pattern alternatives (`../*` at `install.sh:133,187`) are listed as unresolved calls: [work-backlog/003-bash-cache-extractor-disc-003.md](../work-backlog/003-bash-cache-extractor-disc-003.md).
- A failed depcruise run renders Boundary violations as `None.` (JS/TS projects only, predates this spec): [work-backlog/003-bash-cache-extractor-disc-004.md](../work-backlog/003-bash-cache-extractor-disc-004.md).
- The bash extractor does not detect a bare relative glob call (`scripts/*.sh`), nor a call on a line continued after a lone `&` or `|&`.
- flows.md labels script-to-script arrows `main()` and names top-level code `main()` by the agent's own choice; `.agents/agents/cache-regeneration.md` does not fix these rules, so another run could label them differently (not verify-mode tested).

## Deferred

None. (spec.md `deferred` is empty; review findings that could wait went to the work backlog or to proposals.)

## How to verify

1. `tests/run-all.sh`, expected `TOTAL passed=2891 failed=0` (53 suites).
2. `.agents/skills/regenerate-caches/scripts/cache-stamp-check.sh`, expected exit 0 with modules, flows and architecture `fresh`.
3. `sed -n '/^## Boundary violations/,/^## Unresolved/p' .workflow/cache/architecture.md`, expected the "Not checked: no boundary checker ... (bash)." line.

## Evidence

- [E1] [artifacts/sign-off-5.4/toolchain.txt](artifacts/sign-off-5.4/toolchain.txt): `TOTAL passed=2891 failed=0 skipped=0 xfail=0 (53 suites)`, status `pass`, fresh run at Head.
- [E2] [artifacts/review/pass-2/review-targets.yaml](artifacts/review/pass-2/review-targets.yaml), `measurements:`.
- [E3] [artifacts/phase-1-known-bad/record.md](artifacts/phase-1-known-bad/record.md), Run 1 (the 52 original failures) and Run 4 (JRN-006, 2 failures, both assertions).
- [E4] [artifacts/jrn-005/cache-stamp-check.json](artifacts/jrn-005/cache-stamp-check.json) (exit 0, all `fresh`) and [artifacts/jrn-005/stamps.jsonl](artifacts/jrn-005/stamps.jsonl) (each cache at `e530f63`, architecture generator `bash`).
