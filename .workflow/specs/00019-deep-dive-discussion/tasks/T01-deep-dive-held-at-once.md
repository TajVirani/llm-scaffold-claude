# T01: Deep dive held at once

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** When the stakeholder picks "Talk it through (deep dive)" on a question in a questioning round, the questioning loop logs the round and then holds the deep dive straight away, before the term gate, the scope gate or the next round. The agent says back what it thinks the question is and why it recommended its answer, asks where that is wrong, and goes back and forth in plain chat (facts looked up, never asked) until the stakeholder gives an explicit yes to a written agreed statement. That statement is the decision, logged in a Deep dive entry. The agent then checks every other answer in the round against it, re-asks only the ones it contradicts in one ask, and names the rest as still standing. Several deep dives run one at a time in frontier order. A session cut off mid deep dive resumes it on entry, before computing a new frontier. The large path's round (6.5) does the same inside 6.5, settling the question with the agreed statement and the stakeholder's confirming words.

**Seam:** the step-file text as read by `tests/lint/stakeholder-asks-docs.sh` (the "00019 JRN-001" to "00019 JRN-005" checks), plus `tests/lint/step-list.sh` and `tests/scripts/step-progress.sh` (JRN-007). The wording contract is in those checks; write the text to it.

**Acceptance criteria:**

- [ ] `modules/questioning-loop.md` § The round: the 0.3.12–0.3.13 item follows "Log the round" and precedes 0.3.14, starts "straight after the round is logged", and holds the restate ("say back", "where that is wrong"), the "explicit yes" to the "agreed statement", and the round check (answers it "contradicts" re-asked, the rest "still standing"); "after the round closes" is gone. It also says: several deep dives run one at a time in frontier order; the deep dive is held in plain chat, facts looked up not asked; the round's Last round summary answer is dropped when a deep dive runs (0.3.19 asks the revised summary); deep dives run before a Yes to conversion acts; only frontier decision questions offer the option, not the deeper-prompt or veto questions; agreed statements and re-asked answers still pass the term and scope gates.
- [ ] Step 5 "Log the round": a deep dive question's Answer reads "deep dive under way" with no decision id; its `D<n>` is given in the Deep dive entry.
- [ ] § Entry: a logged "deep dive under way" answer with no matching Deep dive entry is resumed "before computing a new frontier".
- [ ] The option reads "Talk it through (deep dive)" in the 0.3.11 step text, the Claude Code option and the chat format line; no file under `.agents/` says "defer to deep dive" or "deferred to deep dive".
- [ ] `assets/design-log.md`: the Deep dive shape holds `- From:`, `- Restated:`, `- Where it was wrong:`, `- Explored:`, `- Exchanges:`, `- Agreed statement:`, `- Answer:`, `- Decision:`, `- Round check:` (data-model.md § Deep dive entry); the Questioning round shape's Answer placeholder reads "deep dive under way"; the Initiative round shape gains a deep dive block with the agreed statement and round check; the header's writer list names the large path for initiative deep dives.
- [ ] `modules/large-path.md` § 6.5: deep dive held inside 6.5 straight after the answers return and before 6.6, with the new label, the "agreed statement", the "explicit yes" and `IT set-question ... --settled "<agreed statement> (confirmed: \"<their yes>\")"`; its Done line drops "or deferred". 6.8's mention of the Initiative round entry covers the deep dive block.
- [ ] `assets/questions.md` documents that `settled` may hold an agreed statement followed by `(confirmed: "<their yes>")` after a deep dive.
- [ ] `references/steps.tsv` keeps 0.3.11, 0.3.12 and 0.3.13 with titles that match the new behaviour; the row count is unchanged. `PLAN/decision-flow.mermaid` and `PLAN/decision-flow-reference.md` node labels follow.
- [ ] `questioning-loop.md` stays at most 15,000 bytes; `lint/workflow-load-size` still passes.
- [ ] `tests/run-all.sh --suite lint/stakeholder-asks-docs --suite lint/step-list --suite scripts/step-progress --suite lint/workflow-load-size --suite lint/md-links` passes.

**Predicted files:** `.agents/skills/feature-workflow/modules/questioning-loop.md`, `.agents/skills/feature-workflow/modules/large-path.md`, `.agents/skills/feature-workflow/assets/design-log.md`, `.agents/skills/feature-workflow/assets/questions.md`, `.agents/skills/feature-workflow/references/steps.tsv`, `PLAN/decision-flow.mermaid`, `PLAN/decision-flow-reference.md`

**Phase 1 tests:** `tests/lint/stakeholder-asks-docs.sh`

**Size:** M (7 files, about 200 changed lines).

**Mode:** afk.

**Notes:** `PLAN/` is scaffold-only and outside every module; its two files change only to keep node labels in step with `steps.tsv`. Write in plain voice: short sentences, the glossary's terms (Questioning round, Deep dive, Frontier). Follow `.workflow/profiles/agent-docs.md`.
