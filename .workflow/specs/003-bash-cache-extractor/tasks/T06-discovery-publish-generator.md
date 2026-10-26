# T06: Discovery 0.2.8 publishes the extractor names

Index: [../tasks.md](../tasks.md) · Blocked by: T1 (Graph extractor per work profile) · Parallel with: None

**What to build:** Discovery 0.2.8's architecture publish line passes `--generator` from `build-architecture.sh --print-generator` instead of the hardcoded `dependency-cruiser`.

**Seam:** None: docs, checked by the agent-docs lint suites.

**Acceptance criteria:**

- [ ] `discovery.md` no longer hardcodes `--generator dependency-cruiser`.
- [ ] Agent-docs lint suites pass.

**Predicted files:** `.agents/skills/feature-workflow/modules/discovery.md`

**Phase 1 tests:** None.

**Size:** S (1 files, about 10 changed lines).

**Mode:** afk.

**Notes:** None.
