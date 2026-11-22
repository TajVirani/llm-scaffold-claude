## Link to issue

No tracker issue yet: the workflow does not create one when a spec starts.

Source: GitHub issue https://github.com/TajVirani/llm-scaffold-claude/issues/7 (not closed by this merge; no tracker is set up).

## What changed

- Picking "Talk it through (deep dive)" (was "Defer to deep dive") in a questioning round now starts the deep dive straight after the round is logged, before the term gate, the scope gate and the next round.
- The deep dive opens with the agent saying back the question and why it recommended its answer, then asking where that is wrong. It goes back and forth in chat until the stakeholder gives an explicit yes to a written agreed statement, which is the logged decision.
- After each deep dive, every other answer in the round is checked against the agreed statement: only the answers it contradicts are asked again, and the rest are named as still standing.
- A deep dive cut off by a session end is resumed first on the next entry, before a new frontier is computed.
- Large-path 6.5 holds the deep dive the same way and settles the question with the agreed statement plus the stakeholder's confirming words.
- The design log's Deep dive entry gains Restated, Where it was wrong, Exchanges, Agreed statement and Round check lines; the Initiative round entry gains a deep dive block.
- The retrospective's waits count adds each deep dive's exchanges.
- 23 new checks in `tests/lint/stakeholder-asks-docs.sh` and the new suite `tests/scripts/retrospective-evidence.sh`.

## Why the change

- A parked deep dive was asked again only after its round ended, by which time it had already shaped the round's other answers.
- Asking it again with the same options was not a discussion, so the misunderstanding behind it was never found.
- The stakeholder wants every logged decision to be one they agreed to in their own understanding (CAP-017).

## Why this approach

- Placement: `feature-workflow` owns the change (D1); `retrospective` and `tests` change only to match, since the retrospective only reads the Deep dive entry.
- The round is logged before the deep dive starts, so the append-only log keeps every answer if the session ends mid deep dive; a changed answer is superseded by a new decision rather than edited.
- Steps 0.3.12 and 0.3.13 keep their ids and the step list keeps its row count, so progress-line totals and every guard stay as they were; no large-path step moves.
- Impact: the deep dive step text and the large-path round are refactored; the Entry, the Questioning round and Initiative round shapes, the `settled` format and the waits count are extended; no script or question state changes.

## Special things to note

- Report: [report.md](.workflow/specs/done/00019-deep-dive-discussion/report.md). Task PRs: none (gh is not installed; both tasks merged locally).
- Browser gate skipped: this repo has no browser suite; every journey is a harness check ([.workflow/deferred/browser-suite.md](.workflow/deferred/browser-suite.md)).
- Not verifiable by the harness: whether an agent actually holds the discussion in a live round; the next real round that picks a deep dive is the first check.
- In large-path 6.5, a round with a deep dive settles its other answers after the round check, because `initiative-transition.sh` settles a question once; a session cut off mid deep dive leaves them open and the next round asks them again.
- `assetlist.md` and `wayfinder-comparison.html` (scaffold-only planning files) still describe the old defer option.
- This branch also carries spec 00018's two glossary entries (Browser-suite evidence, Browser-suite run output), by the stakeholder's choice (D8).

## How to test

1. Run `tests/run-all.sh --suite lint/stakeholder-asks-docs --suite scripts/retrospective-evidence --suite lint/step-list --suite scripts/step-progress`. Expected: every suite passes, including the 23 checks named "00019 JRN-00n".
2. Run `tests/run-all.sh`. Expected: `TOTAL passed=4909 failed=0`.
3. Read `.agents/skills/feature-workflow/modules/questioning-loop.md` § The round, item 6. Expected: the deep dive starts straight after the round is logged and ends on an explicit yes to an agreed statement, followed by the round check.

## Blast radius

- `feature-workflow`: `modules/questioning-loop.md`, `modules/large-path.md`, `assets/design-log.md`, `assets/questions.md`, `references/steps.tsv`. Every questioning loop and large-path round in this repo and in target projects reads them after the next install.
- `retrospective`: `modules/evidence.md` and `assets/retrospective.md` (the waits line and its table row).
- Scaffold-only: `PLAN/decision-flow.mermaid`, `PLAN/decision-flow-reference.md`, `upstream-lineage.json`, `.workflow/deferred/browser-suite.md`.
- Untouched: every script and hook, the guards, `status-transition.sh` and `initiative-transition.sh`, and the step ids.

## Risk and reversibility

Risk: Low - text-only change to step files and one awk line; the main risk is an agent reading the new deep dive text less faithfully than the checks can show, which the next live round will reveal.
Reversibility: Easy - revert the merge commit; no data, settings or state change.

## Areas, concepts and seams changed

- Interfaces whose shape changed: the Deep dive design-log entry (new lines), the Initiative round entry (deep dive block), an initiative question's `settled` text after a deep dive, the retrospective waits command.
- Concepts: Questioning round and Deep dive (new glossary entries), Frontier.
- Modules: feature-workflow (questioning loop 0.3.11–0.3.13 and Entry, large path 6.5 and 6.8), retrospective (Measurements), tests.

## How to undo this PR

1. `git revert -m 1 <merge commit>` on main.
2. Nothing else to restore: no data, settings or generated state depend on the change.
