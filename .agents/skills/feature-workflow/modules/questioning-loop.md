# Questioning loop

Interview the stakeholder until the feature's design tree is settled. Work in **rounds**: each round asks the whole **frontier** at once (design rule 7). **Facts are your job; decisions are the stakeholder's** (design rule 8). Every round, deep dive and scope ruling is appended to `design-log.md`, so the loop survives a cleared context and resumes from the log.

`ST` below is `.agents/skills/feature-workflow/scripts/status-transition.sh`; type the full path every time.

## Entry

1. `ST step .workflow/specs/NNN-slug 0.3.8` (marks where to resume).
2. Read the newest **Deeper prompt** entry in `design-log.md` (0.3.22): its agreed Ask, Goals, Downstream, Tools and Gotchas are the loop's input and frame the design tree; its **Not asked for** items stay out of scope. Then read `spec.md` (the draft goal), `codebase-map.md` (where recommended answers come from) and `design-log.md` (decisions already made; create it from [../assets/design-log.md](../assets/design-log.md) if missing).
3. On a loop-back, seed the tree with the reason you came back:

   | From | Seed question |
   | --- | --- |
   | 0.4.7 | The conflict between the impact model and the goal |
   | 0.6 | Each exit-gate check that was not clear |
   | 2.2 / 2.3 | What made the spec unspecifiable, or the interfaces under test not agreed |
   | 4.5 / 4.6 | The triage finding `F<n>` that needs a decision, or the upstream problem the third pass exposed |
   | 5.6 | The stakeholder's change request, verbatim |
   | 00.24 | The discovered problem and its evidence, from the newest **Discovered work** entry in `design-log.md` |
   | 00.29 (budget re-scope) | The size-budget crossing and the reduction the stakeholder wants, from the newest **Discovered work** entry in `design-log.md` |

## The round

1. **0.3.8 Compute the frontier.** Map the open decisions as a design tree: each decision branches into the decisions that hang off it. The frontier is every open decision whose prerequisites are settled. Order it highest priority first: decisions that change scope or unblock the most others lead. A question whose answer depends on another question still open in this round waits for a later round.
2. **0.3.9 Any answerable?** No → go to [0.3.19](#settle-the-goal).
3. **0.3.10 Look up facts.** For each frontier question that needs a fact from the repo, launch one `fact-lookup` with all such questions numbered:

   ````markdown
   ```yaml launch-header
   task_type: fact-lookup
   spec_dir: .workflow/specs/NNN-slug
   ```

   Affected area: <modules and paths from codebase-map.md>
   Q1: <question>
   Q2: <question>
   ````

   On Codex, launch as the [SKILL.md "Host notes"](../SKILL.md#host-notes) Launch row says: `agent_type` `fact_lookup`, `task_name` `s<NNN>_fact_lookup` (for example `s007_fact_lookup`), `fork_turns: "none"`.

   Ask the rest of the frontier now; only questions downstream of a pending lookup wait for it. Its return, per question (format fixed in `.agents/agents/fact-lookup.md`):
   - **Answer + Source:** the fact is settled; use it in the recommendation, never ask it.
   - **not a fact:** it is a decision; it joins the round.
   - **not determinable from the repo:** the stakeholder may know it; ask it in the round, saying the repo could not settle it.
4. **0.3.11 Ask the whole frontier in one round.** Each question carries options, your recommended answer with its reason (cite the `codebase-map.md` row it rests on), and a **Defer to deep dive** option. Word each question so "yes" accepts the recommendation.
   - **Claude Code:** AskUserQuestion, all questions in one call; put the recommended option first and mark it "(Recommended)", and add "Defer to deep dive" as an option. If the round has more questions than one call accepts, use the chat format below for the whole round.
   - **Codex, or chat:** one message in this format, then wait for the answers:

     ```text
     Q1 - <title>: <question, with the options>
     Recommended: <answer> (<reason, source>)
     Or: defer to deep dive

     Q2 - ...
     ```

   If the stakeholder answers "whatever you think is best", restate your recommendation and get an explicit yes.
5. **Log the round** in `design-log.md` with the **Questioning round** entry shape: per question the options, recommendation, the answer verbatim (or "deferred to deep dive") and a decision id `D<n>`; then the facts looked up instead of asked. Superseding an earlier decision is a new entry naming it.
6. **0.3.12–0.3.13 Deep dives.** After the round closes, take each deferred question one at a time: gather what it needs (a `fact-lookup`, the map, the code via a sub-agent), lay out the options, ask it alone, and log a **Deep dive** entry.
7. **0.3.14–0.3.15 Term gate.** For each answer that introduces a new or conflicting term, invoke the `domain-modeling` skill for gate 0.3.14; it agrees the term and writes the glossary under step `0.3.15`.
8. **0.3.16–0.3.17 Scope gate.** For each answer that puts work outside the agreed scope, run [deferred-handoff](deferred-handoff.md#write) **Write** at step `0.3.17`. It writes `.workflow/deferred/<slug>.md`, adds it to `spec.md` `deferred` and Non-goals, and logs the **Scope decision**.
9. **0.3.18 Questions remaining?** Answers reshape the tree: settled decisions push the frontier outward and surface new questions. Any open or newly surfaced → `ST step .workflow/specs/NNN-slug 0.3.8` and run the next round. None → 0.3.19.

## Settle the goal

**0.3.19 Confirm or revise the goal.** The frontier is empty when every branch is visited and nothing is silently assumed. Summarise the settled design in a few lines and ask the stakeholder to confirm shared understanding; a correction reopens the frontier.

Once confirmed, evaluate the **0.3.20 light-path facts** (table in [discovery.md](discovery.md#0320-light-path-test)) so the same write records them, then write `spec.md`:

```bash
ST step .workflow/specs/NNN-slug 0.3.19
```

- **Why:** the final goal: the deeper prompt's Ask and Goals, as revised by the loop.
- **Capabilities:** each with its ID (existing `CAP-###`, or provisional `CAP-NEW-<slug>`), intent and success line.
- **Constraints**, **Non-goals**, **Assumptions** (calls made without explicit confirmation).
- **Open Questions:** empty; anything still open means the loop is not done.
- Frontmatter `light_path`: `true` only when all three facts are clean. Leave `status` and every other key as they are.

Return to [discovery](discovery.md#0320-light-path-test) at 0.3.20. The size `budget` is not written here: discovery writes it at 0.3.20 on the light path, task-breakdown at 2.5 on the full path.

## Done

- The frontier is empty and the stakeholder confirmed the summary.
- Every round, deep dive and scope ruling is in `design-log.md` with decision ids; every new term is in the glossary; every shelved item is a `.workflow/deferred/` file listed in `spec.md`.
- `spec.md` holds the final goal, capabilities and `light_path`, written at step 0.3.19.
