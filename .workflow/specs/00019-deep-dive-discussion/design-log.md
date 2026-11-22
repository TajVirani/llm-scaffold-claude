# Design log: Hold the deep dive at once, as a discussion that reaches agreement

Spec: [spec.md](spec.md)

## 2026-11-21 Assumed: terms for the questioning round and the deep dive

- Step: 0.2.2
- Question: what to call (a) one ask of the whole frontier in the questioning loop and (b) the one-question discussion the stakeholder opens by picking "Defer to deep dive". Options: "Questioning round" or "round" for (a); "Deep dive" or "deferred question" for (b).
- Answer taken: **Questioning round** and **Deep dive**, written to `.workflow/GLOSSARY.md` at 0.2.3.
- Why safe to assume: the glossary held no competing entry, and both are already the loop's own wording: `questioning-loop.md:3` ("Work in **rounds**", "deep dive"), and the design-log entry shapes "Questioning round <n>" and "Deep dive: <question>" in `assets/design-log.md`. "Round" alone stays allowed inside the loop, so no existing line becomes a naming finding. A veto renames the two entries; nothing else uses them yet.

## 2026-11-21 Placement: feature-workflow

- Owning module: feature-workflow (`modules/questioning-loop.md` 0.3.11–0.3.13, `references/steps.tsv`, the Deep dive shape in `assets/design-log.md`, `modules/large-path.md` 6.5). Retrospective (`modules/evidence.md`) and tests (`tests/lint/step-list.sh`, `tests/scripts/step-progress.sh`, `tests/lint/stakeholder-asks-docs.sh`) change only to match; `PLAN/decision-flow.mermaid` and `PLAN/decision-flow-reference.md` follow the step list.
- Alternatives considered: split ownership with retrospective: it only reads the Deep dive entry and counts `Answer:` lines, so it is a consumer, not a co-owner.
- Conflict with an ADR or rule: none. Retrospective and tests may depend on feature-workflow (`.workflow/rules.md` § Ownership). ADR-0004's 45,000-byte new-feature load still passes with the two new glossary terms (`lint/workflow-load-size`, 14 passed); `questioning-loop.md` is not in that load.
- Offered for veto: Assumed: terms for the questioning round and the deep dive; vetoed: none
- Answer: "feature-workflow (Recommended)"
- Decision: **D1** feature-workflow owns the change; retrospective and tests change only to match. No ADR: the placement is cheap to reverse, so it fails the three-part test.

## 2026-11-21 Deeper prompt

**What this changes:** Picking "Defer to deep dive" in a questioning round no longer parks the question until the round ends. The round pauses and the deep dive starts at once, as a back-and-forth that ends only when the stakeholder confirms a written statement of what was agreed; that statement is logged as the decision, and the rest of the round is checked against it before the round carries on.

**Why:** A parked question is re-asked too late, after it has already shaped the other answers in its round, and re-asking it with the same options never finds the misunderstanding behind it.

**Ask:** When the stakeholder wants to talk a question through, find and fix the misunderstanding behind it before any other answer in the round depends on it, so every decision the loop logs is one the stakeholder actually agreed to in their own understanding.

**Goals:**
- A question the stakeholder picks for a deep dive is discussed before the round's other answers are taken as settled.
- The deep dive opens with the agent saying back what it thinks the question is and why it recommended its answer, then asking where that is wrong.
- The deep dive ends only on the stakeholder's explicit yes to a written statement of what was agreed, and that statement is the logged decision.
- Every other answer in the round is checked against that statement, and any it changes is put back to the stakeholder before the round carries on.
- The large path's 6.5 ask, which reuses the loop's format, behaves the same way.

**Downstream:** asked in the first questioning ask

**Tools and technologies:** asked in the first questioning ask

**Gotchas:** asked in the first questioning ask

**Not asked for:** a deep dive option on other asks (the 0.2.2 term gate, placement, sign-off); changing how the frontier is computed or ordered; changing the deeper prompt skill's own restate loop.

**Original request:** "Picking \"Defer to deep dive\" parks the question until the round ends (steps 0.3.12–0.3.13). The agent then just asks it again with the same options. That's too late, because the deferred question usually shapes the other answers in the round. And it isn't a real discussion, so the misunderstanding behind the question is never found. What should happen: Pause the round and start the deep dive at once. The agent says back what it thinks the question is and why it recommended its answer, then asks where that's wrong. Go back and forth until the stakeholder confirms a written statement of what was agreed. Log that as the decision. Check the rest of the round against it before carrying on." (GitHub issue #7)

Revisions: first restatement.

Agreement: pending, asked in the first questioning ask

## 2026-11-21 Assumed: log the round before the deep dive starts

- Step: 0.3.8
- Question: when a round comes back with a deep dive picked, log the round now (deep dive questions marked "deep dive under way") or hold every answer unlogged until the deep dives end?
- Answer taken: log it now. An answer a deep dive's agreed statement changes is re-asked and its decision superseded by a new entry.
- Why safe to assume: the log is append-only and the loop resumes from it after a cleared context (`questioning-loop.md:3`); holding answers unlogged would lose them. Behaviour the stakeholder sees is the same either way.

## 2026-11-21 Assumed: several deep dives in one round

- Step: 0.3.8
- Question: when more than one question in a round is picked for a deep dive, take them together or one at a time?
- Answer taken: one at a time, in frontier order; each later deep dive starts from the statements already agreed.
- Why safe to assume: the frontier is ordered by what unblocks most (`questioning-loop.md:26`), so an earlier agreement can settle or reshape a later question. Undone by changing one line.

## 2026-11-21 Assumed: how the deep dive is held

- Step: 0.3.8
- Question: hold the deep dive with the multiple-choice tool or in plain chat, and how are facts it raises settled?
- Answer taken: plain chat, free text, since a misunderstanding rarely fits fixed options. A fact the discussion needs is looked up (`fact-lookup` or the map), never asked (design rule 8).
- Why safe to assume: the issue asks for a back-and-forth; fixed options are what it says failed. Facts-not-asked is already the loop's rule.

## 2026-11-21 Assumed: the option's label

- Step: 0.3.8
- Question: keep the label "Defer to deep dive" now that nothing is deferred?
- Answer taken: rename it "Talk it through (deep dive)" in the loop, the chat format and large-path 6.5.
- Why safe to assume: "Defer" now says the wrong thing. Wording only; undone by one replace.

## 2026-11-21 Assumed: keep the step ids 0.3.12 and 0.3.13

- Step: 0.3.8
- Question: renumber the deep dive steps now that they run straight after 0.3.11, or keep their ids?
- Answer taken: keep 0.3.12 and 0.3.13 and retitle their `steps.tsv` rows; the row count is unchanged, so the progress-line totals pinned in `tests/scripts/step-progress.sh:29-44` hold.
- Why safe to assume: no guard or script names these ids (`codebase-map.md`, Relevant code); renumbering would touch the mermaid, the reference doc and the lint for no gain.

## 2026-11-21 Assumed: the Deep dive entry's new lines

- Step: 0.3.8
- Question: what does the design log's Deep dive entry record now?
- Answer taken: From; Restated (the question and the recommendation's reason as the agent first said them back); Where it was wrong (the stakeholder's words, verbatim); Explored (facts looked up, with sources); Exchanges (how many back-and-forths); Agreed statement (verbatim, as confirmed); Answer (the stakeholder's yes, verbatim); Decision; Round check (each other answer in the round: stands, or re-asked as D<n>).
- Why safe to assume: each line maps to one step the issue asks for; the shape lives in `assets/design-log.md:125-132` and is cheap to change.

## 2026-11-21 Assumed: the retrospective counts deep dive exchanges as waits

- Step: 0.3.8
- Question: a deep dive now takes several exchanges but logs one `Answer:` line; should the retrospective's waits count include the exchanges?
- Answer taken: yes. `retrospective/modules/evidence.md:41` adds the `Exchanges:` numbers to its waits count.
- Why safe to assume: the waits figure measures stakeholder time; counting a five-exchange deep dive as one wait would understate it. One grep line, undone by reverting it.

## 2026-11-21 Questioning round 1

- Offered for veto: Assumed: log the round before the deep dive starts; Assumed: several deep dives in one round; Assumed: how the deep dive is held; Assumed: the option's label; Assumed: keep the step ids 0.3.12 and 0.3.13; Assumed: the Deep dive entry's new lines; Assumed: the retrospective counts deep dive exchanges as waits; vetoed: none

**Q1. Pass this deeper prompt on as written?**

- Why now: the Deeper prompt entry's agreement was pending (0.3.22).
- Options: A: yes · B: change it
- Recommended: A, because it keeps the issue's scope and adds only large-path 6.5, which reuses the loop's format (`codebase-map.md`, Relevant code).
- Answer: "Yes to all"
- Decision: **D2** the deeper prompt is agreed as written.

**Q2. Downstream: will other features be built on this one?**

- Why now: asked in the first questioning ask (deeper prompt).
- Options: A: none known · B: name them
- Recommended: A
- Answer: "Yes to all"
- Decision: **D3** none known.

**Q3. Tools and technologies to use or avoid?**

- Why now: asked in the first questioning ask (deeper prompt).
- Options: A: no preference · B: name them
- Recommended: A
- Answer: "Yes to all"
- Decision: **D4** no preference.

**Q4. Gotchas already known?**

- Why now: asked in the first questioning ask (deeper prompt).
- Options: A: none known · B: name them
- Recommended: A
- Answer: "Yes to all"
- Decision: **D5** none known.

**Q5. When an agreed statement changes another answer in the round, re-ask only the answers it contradicts and list the rest as still standing?**

- Why now: the issue asks to "check the rest of the round against it before carrying on"; how is the stakeholder's call.
- Options: A: re-ask only the contradicted answers, list the rest as standing · B: re-ask the whole round · C: log the clash without asking
- Recommended: A, because it reuses the deeper prompt's "ask again every answer the change touches" rule (`codebase-map.md`, Module audit, reuse) and asks nothing a deep dive did not touch.
- Answer: "Yes to all"
- Decision: **D6** after each deep dive, the agent checks every other answer in the round against the agreed statement, re-asks only the ones it contradicts in one ask, and names the rest as still standing.

The round's summary question was withdrawn before it was answered: the module audit returned gaps the summary did not cover (`codebase-map.md`, Module audit).

Facts looked up instead of asked (0.3.10): None.

## 2026-11-21 Deeper prompt

**What this changes:** Picking the deep dive option in a questioning round no longer parks the question until the round ends. The round pauses and the deep dive starts at once, as a back-and-forth that ends only when the stakeholder confirms a written statement of what was agreed; that statement is logged as the decision, and the rest of the round is checked against it before the round carries on.

**Why:** A parked question is re-asked too late, after it has already shaped the other answers in its round, and re-asking it with the same options never finds the misunderstanding behind it.

**Ask:** When the stakeholder wants to talk a question through, find and fix the misunderstanding behind it before any other answer in the round depends on it, so every decision the loop logs is one the stakeholder actually agreed to in their own understanding.

**Goals:**
- A question the stakeholder picks for a deep dive is discussed before the round's other answers are taken as settled.
- The deep dive opens with the agent saying back what it thinks the question is and why it recommended its answer, then asking where that is wrong.
- The deep dive ends only on the stakeholder's explicit yes to a written statement of what was agreed, and that statement is the logged decision.
- Every other answer in the round is checked against that statement, and any it changes is put back to the stakeholder before the round carries on.
- The large path's 6.5 ask, which reuses the loop's format, behaves the same way.

**Downstream:** none known

**Tools and technologies:** no preference

**Gotchas:** none known

**Not asked for:** a deep dive option on other asks (the 0.2.2 term gate, placement, sign-off); changing how the frontier is computed or ordered; changing the deeper prompt skill's own restate loop.

**Original request:** see the first Deeper prompt entry (GitHub issue #7).

Revisions: Downstream, Tools and technologies and Gotchas filled from Questioning round 1.

Agreement: agreed in Questioning round 1

## 2026-11-21 Assumed: resuming a deep dive cut off part way

- Step: 0.3.18
- Question: a session ends mid deep dive; the router re-enters at 0.3.8. Resume the deep dive first, or treat the question as open in a fresh round?
- Answer taken: the round block logs such an answer as "deep dive under way" with no decision id; on entry, a logged round that holds one with no matching Deep dive entry resumes that deep dive (restating from the log) before any new frontier is computed.
- Why safe to assume: it keeps what the stakeholder already said instead of re-asking it cold (`codebase-map.md`, Module audit, gap on resume); no script reads these lines.

## 2026-11-21 Assumed: where a deep dive question takes its decision id

- Step: 0.3.18
- Question: round block, Deep dive entry, or both?
- Answer taken: the Deep dive entry only; the round block's Answer reads "deep dive under way" and names no `D<n>`.
- Why safe to assume: one decision, one id; the Done line's "every round and deep dive ... with decision ids" still holds.

## 2026-11-21 Assumed: which first-round questions offer the deep dive

- Step: 0.3.18
- Question: do the deeper-prompt agreement, its three questions and "Keep these assumptions?" also carry "Talk it through (deep dive)"?
- Answer taken: no; only frontier decision questions carry it. Those asks already have "Change it" or a veto. The round check still covers every answer in the round, the deeper prompt's included.
- Why safe to assume: the agreed deeper prompt keeps other asks out of scope (D2, **Not asked for**); a change to those answers already has its own path.

## 2026-11-21 Assumed: the summary and conversion questions in a round with a deep dive

- Step: 0.3.18
- Question: a round holds the Last round summary or the conversion question and another question goes to a deep dive. What then?
- Answer taken: the summary answer is dropped and 0.3.19 asks the revised summary on its own (its existing "a deep dive changed the design" branch). Deep dives run before a Yes to conversion acts, and the conversion answer is checked against them like any other.
- Why safe to assume: the summary was written on the recommendations a deep dive may overturn; reuses 0.3.19 as it stands (`questioning-loop.md:77`).

## 2026-11-21 Assumed: the large path's deep dive

- Step: 0.3.18
- Question: 6.5 asks the round but 6.8 logs it. Reorder the steps, or hold the deep dive inside 6.5?
- Answer taken: hold it inside 6.5, straight after the answers return and before 6.6. `IT set-question` settles each answer on disk as it lands, so nothing is lost; a deep dive question is settled with its agreed statement once confirmed. 6.8's Initiative round entry gains a deep dive block (Restated, Where it was wrong, Exchanges, Agreed statement, Answer, Round check). 6.5's Done line drops "or deferred", which is not a question state.
- Why safe to assume: no step moves, so large-path step numbers and the steps.tsv rows stay; the settled-on-disk record already gives the resume point.

## 2026-11-21 Assumed: an initiative question settled by a deep dive

- Step: 0.3.18
- Question: `settled` holds "the stakeholder's words verbatim for a decision"; a deep dive ends on an agent-written statement the stakeholder confirmed. What goes in `settled`?
- Answer taken: the agreed statement as confirmed, followed by `(confirmed: "<their yes, verbatim>")`; the `questions.md` template comment says so.
- Why safe to assume: the stakeholder confirmed the exact text, so it is their decision in words they approved; a comment line, undone by reverting it.

## 2026-11-21 Questioning round 2: settled design (0.3.19)

- Offered for veto: Assumed: resuming a deep dive cut off part way; Assumed: where a deep dive question takes its decision id; Assumed: which first-round questions offer the deep dive; Assumed: the summary and conversion questions in a round with a deep dive; Assumed: the large path's deep dive; Assumed: an initiative question settled by a deep dive; vetoed: none

**Q1. Is this the settled design?**

- Why now: round 1 and the module audit's gaps left no open decision.
- Options: A: yes · B: change it
- Recommended: A
- Answer: "Yes (Recommended)"
- Decision: **D7** settled design: picking "Talk it through (deep dive)" pauses the round; the round is logged, the agent says back the question and its recommendation's reason and asks where that is wrong; back and forth in chat until the stakeholder confirms a written statement, logged as the decision; then only answers it contradicts are re-asked and the rest named as standing (D6). Large-path 6.5 does the same. One feature; light path fails on footprint.

Facts looked up instead of asked (0.3.10): None.

## 2026-11-21 Impact classification

| Part | Classification | Note |
| --- | --- | --- |
| Questioning loop 0.3.11–0.3.13 step text | refactor | deep dive runs straight after the round is logged; see data-model.md § Deep dive |
| Questioning loop Entry | extend | resume an unfinished deep dive before computing a new frontier |
| Deep dive option label | refactor | "Talk it through (deep dive)" in the loop, chat format, Answer placeholder and large-path 6.5 |
| Deep dive entry shape | refactor | new lines; see data-model.md § Deep dive entry |
| Questioning round entry shape | extend | a deep dive question's Answer reads "deep dive under way", no `D<n>` |
| Large path 6.5 | refactor | deep dive inside 6.5; Done line drops "or deferred" |
| Initiative round entry shape | extend | a deep dive block |
| Initiative question `settled` | extend | agreed statement plus the confirming words |
| `steps.tsv` rows 0.3.11–0.3.13 | refactor | titles only; ids and row count unchanged |
| Retrospective waits count | extend | adds `Exchanges:` numbers |
| `PLAN/decision-flow.mermaid`, `PLAN/decision-flow-reference.md` | refactor | node titles follow `steps.tsv` |
| `step-progress.sh`, `initiative-transition.sh` question states | unchanged | no new state, no new step |
| Glossary: Questioning round, Deep dive | create | written at 0.2.3 |

## 2026-11-21 Spec branch carries spec 00018's glossary terms

- Step: 1.1
- Question: `spec-worktree.sh create` commits the workflow root, so `.workflow/GLOSSARY.md` would carry spec 00018's two uncommitted entries (Browser-suite evidence, Browser-suite run output) onto this branch. Options: hold them aside · carry them on 00019 · stop.
- Answer: "Carry them on 00019"
- Decision: **D8** the two 00018 entries ride on this spec's first commit and reach main with its merge; 00018's draft sees them missing from the main checkout until then.

## 2026-11-21 Assumed: Phase 1 targets

- Step: 1.1
- Question: what thresholds for the questioning loop's size, errors and coverage, which the spec and rules do not give?
- Answer taken: `questioning-loop.md` at most 15,000 bytes (12,325 at baseline, about 2,700 bytes for the new deep dive text), since it loads on every questioning-loop resume though it sits outside ADR-0004's two budgets; no error or coverage number (a text change; no bash coverage tool).
- Why safe to assume: the cap keeps the loop lean in the spirit of ADR-0004 without changing what is built; the breakdown quiz offers it for veto.

## 2026-11-21 Phase 1: tests in tasks?

- Step: 1.1
- The spec adds a new capability (CAP-NEW-deep-dive-discussion), so "tests in tasks" does not apply: 1.2 builds the journey checks under `test-harness`. No browser suite: the project has no e2e profile and no journey needs one.

## 2026-11-21 Assumed: the seams under test

- Step: 1.2 (2.3 rules)
- Question: which public interface does each slice's tests drive?
- Answer taken: T1: the step-file text as read by `tests/lint/stakeholder-asks-docs.sh` (JRN-001 to JRN-005), plus `lint/step-list` and `scripts/step-progress` (JRN-007). Catches missing or misordered wording, a leftover old label and changed step totals; misses whether an agent actually follows the text in a live round. T2: the waits command line in `retrospective/modules/evidence.md`, run as written on fixture design logs (JRN-006). Catches a wrong count; misses other Measurements lines.
- Why safe to assume: both are existing seams (the doc lints and the fenced command), the highest that reach the behaviour; a live-round check would need a model in the loop, which the harness has no seam for.

## 2026-11-21 Breakdown quiz

- Asked at: 1.2, beside the harness build
- Slices: approved as shown. T1 Deep dive held at once (feature-workflow; `modules/questioning-loop.md`, `modules/large-path.md`, `assets/design-log.md`, `assets/questions.md`, `references/steps.tsv`, `PLAN/decision-flow.mermaid`, `PLAN/decision-flow-reference.md`; M, ~200 lines; JRN-001 to JRN-005, JRN-007). T2 Waits count includes deep dive exchanges (retrospective; `.agents/skills/retrospective/modules/evidence.md`; S, ~5 lines; JRN-006).
- Edges, parallel_with and hitl modes: approved; no edges, no overlaps, both afk, one wave.
- Offered for veto: Assumed: Phase 1 targets; Assumed: the seams under test; vetoed: none
- Size: within the project defaults: 2 tasks, 8 predicted files
- Decision: **D9** two tasks in one wave as shown. Answer: "Approve (Recommended)"

## 2026-11-22 Assumed: when 6.5 settles the other answers of a round with a deep dive

- Step: 3.4 (T1 result)
- Question: `initiative-transition.sh set-question` refuses to settle a question that is already settled, so an answer a deep dive contradicts could not be settled again. Settle the round's other answers as they land (as "Assumed: the large path's deep dive" said), or only after the round check?
- Answer taken: in a round that holds a deep dive, 6.5 settles the other answers after the round check; a round without one settles each answer as it lands, as before.
- Why safe to assume: it keeps the script's one-write rule unchanged; the cost is that a session cut off mid deep dive leaves those answers open, so the next round asks them again. Supersedes the "settles each answer on disk as it lands" line of the earlier entry for rounds with a deep dive.

## 2026-11-22 Task PRs skipped

- Step: 3.16. `task_review` is `pr`, but `gh` is not installed, so `open-task-pr.sh` skipped T1 and T2 before any push ("gh not installed"); both merged locally with `pr: null`.
- 2026-11-22 3.14: browser gate skipped; no e2e-browser profile. Added a Later requests line to [.workflow/deferred/browser-suite.md](../../deferred/browser-suite.md).
