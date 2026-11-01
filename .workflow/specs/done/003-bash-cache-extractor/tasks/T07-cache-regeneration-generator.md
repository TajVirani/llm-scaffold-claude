# T07: cache-regeneration agent names the extractors

Index: [../tasks.md](../tasks.md) · Blocked by: T1 (Graph extractor per work profile) · Parallel with: None

**What to build:** The agent's return line `generator:` names the output of `build-architecture.sh --print-generator` for architecture, and `cache-regeneration` otherwise.

**Seam:** None: docs, checked by the agent-docs lint suites.

**Acceptance criteria:**

- [ ] `cache-regeneration.md` no longer hardcodes dependency-cruiser as the architecture generator.
- [ ] Codex tomls regenerate cleanly if they derive from this file; agent-docs lint suites pass.

**Predicted files:** `.agents/agents/cache-regeneration.md`

**Phase 1 tests:** None.

**Size:** S (1 files, about 10 changed lines).

**Mode:** afk.

**Notes:** None.
