---
name: retrospective
description: "Feature retrospective with the stakeholder: judges the combined result against spec.md, records process lessons and pitfalls, feature notes and model observations, and writes docs/decisions/retrospectives/NNN-slug.md. Use at sign-off (5.7), or when a stakeholder asks for a retrospective on a shipped feature."
---

<!--
Sources: adapted from bmad-code-org/BMAD-METHOD skills/bmad-retrospective/workflow.md and references/{evidence-gathering,acceptance-verdict,team-discussion,retro-document}.md (MIT, Copyright (c) 2025 BMad Code, LLC; prose and structure only, no templating). Changes: one feature spec instead of an epic and its tickets; run with the stakeholder present, so its Tier A writes are approved as agreed; writes pitfalls.md, a design-log.md section and model observations (D35) as well as the document; no team-discussion phase and no headless mode. Mechanical lesson -> tool rule, judgement lesson -> checklist line: mattpocock/skills/skills/engineering/retro/SKILL.md@49dd158 "Coding standards" (MIT). Durable bar for lessons (record only what the final code, tests and docs do not already tell a reader) after EveryInc/compound-engineering-plugin skills/ce-compound/SKILL.md (MIT; idea only). Plan: PLAN/decision-flow-reference.md 5.7, "Persistent files", "Tier A is agent-proposed, human-approved", 00.4, 00.11; assetlist D12, D16, D21, D22, D25, D35, D41, D47.
-->

# Retrospective

Judge a finished feature against its spec with the stakeholder, and turn what the feature taught into records the next feature reads. Every finding and lesson carries a source reference (file:line, commit, test output, a `report.md` section). A claim you cannot point at is not a finding: drop it.

## Inputs

- **Spec folder** `specs/NNN-slug/`. From `sign-off` at 5.7, the spec is `in-review`. Standalone, ask which spec, offering those with `status: done`.
- **Output** `docs/decisions/retrospectives/NNN-slug.md`, with the same `NNN-slug` as the spec folder, from [assets/retrospective.md](assets/retrospective.md).

## Writes and the step marker

The retrospective writes these files, each with the stakeholder's agreement:

| File | Tier | What |
| --- | --- | --- |
| `docs/decisions/retrospectives/NNN-slug.md` | A | The document |
| `docs/decisions/pitfalls.md` | A | Observed failures only |
| `specs/NNN-slug/design-log.md` | — | One appended "Retrospective notes" section |
| `model-map/<type>.md` or `agent-overrides.yaml` | — | Model observations (D35) |

At 5.7, set the step before the first Tier A write, so `tier-a-write-guard` allows it:

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh step specs/NNN-slug 5.7
```

Standalone with no spec in flight, the guard allows Tier A writes without a step. If another spec is in flight, the guard denies them: stop and report the denial with the agreed text, so the human can apply it once that spec is done.

Write Tier A files with Write or Edit, never through Bash. The retrospective does not change `status`: `sign-off` sets `done` after it returns (D47). It never edits `rules.md`, profiles, skills or `.agents/agents/*.md`: those changes become action items.

## Steps

### 1. Open or resume the document

If `docs/decisions/retrospectives/NNN-slug.md` exists, read it, check what it records against the current evidence (the evidence wins), and resume at the first incomplete step. Otherwise, set the step (at 5.7), then copy the template with `spec`, `date` and the title filled in. Write each step's result into the document as you finish it: the document is the working state.

Done when the document exists and you know which step to start from.

### 2. Gather the evidence

Read [modules/evidence.md](modules/evidence.md) and fill **Summary**. Then ask the stakeholder for their going-in concerns ("anything you want weighed: a task that felt rushed, a review finding that worried you?"). A concern directs the analysis, but it becomes a finding only once you can tie it to a source.

Done when Summary lists every evidence source as available or missing.

### 3. Judge the result against the spec

Judge the combined result of all tasks against `spec.md`, not task by task. Give one row per Capability (`CAP-###`), constraint and success signal in `spec.md`, and per journey and target in `verification-plan.md`. Mark each met, partly or no, with its evidence. List anything built that the spec did not ask for. Fill **Behavior verification** from `report.md` and `artifacts/`, and when runtime behavior was not exercised, say so.

Done when every spec item has a row with evidence.

### 4. Findings and follow-through

- **Findings.** Take the open findings from the triage entries in `design-log.md`, the known gaps in `report.md` (D29) and anything step 3 surfaced. Re-check each one against its source; drop any whose source does not hold up. Give each a disposition: `fix now` (it becomes an action item), `defer` (link the `deferred/` file), or `accept` (with the reason).
- **Previous retrospective.** Open the highest-numbered other file in `docs/decisions/retrospectives/`. For each of its action items, record whether it landed, with the commit, file or check that shows it. An item you cannot point at is "no evidence found", which is not the same as "not done". With no earlier file, write "No earlier retrospective."

Done when every finding has a disposition, and every earlier action item has a line.

### 5. Agree the lessons with the stakeholder

Read [modules/routing.md](modules/routing.md). Present the candidate process lessons, pitfalls, feature notes and model observations together, each with its source and proposed destination. The stakeholder approves, changes or rejects each one. Write only the approved ones, each to its destination, and record where each went in the document.

Done when every candidate is written, turned into an action item, or recorded as rejected.

### 6. Verdict and action items

Compile **Action items**: fix-now findings, and approved lessons whose destination this skill cannot write (rules, profiles, skills, tool rules). Give each one an owner, and mark it "awaiting human application".

Then render the machine verdict:

- `accepted`: the spec items are met, no blocking finding is open, and every task in `tasks.md` is `done` or `split-out` (D68).
- `accepted-with-open-items`: the spec items are met, but named findings or known gaps remain and are deferred or tracked.
- `rejected`: a spec item is not met, a blocking finding is unresolved, or a task is neither `done` nor `split-out`. A `split-out` task never counts as unfinished.

The stakeholder's decision overrides the machine verdict; record both when they differ. A spec that fails its items with no stakeholder decision is recorded as not accepted, never as accepted by default. Write the verdict to the frontmatter and to **Acceptance verdict**, keeping the two in sync.

Done when the frontmatter `verdict` matches the section, and every action item has an owner.

### 7. Finish

Fill **Open questions** ("None." if empty), replace any placeholder left in the document, and delete the template comment. Return to the caller with the document path and the verdict. At 5.7 that caller is `sign-off`, which sets `done` and moves on to 5.8.

## Done

- `docs/decisions/retrospectives/NNN-slug.md` exists, every section is filled or says "None.", and it holds no placeholder.
- Every approved pitfall is in `pitfalls.md`, every feature note is in `design-log.md`, and every model observation is in the one destination D35 names.
- Every Tier A write happened with the 5.7 step set, or outside any in-flight feature.
