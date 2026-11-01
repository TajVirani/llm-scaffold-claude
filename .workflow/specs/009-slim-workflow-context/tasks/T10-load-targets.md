# T10: Hit the load targets

Index: [../tasks.md](../tasks.md) · Blocked by: T2 (Output style reads the term list), T9 (Script and asset headers re-pointed) · Parallel with: None

**What to build:** A new-feature start loads at most 45,000 bytes and an implementation resume at most 55,000 bytes, counted the way `tests/lint/workflow-load-size.sh` counts them (AGENTS.md, the fixture session-start hook output, the router, conventions, the first step file, and the term list for a new start) (D15, D19, D21). Measure both loads on the split tree, then trim the counted files (the router, `references/conventions.md`, `modules/discovery.md`, `modules/implementation-waves.md`) until both are under their limit, without dropping a rule: text that only another step needs moves to that step's file, and repeated text becomes a pointer.

**Seam:** `tests/lint/workflow-load-size.sh`, which prints `<load point>: <n> bytes (limit <m>)` per load point and fails above a limit.

**Acceptance criteria:**

- [ ] `tests/run-all.sh --suite lint/workflow-load-size` passes, printing both totals at or under their limits.
- [ ] Every rule moved out of a counted file still has exactly one home (`lint/shared-rule-homes` passes) and every step still routes (`lint/step-routing` passes).
- [ ] `tests/run-all.sh` passes: every suite green (JRN-010).

**Predicted files:** `.agents/skills/feature-workflow/SKILL.md`, `.agents/skills/feature-workflow/references/conventions.md`, `.agents/skills/feature-workflow/modules/discovery.md`, `.agents/skills/feature-workflow/modules/implementation-waves.md`, `.agents/skills/feature-workflow/references/launching.md`

**Phase 1 tests:** `tests/lint/workflow-load-size.sh`

**Size:** M (5 files, about 150 changed lines).

**Mode:** afk.

**Notes:** If a target cannot be met without changing behaviour or dropping a rule, report it as discovered work instead of cutting text. `AGENTS.md` belongs to root-docs and stays as it is.
