# T08: Profile template asks for graph_extractor

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** The shipped profile template and both examples carry `graph_extractor` in their Toolchain block with a comment naming `none` and the shipped extractors (M1). `profiles.md` asks for the key when it writes a profile, and requires dependency-cruiser only for profiles keyed to it.

**Seam:** None: docs, checked by the agent-docs lint suites.

**Acceptance criteria:**

- [ ] TEMPLATE.md contract line lists `graph_extractor` among the descriptive keys.
- [ ] Both examples set the key.
- [ ] profiles.md asks for it and no longer requires dependency-cruiser in every project.
- [ ] Agent-docs lint suites pass.

**Predicted files:** `.agents/skills/project-setup/assets/profiles/TEMPLATE.md`, `.agents/skills/project-setup/assets/profiles/examples/test-harness.md`, `.agents/skills/project-setup/assets/profiles/examples/e2e-browser.md`, `.agents/skills/project-setup/modules/profiles.md`

**Phase 1 tests:** None.

**Size:** S (4 files, about 40 changed lines).

**Mode:** afk.

**Notes:** This repo's own `.workflow/profiles/` keys go through proposals.md at 5.3 (D7, M3), not this task.
