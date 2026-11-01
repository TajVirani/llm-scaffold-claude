# Small path

A spec route for a request that already names the file to change, the cause and the test that proves the fix, as a work-backlog item usually does. It is built exactly as the light path is: one task, test-first, the toolchain, the mini-review and the 3.9 gate. What it drops is the ceremony around the build: library evaluation, the separate deeper-prompt and summary confirmations, the review lenses, the long report and the retrospective session. Every step that catches a defect stays.

This module has no steps of its own. It runs **beside** the module the router names (discovery, questioning-loop, implementation-orchestrator, review-triage, sign-off): follow that module as written, and where this file names one of its steps, do what this file says instead. A step not named here runs unchanged. You are done when the spec is `done` and merged by sign-off, or when it has left the small path.

`ST` is `.agents/skills/feature-workflow/scripts/status-transition.sh`; type the full path every time. `.workflow/specs/NNN-slug` is this feature's folder.

## Leave the small path

The small path holds only while the request stays as small as it looked at 0.0.3. Leave it the moment any of these is true:

- **0.3.3:** the owning module is not clear, so placement needs its own question.
- **The round:** an answer defers a question to a deep dive, leaves one open, or surfaces a new one (0.3.18 is Yes), so a second round is needed.
- **0.3.19:** a light-path fact (table in [discovery](discovery.md#0320-light-path-test)) is not clean, or the request needs a library the project does not have.

To leave: append a dated `Left the small path: <reason>` line to `design-log.md` and tell the stakeholder in one line, leading with the progress line. Then carry on in the module you are in, as written: placement at 0.3.4, a second round at 0.3.8, the full path after 0.3.20. The small path skipped library evaluation, so launch `library-evaluation` now as discovery 0.2.5 says and paste its report into **Library options** in `codebase-map.md`. From then on one change in this file still applies, because the router keeps loading it while `small_path` is `true`: at 0.3.19, write `small_path: false` with the rest of `spec.md`, and `light_path` from the three facts. Every other step runs as its module says.

Done when the line is logged and the stakeholder has been told.

## Phase 0 (discovery and the questioning loop)

Each change below applies only while `design-log.md` has no `Left the small path` line.

1. **0.1.4 Write spec.md.** Write the template as discovery says, and in its frontmatter set `small_path: true` and `light_path: true`. A small-path spec is a light-path spec, so the progress line counts the light path from the start.
2. **0.2.4–0.2.5 Retrieval only.** Launch `retrieval` as discovery says, and no `library-evaluation`. At 0.2.6 write **Library options** in `codebase-map.md` as `None (small path: not evaluated).`
3. **0.3.22 Deeper prompt, without its own round.** Draft the deeper prompt block as the `deeper-prompt` skill's steps 1 and 3 describe, filling **Downstream**, **Tools and technologies** and **Gotchas** from the request and the work item (`none known` where they say nothing). Ask none of its questions yet: the block rides in the round.
4. **0.3.8–0.3.18 One round.** Run the round as the questioning loop says, with two additions to the same ask:
   - **First question:** the deeper prompt block in full, worded "Is this the ask, with these downstream effects, tools and gotchas?", recommended answer "Yes, as written". A change to the block is an answer like any other; apply it and log the agreed block as the **Deeper prompt** entry, as the skill's step 4 says.
   - **Last question:** the settled design as it stands if every recommendation is accepted, worded "If you accept every recommendation above, this is the change: <summary>. Confirm?"

   Log the round as usual. Done when every question has an answer; a deferred, open or new question means [leave the small path](#leave-the-small-path).
5. **0.3.19 Settle the goal.** When every answer in the round took the recommendation, the last question was the confirmation: log `Summary confirmed in the round` and ask nothing more. When any answer differed, restate the summary with those answers and ask the 0.3.19 confirmation on its own; a correction that reopens the frontier means leave the small path. Write `spec.md` as the loop says, keeping `small_path: true` and `light_path: true` when the three facts are clean.

   A loop-back to 0.3.8 (from 4.5, 4.6, 5.6, 00.24 or 00.29) runs the loop as written, with no deeper prompt and no limit of one round; the spec stays on the small path unless 0.3.19 finds a fact that is not clean.
6. **0.3.20 Light-path pass.** Run discovery's light-path pass (spec branch, budget, one task, commit, `ready-for-dev`), then load implementation-orchestrator at 3.1 at once, with no fresh-session offer.

## Phases 3 and 4

The build is the light path's, unchanged: implementation-orchestrator runs the one task test-first through 3.5, 3.7 and 3.9, and 3.13–3.14 for a missing suite. Phase 4 is review-triage as written: on the light path, which includes this one, it launches the one combined review at 4.10 instead of the lenses.

## Phase 5 (sign-off)

1. **5.4 Short report.** Write `report.md` as these five lines instead of the template, with the same evidence rules: run the harness through `run-toolchain.sh` exactly as 5.4 says, and link every result. Fill `pr-body.md` and check it as 5.4 says.

   ```markdown
   # Report: <feature title>

   - **Changed:** <what is different, in one sentence>; files: <the `files` list of budget-check.sh>; `<baseline_revision>`..`<head sha>`.
   - **Tests:** <the harness summary line> ([toolchain.txt](artifacts/sign-off-5.4/toolchain.txt)); <the 3.13–3.14 suite gap, or "both suites ran">.
   - **Findings:** <n> patched, <n> deferred, <n> dismissed over <n> review passes; failed review: <none | the review>. Detail in design-log.md.
   - **Known gaps:** <spec.md Known gaps, and the review's not_checked and not_verifiable lines, one phrase each | None.>
   - **Merge:** `<spec_branch>` into `<main_branch>` at 5.8, by <PR | local merge>.
   ```

2. **5.5 Retrospective folded into the ask.** Before asking, list the candidate lessons from this spec's design log: each failed gate, fix round, rework and verified `high` or `medium` finding, with the destination the retrospective's [routing module](../../retrospective/modules/routing.md) gives it. Replace sign-off's question "Anything you want weighed in the retrospective?" with "Record these in the retrospective?", listing each candidate and its destination, with the options "Record as listed", "None: record the verdict only" and any other answer as a change or a concern in the stakeholder's words. Recommend "None" when there are no candidates. In the Sign-off entry, log `Going-in concerns:` as usual and add `Retrospective lessons approved at 5.5: <each approved candidate and its destination | none>`.
3. **5.7 Retrospective without a session.** Invoke the `retrospective` skill as sign-off says. Its going-in concerns (step 2) and its lesson approvals (step 5) are the 5.5 answers: ask nothing again, write each approved lesson to its destination, and record the rest as rejected at 5.5. Each section of the document may be one line.

Steps 5.1–5.3, 5.6, 5.8 and 5.9 run as sign-off says.

## Done

- The spec ran with `small_path: true` and `light_path: true` from 0.1.4 to `done`, or `design-log.md` holds a `Left the small path` line and the spec continued on the light or full path as written.
- Phase 0 asked one round, with the deeper prompt as its first question and the summary as its last, and launched no `library-evaluation`.
- `report.md` is the five lines with evidence, and the retrospective asked nothing beyond the 5.5 answers.
