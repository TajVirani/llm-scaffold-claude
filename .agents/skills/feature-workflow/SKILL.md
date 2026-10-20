---
name: feature-workflow
description: Workflow 2.0 entry point for feature work. Sizes a request (trivial edit, light path or full path), runs discovery, and resumes an in-flight spec at the phase its status names. Use when starting a feature, resuming or changing work in .workflow/specs/NNN-slug/, acting on a session-start resume offer, or when asked to grill me / stress-test my plan (D76).
modules:
  - discovery
  - questioning-loop
  - deferred-handoff
  - discovered-work
  - verification-setup
  - task-breakdown
  - implementation-orchestrator
  - review-triage
  - sign-off
progressive_loading: true
---

<!--
Sources: router shape (resolve workflow state first, then route by the status in the plan frontmatter, EARLY EXIT to the step file; load only the current step file) adapted from bmad-code-org/BMAD-METHOD skills/bmad-build/workflow.md and step-01-clarify-and-route.md (MIT, Copyright (c) 2025 BMad Code, LLC; structure only, no Jinja). Trivial bypass ("a trivial edit you are willing to review yourself"; "if a bug could escape into production" the workflow is worth it) and the smallest-process rule from BMAD-METHOD docs/build/build-a-change.md (MIT). Module frontmatter (modules, progressive_loading) from .agents/skills/pr-quality/SKILL.md (first-party). Invocation choice from mattpocock/skills skills/productivity/writing-for-agents/SKILL-MECHANICS.md @ 49dd158 (MIT). Status, sizing, re-entry, launch and progress-line rules: PLAN/decision-flow-reference.md "Status", "Sizing", "Model selection", "How to read the diagram" (progress line), 0.0-0.0.2, 5.6; assetlist D3, D9, D13, D14, D16, D22, D24, D27, D31, D33, D35, D37, D40, D41, D45, D47, D49, D56, D57, D58, D68, D69, D84; "Discovered work: the scope-creep guardrail (00.21-00.29)".
-->

# Feature workflow

The router for Workflow 2.0. It sizes each request, picks the phase module, and holds the conventions every module follows. Use the smallest amount of process that safely fits the change (design rule 1). Phase logic lives in `modules/`; load only the module the route names, read it fully, and follow it.

## 1. Find the state

Resolve which feature this request is about before doing anything else. Take the first branch that applies.

1. **The request names a spec**: a `.workflow/specs/NNN-slug/` folder, its `spec.md`, or a feature the stakeholder clearly means. Go to [Route by status](#3-route-by-status).
2. **A session-start resume offer is in context** (from `hooks/session-start-resume.sh`) and the stakeholder picks a spec from it. Go to [Route by status](#3-route-by-status). If they pick a handoff from the offer instead, load the `handoff` skill and follow its Resume section.
3. **No hook offered one** (Codex, or a session without the hook): list in-flight specs yourself.

   ```bash
   for f in .workflow/specs/*/spec.md; do [ -f "$f" ] && printf '%s\t%s\n' "$f" "$(yq --front-matter=extract '.status' "$f")"; done
   ```

   If any status is not `done` and the request could belong to one, show the list and ask whether to resume one of them or start new work.
4. **Otherwise** this is new work. Go to [Size the request](#2-size-the-request).

**"Grill me" / "stress-test my plan" (D76).** Treat it as a request to run the questioning loop (0.3.8 on) for the current spec. Resolve the spec by branches 1-3 and route by status; if none is in flight, start at discovery. There is no separate grill skill: the questioning loop owns it, and the vendored `grilling` and `grill-me` were deleted (D78).

**Work-backlog items.** `.workflow/specs/work-backlog/` holds discovered work that a stakeholder chose to tackle as a next feature (D57). It is not a spec: never route it by status. When you list in-flight specs, or the request starts new work, also list the open items:

```bash
for f in .workflow/specs/work-backlog/*.md; do [ -f "$f" ] && [ "$(yq --front-matter=extract '.status' "$f")" = open ] && printf '%s\t%s\n' "$f" "$(yq --front-matter=extract '.origin_spec' "$f")"; done
```

When the stakeholder picks one, it is new work seeded from the item: size it, and discovery seeds 0.1 from it, marks the item `promoted` at 0.1.4 and deletes it once discovery finishes ([discovery](modules/discovery.md#seeded-from-a-work-item), D69). The origin spec's sign-off (5.9) also offers each open item.

Done when you hold either one `.workflow/specs/NNN-slug/` to resume or a new request to size.

## 2. Size the request

**0.0.1: trivial edit the stakeholder will review themselves?** A typo, a copy change, a one-line config tweak the stakeholder will read in the diff. Ask in one line when unsure, recommending your answer. If a bug could escape into production, it is not trivial.

- **Yes, 0.0.2:** make the edit directly. No spec folder, no workflow, no status. Stop here.
- **No:** load [modules/discovery.md](modules/discovery.md) and start at 0.1.

Light versus full path is decided later, at 0.3.20, once the questioning loop has settled the design. Do not pick it at intake.

## 3. Route by status

Read the spec's frontmatter and step marker, then load the module the table names.

```bash
yq --front-matter=extract '.status, .light_path, .blocked_condition // ""' .workflow/specs/NNN-slug/spec.md
cat .workflow/specs/NNN-slug/.step 2>/dev/null   # step, updated_at, blocked_from (gitignored; main checkout only)
```

| Status | `.step` / condition | Load | Resume at |
| --- | --- | --- | --- |
| `draft` | step in 0.3.8–0.3.19, or a loop-back step (2.2, 2.3, 4.5, 4.6, 5.6, 00.24, 00.29) | [questioning-loop](modules/questioning-loop.md) | 0.3.8 (recompute the frontier from `design-log.md`) |
| `draft` | any other step, or no marker | [discovery](modules/discovery.md) | the step in `.step`; 0.1.6 when there is none |
| `ready-for-dev` | `light_path: true` | implementation-orchestrator | 3.1 |
| `ready-for-dev` | step in 2.x | task-breakdown | the step in `.step` |
| `ready-for-dev` | step 00.28 (resumed after discovered work) | task-breakdown if `tasks.md` exists, else verification-setup | task-breakdown 2.6; verification-setup at its first unfinished 1.x step |
| `ready-for-dev` | otherwise | verification-setup | the 1.x step in `.step`, else 1.1 |
| `in-progress` | any | implementation-orchestrator | 3.1 (task records in `tasks.md` say what is done) |
| `in-review` | any task record `in-progress` (a rework under way), whatever the step | implementation-orchestrator | the rework: relaunch the reopened tasks, then back to review-triage |
| `in-review` | step in 5.x | sign-off | the step in `.step` (order 5.1–5.5, then 5.9, 5.7, 5.8) |
| `in-review` | otherwise | review-triage | the 4.x step in `.step`, else 4.1 |
| `blocked` | `blocked_condition` starts `discovered work:` or `size budget:` | [discovered-work](modules/discovered-work.md) | its "Resuming a blocked spec here" section (00.22 or 00.28) |
| `blocked` | any other condition | none until a human resolves it | see [Blocked](#blocked) |
| `done` | any | none | Read it as context only. A new change to a finished feature is new work: size it. |

The rework row checks the task records, not `.step`: once a reopened task passes its gates the orchestrator's `set-task --step` calls (3.16, 3.9, 3.11) and 3.15 move the step off 4.7. It applies when `yq --front-matter=extract '[.tasks[] | select(.status == "in-progress")] | length' .workflow/specs/NNN-slug/tasks.md` is above 0; with none `in-progress`, the 5.x and review-triage rows apply.

Tell the stakeholder where you are resuming, led by the [progress line](#progress-line). Module files are `modules/<name>.md`. A resumed module re-reads its inputs from disk (spec folder, `design-log.md`, `tasks.md`); never rebuild state from memory.

### Blocked

`blocked` is a routing signal: work stops until a human acts.

A `discovered work:` or `size budget:` condition belongs to [discovered-work](modules/discovered-work.md), which resumes the 00.21–00.29 protocol (D56, D58). For any other condition:

1. Show `blocked_condition` from `spec.md` and `blocked_from` from `.step`, and ask the stakeholder to resolve the condition.
2. Once they confirm it is resolved:
   - `blocked_from: in-review` (a 4.7 block, D47): load sign-off at 5.1, which moves the spec to `in-review` and records the open findings as known gaps.
   - Any other `blocked_from`: return to it, then route again by the table.

     ```bash
     .agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug <blocked_from>
     ```

## 4. Re-entry (5.6) and loop-backs

**5.6** runs when sign-off reports the stakeholder did not approve the work (5.5 No, a change request), and when a resume lands on a change request for an `in-review` spec. Set `draft`, then load the questioning loop at 0.3.8 with the change request as the first frontier question:

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug draft --step 5.6
```

Every loop back to 0.3.8 sets `draft` (D49). The module that owns the gate makes the call, then loads [questioning-loop](modules/questioning-loop.md):

| Gate | Owner | Status call before loading the loop |
| --- | --- | --- |
| 0.4.7 goal conflict, 0.6 not clear | discovery | none (already `draft`); `step .workflow/specs/NNN-slug 0.3.8` |
| 2.2 not specifiable, 2.3 seams not agreed | task-breakdown | `status .workflow/specs/NNN-slug draft --step 2.2` or `--step 2.3` |
| 4.5 decision needed, 4.6 third pass upstream | review-triage | `status .workflow/specs/NNN-slug draft --step 4.5` or `--step 4.6` |
| 5.5 change request | this skill (5.6) | `status .workflow/specs/NNN-slug draft --step 5.6` |
| 00.24 discovered-work blocker sent to discovery, 00.29 re-scope | discovered-work | `status .workflow/specs/NNN-slug draft --step 00.24` or `--step 00.29` (from `blocked` only, D56, D58) |

`status-transition.sh` refuses any other route to `draft`; on exit 2 stop and report the reason.

## 5. Conventions every module follows

### Status, step marker and guarded writes

- **One writer.** Status, the step marker `.workflow/specs/NNN-slug/.step` and task records change only through `.agents/skills/feature-workflow/scripts/status-transition.sh` (D16, D45). Always call scripts with that exact repo-relative prefix from the project root: sandboxed projects exclude these exact command lines (D36).

  ```text
  status-transition.sh status   <spec-dir> <new-status> [--step <node>] [--blocked "<condition>"]
  status-transition.sh step     <spec-dir> <node>
  status-transition.sh set-task <spec-dir> <T<n>> [--status <s>] [--work-type <wt>] [--capability <id>] [--step <node>]
  budget-check.sh --spec-dir <spec-dir> [--cwd <dir>] [--predicted]
  ```

  `<spec-dir>` is `.workflow/specs/NNN-slug`. Exit 0 done; 1 environment error (missing `yq`, file or repo); 2 illegal transition, reason on stderr. On 1 or 2 stop and report; never retry with a different `--step` to get past it.
- **Size budget (D58, D87).** `budget-check.sh` prints `{max_tasks, tasks, max_changed_files, changed_files, over[], source, basis, target, merge_base, excluded, files, test_files}` and exits 0 within budget, 2 over, 1 environment error. `changed_files` counts what a reviewer sees in the feature's PR/MR against `main_branch`, changed since `impl_base_revision`, minus tests (reported in `test_files`). It runs at 2.6 (task count, predicted files with `--predicted`) and 3.15 (changed files after each wave merge); a crossing goes to [discovered-work](modules/discovered-work.md) 00.29.
- **Set the step, then write.** These files are written only from the main session, only at these steps. Run `status-transition.sh step .workflow/specs/NNN-slug <node>` immediately before the write.

  | File | Allowed steps |
  | --- | --- |
  | `spec.md` | 0.1.4, 0.1.6, 0.3.17, 0.3.19, 0.3.20, 0.5.1, 1.1, 2.5, 3.1, 3.14, 4.6, 4.8, 5.1, 5.3, 5.9, 00.29 |
  | `tasks.md` and `tasks/T<nn>-<slug>.md` (create or replace) | 0.3.20, 2.5; afterwards task records only through `set-task` |
  | `.workflow/specs/work-backlog/**` | 00.26, 5.9, 0.1.4 (marking a seeded item `promoted`; D57, D69) |
  | `.workflow/GLOSSARY.md`, `.workflow/GLOSSARY-MAP.md` (any depth) | 0.2.3, 0.3.15, 0.4.3, 5.3 |
  | Other Tier A: `.workflow/capabilities.md`, `.workflow/rules.md`, `.workflow/decisions/**` | 0.3.7, 5.3, 5.7 only (D51) |
  | `.workflow/profiles/**` | new file 00.19 or 5.3; existing file 5.3 only (D50) |
  | `.workflow/cache/**`, `.step` | never by Write/Edit (`publish-cache.sh`, `status-transition.sh`) |

  A spec.md write never changes `status` or `blocked_condition`. Everything else in the spec folder (`codebase-map.md`, `design-log.md`, `data-model.md`, `verification-plan.md`) is unguarded.
- **Never grow the spec mid-build.** Work found outside the agreed scope in Phases 1–4 goes to [discovered-work](modules/discovered-work.md) (00.21), never into `spec.md` or `tasks.md` (D56). In Phase 0 it goes through the scope gate 0.3.16–0.3.17. A Tier A change outside its steps becomes a proposal in `proposals.md` for 5.3 (D21).
- **Sub-agents never write.** They return text; the main session writes files from their returns. The guards deny writes made inside a sub-agent.

### Progress line

Lead every phase or step update you write to the stakeholder (a phase transition, a step change, a resume) with the line this prints for the current step (D84):

```bash
.agents/skills/feature-workflow/scripts/step-progress.sh --spec-dir .workflow/specs/NNN-slug [<step-id>] [--at <origin node>]
```

It reads the step from `.step` and the path from `light_path` unless you pass them, e.g. `Phase 1 of 6 · step 23 of 47 — Discovery: Compute the frontier (0.3.8)`. For a 00.x step pass `--at` with the linear step it was entered from (discovered work's origin node, 3.1 for 00.19). Intake (0.0.x) prints nothing: no line. On exit 2, report the step id without a line. The line is display only; status, guards and step ids are unchanged.

### Launching a sub-agent

Every launch prompt starts with the launch header on its first line (D37), followed by the task:

````markdown
```yaml launch-header
task_type: retrieval
spec_dir: .workflow/specs/007-csv-export
```

<task body: only what the agent's definition says it receives>
````

- Required fields per task type (D31): run `.agents/skills/feature-workflow/scripts/resolve-launch.sh --requirements`. Phase 0 types (`retrieval`, `library-evaluation`, `fact-lookup`, `module-audit`) take `spec_dir` only.
- The task body carries only what `.agents/agents/<type>.md` lists under its inputs. Its return format is fixed in that file; read the return from there rather than expecting another shape.
- A return that starts `LAUNCH ERROR:` means the header was wrong: fix it and relaunch once.
- Launch independent agents in one message so they run in parallel. No nested launches (D32).
- A deny that names **00.14** means no model is configured for that task type: tell the stakeholder, record the model they choose in `.workflow/model-map/<type>.md` (or in `.workflow/agent-overrides.yaml` when the agent definition pins a model for this host, D35), and relaunch. A deny that names **00.19** means a coding launch has no profile: the owning module handles it.

### Host notes

| Concern | Claude Code | Codex |
| --- | --- | --- |
| Launch | Agent tool, `subagent_type: <task type>`, prompt = header + task. Leave `model` unset: `hooks/pre-launch.sh` resolves it, prepends any profile, and denies a malformed launch (D33). | Run `printf '%s' "$TASK_BODY" \| .agents/skills/feature-workflow/scripts/resolve-launch.sh --host codex --task-type <type> --spec-dir .workflow/specs/NNN-slug [--task-id T<n>] [--work-type <wt>]`, then spawn the agent with `agent_type` = `<type>` with `-` replaced by `_` (`fact_lookup`, `profile_mini_review`, `cache_regeneration`; `--task-type` keeps the hyphenated `<type>`), `.prompt` as its prompt, `.model` as its model, `task_name` in its D66 form and `fork_turns: "none"` (a full-history fork may ignore the spawn `model` override, D67, and it keeps the parent's history out of the sub-agent). `task_name` forms (Codex accepts only `[a-z0-9_]`, no `/`; `enc` lowercases and turns every other character into `_`): `s<NNN>_t<N>` for an implementation task, `s<NNN>_t<N>_r<round>` for its `profile-mini-review`, `s<NNN>_integration_<enc(wt)>`, `s<NNN>_phase_1_<enc(wt)>`, `s<NNN>_cache_<type>` for a `cache-regeneration` inside a feature (`cache_<type>` in a bulk run), and `s<NNN>_<enc(task type)>` for every other type (`s007_fact_lookup`, `s007_review_standards`). `hooks/codex-pre-spawn.sh` denies a malformed name and checks the `s<NNN>` spec folder. Exit 2 is a deny (D9). |
| Write guards | `spec-single-writer-guard`, `tier-a-write-guard`, `tier-b-write-guard` hooks. | Before each guarded write run `.agents/skills/feature-workflow/scripts/check-write.sh --cwd "$PWD" --path <file>` (for `spec.md` add `--proposed <file holding the new content>`); write only on exit 0 (advisory, D9). |
| Resume offer | `hooks/session-start-resume.sh` at session start. | Branch 3 of [Find the state](#1-find-the-state). |
| Question rounds | AskUserQuestion. | The numbered round format in chat. |
| Other skills | Skill tool, e.g. `domain-modeling`. | `$domain-modeling`, or read its `SKILL.md`. |

Codex hooks replace the direct script calls only for events a live Codex run has verified (D40); until then the calls above stand.

## 6. Modules

| Module | Nodes | Entered from | Exits to |
| --- | --- | --- | --- |
| [discovery](modules/discovery.md) | 0.1–0.3.7, 0.3.20, 0.3.22 (`deeper-prompt` skill), 0.4–0.6 | [Size the request](#2-size-the-request); questioning-loop at 0.3.20 | questioning-loop (0.3.8); implementation-orchestrator (light path, `ready-for-dev`); verification-setup (full path, `ready-for-dev`) |
| [questioning-loop](modules/questioning-loop.md) | 0.3.8–0.3.19 | discovery; loop-backs from 0.4.7, 0.6, 2.2, 2.3, 4.5, 4.6, 5.6, 00.24, 00.29 | discovery at 0.3.20 |
| [deferred-handoff](modules/deferred-handoff.md) | 00.8–00.10, 0.3.17, 3.14, 4.8, 5.9 | questioning-loop, discovery (0.1.5), implementation-orchestrator (3.14), review-triage (4.8), sign-off (5.9) | back to the caller |
| [discovered-work](modules/discovered-work.md) | 00.21–00.29 | verification-setup (1.2–1.3), task-breakdown (2.1, 2.6), implementation-orchestrator (3.2, 3.4, 3.7, 3.15), review-triage (4.4); [Route by status](#3-route-by-status) for a `discovered work:` or `size budget:` block | the caller at its node (00.28); questioning-loop (00.24, 00.29 re-scope); stays `blocked` |
| [verification-setup](modules/verification-setup.md) | 1.1–1.5 | discovery (0.6) | task-breakdown |
| [task-breakdown](modules/task-breakdown.md) | 2.1–2.6 | verification-setup | implementation-orchestrator; questioning-loop (2.2, 2.3); discovered-work (2.1, 2.6) |
| [implementation-orchestrator](modules/implementation-orchestrator.md) | 3.1–3.16 | task-breakdown; discovery (light path); review-triage (4.7 rework) | review-triage (`in-review`); discovered-work |
| [review-triage](modules/review-triage.md) | 4.1–4.8 | implementation-orchestrator | sign-off; questioning-loop (4.5, 4.6); implementation-orchestrator (4.7 rework); discovered-work (4.4) |
| [sign-off](modules/sign-off.md) | 5.1–5.9 (5.5 Yes → 5.9 → 5.7 → 5.8, D57) | review-triage | done; [Re-entry](#4-re-entry-56-and-loop-backs) (5.5 No); discovery for a work item started at 5.9 |

Templates for every per-feature file are in [assets/](assets/): `spec.md`, `codebase-map.md`, `design-log.md`, `data-model.md`, `verification-plan.md`, `tasks.md` (the task index), `task.md` (one per task under `tasks/`, D85), `deferred.md`, `proposals.md`, `report.md`, and `work-item.md` for `.workflow/specs/work-backlog/` items. The retrospective at 5.7 is the standalone `retrospective` skill (D25).

## Done

- A trivial edit was made directly, or a spec folder exists and the module its status names is loaded.
- Every status and step change went through `status-transition.sh`, and every guarded write happened at its step.
