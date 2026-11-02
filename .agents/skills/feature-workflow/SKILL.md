---
name: feature-workflow
description: Workflow 2.0 entry point for feature work. Sizes a request (trivial edit, small path, light path or full path), runs discovery, resumes an in-flight spec at the phase its status names, and plans a subject too large for one spec as an initiative (large path). Use when starting a feature, resuming or changing work in .workflow/specs/NNN-slug/ or .workflow/initiatives/NNN-slug/, acting on a session-start resume offer, or when asked to grill me / stress-test my plan.
---

# Feature workflow

The router for Workflow 2.0. It sizes each request and picks the step file to load. Use the smallest amount of process that safely fits the change (design rule 1). Step logic lives in `modules/`; load only the step file the route names, read it fully, and follow it. With the first step file of a session, also load [references/conventions.md](references/conventions.md): the rules every step file follows. A step that launches a sub-agent points to [references/launching.md](references/launching.md); read it at that step.

## 1. Find the state

Resolve which feature this request is about before doing anything else. Take the first branch that applies.

1. **The request names an initiative**: a `.workflow/initiatives/NNN-slug/` folder, its `initiative.md`, or an initiative the stakeholder clearly means; or the stakeholder picks an initiative from the resume offer. Load [large-path](modules/large-path.md) at 6.1, which switches to its branch and resumes it by status.
2. **The request names a spec**: a `.workflow/specs/NNN-slug/` folder, its `spec.md`, or a feature the stakeholder clearly means. A finished spec may sit in the Done folder instead, `.workflow/specs/done/NNN-slug/`. Go to [Route by status](#3-route-by-status).
3. **A session-start resume offer is in context** (from `hooks/session-start-resume.sh`) and the stakeholder picks a spec from it. Go to [Route by status](#3-route-by-status). If they pick a handoff from the offer instead, load the `handoff` skill and follow its Resume section.
4. **No hook offered one** (Codex, or a session without the hook): list in-flight specs, and initiatives with their branches, yourself, leaving out the Done folder (finished specs only). A spec past 1.1 (0.3.20 on the light path) lives in its spec worktree, so list those too. Read the list in the main checkout, where the spec worktrees sit, even from a spec worktree.

   ```bash
   ( cd "$(git worktree list --porcelain | sed -n '1s/^worktree //p')" && for f in .workflow/specs/*/spec.md .workflow/.spec-worktrees/*/.workflow/specs/*/spec.md .workflow/initiatives/*/initiative.md; do [ -f "$f" ] && printf '%s\t%s\n' "$f" "$(yq --front-matter=extract '.status' "$f")"; done )
   git for-each-ref --format='%(refname:short)' refs/heads/initiative refs/remotes/origin/initiative   # initiatives in exploration
   ```

   If any status is not `done` and the request could belong to one, show the list and ask whether to resume one of them or start new work.
5. **Otherwise** this is new work. Go to [Size the request](#2-size-the-request).

**"Grill me" / "stress-test my plan".** Treat it as a request to run the questioning loop (0.3.8 on) for the current spec. Resolve the spec by branches 2-4 and route by status; if none is in flight, start at discovery. The questioning loop owns it; there is no separate grill skill.

**Work-backlog items.** `.workflow/specs/work-backlog/` holds discovered work that a stakeholder chose to keep for later: one list per spec, `<NNN-slug>.md`, one line per item, plus older one-file-per-item entries (`<NNN-slug>-disc-<###>.md`). It is not a spec: never route it by status. When you list in-flight specs, or the request starts new work, also list the open items:

```bash
grep -H '^- \[open\]' .workflow/specs/work-backlog/*.md 2>/dev/null
for f in .workflow/specs/work-backlog/*-disc-*.md; do [ -f "$f" ] && [ "$(yq --front-matter=extract '.status' "$f")" = open ] && printf '%s\t%s\n' "$f" "$(yq --front-matter=extract '.origin_spec' "$f")"; done
```

When the stakeholder picks one, it is new work seeded from the item: size it, and discovery seeds 0.1 from it and marks it `promoted` at 0.1.4 ([discovery](modules/discovery.md#seeded-from-a-work-item)).

Done when you hold one `.workflow/specs/NNN-slug/` to resume, an initiative handed to the large path, or a new request to size.

## 2. Size the request

**0.0.1: trivial edit the stakeholder will review themselves?** A typo, a copy change, a one-line config tweak the stakeholder will read in the diff. Ask in one line when unsure, recommending your answer. If a bug could escape into production, it is not trivial.

- **Yes, 0.0.2:** make the edit directly. No spec folder, no workflow, no status. Stop here.
- **No:** go to 0.0.3.

**0.0.3: small path?** Yes when the request already names all three: the file to change, the cause (what goes wrong and why, or what is missing), and the test that will prove the fix. A work-backlog item usually does, in its Problem, Evidence and Suggested scope. It must also look like a light-path change: one owning module, nothing irreversible. Ask in one line when unsure, recommending your answer.

- **Yes:** load [modules/discovery.md](modules/discovery.md) and start at 0.1; discovery writes `small_path: true` at 0.1.4.
- **No:** load [modules/discovery.md](modules/discovery.md) and start at 0.1.

The small path runs the light path with less ceremony, through the same step files: each step it changes carries an "On the small path:" note in its step file. A note applies while `small_path` is `true` in `spec.md` and `design-log.md` has no `Left the small path` line.

Light versus full path is decided at 0.3.20, once the questioning loop has settled the design, never at intake. Only the small path is picked at intake, and it drops to the light or full path as soon as the request proves bigger ([Leave the small path](modules/questioning-loop.md#leave-the-small-path)). The large path is not picked at intake either: the questioning loop converts the spec into an initiative when it finds several features (0.3.23).

## 3. Route by status

Read the spec's frontmatter and step marker, then load the step file the table names.

**Work in the spec checkout.** From 1.1 (0.3.20 on the light path) a spec runs in its spec worktree, `.workflow/.spec-worktrees/NNN-slug` inside the main checkout, on its spec branch; its `.step`, `artifacts/` and agent worktrees live there. A spec started before spec worktrees existed runs in the main checkout on its spec branch. When the session is elsewhere, move it in before reading anything: on Claude Code, call the `EnterWorktree` tool with the worktree's absolute path; on other hosts, ask the stakeholder to reopen the session in that folder (write a handoff first if the session holds context worth keeping). Every step file's commands then run from there.

```bash
yq --front-matter=extract '.status, .light_path, .small_path // false, .blocked_condition // "", .impl_base_revision' .workflow/specs/NNN-slug/spec.md
cat .workflow/specs/NNN-slug/.step 2>/dev/null   # step, updated_at, blocked_from (gitignored; in the spec checkout only)
```

| Status | `.step` / condition | Load | Resume at |
| --- | --- | --- | --- |
| `draft` | step in 0.3.8–0.3.19, or a loop-back step (0.6, 2.2, 2.3, 4.5, 4.6, 5.6, 00.24, 00.29) | [questioning-loop](modules/questioning-loop.md) | 0.3.8 (recompute the frontier from `design-log.md`) |
| `draft` | step 0.3.20, or in 0.4.x or 0.5.x | [discovery-impact](modules/discovery-impact.md) | the step in `.step` |
| `draft` | any other step, or no marker | [discovery](modules/discovery.md) | the step in `.step`; 0.1.6 when there is none |
| `ready-for-dev` | `light_path: true` | [implementation-setup](modules/implementation-setup.md) | 3.1 |
| `ready-for-dev` | step in 2.x | task-breakdown | the step in `.step` |
| `ready-for-dev` | step 00.28 (resumed after discovered work) | task-breakdown if `tasks.md` exists, else verification-setup | task-breakdown 2.6; verification-setup at its first unfinished 1.x step |
| `ready-for-dev` | otherwise | verification-setup | the 1.x step in `.step`, else 1.1 |
| `in-progress` | `impl_base_revision` is `""` | [implementation-setup](modules/implementation-setup.md) | 3.1 |
| `in-progress` | otherwise | [implementation-waves](modules/implementation-waves.md) | its On resume (task records in `tasks.md` say what is done) |
| `in-review` | any task record `in-progress` (a rework under way), whatever the step | [implementation-waves](modules/implementation-waves.md) | its Rework entry (4.7): relaunch the reopened tasks, then back to review-triage |
| `in-review` | step in 5.x | sign-off | the step in `.step` (order 5.1–5.5, then 5.9, 5.7, 5.8) |
| `in-review` | otherwise | review-triage | the 4.x step in `.step`, else 4.1 (4.10 on the light path) |
| `blocked` | `blocked_condition` starts `discovered work:` or `size budget:` | [discovered-work](modules/discovered-work.md) | its "Resuming a blocked spec here" section (00.22 or 00.28) |
| `blocked` | any other condition | none until a human resolves it | see [Blocked](#blocked) |
| `done` | any | none | Read it as context only, from `.workflow/specs/done/NNN-slug/` once 5.8 has moved it (specs finished before the Done folder existed may still sit at the top level). A new change to a finished feature is new work: size it. |

The rework row checks the task records, not `.step`, which Phase 3's `set-task --step` calls and 3.15 move off 4.7 as a reopened task passes its gates. It applies when `yq --front-matter=extract '[.tasks[] | select(.status == "in-progress")] | length' .workflow/specs/NNN-slug/tasks.md` is above 0; with none `in-progress`, the 5.x and review-triage rows apply.

Tell the stakeholder where you are resuming, led by the [progress line](references/conventions.md#progress-line). A resumed step file re-reads its inputs from disk (spec folder, `design-log.md`, `tasks.md`); never rebuild state from memory.

### Blocked

`blocked` is a routing signal: work stops until a human acts.

A `discovered work:` or `size budget:` condition belongs to [discovered-work](modules/discovered-work.md), which resumes the 00.21–00.29 protocol. For any other condition:

1. Show `blocked_condition` from `spec.md` and `blocked_from` from `.step`, and ask the stakeholder to resolve the condition.
2. Once they confirm it is resolved:
   - `blocked_from: in-review` (a 4.7 block): load sign-off at 5.1, which moves the spec to `in-review` and records the open findings as known gaps.
   - Any other `blocked_from`: return to it, then route again by the table.

     ```bash
     .agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug <blocked_from>
     ```

## 4. Re-entry (5.6) and loop-backs

**5.6** runs when sign-off reports the stakeholder did not approve the work (5.5 No, a change request), and when a resume lands on a change request for an `in-review` spec. Set `draft` (`.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug draft --step 5.6`), then load the questioning loop at 0.3.8 with the change request as the first frontier question. Every other loop back to 0.3.8 sets `draft` through the call of the step file that owns the gate, as the loop's [Entry](modules/questioning-loop.md#entry) table lists.

## 5. Templates

Templates for every per-feature file are in [assets/](assets/), named after the file they create (`tasks.md` the index, `task.md` one per task under `tasks/`), except `pr-template.md` (for `pr-body.md`, the Sign-off PR description) and `work-backlog.md` for a spec's `.workflow/specs/work-backlog/` list (`work-item.md` is the older one-file-per-item shape); `initiative.md` and `questions.md` are for an initiative folder.

## Done

- A trivial edit was made directly, or a spec folder exists and the step file its status names is loaded with `references/conventions.md`.
- Every status and step change went through `status-transition.sh`, and every guarded write happened at its step.
