# T08: The research task type

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** A `research` sub-agent that answers one open-ended initiative question from the repo, its docs, git history and the web, and returns a cited answer the main session writes back into `questions.md` as the settled line. It is launched from an initiative with a header carrying `spec_dir` only; it may be left pending across a session end (the question stays `researching` until the next session writes the answer back). The definition follows the agent template, is listed in the install manifest so target projects get it, and has its PROVENANCE row.

**Seam:** `tests/lint/frontmatter.sh` over `.agents/agents/research.md` (exact frontmatter keys, no `model:`, description shape) and the Codex toml `generate-codex-agents.sh` produces from it (`tests/scripts/generate-codex-agents.sh`).

**Acceptance criteria:**

- [ ] `.agents/agents/research.md` has frontmatter `name: research`, a `description` that leads with the role and the step (`Initiative research (large path, 6.x)`), and `tools` (read-only plus `WebSearch` and `WebFetch`); no `model:` key, and no `models:` values are pinned.
- [ ] Its body follows `.agents/skills/writing-for-agents/assets/agent.template.md` (Input / Steps / Return): it receives the question text, the initiative's goal and the dependencies' settled lines; it answers from code, docs, git history or the web with a source for every claim; it returns one block with `answer`, `sources` (`path:line` or URL), `confidence` and `open_points`, never writes a file and never decides for the stakeholder.
- [ ] `.agents/install-manifest.txt` lists `agents/research.md`; `PROVENANCE.md` gains its row (first-party) in the agents entry.
- [ ] `tests/lint/frontmatter.sh` and `tests/scripts/generate-codex-agents.sh` pass, with any agent-count or agent-list pin updated.
- [ ] `tests/scripts/install.sh` still passes (the manifest line matches an existing file).

**Predicted files:** `.agents/agents/research.md`, `.agents/install-manifest.txt`, `PROVENANCE.md`, `tests/lint/frontmatter.sh`, `tests/scripts/generate-codex-agents.sh`.

**Phase 1 tests:** None. The JRN-008 resolve test reads its model from the fixture's model map and is owned by T7.

**Size:** S (5 files, about 100 changed lines).

**Mode:** afk.

**Notes:** Carries migration M6 (D20). The manifest is installer-owned and `PROVENANCE.md` has no owner; the 2.1 quiz granted both to this task because the cross-cutting policy requires them in the same change (proposals.md P2). The glossary's Task type list gains `research` through proposal P1 at 5.3, not here. This repo's own `.workflow/model-map/research.md` is written by the 00.14 flow at the first real launch, not by this task.
