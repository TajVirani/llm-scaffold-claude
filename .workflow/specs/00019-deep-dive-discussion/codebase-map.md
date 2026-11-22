# Codebase map: Hold the deep dive at once, as a discussion that reaches agreement

Affected area: feature-workflow (`.agents/skills/feature-workflow`: `modules/questioning-loop.md`, `references/steps.tsv`, `assets/design-log.md`, `modules/large-path.md`); retrospective (`.agents/skills/retrospective`: `modules/evidence.md`); tests (`tests`: step-list and loop-wording lints)

## Relevant code

| Item | What it does today | Source |
| --- | --- | --- |
| Questioning loop, round steps 0.3.8–0.3.11 | Frontier, answerable check, fact lookups, then one round asked with options, a recommendation and a "Defer to deep dive" option. Step 4 is labelled 0.3.11 and carries the Claude Code and chat formats. | `.agents/skills/feature-workflow/modules/questioning-loop.md:26-63` |
| Round logging (no step id) | Logs each round with the Questioning round shape, answers verbatim or "deferred to deep dive", and decision ids. | `.agents/skills/feature-workflow/modules/questioning-loop.md:64` |
| Deep dive step "0.3.12–0.3.13 Deep dives" | One section covers both 0.3.12 and 0.3.13: after the round, each deferred question is taken alone, gathered, asked, and logged as a Deep dive entry. | `.agents/skills/feature-workflow/modules/questioning-loop.md:65` |
| Term gate and scope gate after the round | Steps 0.3.14–0.3.15 and 0.3.16–0.3.17 run per answer, after the deep dive step. | `.agents/skills/feature-workflow/modules/questioning-loop.md:66-67` |
| Questions remaining (0.3.18) | Any open question sends the flow back to 0.3.8; "A small request usually needs one round" with the summary as last question. | `.agents/skills/feature-workflow/modules/questioning-loop.md:68` |
| Step list rows | 0.3.11 "Ask the round", 0.3.12 "Any deferred to deep dive?", 0.3.13 "Deep dive", all track `both`. Display data only; guards and the decision flow use the node ids. | `.agents/skills/feature-workflow/references/steps.tsv:1-2,12,47-49` |
| Progress line script | Reads steps.tsv and prints "Phase n of N · step n of M — title (id)". Totals come from the rows. | `.agents/skills/feature-workflow/scripts/step-progress.sh:3-5, 98-109` |
| Deeper-prompt agreement and questions | Rides on the first questioning ask; the agreement line says pending until a Questioning round logs the answer. | `.agents/skills/feature-workflow/modules/questioning-loop.md:10`; `.agents/skills/deeper-prompt/SKILL.md:33,79` |
| Design-log shapes | Questioning round shape (Why now, Options, Recommended, Answer, Decision; then Facts looked up). Deep dive shape (From Q<n> in round <n>, Explored, Answer, Decision). | `.agents/skills/feature-workflow/assets/design-log.md:72-84, 125-132` |
| Large path reuses the same ask | 6.5 asks the decision frontier "in the questioning loop's format", with "Defer to deep dive", and takes deferred questions one at a time "as the loop's deep dives do". | `.agents/skills/feature-workflow/modules/large-path.md:158-168` |
| Retrospective counts answers | `grep -cE 'Answer:|...'` counts every `Answer:` line, so round answers and deep dive answers both count as waits. | `.agents/skills/retrospective/modules/evidence.md:41` |
| Retrospective reads deep dives | Inventory row for design-log.md reads "decisions and their reversals, deep dives". | `.agents/skills/retrospective/modules/evidence.md:13` |
| Scripts do not name 0.3.11–0.3.13 | No script under `.agents/` names 0.3.11, 0.3.12 or 0.3.13; status-transition.sh names 0.3.8 only in its loop-back comment. | `.agents/skills/feature-workflow/scripts/status-transition.sh:434` |

## Seams and interfaces

| Interface | Shape (signature, type, contract) | Callers | Source |
| --- | --- | --- | --- |
| Anchor `questioning-loop.md#the-round` | Section "## The round" (0.3.8–0.3.18). | discovery-impact.md (0.4.6), large-path.md (frontier order, 6.5 format) | `.agents/skills/feature-workflow/modules/questioning-loop.md:24`; `modules/discovery-impact.md:67`; `modules/large-path.md:131,160` |
| Anchor `questioning-loop.md#entry` | Section "## Entry" (0.3.8 resume, deeper-prompt handling). | verification-setup.md | `.agents/skills/feature-workflow/modules/verification-setup.md:11`; `modules/questioning-loop.md:7` |
| Anchor `questioning-loop.md#settle-the-goal` | Section "## Settle the goal" (0.3.19). | questioning-loop.md (0.3.18 Last round link) | `.agents/skills/feature-workflow/modules/questioning-loop.md:68,72` |
| `ST step <spec-dir> 0.3.8` | The loop's entry marker; loop-backs from 0.4.7, 0.6, 2.2, 2.3, 4.5, 4.6, 5.6 and 00.24 land here. | discovery-impact.md, verification-setup.md, task-breakdown.md, review-triage.md, sign-off.md | `.agents/skills/feature-workflow/modules/questioning-loop.md:9,11-22` |
| Step ids in steps.tsv | 0.3.11, 0.3.12, 0.3.13 appear only in steps.tsv, the mermaid and the reference doc, not in any guard. | step-progress.sh; tests/lint/step-list.sh; PLAN/decision-flow.mermaid | `.agents/skills/feature-workflow/references/steps.tsv:47-49`; `PLAN/decision-flow.mermaid:79-81` |
| Mermaid node labels | "0.3.11 - Ask the whole frontier in one round…", "0.3.12 - Any question deferred to deep dive?", "0.3.13 - Deep dive each deferred question in turn…". | step-list.sh (mermaid id check) | `PLAN/decision-flow.mermaid:79-81` |
| Decision flow reference | Bold node ids compared with steps.tsv by the step-list lint. | step-list.sh | `PLAN/decision-flow-reference.md:305` |
| `step-progress.sh <id> [--path]` | Prints the progress line; exit 2 for unknown or off-path ids. | Orchestrator | `.agents/skills/feature-workflow/scripts/step-progress.sh:7-21` |
| Design-log entry shapes | "## YYYY-MM-DD Questioning round <n>" and "## YYYY-MM-DD Deep dive: <question>"; append only, one dated section per event. | questioning-loop.md steps 5 and 6; large-path.md 6.8 uses its own Initiative round shape | `.agents/skills/feature-workflow/assets/design-log.md:5-12, 72, 125` |
| Question record (initiative) | `initiative-transition.sh set-question <dir> IQ<n> --state <open\|researching\|settled> [--settled <text>]`; `settled` non-null exactly when the state is `settled`; only research questions may be `researching`. | large-path 6.4, 6.5 | `.agents/skills/feature-workflow/scripts/initiative-transition.sh:16-18,83,149-155`; `assets/questions.md:12-17` |
| Resume route for `draft` | A step in 0.3.8–0.3.19 loads the questioning loop and re-enters at 0.3.8, recomputing the frontier from `design-log.md`. | SKILL.md router | `.agents/skills/feature-workflow/SKILL.md:61` |
| Assumption veto in the first ask | Opens the next blocking ask with "Keep these assumptions?" and logs `- Offered for veto:` in that ask's entry. | Every step that asks | `.agents/skills/feature-workflow/references/conventions.md:41` |
| Initiative round entry shape | `## YYYY-MM-DD Initiative round <n>`: Frontier, a block per IQ, Slices, Still researching. No deep-dive field. | large-path 6.8 | `.agents/skills/feature-workflow/assets/design-log.md:95-114` |

## Prior decisions

| Decision or item | What it says | Source |
| --- | --- | --- |
| Design-log rules | Append only; decision ids local per feature; delete unused entry shapes. | `.agents/skills/feature-workflow/assets/design-log.md` § Rules |
| Decision flow, loop nodes | Nodes 0.3.8–0.3.19; one pass asks the whole frontier with a defer option; "defer-to-deep-dive is ours"; D73, D122. | `PLAN/decision-flow-reference.md:305` |
| Launch before asking | Before a blocking ask, launch what does not depend on the answer. | `PLAN/decision-flow-reference.md:277` |
| Provenance of the defer option | "added defer-to-deep-dive (0.3.12-0.3.13), the host multi-question UI, the term gate … and the scope gate". | `upstream-lineage.json:1450` |
| Grill-me routing | "Grill me" runs the questioning loop from 0.3.8; no separate grill skill. | `.agents/skills/feature-workflow/SKILL.md:27` |
| Deeper-prompt provenance | The loop is the hand-off target, never a grilling skill (D78). | `PROVENANCE.md:130` |
| Ordered-chain question lesson | A new mode's place in an ordered chain should be settled during the loop; it cost a loop-back round. | `.workflow/decisions/retrospectives/00010-worktree-guard-followups.md:74` |
| Shelf: workflow-settings-home.md | A settings item a deep dive surfaced; not a change to the loop. Nearest match only. | `.workflow/deferred/workflow-settings-home.md` § Origin |
| Shelf: all other files | None is about the loop's steps, the Deep dive entry or the Questioning round entry. | `.workflow/deferred/*.md` |

## Library options

Not evaluated: no external library or API involved; the change is to markdown step files, the step list and their lints.

## Module audit

Owning module: feature-workflow

| Kind | Finding | Source |
| --- | --- | --- |
| reuse | The round log (step 5) already runs before the deep dive step; only "after the round closes" in step 6 has to change. | `.agents/skills/feature-workflow/modules/questioning-loop.md:64-65` |
| reuse | Step 6 already says how a deep dive gathers what it needs: a `fact-lookup`, the map, or the code via a sub-agent. | `.agents/skills/feature-workflow/modules/questioning-loop.md:65` |
| reuse | A rule for re-asking answers a change touches exists for the deeper prompt: "ask again, in the next round, every answer the change touches". | `.agents/skills/feature-workflow/modules/questioning-loop.md:10` |
| reuse | Superseding a decision is a new entry, "D7 (supersedes D3)", the old one kept. | `.agents/skills/feature-workflow/assets/design-log.md:6,8`; `modules/questioning-loop.md:64` |
| reuse | "Restate your recommendation and get an explicit yes" pattern for "whatever you think is best". | `.agents/skills/feature-workflow/modules/questioning-loop.md:63` |
| reuse | 0.3.19 already asks the revised summary on its own when "a deep dive ... changed the design". | `.agents/skills/feature-workflow/modules/questioning-loop.md:77` |
| gap | The Last round summary rides in the same round on the recommended answers; no rule says the round check covers it when another question goes to a deep dive. | `.agents/skills/feature-workflow/modules/questioning-loop.md:68,76` |
| gap | A Yes to the conversion question converts at 0.3.23 "after logging the round"; nothing says whether a deep dive in the same round runs first. | `.agents/skills/feature-workflow/modules/questioning-loop.md:30` |
| gap | The first round also carries the deeper-prompt agreement, its own questions and the "Keep these assumptions?" question; unclear whether these offer the deep dive option or fall under the round check. | `.agents/skills/feature-workflow/modules/questioning-loop.md:10,51`; `references/conventions.md:41` |
| gap | No resume rule for a deep dive cut off part way: the router re-enters at 0.3.8, so a logged "deferred" answer with no Deep dive entry comes back as an open question in a fresh round. | `.agents/skills/feature-workflow/SKILL.md:61`; `modules/questioning-loop.md:3,9` |
| gap | Not specified whether a deep dive question takes its `D<n>` in the round block, the Deep dive entry, or both. | `.agents/skills/feature-workflow/assets/design-log.md:81-82,131-132` |
| gap | Large path order: 6.5 asks, 6.6 term gate, 6.7 plans slices, 6.8 logs the round; it cannot log the round and then hold the deep dive at once without reordering. | `.agents/skills/feature-workflow/modules/large-path.md:158-168,178-180` |
| gap | The Initiative round shape has no deep-dive block and the asset header lists the questioning loop as the only writer of deep dives. | `.agents/skills/feature-workflow/assets/design-log.md:3,95-114` |
| gap | 6.5's Done line says "settled or deferred", but "deferred" is not a question state. | `.agents/skills/feature-workflow/modules/large-path.md:168`; `scripts/initiative-transition.sh:16,149`; `assets/questions.md:12` |
| constraint | An initiative question's `settled` holds "the stakeholder's words verbatim for a decision"; an agreed statement the agent writes and the stakeholder confirms must fit that. | `.agents/skills/feature-workflow/assets/questions.md:16`; `modules/large-path.md:160-164` |
| constraint | Design log is append only, one dated section per event, an index not a store; quote the stakeholder verbatim where a decision turned on their wording. | `.agents/skills/feature-workflow/assets/design-log.md:6-10` |
| constraint | `steps.tsv` is display data; totals come from the row count, so keeping 0.3.12 and 0.3.13 as two rows keeps the counts; only the title column changes. | `.agents/skills/feature-workflow/references/steps.tsv:1-4,12,48-49`; `scripts/step-progress.sh:98-108` |
| constraint | No script names 0.3.11–0.3.13 and the loop never calls `ST step` for them. | `.agents/skills/feature-workflow/modules/questioning-loop.md:51,65`; `assets/design-log.md:74,127` |
| constraint | The option's wording appears in the step text, the Claude Code option, the chat line, the Answer placeholder and large-path 6.5; all must match. | `.agents/skills/feature-workflow/modules/questioning-loop.md:51,52,58,64`; `assets/design-log.md:81`; `modules/large-path.md:160` |
| constraint | The round goes out in one AskUserQuestion call (or all in chat when too many); the deep dive starts after that call returns. | `.agents/skills/feature-workflow/modules/questioning-loop.md:52` |
| constraint | The agreed statement and re-asked answers still pass the term gate and scope gate. | `.agents/skills/feature-workflow/modules/questioning-loop.md:66-67` |
| constraint | Launch before asking applies to each blocking ask inside the deep dive; only blocking questions wait. | `.agents/skills/feature-workflow/references/conventions.md:39-43` |

## Not found

- Tests asserting the words "Deep dive" or "Questioning round": none in `tests/`. Reported by retrieval.
- Tests that pin the loop's text or totals: `tests/scripts/step-progress.sh:29-44` pins "step 20 of 46" (0.3.22), "step 21 of 46" (0.3.8) and "of 34" on the light path; `:52` compares 0.3.11 with itself. `tests/lint/step-list.sh:25-59,62-64,127-128,136-144` checks steps.tsv against the reference doc, the mermaid, phase counts and every step id under `.agents/`. `tests/lint/stakeholder-asks-docs.sh:168-169` greps the "Entry" section, `:173` greps "0.3.11" and "Before you send the round", `:174` greps discovery-impact "0.4.6 Launch". `tests/lint/light-path-defaults.sh:3,9-10` describes the questioning round. Reported by retrieval.
- A 0.3.12 / 0.3.13 section split: questioning-loop.md covers both in one step (line 65); steps.tsv has two rows. Granularity only. Reported by retrieval.
- Doc disagrees with code: none found between questioning-loop.md, steps.tsv, step-progress.sh and design-log.md. Reported by retrieval.
- Rules, capabilities, ADR, pitfall or retrospective matches beyond the lines above: none in `.workflow/rules.md`, `.workflow/capabilities.md`, `.workflow/decisions/**`. Reported by retrieval.
- Tests inside the module that pin the deep-dive or round wording: none under `.agents/skills/feature-workflow/**`. Reported by module-audit.
- An existing "restate the question and ask where it is wrong" exchange: none in `modules/*.md`, `references/*.md` or `SKILL.md`; closest is `questioning-loop.md:63`. Reported by module-audit.
- A resume rule for a deep dive interrupted part way: none in `modules/questioning-loop.md`, `SKILL.md` or `references/conventions.md`. Reported by module-audit.
- A script that reads step titles or the Deep dive entry: none under `scripts/`. Reported by module-audit.
