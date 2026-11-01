# T06: New projects get the lessons file; the asset-set lint goes green

Index: [../tasks.md](../tasks.md) · Blocked by: T1 (Lessons file template and the 5.7 guard class), T2 (Launch row, lens table and step 4.9), T3 (The review-lessons lens definition) · Parallel with: None

**What to build:** A project set up from now on starts with an empty `.workflow/review-lessons.md` and a model-map entry for the lens: project-setup's file table copies the feature-workflow template, and its model-map tier table lists `review-lessons` in the cheap tier with a count that matches what the table lists. This task also owns the Phase 1 suite that pins the whole asset set, `tests/lint/review-lessons.sh`, and brings it fully green once T1 to T3 are merged.

**Seam:** The `modules/files.md` table row and the template's own commands (`tests/lint/review-lessons.sh`, JRN-008); the asset-set assertions in the same suite.

**Acceptance criteria:**

- [ ] `.agents/skills/project-setup/modules/files.md` gains the row: Target `.workflow/review-lessons.md`, Source `.agents/skills/feature-workflow/assets/review-lessons.md` (the full path, since the `A/` shorthand covers project-setup assets only), action "Copy as is. The header holds the entry rules and the commands the retrospective follows at 5.7; a project set up before this file existed gets it from the retrospective at its next 5.7."
- [ ] `.agents/skills/project-setup/modules/model-map.md`: the cheap tier row lists `review-lessons`; the "each of the N task types" lines there and in `SKILL.md` state the number of types the table lists after this change (13; the missing `research` row is backlog item `002-review-lessons-disc-001`, not this task).
- [ ] `tests/lint/review-lessons.sh` passes in full on the merged wave: the template (JRN-008), the JRN-006 oracle cases, the agent definition, manifest, PROVENANCE, README, Codex toml and `4.9` row assertions, and the `files.md` row. Any assertion the real asset shapes show to be wrong is corrected in the suite with the reason in the commit message.
- [ ] `tests/scripts/install-payload.sh`, `tests/scripts/install-hosts.sh` and every other suite pass as before.

**Predicted files:** `.agents/skills/project-setup/modules/files.md`, `.agents/skills/project-setup/modules/model-map.md`, `.agents/skills/project-setup/SKILL.md`, `tests/lint/review-lessons.sh`.

**Phase 1 tests:** `tests/lint/review-lessons.sh`.

**Size:** S (4 files, about 20 changed lines).

**Mode:** afk.

**Notes:** Carries the project-setup half of migration M3. Blocked by T1, T2 and T3 because the suite it owns pins their assets (the template, the `4.9` row, the agent and its housekeeping), so it can only go green after they merge. `project-setup` may depend on `feature-workflow`, which the template path respects.
