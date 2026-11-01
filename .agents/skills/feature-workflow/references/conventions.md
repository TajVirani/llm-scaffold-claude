# Workflow conventions

The rules every feature-workflow step file follows, for a spec and for an initiative. The router loads this file once, with the first step file of a session; step files name the exact calls and rely on these rules.

## Status, step marker and guarded writes

- **One writer.** Status, the step marker `.workflow/specs/NNN-slug/.step` and task records change only through `.agents/skills/feature-workflow/scripts/status-transition.sh`. An initiative's status, its `.step` and its slice and question records change only through `.agents/skills/feature-workflow/scripts/initiative-transition.sh`, whose call forms are in [large-path](../modules/large-path.md#conventions). Always call scripts with that exact repo-relative prefix from the project root: sandboxed projects exclude these exact command lines.

  ```text
  status-transition.sh status   <spec-dir> <new-status> [--step <node>] [--blocked "<condition>"]
  status-transition.sh step     <spec-dir> <node>
  status-transition.sh set-task <spec-dir> <T<n>> [--status <s>] [--work-type <wt>] [--capability <id>] [--step <node>]
  budget-check.sh --spec-dir <spec-dir> [--cwd <dir>] [--predicted]
  ```

  `<spec-dir>` is `.workflow/specs/NNN-slug`. Both transition scripts exit the same way. Exit 0 done; 1 environment error (missing `yq`, file or repo, or a usage error); 2 illegal transition, reason on stderr. On 1 or 2 stop and report; never retry with a different `--step`, or any other way, to get past it.
- **Size budget.** `budget-check.sh` prints `{max_tasks, tasks, max_changed_files, changed_files, over[], source, basis, target, merge_base, excluded, files, test_files}` and exits 0 within budget, 2 over, 1 environment error. `changed_files` counts what a reviewer sees in the feature's PR/MR against `main_branch`, changed since `impl_base_revision`, minus tests (reported in `test_files`). It runs at 2.6 (task count, predicted files with `--predicted`) and 3.15 (changed files after each wave merge); a crossing goes to [discovered-work](../modules/discovered-work.md) 00.29.
- **Set the step, then write.** These files are written only from the main session, only at these steps. Run `status-transition.sh step .workflow/specs/NNN-slug <node>` immediately before the write. An initiative runs `initiative-transition.sh step .workflow/initiatives/NNN-slug <6.x>` as it enters each step; large-path's step table names the steps that write `initiative.md` and the term gate.

  | File | Allowed steps |
  | --- | --- |
  | `spec.md` | 0.1.4, 0.1.6, 0.3.17, 0.3.19, 0.3.20, 0.5.1, 1.1, 2.5, 3.1, 3.14, 4.6, 4.8, 5.1, 5.3, 5.9, 00.29 |
  | `tasks.md` and `tasks/T<nn>-<slug>.md` (create or replace) | 0.3.20, 2.5; afterwards task records only through `set-task` |
  | `.workflow/specs/work-backlog/**` | 00.26, 5.9, 0.1.4 (marking a seeded item `promoted`) |
  | `.workflow/initiatives/NNN-slug/initiative.md` | 6.1, 6.7, 6.9 (the initiative's own `.step`, set with `initiative-transition.sh step`) |
  | `.workflow/GLOSSARY.md`, `.workflow/GLOSSARY-MAP.md` (any depth) | 0.2.3, 0.3.15, 0.4.3, 5.3; 6.6 from an initiative |
  | Other Tier A: `.workflow/capabilities.md`, `.workflow/rules.md`, `.workflow/decisions/**` | 0.3.7, 5.3, 5.7 only |
  | `.workflow/profiles/**` | new file 00.19 or 5.3; existing file 5.3 only |
  | `.workflow/review-lessons.md` | 5.7 only |
  | `.workflow/cache/**`, `.step` | never by Write/Edit (`publish-cache.sh`, `status-transition.sh`, `initiative-transition.sh`) |
  | `.workflow/specs/done/**` (the Done folder) | never by Write/Edit: a finished spec stays as `move-to-done.sh` moved it |
  | Path-only rewrites of a moved spec's path, in Tier A files, design logs and every other `.workflow/` file outside `cache/` and `initiatives/` | 5.8, by `.agents/skills/feature-workflow/scripts/move-to-done.sh` only, which changes nothing but that path; the initiative's files are re-pointed at 6.13 |

  A spec.md write never changes `status` or `blocked_condition`. Everything else in the spec folder (`codebase-map.md`, `design-log.md`, `data-model.md`, `verification-plan.md`) is unguarded.
- **Never grow the spec mid-build.** Work found outside the agreed scope in Phases 1–4 goes to [discovered-work](../modules/discovered-work.md) (00.21), never into `spec.md` or `tasks.md` on your own; its [Assess each report first](../modules/discovered-work.md#assess-each-report-first) is the one statement of how a report is proven and routed. In Phase 0 it goes through the scope gate 0.3.16–0.3.17. A Tier A change outside its steps becomes a proposal in `proposals.md` for 5.3.
- **Sub-agents write only their own result file.** Inside a spec, besides the code a coding agent builds (and the staged cache of `cache-regeneration`), a sub-agent writes one file: its findings or result file under the spec's `artifacts/`. The Phase 4 lenses write their pass files; `implementation`, `integration` and `profile-mini-review` write their result files; the main session checks each with a script and never retypes it. Inside an initiative a sub-agent writes nothing. Everything else a sub-agent returns as text, and the main session writes files from it. The guards deny a sub-agent's writes to the guarded workflow files.

## Progress line

Lead every phase or step update you write to the stakeholder (a phase transition, a step change, a resume) with the line this prints for the current step:

```bash
.agents/skills/feature-workflow/scripts/step-progress.sh --spec-dir .workflow/specs/NNN-slug [<step-id>] [--at <origin node>]   # a spec
.agents/skills/feature-workflow/scripts/step-progress.sh <6.x>                                                                   # an initiative
```

For a spec it reads the step from `.step` and the path from `light_path` unless you pass them, e.g. `Phase 1 of 6 · step 23 of 48 — Discovery: Compute the frontier (0.3.8)`. For a 00.x step pass `--at` with the linear step it was entered from (discovered work's origin node, 3.1 for 00.19). For an initiative pass the bare 6.x id, never with `--spec-dir` (that exits 2): it prints `Large path · step n of m — <title> (6.x)`. Intake (0.0.x) prints nothing: no line. On exit 2, report the step id without a line. The line is display only; status, guards and step ids are unchanged.

## Host notes

| Concern | Claude Code | Codex |
| --- | --- | --- |
| Write guards | `spec-single-writer-guard`, `tier-a-write-guard`, `tier-b-write-guard` hooks. | Before each guarded write run `.agents/skills/feature-workflow/scripts/check-write.sh --cwd "$PWD" --path <file>` (for `spec.md` add `--proposed <file holding the new content>`); write only on exit 0 (advisory). |
| Other skills | Skill tool, e.g. `domain-modeling`. | `$domain-modeling`, or read its `SKILL.md`. |

Codex hooks replace a direct script call, here or in the launch rules, only for events a live Codex run has verified; until then the calls stand.
