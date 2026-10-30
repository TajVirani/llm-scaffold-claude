# Report: The bash graph extractor never reads quoted text as commands

Spec: [spec.md](spec.md) · Verification plan: none (light path) · Baseline: `9347768cc6b32ccc89cea7fe536052fc87c8d4ee` · Head: `8c637b18abbc4346d536f02601ac904708f53930`

## Summary

The bash graph extractor now keeps one quote state across lines and shares it with every reader, so text inside a quoted string that spans lines is never reported as a call, while a `$(...)` or backtick substitution inside double quotes still is; a trailing comment's apostrophe and a quoted `<<` no longer derail it. Over the whole repo the extractor's output changed by exactly five removed in-quote false edges, and the full harness passes (3607 of 3607). Open: a pre-existing same-line `$'...'` drop is deferred, and the browser gate is a known gap.

## Capabilities

| Capability | Result | Evidence |
| --- | --- | --- |
| CAP-005 Bash graph extractor (quote-aware across lines) | PASS | [E1] [E2] [E3] |

## Tests and CI

| Suite | Command | Result | Evidence |
| --- | --- | --- | --- |
| Unit and integration (3.9) | `tests/run-all.sh` | 3607 passed, 0 failed, 0 skipped (62 suites); exit 0 | [E1] |
| CI | none (CI deferred, ADR-0001) | not run | none |

Tool audit (3.5) per task:

| Task | Result | Output |
| --- | --- | --- |
| T1 | clean (lint pass, test pass) after one behaviour fix round, one wording round and rework 1 | [artifacts/T1/](artifacts/T1/) |

## Targets vs measured

no targets (light path)

## Journeys

None (light path: no verification plan). The repo-wide oracle stands in for an end-to-end run [E3].

Behaviour verification: the extractor was run over the whole repo (`--scope .`) with the pre-change extractor (`6f37f4c`) and the final one on the same tree: 437 records before, 432 after, the five removed records all inside multi-line single-quoted strings in `tests/scripts/build-architecture.sh` (4) and `tests/scripts/extractor-bash.sh` (1); modules and exports identical; nothing added. Main-session probes confirmed the in-quote `./x`, the multi-line double-quoted `./x`, the trailing-comment apostrophe, `$(...)` and backtick cases. The published architecture cache was not regenerated.

## Review outcome

- Review passes: 1 (rework used 1 of 5) · Findings: 2 patched (F1 medium: backtick substitution in a multi-line double quote was dropped; F3 low: header wording), 1 deferred (F2 medium, pre-existing), 1 dismissed as false (F4) (see design-log.md, Triage, review pass 1)
- Follow-up review recommended: no; the rework's patches were medium and low and passed their gates
- Mini-review: round 1 failed item 3 (an unchecked extractor status in the suite), fixed; round 2 failed R2 (an unexplained here-string branch), fixed; the rework's full mini-review passed.

## Known gaps

- Gate skipped (3.10 browser suite): no `e2e-browser` profile in this repo. Handoff: [.workflow/deferred/browser-suite.md](../../deferred/browser-suite.md)
- F2 (medium, pre-existing): a same-line call after an escaped quote inside `$'...'` is dropped. Handoff: [.workflow/deferred/bash-extractor-quote-rules.md](../../deferred/bash-extractor-quote-rules.md)
- The published `.workflow/cache/architecture.md` (stamped `58019c8`) still lists the five removed edges until the next cache regeneration.

## Deferred

- [.workflow/deferred/browser-suite.md](../../deferred/browser-suite.md): browser suite for this repo; Later requests line added (suite gap, no severity).
- [.workflow/deferred/bash-extractor-quote-rules.md](../../deferred/bash-extractor-quote-rules.md): one set of quote rules for every reader (medium).

## How to verify

1. Run `tests/run-all.sh --suite scripts/extractor-bash`: expect `RESULT passed=54 failed=0`.
2. Run `.agents/skills/regenerate-caches/scripts/extractors/bash.sh --root . --scope tests/scripts/extractor-bash.sh | jq '.modules[].dependencies[] | select(.module == "./x")'`: expect no output.
3. Compare `artifacts/oracle/oracle-diff.txt`: five removed records, nothing added.

## Evidence

- [E1] `artifacts/sign-off-5.4/toolchain.txt`: `TOTAL passed=3607 failed=0 skipped=0 xfail=0 (62 suites)`; `scripts/extractor-bash passed=54`; also `artifacts/gate-3.9-w2/toolchain.txt`.
- [E2] `artifacts/T1/implementation.yaml` (`tests_added`) and `tests/scripts/extractor-bash.sh` quote cases.
- [E3] `artifacts/oracle/oracle-diff.txt`: repo-wide before/after records of the extractor.
