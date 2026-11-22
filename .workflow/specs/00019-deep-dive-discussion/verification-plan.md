# Verification plan: Hold the deep dive at once, as a discussion that reaches agreement

Spec: [spec.md](spec.md)

## End state

- [ ] CAP-017: `questioning-loop.md` says a question picked for a deep dive is discussed straight after the round is logged, before the term gate, scope gate and next round, and not "after the round closes".
- [ ] CAP-017: the loop's deep dive step says the agent opens by saying back the question and its recommendation's reason and asking where that is wrong, continues in chat, and ends only on the stakeholder's explicit yes to a written statement, which is the logged decision.
- [ ] CAP-017: the loop's deep dive step says every other answer in the round is checked against the agreed statement, only contradicted answers are re-asked in one ask, and the rest are named as standing.
- [ ] CAP-017: the loop's Entry says a logged "deep dive under way" answer with no matching Deep dive entry is resumed before a new frontier is computed.
- [ ] CAP-017: no file under `.agents/` says "Defer to deep dive", "defer to deep dive" or "deferred to deep dive"; the loop, its chat format and large-path 6.5 say "Talk it through (deep dive)".
- [ ] CAP-017: the design-log template's Deep dive shape carries the lines Restated, Where it was wrong, Explored, Exchanges, Agreed statement, Answer, Decision and Round check, and its Initiative round shape carries a deep dive block.
- [ ] CAP-017: `large-path.md` 6.5 holds the deep dive inside 6.5 the same way, settles the question with the agreed statement and its confirmation, and its Done line no longer says "or deferred"; `assets/questions.md` documents that `settled` form.
- [ ] CAP-017: the retrospective's waits count adds the `Exchanges:` numbers, and on a design log with no `Exchanges:` line gives the same number as today.
- [ ] CAP-017: `steps.tsv` keeps 0.3.11, 0.3.12 and 0.3.13 with new titles, `step-progress.sh` totals are unchanged, and `tests/run-all.sh` passes.

## Journeys

| Id | Journey | Proves | Steps | Expected outcome | Check |
| --- | --- | --- | --- | --- | --- |
| JRN-001 | Deep dive held at once | CAP-017 | 1. Read `questioning-loop.md` § The round. 2. Find the deep dive step and the round log step. | The deep dive step follows the round log and comes before the term gate; it holds the restate, where-is-it-wrong, explicit-yes and round-check wording | "00019 JRN-001" checks in `tests/lint/stakeholder-asks-docs.sh` |
| JRN-002 | Unfinished deep dive resumed | CAP-017 | 1. Read `questioning-loop.md` § Entry. | It names "deep dive under way" and resuming it before computing a new frontier | "00019 JRN-002" check in `tests/lint/stakeholder-asks-docs.sh` |
| JRN-003 | One label everywhere | CAP-017 | 1. Search `.agents/` for the old label in any case. 2. Search the loop and large-path for the new one. | No old label; the new label in the loop step, the Claude Code option, the chat format and 6.5 | "00019 JRN-003" checks in `tests/lint/stakeholder-asks-docs.sh` |
| JRN-004 | Entry shapes carry the agreement | CAP-017 | 1. Read the Deep dive and Initiative round shapes in `assets/design-log.md`. 2. Read the `settled` comment in `assets/questions.md`. | Every new line is present; `settled` documents the agreed statement with its confirmation | "00019 JRN-004" checks in `tests/lint/stakeholder-asks-docs.sh` |
| JRN-005 | Large path behaves the same | CAP-017 | 1. Read `large-path.md` § 6.5. | Deep dive inside 6.5 before 6.6, settled with the agreed statement, Done line without "or deferred" | "00019 JRN-005" checks in `tests/lint/stakeholder-asks-docs.sh` |
| JRN-006 | Waits count includes exchanges | CAP-017 | 1. Build a design log fixture with two `Answer:` lines and a Deep dive entry with `Exchanges: 3`, and one with no `Exchanges:` line. 2. Run the waits command from `retrospective/modules/evidence.md` on each. | 5 for the first (2 answers + 3 exchanges, the Deep dive's own Answer included in the 2); the old count for the second | "00019 JRN-006" check in `tests/scripts/retrospective-evidence.sh` |
| JRN-007 | Step list and totals hold | CAP-017 | 1. Run `tests/run-all.sh --suite lint/step-list` and the step-progress suite. | Both pass with the new titles; "step 21 of 46" for 0.3.8 still printed | `tests/lint/step-list.sh`, `tests/scripts/step-progress.sh` |

## Fixtures and oracles

| Fixture or oracle | What it provides | Source | Used by |
| --- | --- | --- | --- |
| The edited docs themselves | The text the lint checks read | `.agents/skills/feature-workflow/modules/questioning-loop.md`, `modules/large-path.md`, `assets/design-log.md`, `assets/questions.md` | JRN-001 to JRN-005 |
| Expected wording | Literal phrases and order the docs must hold | spec.md Capabilities success line; decisions D6, D7 and the kept Assumed entries in design-log.md; data-model.md § Deep dive entry | JRN-001 to JRN-005 |
| Design log fixtures | Two small design logs written at run time under `new_workdir` (`tests/lib/common.sh`) | data-model.md § Deep dive entry (Exchanges line) | JRN-006 |
| Waits command | The fenced command line in the retrospective's Measurements step, run as written | `.agents/skills/retrospective/modules/evidence.md` | JRN-006 |
| Pinned totals | "step 21 of 46" for 0.3.8, "of 34" on the light path | `tests/scripts/step-progress.sh:29-44` | JRN-007 |

## Targets

| Target | Kind | Threshold | How measured (exact command) | Source of the threshold |
| --- | --- | --- | --- | --- |
| New-feature start load | performance | at most 45,000 bytes (baseline 41,392) | `bash tests/lint/workflow-load-size.sh \| grep '^new-feature start:'` | ADR-0004 (`.workflow/decisions/adr/0004-workflow-load-budget.md`); spec.md Constraints |
| Questioning loop size | performance | `questioning-loop.md` at most 15,000 bytes (baseline 12,325) | `wc -c < .agents/skills/feature-workflow/modules/questioning-loop.md` | assumed (design-log.md) |
| Errors | error | none set | Not measurable as a number: the change is to step-file text; the label, wording and order checks are journeys (JRN-001 to JRN-005) | assumed (design-log.md) |
| Coverage | coverage | none set | Not measurable: no bash line-coverage tool is installed ([.workflow/deferred/bash-line-coverage.md](../../deferred/bash-line-coverage.md)) | assumed (design-log.md) |

## Suites

| Suite | Profile key | Command (copied from the profile) | CI check | Known-bad-build evidence (1.4) |
| --- | --- | --- | --- | --- |
| Harness | `test` | `tests/run-all.sh` | none | `artifacts/phase-1-known-bad/record.md` |
| Browser | `e2e` | none: the project has no e2e profile | none | not applicable |
