# Routing lessons

A candidate earns a record only when it holds something the final code, tests and docs do not already tell a reader, and losing it would plausibly let the problem recur. Effort or diff size alone does not qualify it.

| Candidate | Destination | Written by this skill? |
| --- | --- | --- |
| Pitfall: something actually went wrong | `.workflow/decisions/pitfalls.md`, plus a row in the document's **Pitfalls** | Yes (Tier A, step 5.7) |
| Process lesson: how the workflow ran | The document's **Process lessons** | Yes |
| Mechanical lesson: a fixed pattern a tool can catch | Action item: a tool rule (lint rule, hook, CI check) | No: awaiting human application |
| Judgement lesson: needs a reader | Action item: a profile **Mini-review checklist** line, or a `.workflow/rules.md` line | No: a 5.3 proposal in a later feature, or applied by a human |
| Feature note: about this feature only | `.workflow/specs/NNN-slug/design-log.md` | Yes |
| Model observation | `.workflow/agent-overrides.yaml` or `.workflow/model-map/<type>.md` (below) | Yes |

Each finding gets two dispositions: what to do about this instance (step 4), and what would prevent the next one (this table, or nothing).

## Pitfalls

Admit only an observed failure: a suspicion or a trap-looking fact is not an entry. Use the entry shape in the comment of `.workflow/decisions/pitfalls.md`, add it newest first, and skip it if an existing entry already covers the same failure (mark the row "already present").

```markdown
## {Short imperative title that names the permitted alternative}
- What happened: {the observed failure}
- Where: {file or area}
- Spec: .workflow/specs/NNN-slug
- Prevented by: {the rule or check that now prevents it, or "none yet"}
```

## Feature notes

Append one section to `design-log.md`, newest last, and never edit an earlier entry:

```markdown
## YYYY-MM-DD Retrospective notes

- {note}, see .workflow/decisions/retrospectives/NNN-slug.md
```

## Model observations

For each task type and host with an observation backed by evidence (rework rounds, a `profile-wrong` or `blocked` return, a launch denial, review findings traced to one agent's output, the stakeholder's account):

1. Check whether the agent definition pins a model for that host:

   ```bash
   yq --front-matter=extract '.models.<host> // ""' .agents/agents/<type>.md
   ```

2. Route the proposal to exactly one place:
   - **Pinned** (a non-empty value): set the override in `.workflow/agent-overrides.yaml`, which takes precedence over the definition:

     ```bash
     yq -i '.<type>.<host> = "<alias>"' .workflow/agent-overrides.yaml
     ```

   - **Not pinned**: in `.workflow/model-map/<type>.md`, append a dated line under `## Observations`. When the stakeholder agreed an alias change, also set the frontmatter key:

     ```bash
     yq -i --front-matter=process '.<host> = "<alias>"' .workflow/model-map/<type>.md
     ```

3. Write aliases only, never a dated model ID. Leave `.agents/agents/*.md` unedited: definitions are scaffold-owned and overwritten on reinstall.
4. Record the row in the document's **Model observations** table, with the destination.

An observation with no proposed change still gets its dated line in `.workflow/model-map/<type>.md` when the definition pins nothing. When the definition pins a model, record it in the document only.

Done when every approved candidate is at its destination, and the document names that destination for each one.
