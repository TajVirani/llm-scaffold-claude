---
name: project-standards
description: "Grill the human through a mandatory coverage list (libraries per concern, folder structure and layout tree, naming per layer, boundaries, contracts, process patterns, bootstrap order, deferred), then approve and write the project's standards: a staged baseline split into .workflow/rules.md, work profiles, ADRs, .workflow/pr-quality checks, per-profile lint config and a managed AGENTS.md block, every line carrying its destination, enforcement and evidence. Use when project-setup hands over after agreeing the work types (and again for lint config once toolchains are installed), when adopting standards in an existing codebase, when importing an architecture or standards document, when refreshing standards after code changed, or when adding a work type."
---

# Project standards

Turn what the project brings (policy, an imported document, the code itself) into enforced standards. The baseline in `.workflow/.standards-staging/baseline.md` is a **staging draft, never a source of truth**: each line is routed to its home (`.workflow/rules.md`, `.workflow/profiles/<work-type>.md`, an ADR, a `.workflow/pr-quality/` check, lint config, the AGENTS.md block) and to the cheapest mechanism that holds it. Done when every applicable item of the mandatory coverage list ([assets/coverage.md](assets/coverage.md)) has a human answer, every approved line is written to its destination, the boundary config regenerates, the lint config parses, and each written doc carries a `verified_at_commit` stamp.

## Modes

| Mode | When | Steps |
| --- | --- | --- |
| greenfield | No tracked source code yet | 0-2, 3 (starter research and library candidates), 4-9; every coverage item is mandatory |
| brownfield | Code exists; no `verified_at_commit` stamp in `.workflow/rules.md` or `.workflow/profiles/` | 0-9; coverage items discovery left unknown are mandatory |
| refresh | Stamps exist | [modules/refresh.md](modules/refresh.md), then 5-9 for what changed |
| add-work-type | Stamps exist and a new kind of work appears | 0-9, scoped to the new work type's paths and profile |

## When called from project-setup

project-setup calls this skill twice, passing the agreed work types and the mode (greenfield, brownfield, or add-work-type with the one new work type). The work-type list is settled; change it only through a ledger row the human approves.

| Call | When | You run | You return |
| --- | --- | --- | --- |
| `phase: standards` | After the shared files exist and the work types are agreed; no toolchain is installed and no profile exists yet | Steps 0-7. Create each `.workflow/profiles/<work-type>.md` from the template and write every approved row **except** `profile:* § Toolchain` rows and `lint:*` rows, which stay `approved` with an empty Written cell | The files written, the approved Toolchain rows per work type (tools, versions, commands), the approved lint rows, open items |
| `phase: lint` | After project-setup has written the Toolchain blocks from your rows and installed the toolchains | write.md "Lint config" for the approved `lint:*` rows, the lint proof in step 8 (not the generator), then step 9 for every doc written in either call | The lint result per profile and the stamps |

project-setup owns the Toolchain blocks and the installs; you own every other standards line, every lint rule beyond the base config the installer registers (anti-slop), and the lint parse proof. project-setup runs the boundary generator itself after the `lint` call.

The example profiles (`.agents/skills/project-setup/assets/profiles/examples/`) are never pre-seeded: offer their lines as candidate answers inside the interview (C1, C3, C4 for `test-harness` and `e2e-browser`), and the human picks.

Standalone, run every step, and write Toolchain and lint rows yourself at step 7.

## 0. Gate on in-flight work

List the specs whose status is not `done`:

```bash
for s in .workflow/specs/*/spec.md; do [ -f "$s" ] || continue; st=$(yq --front-matter=extract '.status // ""' "$s"); [ "$st" = done ] || echo "$s $st"; done
```

- **None**: Tier A writes are allowed from the main session without a step. Continue.
- **One or more**: run steps 1-6 as normal, but at step 7 write each approved line as a `proposed` row in the in-flight spec's `.workflow/specs/NNN-slug/proposals.md` instead (ask which spec when several are in flight). Copy `.agents/skills/feature-workflow/assets/proposals.md` there when the file is absent, and continue its `P<n>` numbering. Use its groups: Rules, Decisions, Profiles, and Tool rules for lint config. Set Origin to `project-standards <date>`. That spec's sign-off applies them at 5.3. Keep the `.workflow/pr-quality/` and AGENTS.md block lines in `.workflow/.standards-staging/baseline.md`, and write them in a later run once no spec is in flight.

Done when the in-flight list is known and the write route (direct or proposals) is fixed.

## 1. Assess

Read the Tier A docs that exist (`.workflow/rules.md`, `.workflow/profiles/*.md`, `.workflow/decisions/adr/`, `.workflow/GLOSSARY.md`), the instruction files (`AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING*`, `CODING_STANDARDS*`, editor rule files, PR templates), the lint, format and typecheck configs, and the manifests. Detect the mode from the table above. Create the staging folder (`install.sh` gitignores it):

```bash
mkdir -p .workflow/.standards-staging
```

Copy [assets/baseline.md](assets/baseline.md) to `.workflow/.standards-staging/baseline.md` when it is absent. In brownfield and refresh, open one **Existing instructions** row per independently meaningful instruction in those files, starting at `retain` or `rewrite`.

Done when the human has seen what exists, what is missing, and the mode, and has confirmed the mode.

## 2. Ask what they bring

Ask for what no scan reaches: policy (governance, security, compliance), frozen or generated areas, external standards or style guides, and any existing document to import (an architecture doc, a standards page). On greenfield also ask what is being built, for whom, and at what scale (it decides what C7 and C9 cover). Note the paths. Each of these needs its own answer; follow up on any the reply skipped. An imported document is testimony: split it line by line into baseline rows in step 5; it never becomes a standard as a whole.

Done when every question above has an answer or the human's "nothing".

## 3. Discover

Read [modules/discovery.md](modules/discovery.md). Brownfield and add-work-type: launch one `standards-discovery` agent per scope. Greenfield: recommend a starter and verify current versions on the web; after the first interview batch settles the paradigm, starter and frameworks, research the library candidates for every C1 concern before asking about them. Brownfield does the same for any C1 concern discovery left unknown.

Done when every scope's return is saved under `.workflow/.standards-staging/`, or, in greenfield, the starter and every pinned version carry a cited URL, and every C1 concern has its candidates saved with URLs.

## 4. Interview

Read [modules/interview.md](modules/interview.md) and work through [assets/coverage.md](assets/coverage.md). Coaching is the default and the path you start on; the fast path runs only when the human asks for it in so many words.

Done when every applicable coverage item has a row with `H` evidence (answered or delegated).

## 5. Draft the baseline

Fill `.workflow/.standards-staging/baseline.md`. Every line gets a destination and an enforcement class from [assets/enforcement-map.md](assets/enforcement-map.md), its coverage item, and the evidence it rests on, tagged `D`, `H`, `I`, `V` or `A` ([assets/baseline.md](assets/baseline.md) column notes). Prefer a tool over judgement and judgement over prose. The agreed layout tree is kept: one File locations row per folder, with every folder rule a tool can fail routed to `boundary` or `lint`. Aspirational state and restated manifest facts go to `drop` with their reason. Fill the header's evidence counts.

Done when no row has an empty Destination, Enforcement or Evidence cell, every Existing instructions row has a settled action, and the header counts match the rows.

## 6. Approve once

Open with the header's evidence counts (how many rows are `A`, and how many of those sit in a mandatory coverage item). If any `A` row sits in an applicable coverage item, stop: ask those as questions (batches of at most eight) until each is `H` or delegated, then show the ledger. Show the human the ledger: every row, as line → destination → enforcement, grouped by destination file, together with the Existing instructions rows and their actions. List separately every deletion that does not rest on a stated ground, and the lost part of any rewrite that narrows a rule: approving the set does not approve those. A declined deletion, relocation or automation reverts to `retain`. Record each answer in the row's Status.

Done when every row is `approved`, `modified` (the new text shown and confirmed) or `rejected`, and no applicable coverage item rests on an `A` row.

## 7. Write

Read [modules/write.md](modules/write.md) and write each approved row to its destination, from the main session (sub-agents are denied Tier A writes). In the `phase: standards` call, leave Toolchain and lint rows for project-setup and the `phase: lint` call.

Done when every approved row this call owns is in its destination file, and the baseline's Written column names the file and section for each.

## 8. Regenerate and prove

```bash
.agents/skills/project-setup/scripts/generate-boundary-config.sh .
```

It must exit 0. Exit 2: fix the Ownership or Shared core block with the human and re-run. Exit 3: jq or mikefarah yq v4 is missing. Skip this command when project-setup called you (it runs it after the `lint` call).

Then run each touched profile's Toolchain `lint` command once. Findings in existing code mean the config parses: report the count. A config error (unknown rule, bad JSON, unresolved plugin) is a failure: fix the config and re-run.

Done when the generator exited 0 (or was skipped for project-setup) and every touched lint config parsed (in the `phase: lint` call when project-setup called you).

## 9. Stamp and close

Stamp each doc written this run with `<!-- verified_at_commit: <git rev-parse HEAD> -->` at the place [modules/write.md](modules/write.md) gives for its kind. Report: what went in where, what was dropped and why, where each existing instruction landed, the open questions, and that a refresh diffs from the stamp. If a document was imported, tell the human its lines now live in the destinations and the document can be retired; leave it in place yourself.

Done when every doc written this run carries the stamp and the human has the report.

## Reference

- Mandatory coverage list: [assets/coverage.md](assets/coverage.md).
- Destinations and enforcement classes: [assets/enforcement-map.md](assets/enforcement-map.md).
- Managed AGENTS.md block: [assets/agents-block.md](assets/agents-block.md).
- Refresh mode: [modules/refresh.md](modules/refresh.md).
- Ledger actions: `retain` (keep the wording), `rewrite` (same rule, new wording), `relocate` (move to the destination named), `automate` (a check replaces the line; the line stays until the check is live), `delete`. A delete needs one ground: stale or incorrect (evidence named), mechanically enforced (a named check fails the violation), harmful or contradictory, or approved by the human as a line item.
