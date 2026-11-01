# Deferred handoff

One file per shelved concept in `.workflow/deferred/`, written so a fresh agent with no access to this conversation can act on it months later. `retrieval` reads the shelf at 0.2.4 of every later feature, so a well-named, durable file is how shelved work comes back.

Run [Write](#write), [Archive](#archive) or [Re-point at conversion](#re-point-at-conversion) as the caller asks, then return to the calling module with the [Return](#return) summary.

`origin_spec` and `superseded_by` name the folder that owns the item: a spec, `.workflow/specs/NNN-slug`, or an initiative, `.workflow/initiatives/NNN-slug`. An initiative's large path writes an item at 6.5 with its own folder as `origin_spec`; the steps below that touch `spec.md` (`deferred`, Non-goals) and the spec's step do not apply to it, and the note goes to the initiative's `design-log.md`.

## Write

Used at 0.3.17 (outside agreed scope), 3.14 (light-path suite gap), and for a discovered-work item or backlog line only when the stakeholder asks for a shelf file (at a batched ask, or at 5.9). Review and sign-off never write one on their own: a kept item is a line on the spec's backlog list (`modules/discovered-work.md`, 00.26).

1. **Name the concept.** A short kebab-case name for what is shelved, not the incident: `csv-export.md`, not `review-finding-3.md`.
2. **Check the shelf.** List `.workflow/deferred/*.md` (not `.workflow/deferred/archive/`) and open any file whose name could be the same concept. Match by concept, not keyword: "night theme" matches `dark-mode.md`.
   - **Match:** append one line to its **Later requests** section (`- .workflow/specs/NNN-slug, <step>: <one line>`) instead of writing a new file, without asking; the match is your call, and the Return names the file under `appended:`. When the two are clearly distinct concepts that only share words, choose a distinct name and continue.
   - **No match:** continue.
3. **Fill the template.** Copy [../assets/deferred.md](../assets/deferred.md) to `.workflow/deferred/<slug>.md` (create `.workflow/deferred/` if missing) and fill every section; delete the template comment and any optional section left empty.

   | Field | 0.3.17 scope decision | 3.14 suite gap | Stakeholder's shelf request |
   | --- | --- | --- | --- |
   | `origin_spec` | `.workflow/specs/NNN-slug` | same | this spec |
   | `created` | today, `date -u +%F` | same | same |
   | `severity` | delete the key | delete the key | the verified triage severity (`high`, `medium` or `low`) for a review finding; else delete the key |
   | **Mode** | HITL when a human must decide; AFK when an agent can act alone | AFK unless the suite needs a human choice | as the item needs |
   | **Origin** | `0.3.17 scope decision` + design-log entry | `3.14 suite gap` | `shelf request` + the step it was asked at, the triage row `F<n>` or the backlog line or item file, and its Discovered work entry; Problem and Evidence copied from the item |

   Write it to these rules:
   - **Durable.** Describe behaviour, interfaces and contracts. File paths and line numbers appear only under Evidence, each with the commit it was true at (`git rev-parse HEAD`).
   - **Behavioural.** Say what the system should do, not how to change the code.
   - **Self-contained.** Background gives the durable reason it was shelved (scope, a technical constraint, a strategic decision), never "no time now".
   - **Reference, don't duplicate.** Link the origin spec, its design-log entry and any ADR instead of copying them.
   - **Redact** secrets, credentials and personal data.
   - **Acceptance criteria** are specific and independently checkable. **Out of scope** names the adjacent work this item does not cover.
4. **Record it in the spec** at 0.3.17, 3.14 and 5.9. Set the caller's step, then add the path to the `deferred` list in `spec.md` frontmatter (leave `status` and every other key as they are):

   ```bash
   .agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug <0.3.17 | 3.14 | 5.9>
   ```

   At 0.3.17 also add the item to **Non-goals**. At 3.14 the orchestrator adds the **Known gaps** line in the same write. At 5.9 sign-off also takes the item off the backlog (its line deleted, or an older item file set `moved-to-deferred` with the link). A shelf request at any other step is not added to `deferred`; its log line is the record. On Codex, check the write first (see SKILL.md, Host notes).
5. **Log it** in `design-log.md` with the matching entry shape: a **Scope decision** entry at 0.3.17 (with HITL or AFK), a one-line note at 3.14, and for a shelf request the item's `Ruling:` line naming the file.

Done when every item the caller handed over is a file under `.workflow/deferred/` (or a Later requests line), listed in `spec.md` `deferred` where step 4 applies, and logged in `design-log.md`.

## Archive

Used at 0.1.5 when the request came off the shelf (00.9), and when the stakeholder confirms that a shelf match reported by `retrieval` is this request.

1. Insert `superseded_by: .workflow/specs/NNN-slug` as the first frontmatter key of `.workflow/deferred/<slug>.md`, directly under the opening `---`. Change nothing else.
2. Move it: `mkdir -p .workflow/deferred/archive && mv .workflow/deferred/<slug>.md .workflow/deferred/archive/<slug>.md`.
3. Note it in this spec's `design-log.md` (create it from [../assets/design-log.md](../assets/design-log.md) if it does not exist yet): `Came off the shelf: [.workflow/deferred/archive/<slug>.md](../../deferred/archive/<slug>.md)`. The 0.1.6 goal draft starts from the archived brief's Goal and Acceptance criteria.

Done when `.workflow/deferred/<slug>.md` no longer exists, `.workflow/deferred/archive/<slug>.md` carries `superseded_by`, and the design log links it.

## Re-point at conversion

Used at 0.3.23, when the large path converts a draft spec into an initiative and deletes the spec folder. Every shelf item that names the spec must name the initiative instead, or it would point at nothing.

1. Find them: every `.workflow/deferred/*.md` and `.workflow/deferred/archive/*.md` whose `origin_spec` or `superseded_by` is `.workflow/specs/<spec NNN-slug>`.

   ```bash
   for f in .workflow/deferred/*.md .workflow/deferred/archive/*.md; do [ -f "$f" ] && OLD=.workflow/specs/<spec NNN-slug> yq --front-matter=extract -e '.origin_spec == strenv(OLD) or .superseded_by == strenv(OLD)' "$f" >/dev/null 2>&1 && echo "$f"; done
   ```

2. In each, set the matching key to `.workflow/initiatives/NNN-slug`. Change nothing else, and leave the file where it is.

Done when the loop above prints nothing. Report each file under `re-pointed:` in the Return.

## Return

Report back to the calling module:

```text
written:  .workflow/deferred/<slug>.md, ...
appended: .workflow/deferred/<slug>.md (Later requests), ...
archived: .workflow/deferred/archive/<slug>.md, ...
re-pointed: .workflow/deferred/<slug>.md, ...
failed:   <item>: <why>
```

A failed item is never dropped: tell the stakeholder, and keep it in `design-log.md` with the reason until it is written.
