---
name: project-standards
description: "Draft, approve and write a project's standards: a staged baseline (stack, core decisions, naming, structure, boundaries, format and communication, process patterns, deferred) split into docs/rules.md, work profiles, ADRs, docs/pr-quality checks, per-profile lint config and a managed AGENTS.md block, every line carrying its destination and enforcement. Use when project-setup hands over after installing toolchains, when adopting standards in an existing codebase, when importing an architecture or standards document, when refreshing standards after code changed, or when adding a work type."
---

<!--
Sources: first-party; plan PLAN/decision-flow-reference.md "Persistent artifacts" 00.3, 00.4, 00.16-00.17, "Work profiles", "Tier A is agent-proposed, human-approved"; assetlist D15, D16, D20, D21, D26, D35, D51, D75, D80.
Adapted (patterns and structure, no text copied): bmad-code-org/BMAD-METHOD/skills/bmad-project-context/SKILL.md@8f0d50e (MIT): assess, ask what the user brings, discover, interview the gaps in batches of at most eight, the ledger (retain | rewrite | relocate | automate | delete) and its deletion grounds, "prefer a check over a line", one approval of the whole set, the managed block between markers, the commit-stamped provenance line and refresh-by-commit. bmad-code-org/BMAD-METHOD/skills/bmad-project-context/references/{template,best-practices}.md@8f0d50e (MIT): block sections, admit and exclude rules. bmad-code-org/BMAD-METHOD/skills/bmad-architecture/SKILL.md@8f0d50e and assets/spine-template.md@8f0d50e (MIT): coaching path by default with a fast path, the "two builders could diverge" test, recommend a verified current starter for greenfield, ratify brownfield conventions, a named paradigm, an explicit Deferred list. bmad-code-org/BMAD-METHOD/src/bmm-skills/3-solutioning/bmad-create-architecture/steps/{step-05-patterns,step-06-structure}.md@560a2e3a (MIT): conflict-point categories (naming, structure, format, communication, process) and integration boundaries.
-->

# Project standards

Turn what the project brings (policy, an imported document, the code itself) into enforced standards. The baseline in `.standards-staging/baseline.md` is a **staging draft, never a source of truth**: each line is routed to its home (`docs/rules.md`, `profiles/<work-type>.md`, an ADR, a `docs/pr-quality/` check, lint config, the AGENTS.md block) and to the cheapest mechanism that holds it. Done when every approved line is written to its destination, the boundary config regenerates, the lint config parses, and each written doc carries a `verified_at_commit` stamp.

## Modes

| Mode | When | Steps |
| --- | --- | --- |
| greenfield | No tracked source code yet | 0-2, 3 (starter research), 4-9 |
| brownfield | Code exists; no `verified_at_commit` stamp in `docs/rules.md` or `profiles/` | 0-9 |
| refresh | Stamps exist | [modules/refresh.md](modules/refresh.md), then 5-9 for what changed |
| add-work-type | Stamps exist and a new kind of work appears | 0-9, scoped to the new work type's paths and profile |

## When called from project-setup

project-setup calls this skill after it has created the shared files from templates, written each `profiles/<work-type>.md` with only its Toolchain block filled, and installed the toolchains, and before it generates the boundary config. It passes the agreed work types and the mode (greenfield, brownfield, or add-work-type with the one new work type). Then:

- The work-type list and each profile's Toolchain commands are settled; change them only through a ledger row the human approves. You fill all of `docs/rules.md` (Ownership, Shared core and the prose sections) and the other four profile sections. project-setup has not drafted any of them. A profile that still opens with an "Example: adapt before use" banner came from a D26 example: treat its lines as candidates, confirm or change each against the project through the ledger, then delete the banner.
- Run steps 0-9, but skip the `generate-boundary-config.sh` run in step 8: project-setup's next step runs it. The lint parse proof in step 8 still runs here.
- Return to project-setup: the files written, the lint result per profile, and the open items (unanswered questions, declined automations, `TODO` commands).

Standalone, run every step.

## 0. Gate on in-flight work

List the specs whose status is not `done`:

```bash
for s in specs/*/spec.md; do [ -f "$s" ] || continue; st=$(yq --front-matter=extract '.status // ""' "$s"); [ "$st" = done ] || echo "$s $st"; done
```

- **None**: Tier A writes are allowed from the main session without a step (D51). Continue.
- **One or more**: run steps 1-6 as normal, but at step 7 write each approved line as a `proposed` row in the in-flight spec's `specs/NNN-slug/proposals.md` instead (ask which spec when several are in flight). Copy `.agents/skills/feature-workflow/assets/proposals.md` there when the file is absent, and continue its `P<n>` numbering. Use its groups: Rules, Decisions, Profiles, and Tool rules for lint config. Set Origin to `project-standards <date>`. That spec's sign-off applies them at 5.3. Keep the `docs/pr-quality/` and AGENTS.md block lines in `.standards-staging/baseline.md`, and write them in a later run once no spec is in flight.

Done when the in-flight list is known and the write route (direct or proposals) is fixed.

## 1. Assess

Read the Tier A docs that exist (`docs/rules.md`, `profiles/*.md`, `docs/decisions/adr/`, `GLOSSARY.md`), the instruction files (`AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING*`, `CODING_STANDARDS*`, editor rule files, PR templates), the lint, format and typecheck configs, and the manifests. Detect the mode from the table above. Create the staging folder:

```bash
mkdir -p .standards-staging && printf '*\n' > .standards-staging/.gitignore
```

Copy [assets/baseline.md](assets/baseline.md) to `.standards-staging/baseline.md` when it is absent. In brownfield and refresh, open one **Existing instructions** row per independently meaningful instruction in those files, starting at `retain` or `rewrite`.

Done when the human has seen what exists, what is missing, and the mode, and has confirmed the mode.

## 2. Ask what they bring

Ask once for what no scan reaches: policy (governance, security, compliance), frozen or generated areas, external standards or style guides, and any existing document to import (an architecture doc, a standards page). Note the paths. An imported document is testimony: split it line by line into baseline rows in step 5; it never becomes a standard as a whole.

Done when the human has answered or said there is nothing.

## 3. Discover

Read [modules/discovery.md](modules/discovery.md). Brownfield and add-work-type: launch one `standards-discovery` agent per scope. Greenfield: recommend a starter and verify current versions on the web.

Done when every scope's return is saved under `.standards-staging/`, or, in greenfield, the starter and every pinned version carry a cited URL.

## 4. Interview the gaps

Read [modules/interview.md](modules/interview.md). Coaching path by default; fast path on request.

Done when every conflict-point category is decided, deferred with a reason, or an open question the human chose to leave.

## 5. Draft the baseline

Fill `.standards-staging/baseline.md`. Every line gets a destination and an enforcement class from [assets/enforcement-map.md](assets/enforcement-map.md), and the evidence it rests on (a discovery citation, the human's answer, an imported line, a URL). Prefer a tool over judgement and judgement over prose. A line that is not a standard (a directory tree, a stack list a manifest already states, aspirational state) goes to `drop` with its reason.

Done when no row has an empty Destination, Enforcement or Evidence cell, and every Existing instructions row has a settled action.

## 6. Approve once

Show the human the ledger: every row, as line → destination → enforcement, grouped by destination file, together with the Existing instructions rows and their actions. List separately every deletion that does not rest on a stated ground, and the lost part of any rewrite that narrows a rule: approving the set does not approve those. A declined deletion, relocation or automation reverts to `retain`. Record each answer in the row's Status.

Done when every row is `approved`, `modified` (the new text shown and confirmed) or `rejected`.

## 7. Write

Read [modules/write.md](modules/write.md) and write each approved row to its destination, from the main session (sub-agents are denied Tier A writes, D16).

Done when every approved row is in its destination file, and the baseline's Written column names the file and section for each.

## 8. Regenerate and prove

```bash
.agents/skills/project-setup/scripts/generate-boundary-config.sh .
```

It must exit 0. Exit 2: fix the Ownership or Shared core block with the human and re-run. Exit 3: jq or mikefarah yq v4 is missing. Skip this command when project-setup called you.

Then run each touched profile's Toolchain `lint` command once. Findings in existing code mean the config parses: report the count. A config error (unknown rule, bad JSON, unresolved plugin) is a failure: fix the config and re-run.

Done when the generator exited 0 (or was skipped for project-setup) and every touched lint config parsed.

## 9. Stamp and close

Stamp each doc written this run with `<!-- verified_at_commit: <git rev-parse HEAD> -->` at the place [modules/write.md](modules/write.md) gives for its kind. Report: what went in where, what was dropped and why, where each existing instruction landed, the open questions, and that a refresh diffs from the stamp. If a document was imported, tell the human its lines now live in the destinations and the document can be retired; leave it in place yourself.

Done when every doc written this run carries the stamp and the human has the report.

## Reference

- Destinations and enforcement classes: [assets/enforcement-map.md](assets/enforcement-map.md).
- Managed AGENTS.md block: [assets/agents-block.md](assets/agents-block.md).
- Refresh mode: [modules/refresh.md](modules/refresh.md).
- Ledger actions: `retain` (keep the wording), `rewrite` (same rule, new wording), `relocate` (move to the destination named), `automate` (a check replaces the line; the line stays until the check is live), `delete`. A delete needs one ground: stale or incorrect (evidence named), mechanically enforced (a named check fails the violation), harmful or contradictory, or approved by the human as a line item.
