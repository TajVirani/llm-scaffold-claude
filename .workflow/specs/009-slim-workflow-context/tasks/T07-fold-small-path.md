# T07: Fold the small path into its step files

Index: [../tasks.md](../tasks.md) · Blocked by: T5 (Discovery split and the 0.2.1 read), T6 (Shared-core and per-task gates step files) · Parallel with: None

**What to build:** A small-path session loads the same files as any other session: `modules/small-path.md` is deleted and each step it changes carries a short "On the small path:" note in the step file that owns that step (D17). 0.1.4, 0.2.4–0.2.6 and 0.3.22 notes go to `discovery.md`; 0.3.8–0.3.19 with the loop-back clause to `questioning-loop.md`; 0.3.20 (no fresh-session offer) to `discovery-impact.md`; 5.4, 5.5 and 5.7 to `sign-off.md`. "Leave the small path" (the triggers at 0.3.3, at a round and at 0.3.19, plus the late library-evaluation launch) becomes `## Leave the small path` in `questioning-loop.md` (D24). The router's 0.0.3 "Yes" loads discovery alone and states the sizing rule, its Route table drops the small-path line, and links to the leave section point at `questioning-loop.md#leave-the-small-path`. `assets/report.md` names sign-off's five-line short form instead of `small-path.md`.

**Seam:** `tests/lint/small-path-docs.sh` (the notes, the leave section, the router sizing and links, the review-triage 4.10 launch) and `tests/lint/shared-rule-homes.sh` (each marker in one file, `small-path.md` absent).

**Acceptance criteria:**

- [ ] `tests/run-all.sh --suite lint/small-path-docs` passes.
- [ ] `tests/run-all.sh --suite lint/shared-rule-homes` passes (`## Leave the small path` only in `questioning-loop.md`; every marker from T3 and T4 in exactly one file).
- [ ] No file under `.agents/` names `small-path.md`.
- [ ] `lint/md-links` and every other existing suite pass.
- [ ] `PROVENANCE.md` drops the `small-path.md` row.

**Predicted files:** `.agents/skills/feature-workflow/modules/small-path.md`, `.agents/skills/feature-workflow/modules/discovery.md`, `.agents/skills/feature-workflow/modules/discovery-impact.md`, `.agents/skills/feature-workflow/modules/questioning-loop.md`, `.agents/skills/feature-workflow/modules/sign-off.md`, `.agents/skills/feature-workflow/SKILL.md`, `.agents/skills/feature-workflow/assets/report.md`, `PROVENANCE.md`

**Phase 1 tests:** `tests/lint/small-path-docs.sh`, `tests/lint/shared-rule-homes.sh`

**Size:** M (8 files, about 200 changed lines).

**Mode:** afk.

**Notes:** Phases 3 and 4 change nothing on the small path; review-triage already says "the small path included". The edge from T6 orders their `PROVENANCE.md` edits.
