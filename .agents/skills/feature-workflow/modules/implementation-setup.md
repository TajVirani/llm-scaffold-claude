# 3.1 Classify each task and start

Phase 3 starts here, once per spec: the router loads this step file at `ready-for-dev` on the light path and at `in-progress` while `impl_base_revision` is still `""`, task-breakdown loads it after 2.6, and the [wave loop](implementation-waves.md#resume-and-rework) sends a resume here first when a task has no `work_type`. Every command runs in the spec checkout, with the scripts called by their full `.agents/skills/feature-workflow/scripts/` path, as the wave loop says. Status and task records change only through `status-transition.sh`.

1. **Classify.** For every task whose `work_type` is null (`yq --front-matter=extract '.tasks[] | select(.work_type == null) | .id' .workflow/specs/NNN-slug/tasks.md`), pick the profile in `.workflow/profiles/` whose `## File locations` cover the task's module and kind of work, and record it. A work type is set once and never reclassified:

   ```bash
   .agents/skills/feature-workflow/scripts/status-transition.sh set-task .workflow/specs/NNN-slug T3 --work-type <work-type> --step 3.1
   ```

   **00.18 No.** A task that fits no profile is a finding: either the task is badly cut or a work type is missing. For a missing work type, create the profile with the human from `.workflow/profiles/TEMPLATE.md` (`.agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug 00.19`, then Write `.workflow/profiles/<work-type>.md`). With no human available: `.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug blocked --step 00.19 --blocked "task T3 has no profile; define .workflow/profiles/<work-type>.md"`.

2. **Start.** `.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug in-progress --step 3.1` (from `ready-for-dev`, or again on resume). Then move the spec's tracker issue to in progress:

   ```bash
   .agents/skills/issue-tracking/scripts/issue-tracker.sh move "$(yq --front-matter=extract '.tracker_issue // ""' .workflow/specs/NNN-slug/spec.md)" in_progress
   ```

3. **Record the implementation base.** Check you are in the spec checkout on the spec branch (`git branch --show-current` prints the `spec_branch` from `spec.md`). If `impl_base_revision` is `""`, Edit it to `git rev-parse HEAD` now (the step is 3.1): the spec-branch tip, which holds the Phase 1 commit and the committed breakdown. On the light path, also set `baseline_revision` to the same sha if it is `""` (the spec branch's first commit, from 0.3.20). Both are never overwritten on resume or rework. The 3.15 size budget counts only files changed since `impl_base_revision`, so the Phase 1 harness and suite count only when a task changes them again.

**Done when:** every task has a `work_type`, the spec is `in-progress`, and `impl_base_revision` is a full SHA. Then load `modules/implementation-waves.md` and run the wave loop; a resume the wave loop sent here goes back to its On resume.
