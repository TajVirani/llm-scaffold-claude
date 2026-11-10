# Discovery (Phase 0)

Turn a request into a spec folder that says what to build, where it goes, what it touches and how it will be proven. This file runs discovery up to the questioning loop: 0.1–0.3.7 and 0.3.22. You run in the main session; the corpus (Tier A docs, the code of the affected area, the shelf) reaches you only as sub-agent extracts, except the glossary's term list and the `.workflow/rules.md` blocks a step names (design rule 3).

Out-of-scope work raised in Phase 0 goes through the scope gate 0.3.16–0.3.17 to `.workflow/deferred/`, never to `.workflow/specs/work-backlog/`.

`ST` and the exit codes are in [conventions](../references/conventions.md). `NNN-slug` is this feature's folder. Keep `spec.md` an index: link the support files, never copy them.

## 0.1 Initialise the feature folder

1. **0.1.1 Scan.** Take the number from one call, run where the session is; it leaves the session there:

   ```bash
   .agents/skills/feature-workflow/scripts/next-spec-number.sh
   ```

   Its first line is `NNN`. With no tracker set up it is the next number after the highest any spec has taken, counted in the main checkout even from a spec worktree: specs at the top level and in the Done folder, spec worktrees, and every initiative's `origin` and slices, on `initiative/*` branches too. With a tracker it is the new tracker issue's number, and the second line is the issue's URL. Exit 1 (the tracker failed) or 2 (bad settings): stop and show the stakeholder the message; never pick a number by hand. Older specs keep three digits; only a number's value orders it.
2. **0.1.2 Slug.** Two to four lowercase kebab-case words from the request, action-noun where it reads well, keeping technical terms ("Implement OAuth2 for the API" → `oauth2-api`). Use the glossary's term when the request names a known concept; the term list (0.2.1) names them.
3. **0.1.3** `mkdir -p .workflow/specs/NNN-slug`.
4. **0.1.4 `spec.md`.** Set the step, write the template, then record the status through the script:

   ```bash
   ST step .workflow/specs/NNN-slug 0.1.4
   # Write .workflow/specs/NNN-slug/spec.md from ../assets/spec.md: status: draft, tracker_issue set, title filled, template comment removed
   ST status .workflow/specs/NNN-slug draft --step 0.1.4
   ```

   Set `tracker_issue` to the second line 0.1.1 printed, or keep `""` when it printed one line (no tracker). With a URL, the first Links line is `Tracker issue: [#<n>](<url>)`, `<n>` the number without its padding; with `""`, delete that line.

5. **0.1.5 Off the shelf?** Yes when the stakeholder points at a `.workflow/deferred/` file, or names an item whose concept matches a file name in `.workflow/deferred/` (list names only) and the match is clear: assume and log it as [conventions](../references/conventions.md#asking-the-stakeholder) says, and ask only when it is not. Yes → run [deferred-handoff](deferred-handoff.md#archive) **Archive**. No → continue. A concept match found later by `retrieval` comes back to this step (see 0.2.6).
6. **0.1.6 Draft the goal.** `ST step .workflow/specs/NNN-slug 0.1.6`, then write the **Why** paragraph as understood from the request (or from the archived brief's Goal, or the work item's Problem). Leave other sections as placeholders; 0.3.19 settles them.

### Seeded from a work item

A request can come from a work item: a line `B<n>` on a backlog list `.workflow/specs/work-backlog/<origin>.md`. Sign-off chose **Start it** at 5.9 of the origin spec, or the stakeholder picked an open item at any later time. It is not off the shelf: 0.1.5 is No.

- **Seed.** Read the line. Its problem is the request for 0.1.2 and drafts the Why at 0.1.6; its evidence becomes the first facts for retrieval and the questioning loop. Also read the origin spec's **Discovered work** entry for it in that spec's `design-log.md`.
- **At 0.1.4** (step 0.1.4 admits both writes), while writing `spec.md`:
  - add `origin: <origin>.md#B<n>` to the new spec's frontmatter (for example `origin: 00012-csv-export.md#B2`);
  - mark the line promoted: Edit it from `- [open]` to `- [promoted]` and add ` -> .workflow/specs/NNN-slug` at its end. Change nothing else (on Codex check the write first with `check-write.sh`).
- **Origin entry.** Create `design-log.md` from [../assets/design-log.md](../assets/design-log.md) if needed and append a dated **Origin** entry: the item, its origin spec and step, and its problem and evidence copied in full. This entry is the lasting record.
- **Started from 5.9:** after 0.1.6, hand the new folder name back to sign-off. The new spec waits in `draft` and resumes through the router.
- The promoted line stays on its list as the pointer to the new spec.

A spec the large path emits from an initiative's slice runs 0.1.1–0.1.6 with the additions in [Seeded from a slice](large-path.md#seeded-from-a-slice).

## 0.2 Retrieve existing system context

1. **0.2.1 Affected area.** Name the affected area as module names plus repo-relative paths, from the `owns` globs of the **Ownership** block in `.workflow/rules.md`. This command prints one line per module with its `owns` paths, trailing `/**` or `*` removed. Read nothing else from `rules.md` here: 0.3.3 and 0.3.20 read the blocks they need.

   ```bash
   awk '/^## /{f=($0 ~ /^## Ownership[[:space:]]*$/); next} f && /^```ya?ml/{y=1; next} y && /^```/{exit} y' .workflow/rules.md \
     | yq '.modules // {} | to_entries | .[] | .key + ": " + ((.value.owns // []) | map(sub("/\*\*$"; "") | sub("\*$"; "")) | join(" "))'
   ```

   Keep the lines for the modules the request touches as the area list used below. Then read the project's terms with `.agents/skills/domain-modeling/scripts/term-list.sh`: one line per glossary entry, with the aliases to avoid (with a `.workflow/GLOSSARY-MAP.md`, every context glossary it maps, each line labelled by its context). Never read the glossary whole: when a term in the request matches one on the list, read that entry alone with `term-list.sh --define <term>`.
2. **0.2.2 Term gate, with the launches beside it.** Does the request use a new, ambiguous or conflicting term? Note each raised term with the name you would propose. Then send the launches below in the same message as the gate's first question, so the agents run while the stakeholder answers:
   - **The launches:** `retrieval`, and `library-evaluation` when step 3 finds it needed.
   - **The ask:** with a term raised, invoke the `domain-modeling` skill for gate 0.2.2. It assumes and logs each clear term and writes it under step `0.2.3` at once; only an open term (a conflict with an entry, or two terms competing) is asked, and written as its answer lands. With no open term there is no ask; send the launches alone, with the assumed terms as agreed.

   Done when every raised term is agreed or assumed, or confirmed or assumed to mean an existing entry, and the launches are out.
3. **0.2.4 / 0.2.5 Launch `retrieval`, and `library-evaluation` when it is needed**, in one message, beside the term-gate ask (step 2).

   **Is library evaluation needed?** Yes when the request names a library, SDK or external API the project does not use yet, or when a concern the change needs from outside the project has no approved library in the **Approved libraries per concern** section of the work profile for the affected area (`.workflow/profiles/<work type>.md`). Otherwise launch `retrieval` alone; at 0.2.6, **Library options** is one line saying it was not needed and why.

 `Agreed terms` is the terms agreed at 0.2.2 when the gate has finished, else each raised term followed by `(proposed, pending the 0.2.2 gate)`.

   ````markdown
   ```yaml launch-header
   task_type: retrieval
   spec_dir: .workflow/specs/NNN-slug
   ```

   Affected area: <modules and paths>
   Agreed terms: <terms from 0.2.2 | <term> (proposed, pending the 0.2.2 gate), ... | "none raised">
   ````

   ````markdown
   ```yaml launch-header
   task_type: library-evaluation
   spec_dir: .workflow/specs/NNN-slug
   ```

   Affected area: <modules and paths>
   Agreed terms: <as for retrieval>
   External systems: .workflow/rules.md, section "External systems"
   ````

   Launch them on your host as [launching](../references/launching.md) says.

4. **0.2.6 Write `codebase-map.md`** from [../assets/codebase-map.md](../assets/codebase-map.md) and the returns only, each part as its return lands. Use the name agreed at 0.2.2 wherever a return used a proposed term the stakeholder renamed:
   - **Affected area** ← the 0.2.1 list. **Relevant code**, **Seams and interfaces**, **Prior decisions**, **Not found** ← the same-named sections of the `retrieval` return.
   - **Library options** ← the `library-evaluation` report, pasted whole in place of the template table, with its Evidence URLs intact. A `Hold` or `Blocked: missing context` return goes in as returned and its missing items become questions for the loop. With no launch, write one line in place of the table: `Not evaluated: <why>`, for example `Not evaluated: no new library named; shell-scripts approves jq and yq for JSON and YAML.`
   - Delete the template comment and placeholder rows; write `None.` for an empty section.
   - **Shelf match.** If **Prior decisions** reports a `.workflow/deferred/` file that matches this request by concept, decide whether this request is that item. A clear match is assumed: assume and log it as [conventions](../references/conventions.md#asking-the-stakeholder) says, quoting the shelved reason in the entry. Ask only when the match is partial or the shelved reason argues against doing it now, quoting the reason. Yes → [deferred-handoff](deferred-handoff.md#archive) **Archive**, then revisit the goal at 0.3.19. No → continue.

   Done when every section holds either agent extracts with sources or `None.`.

## 0.3 Frame the problem (placement first)

1. **0.3.1 Capability already exists?** Check the goal against the capabilities in **Prior decisions** and, for the candidate names, `grep -n -i '<term>' .workflow/capabilities.md`.
   - Yes → **0.3.2 Reframe** as a change to that capability: it keeps its `CAP-###`. Log the reframe in `design-log.md`; 0.3.19 writes it into `spec.md`.
   - No → a new capability gets a provisional `CAP-NEW-<slug>` (lowercase kebab-case, unique in this spec) until 5.3.
2. **0.3.3 Owning module clear?** Read the **Ownership** block of `.workflow/rules.md` whole. Clear when every path the change touches falls under one module's `owns` in that block.
   - Yes → go to [0.3.22](#hand-off-to-the-questioning-loop). No placement ADR is needed.
   - No → **0.3.4 Resolve placement** with the stakeholder: put the candidate modules to them as one question with your recommendation (from **Seams and interfaces** and **Prior decisions**), then log a **Placement** entry in `design-log.md` (create it from [../assets/design-log.md](../assets/design-log.md) if missing; that is node 0.3.21).
3. **0.3.5–0.3.7 Conflicts and the ADR.** Invoke `domain-modeling` for placement: it checks the placement against the ADRs and `.workflow/rules.md` (0.3.5), has the stakeholder conform or supersede (0.3.6), and writes the placement ADR under step `0.3.7`, or a design-log entry when the placement fails the three-part ADR test. A rule conflict becomes a 5.3 proposal, never a mid-feature rule edit.

### Hand off to the questioning loop

1. **0.3.22 Deeper prompt.** Invoke the `deeper-prompt` skill. It appends a **Deeper prompt** entry to `design-log.md`; its "ready to pass on?" question is not asked on its own but rides on the questioning loop's first ask. Runs on both paths (light versus full is decided later, at 0.3.20), and only on this first entry: loop-backs to 0.3.8 go straight to the loop.

2. Load [questioning-loop.md](questioning-loop.md) with the block as its input. It runs 0.3.8–0.3.19 and returns at 0.3.20 to [discovery-impact.md](discovery-impact.md#0320-light-path-test).

## Done

- `spec.md` exists at `draft` with its Why drafted.
- A spec seeded from a work item carries `origin` and a design-log Origin entry, and the item is marked `promoted`.
- `codebase-map.md` was written only from agent returns; `design-log.md` holds any placement decision and the **Deeper prompt** entry.
- The questioning loop is loaded, and returns at 0.3.20 to [discovery-impact.md](discovery-impact.md).
