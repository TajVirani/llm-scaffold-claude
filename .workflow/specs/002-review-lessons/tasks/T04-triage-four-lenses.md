# T04: Triage launches four lenses; sign-off names the lessons write

Index: [../tasks.md](../tasks.md) · Blocked by: T1 (Lessons file template and the 5.7 guard class), T2 (Launch row, lens table and step 4.9), T3 (The review-lessons lens definition) · Parallel with: None

**What to build:** Phase 4 runs four lenses. `modules/review-triage.md` launches `review-lessons` together with the other three at step 4.9, checks its pass file like theirs, and triages `category: lesson` findings as any other; the feature-workflow `SKILL.md` module table, the design-log template's lens column and the sign-off 5.7 paragraph (the retrospective now also writes review lessons) say the same.

**Seam:** None in the harness: prose read by the orchestrator. Checked by the mini-review at 3.7 and the end-state lens at 4.2 against the criteria below; `tests/lint/step-list.sh` guards that every `4.9` step call it adds is in `steps.tsv`.

**Acceptance criteria:**

- [ ] `modules/review-triage.md`: the intro and step 2 heading say four lenses (4.1-4.3, 4.9); step 2 launches `review-lessons` in the same message with the same one-line task, with the Codex form (`agent_type` `review_lessons`, `task_name` `s<NNN>_review_lessons`); the light-path note keeps the lessons lens when the targets lens is dropped; step 3 names the fourth pass file (`review-lessons.yaml`, prefix `RL`) and its failed-lens handling; step 4 says a `category: lesson` finding carries the repeated lesson's id in `lesson:` and that the lens severity is a claim like any other. Nothing about triage verdicts, routing or exits changes.
- [ ] `.agents/skills/feature-workflow/SKILL.md` Modules table: the review-triage row's nodes read `4.1–4.9`; no other change to that file beyond T1's row.
- [ ] `.agents/skills/feature-workflow/assets/design-log.md`: the Source lens column lists `review-standards / review-end-state / review-targets / review-lessons`.
- [ ] `modules/sign-off.md` 5.7: the retrospective also writes each approved review lesson to `.workflow/review-lessons.md` (created from `.agents/skills/feature-workflow/assets/review-lessons.md` when missing) and retires one a rule, lint or profile line now enforces, in the same sentence that lists its other writes.
- [ ] `tests/lint/step-list.sh` and every other suite pass as they did before this task.

**Predicted files:** `.agents/skills/feature-workflow/modules/review-triage.md`, `.agents/skills/feature-workflow/modules/sign-off.md`, `.agents/skills/feature-workflow/assets/design-log.md`, `.agents/skills/feature-workflow/SKILL.md`.

**Phase 1 tests:** None.

**Size:** S (4 files, about 60 changed lines).

**Mode:** afk.

**Notes:** Carries migration M7. Blocked by T2 because the step `4.9` and the `RL` row must exist before the module names them, by T3 because the lens it launches must exist, and by T1 because both edit `SKILL.md` (overlap settled as an edge; T1 merges first). The retrospective's own procedure is T5.
