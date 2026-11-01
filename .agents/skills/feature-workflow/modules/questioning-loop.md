# Questioning loop

Interview the stakeholder until the feature's design tree is settled. Work in **rounds**: each round asks the whole **frontier** at once (design rule 7). **Facts are your job; decisions are the stakeholder's** (design rule 8). Every round, deep dive and scope ruling is appended to `design-log.md`, so the loop survives a cleared context and resumes from the log.

`ST` below is `.agents/skills/feature-workflow/scripts/status-transition.sh`; type the full path every time.

## Entry

1. `ST step .workflow/specs/NNN-slug 0.3.8` (marks where to resume).
2. Read the newest **Deeper prompt** entry in `design-log.md` (0.3.22): its Ask, Goals, Downstream, Tools and Gotchas are the loop's input and frame the design tree; its **Not asked for** items stay out of scope. When its `Agreement:` line says pending and no later Questioning round logs the answer, the next ask carries it (the first round, or the 0.3.19 summary when no round is needed): open the message with the block and make its first question "Pass this deeper prompt on as written?", with "Yes (Recommended)" and "Change it". Log the answer as that round's first question. A change: apply it, append the revised block as a new **Deeper prompt** entry (`Agreement: agreed in Questioning round <n>`), and ask again, in the next round, every answer the change touches. Then read `spec.md` (the draft goal), `codebase-map.md` (where recommended answers come from) and `design-log.md` (decisions already made; create it from [../assets/design-log.md](../assets/design-log.md) if missing).
3. On a loop-back, seed the tree with the reason you came back. Every loop-back sets `draft`: the step file that owns the gate makes the status call below before loading this loop, and `ST` refuses any other route to `draft` (on exit 2 the owner stops and reports the reason).

   | From | Owner | Status call before loading the loop | Seed question |
   | --- | --- | --- | --- |
   | 0.4.7 goal conflict | discovery | none (already `draft`); `ST step .workflow/specs/NNN-slug 0.3.8` | The conflict between the impact model and the goal |
   | 0.6 not clear | discovery | none (already `draft`); `ST step .workflow/specs/NNN-slug 0.3.8` | Each exit-gate check that was not clear |
   | Scope change after 0.6, before 1.1 starts | verification-setup | `ST status .workflow/specs/NNN-slug draft --step 0.6` (refused once 1.1 has started) | The stakeholder's change, verbatim |
   | 2.2 / 2.3 | task-breakdown | `ST status .workflow/specs/NNN-slug draft --step 2.2` or `--step 2.3` | What made the spec unspecifiable, or the interfaces under test not agreed |
   | 4.5 / 4.6 | review-triage | `ST status .workflow/specs/NNN-slug draft --step 4.5` or `--step 4.6` | The triage finding `F<n>` that needs a decision, or the upstream problem the third pass exposed |
   | 5.6 | the router (5.6) | `ST status .workflow/specs/NNN-slug draft --step 5.6` | The stakeholder's change request, verbatim |
   | 00.24 | discovered-work | `ST status .workflow/specs/NNN-slug draft --step 00.24` (from `blocked` only) | The discovered problem and its evidence, from the newest **Discovered work** entry in `design-log.md` |
   | 00.29 (budget re-scope) | discovered-work | `ST status .workflow/specs/NNN-slug draft --step 00.29` (from `blocked` only) | The size-budget crossing and the reduction the stakeholder wants, from the newest **Discovered work** entry in `design-log.md` |

## The round

1. **0.3.8 Compute the frontier.** Map the open decisions as a design tree: each decision branches into the decisions that hang off it. The frontier is every open decision whose prerequisites are settled. Order it highest priority first: decisions that change scope or unblock the most others lead. A question whose answer depends on another question still open in this round waits for a later round.

   **A new step in an ordered chain.** When a frontier decision would add a step, mode or check to an ordered chain of rules (a guard's allow and deny order, a pipeline, a fallback list), put "where in the order does it go?" on the frontier in the same round, worded as "if yes, where?", with the position you recommend from `codebase-map.md`.

   **Several features?** When the tree holds more than one capability with its own success signal or its own owning module, put a conversion question first on the frontier: "This is several features: convert the spec into an initiative and plan each one as its own spec?" The stakeholder decides. Yes → convert at [0.3.23](large-path.md#0323-convert-a-spec-into-an-initiative) after logging the round; the loop ends there. No → keep the tree as one feature and continue.
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

   Launch it on your host as [launching](../references/launching.md) says.

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

**0.3.19 Confirm or revise the goal.** The frontier is empty when every branch is visited and nothing is silently assumed. Summarise the settled design in a few lines and have the stakeholder confirm shared understanding; a correction reopens the frontier. The confirmation rides on an ask that happens anyway:

- **Last round.** When the round you are about to ask can be the last one (no answer to it opens a new question), add the summary as its last question, written on your recommended answers: "If you take every recommendation, this is the settled design: <summary>. Right?" Every answer taking its recommendation and a yes here confirm it.
- **Otherwise** (an answer departed from its recommendation, a deep dive or term gate changed the design, or no round was needed), ask the revised summary as one ask, together with anything still pending, such as the deeper prompt's agreement.

**One feature?** Before writing `spec.md`, check that the settled design is one feature: one capability set with one success signal, buildable as one spec. No → convert at [0.3.23](large-path.md#0323-convert-a-spec-into-an-initiative) and write nothing here; the large path takes the design log with it. Yes → continue.

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

- The frontier is empty and the stakeholder confirmed the summary as one feature, or the spec was handed to the large path at 0.3.23.
- The deeper prompt's agreement is logged in a round: none is left pending.
- Every round, deep dive and scope ruling is in `design-log.md` with decision ids; every new term is in the glossary; every shelved item is a `.workflow/deferred/` file listed in `spec.md`.
- `spec.md` holds the final goal, capabilities and `light_path`, written at step 0.3.19.
