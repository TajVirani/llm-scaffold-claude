# T02: Large track in the step list and progress line

Index: [../tasks.md](../tasks.md) · Blocked by: T9 The large-path module and its entry points · Parallel with: None

**What to build:** The step list knows the large path. `references/steps.tsv` gains a phase row `6` for the large path, one row per `6.x` step on a new track `large` in the order `modules/large-path.md` (T9) numbers them, and the conversion node in phase 0 on track `both` that the questioning loop enters from 0.3.19. The step-list lint accepts the wider id range, pins seven phase rows and counts `large` apart from `full` and `light`; the two PLAN flow docs carry the same ids in the same commit. `step-progress.sh` prints `Large path · step n of m — <title> (6.x)` for a large row while every phase 0 row still prints the `Phase 1 of 6` form on both paths. The three placeholders in `tests/fixtures/initiative.sh` are set to the real ids.

**Seam:** `step-progress.sh <id> [--path full|light]` stdout and exit code (with `STEP_PROGRESS_STEPS` pointing at a fixture copy of `steps.tsv`), and `tests/lint/step-list.sh` over `steps.tsv`, `PLAN/decision-flow-reference.md` and `PLAN/decision-flow.mermaid`.

**Acceptance criteria:**

- [ ] `steps.tsv` has a `6`/`phase` row, every `6.x` row on track `large` with the title T9's module gives it, and the conversion node as a `0`/`both` row; the file keeps four tab columns and the existing per-path counts change only by the conversion node.
- [ ] `tests/lint/step-list.sh` widens its id regex to `(00|[0-6])`, pins seven phase rows, counts `large` rows separately, checks every `6.x` id used by `check-write.sh`, `initiative-transition.sh` and the skills is in `steps.tsv`, and its existing full and light pins are updated for the conversion node; the suite passes.
- [ ] `PLAN/decision-flow-reference.md` has a Phase 6 section and `PLAN/decision-flow.mermaid` has the same `6.x` node ids as `steps.tsv`, so the lint's reference and mermaid comparisons pass.
- [ ] `step-progress.sh` prints `Large path · step n of m — <title> (6.x)` for the first and the last large row (n counts large rows only) and exits 2 for a `6.x` id asked on `--path full` or `--path light`; a phase 0 row keeps `Phase 1 of 6 · step n of m` on both paths; `tests/scripts/step-progress.sh` passes with its existing assertions updated for the new totals.
- [ ] `CONVERSION_STEP`, `INITIATIVE_READONLY_STEP` and `LARGE_TERM_GATE_STEP` in `tests/fixtures/initiative.sh` hold the ids T9 fixed (`LARGE_ENTRY_STEP` and `INITIATIVE_WRITER_STEP` stay `6.1` unless T9 changed them).

**Predicted files:** `.agents/skills/feature-workflow/references/steps.tsv`, `.agents/skills/feature-workflow/scripts/step-progress.sh`, `PLAN/decision-flow-reference.md`, `PLAN/decision-flow.mermaid`, `tests/lint/step-list.sh`, `tests/scripts/step-progress.sh`, `tests/fixtures/initiative.sh`.

**Phase 1 tests:** `tests/lint/step-list.sh`, `tests/scripts/step-progress.sh` (the JRN-007 assertions added at 1.2).

**Size:** M (7 files, about 250 changed lines).

**Mode:** afk.

**Notes:** Carries migration M2. The `6.x` list is not invented here: it is copied from the step numbering in `modules/large-path.md` (T9), and the conversion node id from `modules/questioning-loop.md` as T9 left it. `PLAN/` has no owning module in `.workflow/rules.md`; the 2.1 quiz granted the two flow docs to this task because the spec constraint requires them in the same commit as `steps.tsv` (proposals.md P2). `tests/fixtures/initiative.sh` is the harness's shared fixture; change only the placeholder values at its top.
