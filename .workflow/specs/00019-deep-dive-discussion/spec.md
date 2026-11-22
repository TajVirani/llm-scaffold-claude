---
status: done
baseline_revision: "55d8ecf2a7bf44d466fa19d52fc1229ab1647da7"
spec_branch: spec/00019-deep-dive-discussion
impl_base_revision: "677414b4773a5ecf1542a679502f034dbdfd8fd1"
light_path: false
followup_review_recommended: false
deferred: [.workflow/deferred/browser-suite.md]
tracker_issue: ""
budget: {max_tasks: 10, max_changed_files: 30}
---

# Hold the deep dive at once, as a discussion that reaches agreement

## Why

When the stakeholder wants to talk a question through, find and fix the misunderstanding behind it before any other answer in the round depends on it, so every decision the questioning loop logs is one the stakeholder agreed to in their own understanding. Before this change, picking "Defer to deep dive" parked the question until the questioning round ended (0.3.12–0.3.13) and then asked it again with the same options. That was too late, because the parked question often shapes the round's other answers, and it was not a discussion, so the misunderstanding was never found. The deep dive now starts as soon as it is picked: the agent says back what it thinks the question is and why it recommended its answer, asks where that is wrong, and the two go back and forth until the stakeholder confirms a written statement of what was agreed. That statement is the logged decision, and the rest of the round is checked against it before the loop carries on. The large path's round (6.5), which reuses the loop's format, behaves the same way.

## Capabilities

- **CAP-017** Deep dive held at once, ending in an agreed statement
  - **intent:** A stakeholder who picks "Talk it through (deep dive)" on a questioning round question gets a discussion of that question straight after the round returns, ending in a written statement they confirm, and the round's other answers are checked against it before the loop carries on.
  - **success:** `questioning-loop.md` 0.3.11–0.3.13 and `large-path.md` 6.5 say the deep dive runs straight after the round's answers return (after the round is logged in the spec loop), opens by restating the question and the recommendation's reason and asking where that is wrong, continues in chat until the stakeholder's explicit yes to a written statement, logs that statement as the decision, and then re-asks only the round's answers it contradicts while naming the rest as standing; the Deep dive entry shape and the Initiative round shape carry Restated, Where it was wrong, Exchanges, Agreed statement, Answer and Round check lines; the option reads "Talk it through (deep dive)" everywhere; `tests/run-all.sh` passes.

## Constraints

- The round still goes out as one ask (one AskUserQuestion call, or all in chat when too many); the deep dive starts after it returns (D7).
- Steps 0.3.12 and 0.3.13 keep their ids and `steps.tsv` keeps its row count, so progress-line totals do not change; no large-path step moves.
- The design log stays append only: an answer a deep dive changes is superseded by a new decision, never edited.
- Facts a deep dive needs are looked up, never asked of the stakeholder.
- ADR-0004's load budget: the new-feature start stays under 45,000 bytes (`lint/workflow-load-size`).

## Non-goals

- A deep dive option on asks outside the questioning round's frontier decisions: the term gates, placement, the deeper-prompt agreement and its questions, the assumption veto, sign-off.
- Changing how the frontier is computed or ordered.
- Changing the `deeper-prompt` skill's own restate loop.

## Success signal

A stakeholder who picks the deep dive on a question in a round is, in the same sitting, asked "here is what I think the question is and why I recommended X; where is that wrong?", talks it through until they say yes to a written statement, sees that statement as the decision in `design-log.md`, and is asked again only about the earlier answers in the round that the statement contradicts.

## Assumptions

- The Assumed entries in [design-log.md](design-log.md): the two glossary terms, round-logging order, several deep dives, plain-chat discussion, label, step ids, entry shape, waits count, resume, decision id placement, first-round extras, summary and conversion, large-path handling, initiative `settled` text, Phase 1 targets and the seams under test, each offered for veto and kept.
- In large-path 6.5, a round that holds a deep dive settles its other answers only after the round check, because `initiative-transition.sh` settles a question once; a session cut off mid deep dive leaves those answers open, so the next round asks them again (Assumed entry of 2026-11-22, offered for veto at 5.5).

## Links

- Source: GitHub issue [TajVirani/llm-scaffold-claude#7](https://github.com/TajVirani/llm-scaffold-claude/issues/7)
- Codebase map: [codebase-map.md](codebase-map.md)
- Design log: [design-log.md](design-log.md)
- Data model: [data-model.md](data-model.md)
- Verification plan: [verification-plan.md](verification-plan.md)
- Tasks: [tasks.md](tasks.md)
- Proposals: [proposals.md](proposals.md)
- Report: [report.md](report.md)

## Known gaps

- Gate skipped (3.10 browser suite): this repo has no browser suite; every journey is a harness check. Handoff: [.workflow/deferred/browser-suite.md](../../deferred/browser-suite.md)
