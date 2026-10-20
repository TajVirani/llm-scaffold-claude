<!--
Module: deferred-handoff (shared, D24). Writes and archives .workflow/deferred/ handoffs: 0.3.17, 3.14, 4.8, 5.9 (write; 5.9 moves a work-backlog item to the shelf, D57); 0.1.5 / 00.9 (archive); 00.8, 00.10 (the files).
Loaded by: modules/questioning-loop.md (0.3.17), modules/implementation-orchestrator.md (3.14, D29), modules/review-triage.md (4.8), modules/sign-off.md (5.9), modules/discovery.md (0.1.5, and a shelf match reported by retrieval at 0.2.4).
Sources: brief shape (current vs desired behaviour, acceptance criteria, out of scope; durable and behavioural, no paths outside evidence) from mattpocock/skills/skills/engineering/triage/AGENT-BRIEF.md@49dd158; one file per concept, kebab-case concept names, durable reasons, append later requests to the existing file, and "concept match -> surface the prior decision" from mattpocock/skills/skills/engineering/triage/OUT-OF-SCOPE.md@49dd158; "reference, don't duplicate; redact" from mattpocock/skills/skills/productivity/handoff/SKILL.md@49dd158; HITL/AFK from mattpocock/skills/skills/engineering/wayfinder/SKILL.md@49dd158 "Ticket Types" (all MIT). "A deferral that leaves no durable artifact and no message to the user is data loss", and a written/appended/failed return so nothing is dropped silently, adapted from EveryInc/compound-engineering-plugin skills/ce-work/references/tracker-defer.md (MIT, Copyright (c) 2025 Every; pattern only). Out-of-scope discoveries logged rather than fixed: open-gsd/gsd-core agents/gsd-executor.md "SCOPE BOUNDARY" (MIT; idea only). Archive step and frontmatter: PLAN/decision-flow-reference.md "Persistent files" 00.8-00.10; assetlist D24, D29, D57. Template: ../assets/deferred.md.
-->

# Deferred handoff

One file per shelved concept in `.workflow/deferred/`, written so a fresh agent with no access to this conversation can act on it months later. `retrieval` reads the shelf at 0.2.4 of every later feature, so a well-named, durable file is how shelved work comes back.

Run [Write](#write) or [Archive](#archive) as the caller asks, then return to the calling module with the [Return](#return) summary.

## Write

Used at 0.3.17 (outside agreed scope), 3.14 (light-path suite gap, D29), 4.8 (deferred review findings and remaining gaps) and 5.9 (an open `.workflow/specs/work-backlog/` item the stakeholder moves to the shelf at sign-off, D57).

1. **Name the concept.** A short kebab-case name for what is shelved, not the incident: `csv-export.md`, not `review-finding-3.md`.
2. **Check the shelf.** List `.workflow/deferred/*.md` (not `.workflow/deferred/archive/`) and open any file whose name could be the same concept. Match by concept, not keyword: "night theme" matches `dark-mode.md`.
   - **Match:** tell the stakeholder: "This matches `.workflow/deferred/<slug>.md`, shelved because <reason>. Same item?" If they confirm, append one line to its **Later requests** section (`- .workflow/specs/NNN-slug, <step>: <one line>`) instead of writing a new file. If they say it is distinct, choose a distinct name and continue.
   - **No match:** continue.
3. **Fill the template.** Copy [../assets/deferred.md](../assets/deferred.md) to `.workflow/deferred/<slug>.md` (create `.workflow/deferred/` if missing) and fill every section; delete the template comment and any optional section left empty.

   | Field | 0.3.17 scope decision | 3.14 suite gap | 4.8 review finding | 5.9 work-backlog item |
   | --- | --- | --- | --- | --- |
   | `origin_spec` | `.workflow/specs/NNN-slug` | same | same | the item's `origin_spec` (this spec) |
   | `created` | today, `date -u +%F` | same | same | same |
   | `severity` | delete the key | delete the key | the verified triage severity: `high`, `medium` or `low`. A `maybe-false` finding takes the severity it would have if true and says "unverified" under Evidence | delete the key |
   | **Mode** | HITL when a human must decide; AFK when an agent can act alone | AFK unless the suite needs a human choice | as the finding needs | as the item needs |
   | **Origin** | `0.3.17 scope decision` + design-log entry | `3.14 suite gap` | `4.8 review finding` + triage row `F<n>` | `5.9 work-backlog item` + the item file name and its origin step; Problem and Evidence copied from the item |

   Write it to these rules:
   - **Durable.** Describe behaviour, interfaces and contracts. File paths and line numbers appear only under Evidence, each with the commit it was true at (`git rev-parse HEAD`).
   - **Behavioural.** Say what the system should do, not how to change the code.
   - **Self-contained.** Background gives the durable reason it was shelved (scope, a technical constraint, a strategic decision), never "no time now".
   - **Reference, don't duplicate.** Link the origin spec, its design-log entry and any ADR instead of copying them.
   - **Redact** secrets, credentials and personal data.
   - **Acceptance criteria** are specific and independently checkable. **Out of scope** names the adjacent work this item does not cover.
4. **Record it in the spec.** Set the caller's step, then add the path to the `deferred` list in `spec.md` frontmatter (leave `status` and every other key as they are):

   ```bash
   .agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug <0.3.17 | 3.14 | 4.8 | 5.9>
   ```

   At 0.3.17 also add the item to **Non-goals**. At 3.14 the orchestrator adds the **Known gaps** line in the same write. At 5.9 sign-off also sets the work item `status: moved-to-deferred` and links the new `.workflow/deferred/` file in its **Links** (step 5.9 admits that write). On Codex, check the write first (see SKILL.md, Host notes).
5. **Log it** in `design-log.md` with the matching entry shape: a **Scope decision** entry at 0.3.17 (with HITL or AFK), the `Route` cell of the triage row at 4.8 (`defer (.workflow/deferred/<slug>.md)`), a one-line note at 3.14 and at 5.9.

Done when every item the caller handed over is a file under `.workflow/deferred/` (or a Later requests line), listed in `spec.md` `deferred`, and logged in `design-log.md`.

## Archive

Used at 0.1.5 when the request came off the shelf (00.9), and when the stakeholder confirms that a shelf match reported by `retrieval` is this request.

1. Insert `superseded_by: .workflow/specs/NNN-slug` as the first frontmatter key of `.workflow/deferred/<slug>.md`, directly under the opening `---`. Change nothing else.
2. Move it: `mkdir -p .workflow/deferred/archive && mv .workflow/deferred/<slug>.md .workflow/deferred/archive/<slug>.md`.
3. Note it in this spec's `design-log.md` (create it from [../assets/design-log.md](../assets/design-log.md) if it does not exist yet): `Came off the shelf: [.workflow/deferred/archive/<slug>.md](../../deferred/archive/<slug>.md)`. The 0.1.6 goal draft starts from the archived brief's Goal and Acceptance criteria.

Done when `.workflow/deferred/<slug>.md` no longer exists, `.workflow/deferred/archive/<slug>.md` carries `superseded_by`, and the design log links it.

## Return

Report back to the calling module:

```text
written:  .workflow/deferred/<slug>.md, ...
appended: .workflow/deferred/<slug>.md (Later requests), ...
archived: .workflow/deferred/archive/<slug>.md, ...
failed:   <item>: <why>
```

A failed item is never dropped: tell the stakeholder, and keep it in `design-log.md` with the reason until it is written.
