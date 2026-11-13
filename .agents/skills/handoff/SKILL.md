---
name: handoff
description: Write a session handoff, one compact file a fresh session resumes from, or resume from one. Each run writes a new file under its own name in .workflow/.handoff/ of the checkout it works in, a folder whose own .gitignore keeps it out of git. Use when the user asks to hand off, pause or end a session, before clearing or compacting a long session, when context is running low mid-task, or when picking up a handoff offered at session start.
argument-hint: "What will the next session focus on?"
---

# Handoff

A **session handoff** is one file a fresh session reads to carry on the work: what the conversation knows that no artifact records yet, plus pointers to everything an artifact does record. It is not a **deferred handoff** (out-of-scope work shelved in `.workflow/deferred/` by feature-workflow).

## Write

### 1. Locate

1. **Spec or not.** The work belongs to a spec when the session worked in `.workflow/specs/NNN-slug/` (named, resumed, or the one being edited). Then read its live state; you point to it, never copy it:

   ```bash
   yq --front-matter=extract '.status' .workflow/specs/NNN-slug/spec.md; cat .workflow/specs/NNN-slug/.step 2>/dev/null
   ```

2. **Root, folder and file name.** The handoff goes in `.workflow/.handoff/` of the checkout the session works in (a spec worktree, a task worktree or the main checkout), never in another checkout. Set `stem` to the spec folder name (`NNN-slug`) for spec work, or to the topic (kebab-case, two to four words) otherwise, then run:

   ```bash
   root=$(git rev-parse --show-toplevel 2>/dev/null) || root=$PWD
   handoff_dir="$root/.workflow/.handoff"
   mkdir -p "$handoff_dir"
   [ -e "$handoff_dir/.gitignore" ] || printf '*\n' > "$handoff_dir/.gitignore"
   while :; do
     suffix=$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 4)
     file="$handoff_dir/$stem--$(date -u +%Y%m%dT%H%M%SZ)-$suffix.md"
     [ -e "$file" ] || break
   done
   ```

   The folder's own `.gitignore` keeps every handoff out of git, even where the project's `.gitignore` has no entry for it. `file` is a new path no other run uses: `<stem>--<UTC time>-<4 random chars>.md`. Every handoff is a new file; never replace or overwrite another handoff, even one for the same work.

Done when you hold the file path and, for spec work, the spec's status and step.

### 2. Gather

Write each fact once, in the place that owns it. For each section of the template, take the first that applies:

- **An artifact records it**: point to it by path, commit sha or URL. In a spec: goal and scope (`spec.md`), status and step (`spec.md`, `.step`), decisions (`design-log.md`), tasks (`tasks.md`), shelved work (`.workflow/deferred/`). Outside a spec: commits, branches, issues, PRs, ADRs, docs.
- **Only the conversation knows it**: write it in one line. A decision agreed in the conversation but not yet in `design-log.md` goes under Decisions marked `not logged`, so the next session logs it at its step.
- **Nothing to say**: write `none`.

Fill the two drift keys of the frontmatter, so the next session can see what landed on the main branch meanwhile:

- **`main_sha`**: the main branch tip; outside a git repo, leave it `""`. The main branch is the `main_branch` value in the yaml block under `## Workflow settings` in `.workflow/rules.md` of the session's checkout (`$root` from Locate), or `main` when that file, block or key is absent:

  ```bash
  main=$(awk '/^## /{s=($0 ~ /^## Workflow settings[[:space:]]*$/); next} s && /^```ya?ml/{y=1; next} y && /^```/{exit} y' "$root/.workflow/rules.md" 2>/dev/null | yq '.main_branch // ""' 2>/dev/null)
  main=${main:-main}
  git rev-parse "$main"
  ```

- **`affected_paths`**: in a spec, the paths on the `Affected area:` line of `.workflow/specs/NNN-slug/codebase-map.md` (`grep '^Affected area:' .workflow/specs/NNN-slug/codebase-map.md`), module names dropped; with no codebase map, or outside a spec, the paths under **Files touched**. Repo-relative, one list item each.

If the user passed an argument, it names what the next session is for: put what that work needs first and drop what it does not. Redact secrets, tokens, passwords and personal data; name where they live instead (`.env`, a vault entry).

### 3. Write the file

Fill [assets/handoff.md](assets/handoff.md) and delete its comment. The frontmatter `goal`, `spec` and `created` are what the session-start offer shows, so keep `goal` to one line.

Done when a fresh session holding only this file and the repo could take the next action without asking what happened: every section is filled or `none`, every path exists, and no secret is in the file.

### 4. Tell the user

Give the full path of the file (`$file`) and one line on resuming: start a fresh session in the same folder (or clear the context); where the session-start hook is installed it offers the handoff, or give the new session the path and it resumes from that file.

## Resume

When the user picks a handoff from the session-start offer, or the session's first message names a handoff by path, resume from that file; a handoff named by path is resumed without asking. A handoff under an old name (`<NNN-slug | topic>.md`) is resumed the same way.

1. Read the file. Load the skills under **Load first**.
2. If `spec` is set, load the `feature-workflow` skill for that spec. Its live `spec.md` status and `.step` win over `step_at_handoff`; if they differ, the spec moved on after the handoff: say so and trust the spec. Log any `not logged` decision through the module for the current step.
3. **Main drift.** When `main_sha` is set, set `root` to the session's own checkout and `main` as Write step 2 does, then compare:

   ```bash
   root=$(git rev-parse --show-toplevel 2>/dev/null) || root=$PWD
   ```

   If `git rev-parse "$main"` still equals `main_sha`, say "main has not moved" and go on. Otherwise run, with the `affected_paths` as `<paths>` (none listed: leave `-- <paths>` off):

   ```bash
   git log --oneline <main_sha>.."$main" -- <paths>
   git diff --stat <main_sha>.."$main" -- <paths>
   ```

   Before the first action, tell the user what changed in the affected area: each commit and each file, one line each, or "main moved, but not in the affected area" when both print nothing. When `spec` is set and something changed, append a dated entry to `<spec>/design-log.md`, newest last:

   ```markdown
   ## YYYY-MM-DD Main moved since handoff

   - Main: <main_sha short>..<new tip short> (<main branch>)
   - Commit <sha> <subject>
   - File <path> <+n -m>
   ```

   Done when the user has the drift report and, for a spec, the design log holds it.
4. Run the **Verify** check to confirm the state before the first change.
5. Take the **Next action**.

The file stays while you work. Once you have written your own handoff or finished the work, delete the handoff you resumed from; delete it too when the user drops the work. Leave every other handoff alone.
