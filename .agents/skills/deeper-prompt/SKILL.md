---
name: deeper-prompt
description: Rewrite a feature request into a deeper prompt the stakeholder agrees to (the ask one level up, its goals, downstream work, suggested tools and gotchas) before the questioning loop. Use at feature-workflow step 0.3.22, or when asked for a deeper version of a task.
---

<!--
Sources: first-party. The steps (elevate the ask, define its goals, ask about downstream effects and suggested tools or gotchas, restate, revise until agreed) are the user's own prompt, adapted. Plan: PLAN/decision-flow-reference.md 0.3.22, "The questioning loop"; assetlist D73. Hands off to feature-workflow modules/questioning-loop.md, never to a grilling skill (the vendored ones were deleted, D78).
-->

# Deeper prompt

Make the request **deeper, not bigger**: sharpen its intent, goals and constraints while keeping its scope exactly as asked. The output is one agreed prompt block, and it becomes the input to the questioning loop. A feature or extra the stakeholder did not ask for goes under **Not asked for**, never into **Ask**.

## Inputs

- **Inside the workflow** (step 0.3.22, `specs/NNN-slug/` in flight): the request, the draft **Why** in `spec.md` (0.1.6), and `codebase-map.md` (what exists, what the change touches). Set the step first:

  ```bash
  .agents/skills/feature-workflow/scripts/status-transition.sh step specs/NNN-slug 0.3.22
  ```

  If `design-log.md` already holds a **Deeper prompt** entry the stakeholder agreed to, the step is done: go to [Hand off](#4-hand-off).
- **Standalone**: the request in the conversation. Nothing is written to disk; the agreed block is the result.

## 1. Draft the elevation and the goals

Your own work, done before asking anything.

1. **Elevate the ask.** Name the problem behind the request, one level of abstraction up: "add a CSV export button" becomes "let users take their report data into their own tools". Keep the stakeholder's terms; use `GLOSSARY.md` names where they exist.
2. **Define the goals.** List the outcomes that would make the ask a success, each one observable in the result ("a user can open the export in a spreadsheet without fixing columns"). Two to five goals; each traces back to something the request said or clearly implied.

Done when you have one elevated statement and a goal list, each goal traceable to the request.

## 2. Ask about downstream effects, tools and gotchas

One message, these questions numbered, then wait for the answers:

1. **Downstream:** Will other features be built on this one? Ask for their shape one level up (what will sit on this), so the architecture leaves room for them. Take the general sense and stop there; details of future work belong to that future work.
2. **Tools and technologies:** Any tools, libraries or technologies you want used, or avoided, for this?
3. **Gotchas:** Anything you already know will bite: constraints, past failures, systems that behave unexpectedly?

"None" or "no idea" is a complete answer. Record it and move on.

## 3. Restate and revise

Restate the whole ask back as the block below, with your elevation and goals from step 1 presented as proposals, and ask: "Is this ready to pass on, or what should change?"

```markdown
**Ask:** <the request, restated at the elevated level, one or two sentences>

**Goals:**
- <observable outcome>

**Downstream:** <what later work will build on this, at a high level, or "none known">

**Tools and technologies:** <preferred or ruled-out tools, or "no preference">

**Gotchas:** <known constraints and traps, or "none known">

**Not asked for:** <anything the elevation suggested that stays out of scope, or "nothing">

**Original request:** "<the stakeholder's words, verbatim>"
```

- **Changes:** apply them to the block, restate the whole block again, and ask again.
- **Agreement:** an explicit yes ("yes", "ready", "pass it on"). "Whatever you think" is not agreement: restate and ask for the yes.

Loop until agreement. Done when the stakeholder has explicitly agreed to the block as last shown.

## 4. Hand off

- **Inside the workflow:** append the agreed block to `specs/NNN-slug/design-log.md` as a **Deeper prompt** entry (create the log from `.agents/skills/feature-workflow/assets/design-log.md` if missing), with each revision round summarised in one line. Then return to discovery, which loads the questioning loop at 0.3.8; the loop frames its design tree from this block.
- **Standalone:** return the agreed block. When the next step is the feature workflow, it starts there with this block as the request.

## Done

- The block was restated in full and the stakeholder explicitly agreed to it.
- Every goal traces to the request; every addition the request did not ask for sits under **Not asked for**.
- Inside the workflow, the agreed block is in `design-log.md` as a **Deeper prompt** entry.
