# T10: regenerate-caches docs for the boundary check rule

Index: [../tasks.md](../tasks.md) · Blocked by: T5 (done; same files) · Parallel with: None

**What to build:** `SKILL.md` preflight (lines 41-45) says depcruise is needed for `architecture` only when the boundary config exists and a profile names `dependency-cruiser`, not whenever the config exists. `assets/cache-frontmatter.md` Boundary violations line (112) gives the rule and adds the `Not checked: no boundary checker for this project's graph extractors (<names>).` wording (D16, D17). The stamp-only scope text (`SKILL.md:73`, `cache-frontmatter.md:21,83`) stays: the config stays in the architecture scope whenever it exists (D18).

**Seam:** None: docs, checked by the agent-docs lint suites.

**Acceptance criteria:**

- [ ] No line still says depcruise is needed, or the check runs, whenever the boundary config exists whatever extractors the profiles name.
- [ ] `cache-frontmatter.md` lists all three Boundary violations outcomes: violations or `None.`, no boundary config, no boundary checker for the project's extractors.
- [ ] Agent-docs lint suites pass.

**Predicted files:** `.agents/skills/regenerate-caches/SKILL.md`, `.agents/skills/regenerate-caches/assets/cache-frontmatter.md`

**Phase 1 tests:** None.

**Size:** S (2 files, about 10 changed lines).

**Mode:** afk.

**Notes:** None.
