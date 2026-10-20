---
name: handoff
description: Write a session handoff, one compact file in .workflow/.handoff/ that a fresh session resumes from, or resume from one. Use when the user asks to hand off, pause or end a session, before clearing or compacting a long session, when context is running low mid-task, or when picking up a handoff offered at session start.
argument-hint: "What will the next session focus on?"
---

# Handoff

A **session handoff** is one file a fresh session reads to carry on the work: what the conversation knows that no artifact records yet, plus pointers to everything an artifact does record. It is not a **deferred handoff** (out-of-scope work shelved in `.workflow/deferred/` by feature-workflow).

## Write

### 1. Locate

1. **Root and folder.** Handoffs live in `.workflow/.handoff/` at the main checkout, where the session-start hook looks, even when you work in a worktree. `install.sh` gitignores the folder, so nothing is committed.

   ```bash
   if common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then root=$(dirname "$common"); else root=$PWD; fi
   mkdir -p "$root/.workflow/.handoff"
   ```

2. **Spec or not.** The work belongs to a spec when the session worked in `.workflow/specs/NNN-slug/` (named, resumed, or the one being edited). Then read its live state; you point to it, never copy it:

   ```bash
   yq --front-matter=extract '.status' .workflow/specs/NNN-slug/spec.md; cat .workflow/specs/NNN-slug/.step 2>/dev/null
   ```

3. **File name.** `.workflow/.handoff/NNN-slug.md` for spec work; `.workflow/.handoff/<topic>.md` (kebab-case, two to four words) otherwise. If that file exists it is the previous handoff for this work: read it and replace it.

Done when you hold the file path and, for spec work, the spec's status and step.

### 2. Gather

Write each fact once, in the place that owns it. For each section of the template, take the first that applies:

- **An artifact records it**: point to it by path, commit sha or URL. In a spec: goal and scope (`spec.md`), status and step (`spec.md`, `.step`), decisions (`design-log.md`), tasks (`tasks.md`), shelved work (`.workflow/deferred/`). Outside a spec: commits, branches, issues, PRs, ADRs, docs.
- **Only the conversation knows it**: write it in one line. A decision agreed in the conversation but not yet in `design-log.md` goes under Decisions marked `not logged`, so the next session logs it at its step.
- **Nothing to say**: write `none`.

If the user passed an argument, it names what the next session is for: put what that work needs first and drop what it does not. Redact secrets, tokens, passwords and personal data; name where they live instead (`.env`, a vault entry).

### 3. Write the file

Fill [assets/handoff.md](assets/handoff.md) and delete its comment. The frontmatter `goal`, `spec` and `created` are what the session-start offer shows, so keep `goal` to one line.

Done when a fresh session holding only this file and the repo could take the next action without asking what happened: every section is filled or `none`, every path exists, and no secret is in the file.

### 4. Tell the user

Give the path and one line on resuming: start a fresh session (or clear the context); where the session-start hook is installed it offers the handoff, otherwise ask the agent to resume from `.workflow/.handoff/<name>.md`.

## Resume

When the user picks a handoff (from the session-start offer, or by name):

1. Read the file. Load the skills under **Load first**.
2. If `spec` is set, load the `feature-workflow` skill for that spec. Its live `spec.md` status and `.step` win over `step_at_handoff`; if they differ, the spec moved on after the handoff: say so and trust the spec. Log any `not logged` decision through the module for the current step.
3. Run the **Verify** check to confirm the state before the first change.
4. Take the **Next action**.

The file stays while the work goes on; the next handoff for the same work replaces it. Delete it when its work is done or the user drops it.
