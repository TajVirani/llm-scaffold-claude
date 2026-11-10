# Routing lessons

A candidate earns a record only when it holds something the final code, tests and docs do not already tell a reader, and losing it would plausibly let the problem recur. Effort or diff size alone does not qualify it.

| Candidate | Destination | Written by this skill? |
| --- | --- | --- |
| Pitfall: something actually went wrong | `.workflow/decisions/pitfalls.md`, plus a row in the document's **Pitfalls** | Yes (Tier A, step 5.7) |
| Process lesson: how the workflow ran | The document's **Process lessons** | Yes |
| Mechanical lesson: a fixed pattern a tool can catch | Action item: a tool rule (lint rule, hook, CI check) | No: awaiting human application |
| Review lesson: a symptom a reader can see in a diff, with the paths where it can recur | `.workflow/review-lessons.md` (below), plus the file and id under the document's **Recorded in** | Yes (Tier A, step 5.7) |
| Judgement lesson: needs a reader, but no diff shows its symptom | Action item: a profile **Mini-review checklist** line, or a `.workflow/rules.md` line | No: a 5.3 proposal in a later feature, or applied by a human |
| Feature note: about this feature only | `.workflow/specs/NNN-slug/design-log.md` | Yes |
| Model observation | The task type's row in `.workflow/model-map.yaml` (below) | Yes |

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

## Review lessons

A review lesson tells the Phase 4 review what to look for: its symptom shows in changed lines, and it names the paths where the mistake can recur. A lesson about how the workflow ran is a process lesson, and one whose symptom no diff shows is a judgement lesson: both go where the table sends them. A lesson a rule, a lint or a profile checklist line already enforces is not a review lesson.

Only the retrospective of a feature in flight writes the file. With no feature in flight, `workflow-write-guard` denies the write, so a standalone run turns an approved review lesson into an action item.

The template is `.agents/skills/feature-workflow/assets/review-lessons.md`. Its header comment holds the entry rules and two commands, `validate:` and `next-id:`. Run either one on the lessons file like this:

```bash
template=.agents/skills/feature-workflow/assets/review-lessons.md
cmd=$(sed -n 's/^validate: //p' "$template")    # or 's/^next-id: //p'
bash -c "$cmd" _ .workflow/review-lessons.md
```

### Recording a lesson

With the step already at 5.7, for each approved review lesson:

1. If `.workflow/review-lessons.md` is missing, copy the template to it unchanged with Write.
2. Read the file. If an entry, retired or not, already describes the same symptom, skip the candidate and mark it "already present" with that entry's id.
3. Run `next-id:` for the new entry's id.
4. Append one entry at the end of the `lessons` list with Edit, never Bash. While the list is still `lessons: []`, replace that line with `lessons:` followed by the entry. Double-quote `symptom`:

   ```yaml
     - id: RL-003
       symptom: "{what went wrong, in one or two plain sentences a reviewer can match against a diff}"
       paths: ["{glob relative to the repo root, e.g. src/**}"]
       origin_spec: .workflow/specs/NNN-slug
       date: YYYY-MM-DD
   ```

5. Run `validate:`. If it fails, stop and report its error with the entry you wrote; make no further write until the file passes.
6. Name the file and the id under **Recorded in**: `.workflow/review-lessons.md RL-003`.

### Retiring a lesson

A lesson retires once a rule, a lint or a profile line enforces it. The candidates are this feature's approved 5.3 proposals that enforce a recorded lesson, and any lesson the stakeholder names. Present each with its id and the enforcing line, for the same per-entry approval as the other candidates. For each approved one:

1. Edit the entry to add two fields under it, leaving the rest unchanged:

   ```yaml
       retired: YYYY-MM-DD
       enforced_by: "{the rule, lint or profile line that now catches it}"
   ```

2. Run `validate:`, and stop with its error when it fails.
3. Record it in the document's **Process lessons**: kind `review lesson`, recorded in `.workflow/review-lessons.md RL-003 (retired)`.

Never delete an entry and never reuse an id: a retired entry stays in the list and keeps its id taken.

## Feature notes

Append one section to `design-log.md`, newest last, and never edit an earlier entry:

```markdown
## YYYY-MM-DD Retrospective notes

- {note}, see .workflow/decisions/retrospectives/NNN-slug.md
```

## Model observations

For each task type and host with an observation backed by evidence (rework rounds, a `profile-wrong` or `blocked` return, a launch denial, review findings traced to one agent's output, the stakeholder's account):

1. Append one dated line to that task type's `observations` list in `.workflow/model-map.yaml`, in the form its header comment gives:

   ```bash
   yq -i '.<type>.observations += ["<YYYY-MM-DD> (<host> <alias>, spec <NNN-slug>): <what happened>. <the alias change, or No alias change.>"]' .workflow/model-map.yaml
   ```

2. When the stakeholder agreed an alias change, also set that row's host key:

   ```bash
   yq -i '.<type>.<host> = "<alias>"' .workflow/model-map.yaml
   ```

3. Write aliases only, never a dated model ID. Leave `.agents/agents/*.md` unedited: definitions are scaffold-owned and overwritten on reinstall.
4. Record the row in the document's **Model observations** table.

An observation with no proposed change still gets its dated line.

Done when every approved candidate is at its destination, the document names that destination for each one, and `.workflow/review-lessons.md`, when this run wrote it, passes `validate:`.
