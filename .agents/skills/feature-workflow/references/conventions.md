# Workflow conventions

The rules every feature-workflow step file follows, for a spec and for an initiative; step files name the exact calls.

## Status, step marker and guarded writes

- **One writer.** Status, the step marker `.workflow/specs/NNN-slug/.step` and task records change only through `.agents/skills/feature-workflow/scripts/status-transition.sh`. An initiative's status, its `.step` and its slice and question records change only through `.agents/skills/feature-workflow/scripts/initiative-transition.sh`, whose call forms are in [large-path](../modules/large-path.md#conventions). Always call scripts with that exact repo-relative prefix from the project root: sandboxed projects exclude these exact command lines. Step files write these two scripts as `ST` and `IT`; type the full path.

  ```text
  status-transition.sh status   <spec-dir> <new-status> [--step <node>] [--blocked "<condition>"]
  status-transition.sh step     <spec-dir> <node>
  status-transition.sh set-task <spec-dir> <T<n>> [--status <s>] [--work-type <wt>] [--capability <id>] [--step <node>]
  ```

  `<spec-dir>` is `.workflow/specs/NNN-slug`. Both transition scripts exit the same way. Exit 0 done; 1 environment error (missing `yq`, file or repo, or a usage error); 2 illegal transition, reason on stderr. On 1 or 2 stop and report; never retry with a different `--step`, or any other way, to get past it.
- **Set the step, then write.** These files are written only from the main session, only at these steps. Run `status-transition.sh step .workflow/specs/NNN-slug <node>` immediately before the write. An initiative runs `initiative-transition.sh step .workflow/initiatives/NNN-slug <6.x>` as it enters each step; large-path's step table names the steps that write `initiative.md` and the term gate.

  | File | Allowed steps |
  | --- | --- |
  | `spec.md` | 0.1.4, 0.1.6, 0.3.17, 0.3.19, 0.3.20, 0.5.1, 1.1, 2.5, 3.1, 3.14, 4.6, 5.1, 5.3, 5.9, 00.29 |
  | `tasks.md` and `tasks/T<nn>-<slug>.md` (create or replace) | 0.3.20, 2.5; afterwards task records only through `set-task` |
  | `.workflow/specs/work-backlog/**` | 00.26, 5.9, 0.1.4 (marking a seeded item `promoted`) |
  | `.workflow/initiatives/NNN-slug/initiative.md` | 6.1, 6.7, 6.9 (the initiative's own `.step`, set with `initiative-transition.sh step`) |
  | `.workflow/GLOSSARY.md`, `.workflow/GLOSSARY-MAP.md` (any depth) | 0.2.3, 0.3.15, 0.4.3, 5.3; 6.6 from an initiative |
  | Other Tier A: `.workflow/capabilities.md`, `.workflow/rules.md`, `.workflow/decisions/**` | 0.3.7, 5.3, 5.7 only |
  | `.workflow/profiles/**` | new file 00.19 or 5.3; existing file 5.3 only |
  | `.workflow/review-lessons.md` | 5.7 only |
  | `.step` | never by Write/Edit (`status-transition.sh`, `initiative-transition.sh`) |
  | `.workflow/specs/done/**` (the Done folder) | never by Write/Edit: a finished spec stays as `move-to-done.sh` moved it |
  | Path-only rewrites of a moved spec's path, in Tier A files, design logs and every other `.workflow/` file outside `initiatives/` | 5.8, by `.agents/skills/feature-workflow/scripts/move-to-done.sh` only, which changes nothing but that path; the initiative's files are re-pointed at 6.13. Also Tracker adoption, for a renamed spec, outside any step |

  A spec.md write never changes `status` or `blocked_condition`. Everything else in the spec folder (`codebase-map.md`, `design-log.md`, `data-model.md`, `verification-plan.md`) is unguarded.
- **Tracker calls.** Steps call `.agents/skills/issue-tracking/scripts/issue-tracker.sh` the same with or without a tracker (with none it prints `skipped: no tracker`). `<issue>` is the task record's `issue`, `""` when null. On exit 1 or 2 stop, show the stakeholder its message and run it again once fixed.
- **Never grow the spec mid-build.** Work found outside the agreed scope in Phases 1–4 goes to [discovered-work](../modules/discovered-work.md) (00.21), never into `spec.md` or `tasks.md` on your own; its [Assess each report first](../modules/discovered-work.md#assess-each-report-first) is the one statement of how a report is proven and routed. In Phase 0 it goes through the scope gate 0.3.16–0.3.17. A Tier A change outside its steps becomes a proposal in `proposals.md` for 5.3.
- **Sub-agents write only their own result file.** Inside a spec, besides the code a coding agent builds, a sub-agent writes one file: its findings or result file under the spec's `artifacts/`. The Phase 4 lenses write their pass files; `implementation`, `integration` and `profile-mini-review` write their result files; the main session checks each with a script and never retypes it. Inside an initiative a sub-agent writes nothing. Everything else a sub-agent returns as text, and the main session writes files from it. The guards deny a sub-agent's writes to the guarded workflow files.

## Asking the stakeholder

- **Only blocking questions wait.** A question blocks when its answer changes the scope or intent of the work, or when the action it gates is hard to reverse: a merge to the main branch, a publish, a delete, a migration, or anything outside the repo (a tracker, a remote, another system). Ask a blocking question and wait for the answer.
- **Assume and log the rest.** Any other question has a recommended answer you would give anyway. Take it at once; do not ask. If you cannot recommend one answer, it blocks. Append an **Assumed** entry to `design-log.md` (shape in [../assets/design-log.md](../assets/design-log.md)): the question, the answer taken, and why it was safe to assume. A step that says "assume and log" points here.
- **Offer every assumption for veto.** Open the next blocking ask with each **Assumed** entry no `Offered for veto:` line names yet, one line each, as its first question: "Keep these assumptions?", with "Keep them all (Recommended)"; a veto names the entry. List them with `grep -n '^## .* Assumed: \|^- Offered for veto: ' .workflow/specs/NNN-slug/design-log.md`, and log `- Offered for veto: <titles>; vetoed: <titles | none>` in the entry of that ask. A veto is a change at that point, handled the way that step handles any change the stakeholder asks for.
- **Launch before asking.** Before you send a blocking ask, launch every sub-agent whose input does not depend on its answer, and start any long check that can run meanwhile, so the stakeholder's time to answer is not idle time. Launch nothing an answer could invalidate: work that reads a term, a scope or a design the question is still deciding waits for the answer. Step files name the launches this applies to.

## Progress line

Lead every phase or step update you write to the stakeholder (a phase transition, a step change, a resume) with the line this prints for the current step:

```bash
.agents/skills/feature-workflow/scripts/step-progress.sh --spec-dir .workflow/specs/NNN-slug [<step-id>] [--at <origin node>]   # a spec
.agents/skills/feature-workflow/scripts/step-progress.sh <6.x>                                                                   # an initiative
```

For a spec it reads the step from `.step` and the path from `light_path` unless you pass them, e.g. `Phase 1 of 6 · step 23 of 48 — Discovery: Compute the frontier (0.3.8)`. For a 00.x step pass `--at` with the linear step it was entered from (discovered work's origin node, 3.1 for 00.19). For an initiative pass the bare 6.x id, never with `--spec-dir` (that exits 2): it prints `Large path · step n of m — <title> (6.x)`. Intake (0.0.x) prints nothing: no line. On exit 2, report the step id without a line. The line is display only.

## Host notes

| Concern | Claude Code | Codex |
| --- | --- | --- |
| Write guards | `workflow-write-guard` hook. | Before each guarded write run `.agents/skills/feature-workflow/scripts/check-write.sh --cwd "$PWD" --path <file>` (for `spec.md` add `--proposed <file holding the new content>`); write only on exit 0 (advisory). |
| Other skills | Skill tool, e.g. `domain-modeling`. | `$domain-modeling`, or read its `SKILL.md`. |

Codex hooks replace a direct script call, here or in [launching](launching.md), only for events a live Codex run has verified; until then the calls stand.
