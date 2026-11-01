# T05: Retrospective writes and retires review lessons

Index: [../tasks.md](../tasks.md) · Blocked by: T1 (Lessons file template and the 5.7 guard class) · Parallel with: None

**What to build:** At 5.7 the retrospective can record a stakeholder-approved "watch for X in Y" lesson directly as a review lesson, and retire one that a rule, lint or profile line now enforces. The routing table gains the destination with the rule that tells a review lesson from a judgement lesson (a symptom a reader can see in a diff, with the paths it applies to, is a review lesson; a process lesson or one with no diff-visible symptom stays an action item), the documented procedure creates the file from the feature-workflow template when missing, takes the next id from the template's `next-id:` command, appends one entry with Edit, validates with the template's `validate:` command, and retires in place; the skill's writes table, candidate list, Done line and the template's Kind column change with it.

**Seam:** The template's own `validate:` and `next-id:` commands (the oracle `tests/lint/review-lessons.sh`, owned by T6, pins for JRN-006); the procedure itself is prose the agent follows, exercised for real at this spec's 5.7 and recorded in its retrospective.

**Acceptance criteria:**

- [ ] `modules/routing.md`: a **Review lesson** row (written by this skill: yes; destination `.workflow/review-lessons.md`) with the admission rule above, placed beside the judgement-lesson row so the two are told apart in one place; the procedure under the table: with the step already at 5.7, copy `.agents/skills/feature-workflow/assets/review-lessons.md` to `.workflow/review-lessons.md` with Write when the file is missing; run its `next-id:` command for the id; append one entry (`id`, `symptom`, `paths`, `origin_spec`, `date`) with Edit, never Bash; run its `validate:` command and stop with the error when it fails; skip a duplicate symptom as "already present". Retirement: candidates are this feature's approved 5.3 proposals that enforce a recorded lesson and any lesson the stakeholder names; under the same per-entry approval, Edit the entry to add `retired: <date>` and `enforced_by: <the rule, lint or profile line>`; an entry is never deleted and an id never reused.
- [ ] `SKILL.md`: the writes table gains the `.workflow/review-lessons.md` (Tier A) row; step 5's candidate list names review lessons; the Done list has a line for them; step 6's action items exclude a written review lesson; "Recorded in" for a review lesson names the file and the id.
- [ ] `assets/retrospective.md`: the Kind column admits `review lesson`, the "Recorded in" examples include `.workflow/review-lessons.md RL-003`, and the note under the table names the third outcome. Only the lesson-kind lines change; the two stale notes stay with the deferred item.
- [ ] `modules/evidence.md`: the inventory reads `.workflow/review-lessons.md` when present, so a duplicate is seen and a retirement candidate found.
- [ ] The three places that define lesson kinds (the routing table, the template's Kind column and note, step 6's list) change together and agree.
- [ ] Prose follows `.agents/skills/writing-for-agents/SKILL.md`: steps end on a completion criterion, no decision id in the skill files, `.workflow/GLOSSARY.md` terms (**Review lesson**). Every suite passes as before (no harness test owns this task).

**Predicted files:** `.agents/skills/retrospective/SKILL.md`, `.agents/skills/retrospective/modules/routing.md`, `.agents/skills/retrospective/modules/evidence.md`, `.agents/skills/retrospective/assets/retrospective.md`.

**Phase 1 tests:** None. JRN-006's oracle half is in `tests/lint/review-lessons.sh` (T6); the agent's own judgement runs live at this spec's 5.7.

**Size:** M (4 files, about 160 changed lines).

**Mode:** afk.

**Notes:** Carries migration M8 (sign-off prose is T4). Decisions: D1 (retrospective owns the lesson), D3 (entry shape), D6 and D10 (retire in place, ids never reused), D7 (only the retrospective creates the file), D9 (template path), and the routing distinction in the design-log "Module audit follow-up" entry. `retrospective` may depend on `feature-workflow` only, which the template path respects. The deferred item `.workflow/deferred/retrospective-template-drift.md` stays out of scope.
