# T02: Launch row, lens table and step 4.9

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** The workflow's plumbing knows a fourth lens. A `review-lessons` launch with the header is accepted and its model resolved (`resolve-launch.sh` task-type table), its pass file passes the triage shape check with ids `RL-<n>` and category `lesson` (`check-review-findings.sh` lens table), and the step list carries `4.9` in run order right after 4.3 so the progress line counts it fourth in Phase 4 and the step-list lint, which pins the Phase 4 count at 9, passes again. Both PLAN docs gain the node so the lint's id comparison holds.

**Seam:** `resolve-launch.sh --requirements [--task-type review-lessons]` JSON (`tests/scripts/resolve-launch.sh`); `pre-launch.sh` allow or deny JSON on an Agent payload (`tests/hooks/pre-launch.sh`); `check-review-findings.sh <file>` exit code, error lines and table (`tests/scripts/check-review-findings.sh`); `step-progress.sh` output (`tests/scripts/step-progress.sh`); the `steps.tsv` rows and PLAN node ids (`tests/lint/step-list.sh`).

**Acceptance criteria:**

- [ ] `resolve-launch.sh` `D31_TABLE` gains the row `"review-lessons": {"d31_fields": ["spec_dir"], "shapes": [{"when": "Phase 4 lens", "required": ["spec_dir"], "optional": []}], "header_optional": false, "profile": "none"}`; `--requirements` lists 14 types; `pre-launch.sh` allows a `review-lessons` launch whose header carries `spec_dir`, with `updatedInput` carrying the model from `.workflow/model-map/review-lessons.md`, denies naming 00.14 when no model source exists, and denies a header without `spec_dir` (JRN-005).
- [ ] `check-review-findings.sh`: the `lenses` table gains `"review-lessons": {prefix: "RL", categories: ["lesson"]}`; the header comment names the four lenses, the `RL` prefix and the `lesson` category; a `review-lessons` file with one `RL-1` high `lesson` finding exits 0 with the header line `findings: 1 (high 1, medium 0, low 0)` and one row; an `RS-` id, a confidence of 70 and a `lesson` category under another lens each exit 1 naming the field; `findings: []` exits 0 (JRN-003). The extra `lesson:` field on a finding is ignored.
- [ ] `.agents/skills/feature-workflow/references/steps.tsv` gains the row `4.9	4	both	Review lessons lens` directly after the `4.3` row; `step-progress.sh` prints `step 4 of 9` for 4.9 and `step 5 of 9` for 4.4 through `step 9 of 9` for 4.8 on the full and the light path (JRN-007) without a script change.
- [ ] `PLAN/decision-flow-reference.md` Phase 4 section gains a `**4.9 — Sub-agent: recorded review lessons, pitfalls and retrospectives**` entry placed after 4.3, and `PLAN/decision-flow.mermaid` gains the node `"4.9 - Sub-agent: recorded review lessons, pitfalls and retrospectives"` in the Phase 4 subgraph wired like 4.3; where either doc says three lenses run in parallel it says four.
- [ ] `tests/lint/step-list.sh` passes with its `4:9` pins on both paths; `tests/scripts/resolve-launch.sh`, `tests/scripts/check-review-findings.sh`, `tests/scripts/step-progress.sh` and `tests/hooks/pre-launch.sh` pass in full; `tests/hooks/codex-adapters.sh` and `tests/hooks/codex-shim.sh` still pass.

**Predicted files:** `.agents/skills/feature-workflow/scripts/resolve-launch.sh`, `.agents/skills/feature-workflow/scripts/check-review-findings.sh`, `.agents/skills/feature-workflow/references/steps.tsv`, `PLAN/decision-flow-reference.md`, `PLAN/decision-flow.mermaid`, `tests/scripts/resolve-launch.sh`, `tests/scripts/check-review-findings.sh`, `tests/scripts/step-progress.sh`, `tests/lint/step-list.sh`, `tests/hooks/pre-launch.sh`.

**Phase 1 tests:** `tests/scripts/resolve-launch.sh`, `tests/scripts/check-review-findings.sh`, `tests/scripts/step-progress.sh`, `tests/lint/step-list.sh`, `tests/hooks/pre-launch.sh`.

**Size:** M (10 files, about 120 changed lines).

**Mode:** afk.

**Notes:** Carries migrations M4 (the launch row) and M5 (the step row, lint counts, PLAN docs). The PLAN docs are scaffold-only and were granted to this task at the 2.1 quiz. The step id is `4.9` by D2: ids may run out of order, the progress line counts rows. The triage module prose that launches the fourth lens is T4, not this task. This repo's own `.workflow/model-map/review-lessons.md` is written by the orchestrator at the first real launch (00.14), not here; the JRN-005 fixture builds its own.
