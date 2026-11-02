# Discovery (Phase 0)

Turn a request into a spec folder that says what to build, where it goes, what it touches and how it will be proven. This file runs discovery up to the questioning loop: 0.1–0.3.7 and 0.3.22. You run in the main session; the corpus (Tier A docs, Tier B caches, the shelf) reaches you only as sub-agent extracts, except the glossary's term list and the `.workflow/rules.md` blocks a step names (design rule 3).

Out-of-scope work raised in Phase 0 goes through the scope gate 0.3.16–0.3.17 to `.workflow/deferred/`, never to `.workflow/specs/work-backlog/`.

`ST` is shorthand for `.agents/skills/feature-workflow/scripts/status-transition.sh`: type the full path every time. `NNN-slug` is this feature's folder. Keep `spec.md` an index: link the support files, never copy them.

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
   # Write .workflow/specs/NNN-slug/spec.md from ../assets/spec.md: frontmatter unchanged (status: draft), title filled, template comment removed
   ST status .workflow/specs/NNN-slug draft --step 0.1.4
   ```

   On the small path: also set `small_path: true` and `light_path: true` in the frontmatter. A small-path spec is a light-path spec, so the progress line counts the light path from the start.

5. **0.1.5 Off the shelf?** Yes when the stakeholder points at a `.workflow/deferred/` file, or names an item whose concept matches a file name in `.workflow/deferred/` (list names only) and confirms it is that item. Yes → run [deferred-handoff](deferred-handoff.md#archive) **Archive**. No → continue. A concept match found later by `retrieval` comes back to this step (see 0.2.6).
6. **0.1.6 Draft the goal.** `ST step .workflow/specs/NNN-slug 0.1.6`, then write the **Why** paragraph as understood from the request (or from the archived brief's Goal, or the work item's Problem). Leave other sections as placeholders; 0.3.19 settles them.

### Seeded from a work item

A request can come from a work item: a line `B<n>` on a backlog list `.workflow/specs/work-backlog/<origin>.md`, or an older item file `.workflow/specs/work-backlog/<origin>-disc-<###>.md`. Sign-off chose **Start it** at 5.9 of the origin spec, or the stakeholder picked an open item at any later time. It is not off the shelf: 0.1.5 is No.

- **Seed.** Read the line, or the item file whole. Its problem (with the title and **Suggested scope and size** of an older file) is the request for 0.1.2 and drafts the Why at 0.1.6; its evidence (and an older file's **Why not a blocker**) become the first facts for retrieval and the questioning loop. For a line, also read the origin spec's **Discovered work** entry for it in that spec's `design-log.md`.
- **At 0.1.4** (step 0.1.4 admits both writes), while writing `spec.md`:
  - add `origin: <item>` to the new spec's frontmatter: `<origin>.md#B<n>` for a line (for example `origin: 00012-csv-export.md#B2`), the file name for an older item (for example `origin: 007-csv-export-disc-002.md`);
  - mark it promoted. A line: Edit it from `- [open]` to `- [promoted]` and add ` -> .workflow/specs/NNN-slug` at its end. An older file: Edit its frontmatter to `status: promoted` and `promoted_to: .workflow/specs/NNN-slug`. Change nothing else (on Codex check the write first with `check-write.sh`).
- **Origin entry.** Create `design-log.md` from [../assets/design-log.md](../assets/design-log.md) if needed and append a dated **Origin** entry: the item, its origin spec and step, and its problem and evidence copied in full. This entry is the lasting record.
- **Started from 5.9:** after 0.1.6, hand the new folder name back to sign-off. The new spec waits in `draft` and resumes through the router.
- **An older item file is deleted when discovery finishes** ([discovery-impact](discovery-impact.md#delete-a-promoted-item-file)); a promoted line stays on its list.

A spec the large path emits from an initiative's slice runs 0.1.1–0.1.6 with the additions in [Seeded from a slice](large-path.md#seeded-from-a-slice).

## 0.2 Retrieve existing system context

1. **0.2.1 Affected area.** Name the affected area as module names plus repo-relative paths, from the `owns` globs of the **Ownership** block in `.workflow/rules.md`. This command prints one line per module with its `owns` paths, trailing `/**` or `*` removed (the cache scripts take no globs). Read nothing else from `rules.md` here: 0.3.3 and 0.3.20 read the blocks they need.

   ```bash
   awk '/^## /{f=($0 ~ /^## Ownership[[:space:]]*$/); next} f && /^```ya?ml/{y=1; next} y && /^```/{exit} y' .workflow/rules.md \
     | yq '.modules // {} | to_entries | .[] | .key + ": " + ((.value.owns // []) | map(sub("/\*\*$"; "") | sub("\*$"; "")) | join(" "))'
   ```

   Keep the lines for the modules the request touches as the area list used below. Then read the project's terms with `.agents/skills/domain-modeling/scripts/term-list.sh`: one line per glossary entry, with the aliases to avoid (with a `.workflow/GLOSSARY-MAP.md`, every context glossary it maps, each line labelled by its context). Never read the glossary whole: when a term in the request matches one on the list, read that entry alone with `term-list.sh --define <term>`.
2. **0.2.7 Cache stamps match HEAD?** Run the check before any agent reads `.workflow/cache/`, and before the term gate asks anything, since its result decides what launches beside that ask:

   ```bash
   .agents/skills/regenerate-caches/scripts/cache-stamp-check.sh --area <path> [--area <path> ...]
   ```

   When `.workflow/tools/boundaries/dependency-cruiser.cjs` exists, also pass `--area .workflow/tools/boundaries/dependency-cruiser.cjs`. It is in the `architecture` scope (its Boundary violations come from it), and `--area` checks only the scope paths that intersect an area.

   It prints one JSON object (`.stale`, `.stamps`, `.caches[] | {cache_type, status, stale_paths, reason}`). Exit 0: every cache is fresh. Exit 1: some are `stale` or `missing` and need 0.2.8. Exit 2 → read `.caches[].reason`: an `invalid` cache is treated like a stale one; a tooling or usage error stops the step and is reported to the stakeholder. Every exit except a tooling or usage error goes to step 3, which sends the launches this result needs beside the term gate.
3. **0.2.2 Term gate, with the launches beside it.** Does the request use a new, ambiguous or conflicting term? Note each raised term with the name you would propose. Then send the launches below in the same message as the gate's first question, so the agents run while the stakeholder answers:
   - **Every cache fresh (0.2.7 exit 0):** launch `retrieval` and `library-evaluation` as step 5 says.
   - **Some cache needs 0.2.8:** launch the `cache-regeneration` agents in the background as step 4 says, and `retrieval` and `library-evaluation` beside them as step 5 says, with every cache 0.2.7 did not find fresh listed under `Stale caches`. Retrieval reads the code for those, so nothing waits for publishing.
   - **The ask:** with a term raised, invoke the `domain-modeling` skill for gate 0.2.2; it agrees each term with the stakeholder and writes the glossary under step `0.2.3` as each answer lands. With none raised, there is no ask; send the launches alone.

   Done when every raised term is agreed or confirmed as an existing entry, and the launches for this cache state are out.
4. **0.2.8 Regenerate and restamp** each cache whose status is `stale`, `missing` or `invalid`. Leave them running: retrieval and the questioning go on meanwhile. When each returns, check and publish its staged body as the second bullet says, between rounds. Launch here only when step 3 did not (a later check found a cache stale).
   - The launch: one `cache-regeneration` per cache type (parallel). Launch each on your host as [launching](../references/launching.md) says. It receives no Tier A and not the previous cache. The prompt is the launch header followed by exactly the four task lines `.agents/agents/cache-regeneration.md` defines:

     ````markdown
     ```yaml launch-header
     task_type: cache-regeneration
     spec_dir: .workflow/specs/NNN-slug
     ```
     Cache type: <modules | flows | architecture>
     Scope: <repo-relative path>[, <path> ...]
     Commit: <40-hex sha>
     Staging path: .workflow/.cache-staging/<cache type>.md
     ````

     `Scope` is the cache's current `scope` (`yq --front-matter=extract '.scope' .workflow/cache/<type>.md`), or the affected-area paths when the cache is missing; plain paths only, no globs. For `architecture`, leave `.workflow/tools/boundaries/dependency-cruiser.cjs` out of `Scope` (`build-architecture.sh` would analyse it as source) and add it back to the publish scope paths when it exists (regenerate-caches step 3). `Commit` is `git rev-parse HEAD`.

   - When each returns, check the staged body, then publish it:

     ```bash
     .agents/skills/regenerate-caches/scripts/check-staged-cache.sh <type> .workflow/.cache-staging/<type>.md
     .agents/skills/regenerate-caches/scripts/publish-cache.sh .workflow/.cache-staging/<type>.md <type> <scope-path> [<scope-path> ...]
     # architecture only: add --generator "$(.agents/skills/regenerate-caches/scripts/build-architecture.sh --print-generator)"
     ```

     `check-staged-cache.sh` exit 0 → publish. Exit 1 (problems listed on stderr): resume the agent once with those lines; if it fails again, do not publish. `publish-cache.sh` exit 0 published; exit 1 means the staged file is missing, empty or fails validation. A cache not published stays out of date: tell the stakeholder which one. Retrieval already read the code for it, so nothing is relaunched.

5. **0.2.4 / 0.2.5 Launch `retrieval` and `library-evaluation`** in one message, beside the term-gate ask (step 3). `Agreed terms` is the terms agreed at 0.2.2 when the gate has finished, else each raised term followed by `(proposed, pending the 0.2.2 gate)`.

   ````markdown
   ```yaml launch-header
   task_type: retrieval
   spec_dir: .workflow/specs/NNN-slug
   ```

   Affected area: <modules and paths>
   Agreed terms: <terms from 0.2.2 | <term> (proposed, pending the 0.2.2 gate), ... | "none raised">
   Stale caches (read the code for these, stamp null): <types, or "none">
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

   Launch both on your host as [launching](../references/launching.md) says.

   On the small path: launch `retrieval` alone, here and beside the term gate (step 3), and no `library-evaluation`. At 0.2.6 write **Library options** in `codebase-map.md` as `None (small path: not evaluated).`

6. **0.2.6 Write `codebase-map.md`** from [../assets/codebase-map.md](../assets/codebase-map.md) and the two returns only, each part as its return lands. Use the name agreed at 0.2.2 wherever a return used a proposed term the stakeholder renamed:
   - `cache_stamps` frontmatter ← the `cache_stamps` block of the `retrieval` return (`null` for a cache it read from the code). When a regenerated cache is published later, set its stamp to the published one.
   - **Affected area** ← the 0.2.1 list. **Relevant code**, **Seams and interfaces**, **Prior decisions**, **Not found** ← the same-named sections of the `retrieval` return.
   - **Library options** ← the `library-evaluation` report, pasted whole in place of the template table, with its Evidence URLs intact. A `Hold` or `Blocked: missing context` return goes in as returned and its missing items become questions for the loop.
   - Delete the template comment and placeholder rows; write `None.` for an empty section.
   - **Shelf match.** If **Prior decisions** reports a `.workflow/deferred/` file that matches this request by concept, ask the stakeholder whether this request is that item (quote the shelved reason). Yes → [deferred-handoff](deferred-handoff.md#archive) **Archive**, then revisit the goal at 0.3.19. No → continue.

   Done when every section holds either agent extracts with sources or `None.`, and the stamps are copied.

## 0.3 Frame the problem (placement first)

1. **0.3.1 Capability already exists?** Check the goal against the capabilities in **Prior decisions** and, for the candidate names, `grep -n -i '<term>' .workflow/capabilities.md`.
   - Yes → **0.3.2 Reframe** as a change to that capability: it keeps its `CAP-###`. Log the reframe in `design-log.md`; 0.3.19 writes it into `spec.md`.
   - No → a new capability gets a provisional `CAP-NEW-<slug>` (lowercase kebab-case, unique in this spec) until 5.3.
2. **0.3.3 Owning module clear?** Read the **Ownership** block of `.workflow/rules.md` whole. Clear when every path the change touches falls under one module's `owns` in that block.
   - Yes → go to [0.3.22](#hand-off-to-the-questioning-loop). No placement ADR is needed.
   - No → **0.3.4 Resolve placement** with the stakeholder: put the candidate modules to them as one question with your recommendation (from **Seams and interfaces** and **Prior decisions**), then log a **Placement** entry in `design-log.md` (create it from [../assets/design-log.md](../assets/design-log.md) if missing; that is node 0.3.21).
   - On the small path: a No first means [leave the small path](questioning-loop.md#leave-the-small-path), then 0.3.4 runs as written.
3. **0.3.5–0.3.7 Conflicts and the ADR.** Invoke `domain-modeling` for placement: it checks the placement against the ADRs and `.workflow/rules.md` (0.3.5), has the stakeholder conform or supersede (0.3.6), and writes the placement ADR under step `0.3.7`, or a design-log entry when the placement fails the three-part ADR test. A rule conflict becomes a 5.3 proposal, never a mid-feature rule edit.

### Hand off to the questioning loop

1. **0.3.22 Deeper prompt.** Invoke the `deeper-prompt` skill. It appends a **Deeper prompt** entry to `design-log.md`; its "ready to pass on?" question is not asked on its own but rides on the questioning loop's first ask. Runs on both paths (light versus full is decided later, at 0.3.20), and only on this first entry: loop-backs to 0.3.8 go straight to the loop.

   On the small path: skip the skill's step 2 questions. Fill **Downstream**, **Tools and technologies** and **Gotchas** from the request and the work item (`none known` where they say nothing); the block's agreement still rides on the loop's first ask.

2. Load [questioning-loop.md](questioning-loop.md) with the block as its input. It runs 0.3.8–0.3.19 and returns at 0.3.20 to [discovery-impact.md](discovery-impact.md#0320-light-path-test).

## Done

- `spec.md` exists at `draft` with its Why drafted.
- A spec seeded from a work item carries `origin` and a design-log Origin entry, and the item is marked `promoted`.
- `codebase-map.md` was written only from agent returns and carries the stamps; `design-log.md` holds any placement decision and the **Deeper prompt** entry.
- The questioning loop is loaded, and returns at 0.3.20 to [discovery-impact.md](discovery-impact.md).
