# Phase 3 finish

The [wave loop](implementation-waves.md) loads this step file once no task is left `pending` and the last wave has passed 3.9 (or skipped it at 3.13), and a resume whose `.step` says 3.10, 3.11 or 3.14 continues here. Every command runs in the spec checkout, as the wave loop says. A failing journey reopens its task through the wave loop: its gates, 3.16, 3.15 and 3.9 run there again before this step file resumes.

## 3.10-3.11 Browser suite against the running feature

When the browser suite exists ([3.13](implementation-waves.md#313-do-both-suites-exist); when it is missing, go to [3.14](#314-record-each-missing-suite)), run it yourself with Bash on the merged spec branch, after the last wave passes 3.9 (or straight after its 3.13 when only the browser suite exists): the browser-suite command from `## Suites` (the `e2e` key of `.workflow/profiles/e2e-browser.md`), or `.agents/skills/feature-workflow/scripts/run-toolchain.sh --spec-dir .workflow/specs/NNN-slug --task-id e2e-<run> --work-type e2e-browser --cwd "$PWD" --e2e`, which runs the profile's other command keys (`lint`, `typecheck`, `format`, `boundary`, `test`) and then `e2e` last. The 3.5 stop audit never runs `e2e`, and the evidence-capture hook does not run the suite either: it only files the run's screenshots, traces, console and network logs under `artifacts/` by run and journey id (3.12). Where that hook is not wired (Codex, or before it is installed), copy the runner's output into `artifacts/<run>/<JRN-id>/` yourself.

- **3.11 Yes, every journey passes:** `.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug in-review --step 3.11`, then [hand off](#hand-off).
- **No:** for each failing journey, take the capability it proves (`## Journeys`, Proves column) and reopen the task serving it: `.agents/skills/feature-workflow/scripts/status-transition.sh set-task .workflow/specs/NNN-slug T3 --status in-progress --step 3.11`, then `.agents/skills/issue-tracking/scripts/issue-tracker.sh move <issue> in_progress`, `<issue>` being the task record's `issue` (`""` when null). Give it a fix round, then 3.5-3.8 ([gates](implementation-gates.md#per-task-gates-34-38)), 3.16, 3.15 and 3.9 ([wave loop](implementation-waves.md#316-merge-the-wave)) and 3.10 again. A task that cannot continue: `set-task .workflow/specs/NNN-slug T3 --status blocked --step 3.11`, then [Stops](implementation-waves.md#stops).

## 3.14 Record each missing suite

When [3.13](implementation-waves.md#313-do-both-suites-exist) found a suite missing (light path only), its gate was skipped. Record each gap; it is never reported as a pass:

1. **Record each missing suite on the shelf.** A project that lacked the suite before already has a shelf file for it; list the suite-gap files and read each one's Summary line:

   ```bash
   grep -l '^\*\*Origin:\*\*.*3\.14 suite gap' .workflow/deferred/*.md
   ```

   - **A file for this suite exists** (its Summary names the same missing suite): add to it without asking. `.agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug 3.14`, then append one line to its **Later requests** section, `- .workflow/specs/NNN-slug, 3.14: <suite> gate skipped again; <why the suite is still missing> at commit <git rev-parse HEAD>.`, add the file's path to `deferred` in `spec.md` and log a one-line note in `design-log.md`.
   - **None exists** (the first time this project shows the gap): load `modules/deferred-handoff.md` with the missing suite as a `3.14 suite gap` item. It writes `.workflow/deferred/<slug>.md`, sets step 3.14 and adds the path to `deferred` in `spec.md`.

   In that same `spec.md` write, add one line per skipped gate under `## Known gaps` with the shelf file's link.
2. **Only the harness exists:** once every task is `done` or `split-out` and 3.9 passes, `.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug in-review --step 3.14`. **Only the browser suite exists:** 3.11 sets `in-review` as above. **Neither exists:** set `in-review` at 3.14 once every task is `done` or `split-out`, and go straight to Phase 4. Sign-off flags the gap in the 5.4 report.

## Hand off

Task worktrees and branches are already gone (3.16). Remove what is left: `git worktree list`, then `git worktree remove <path>` for each remaining implementation or integration worktree under `.workflow/.worktrees/`, and `git branch -d <branch>` for its merged branch. Commit the workflow data the last gates wrote (3.9 and 3.10 evidence, the `in-review` status): `.agents/skills/feature-workflow/scripts/commit-workflow-data.sh .workflow/specs/NNN-slug -m "Workflow data for NNN-slug: implementation done"`. Then load `modules/review-triage.md`.
