<!--
Module of retrospective: route each agreed lesson to its one destination.
Sources: first-party routing (PLAN/decision-flow-reference.md 5.7, 00.4, 00.11, "Persistent files"; assetlist D12, D16, D21, D35). Two dispositions per finding (this instance, and what prevents the next one) and "proposed, not applied" action items adapted from bmad-code-org/BMAD-METHOD skills/bmad-retrospective/references/acceptance-verdict.md (MIT, Copyright (c) 2025 BMad Code, LLC). Mechanical lesson -> tool rule, judgement lesson -> checklist line: mattpocock/skills/skills/engineering/retro/SKILL.md@49dd158 "Coding standards" (MIT). Durable bar after EveryInc/compound-engineering-plugin skills/ce-compound/SKILL.md (MIT; idea only).
-->

# Routing lessons

A candidate earns a record only when it holds something the final code, tests and docs do not already tell a reader, and losing it would plausibly let the problem recur. Effort or diff size alone does not qualify it.

| Candidate | Destination | Written by this skill? |
| --- | --- | --- |
| Pitfall: something actually went wrong | `docs/decisions/pitfalls.md`, plus a row in the document's **Pitfalls** | Yes (Tier A, step 5.7) |
| Process lesson: how the workflow ran | The document's **Process lessons** | Yes |
| Mechanical lesson: a fixed pattern a tool can catch | Action item: a tool rule (lint rule, hook, CI check) | No: awaiting human application |
| Judgement lesson: needs a reader | Action item: a profile **Mini-review checklist** line, or a `docs/rules.md` line | No: a 5.3 proposal in a later feature, or applied by a human |
| Feature note: about this feature only | `specs/NNN-slug/design-log.md` | Yes |
| Model observation | `agent-overrides.yaml` or `model-map/<type>.md` (D35, below) | Yes |

Each finding gets two dispositions: what to do about this instance (step 4), and what would prevent the next one (this table, or nothing).

## Pitfalls

Admit only an observed failure: a suspicion or a trap-looking fact is not an entry. Use the entry shape in the comment of `docs/decisions/pitfalls.md`, add it newest first, and skip it if an existing entry already covers the same failure (mark the row "already present").

```markdown
## {Short imperative title that names the permitted alternative}
- What happened: {the observed failure}
- Where: {file or area}
- Spec: specs/NNN-slug
- Prevented by: {the rule or check that now prevents it, or "none yet"}
```

## Feature notes

Append one section to `design-log.md`, newest last, and never edit an earlier entry:

```markdown
## YYYY-MM-DD Retrospective notes

- {note}, see docs/decisions/retrospectives/NNN-slug.md
```

## Model observations (D35)

For each task type and host with an observation backed by evidence (rework rounds, a `profile-wrong` or `blocked` return, a launch denial, review findings traced to one agent's output, the stakeholder's account):

1. Check whether the agent definition pins a model for that host:

   ```bash
   yq --front-matter=extract '.models.<host> // ""' .agents/agents/<type>.md
   ```

2. Route the proposal to exactly one place:
   - **Pinned** (a non-empty value): set the override in `agent-overrides.yaml`, which takes precedence over the definition:

     ```bash
     yq -i '.<type>.<host> = "<alias>"' agent-overrides.yaml
     ```

   - **Not pinned**: in `model-map/<type>.md`, append a dated line under `## Observations`. When the stakeholder agreed an alias change, also set the frontmatter key:

     ```bash
     yq -i --front-matter=process '.<host> = "<alias>"' model-map/<type>.md
     ```

3. Write aliases only, never a dated model ID (D23). Leave `.agents/agents/*.md` unedited: definitions are scaffold-owned and overwritten on reinstall.
4. Record the row in the document's **Model observations** table, with the destination.

An observation with no proposed change still gets its dated line in `model-map/<type>.md` when the definition pins nothing. When the definition pins a model, record it in the document only.

Done when every approved candidate is at its destination, and the document names that destination for each one.
