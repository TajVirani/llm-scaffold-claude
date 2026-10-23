# T05: regenerate-caches docs for graph extractors

Index: [../tasks.md](../tasks.md) · Blocked by: T1 (Graph extractor per work profile), T2 (Unresolved edges in architecture) · Parallel with: None

**What to build:** `SKILL.md` preflight requires depcruise only when a profile names `dependency-cruiser`, adds `yq` for the profile read, and publishes architecture with `--generator "$(build-architecture.sh --print-generator)"`. `cache-frontmatter.md` describes `generator` as the sorted, comma-joined extractor names and documents the Unresolved edges section and the `line` field.

**Seam:** None: docs, checked by the agent-docs lint suites.

**Acceptance criteria:**

- [ ] No line still says dependency-cruiser is the only generator or always required.
- [ ] The publish step takes the generator from `--print-generator`.
- [ ] Agent-docs lint suites pass.

**Predicted files:** `.agents/skills/regenerate-caches/SKILL.md`, `.agents/skills/regenerate-caches/assets/cache-frontmatter.md`

**Phase 1 tests:** None.

**Size:** S (2 files, about 60 changed lines).

**Mode:** afk.

**Notes:** None.
