# T09: Root docs and changelog

Index: [../tasks.md](../tasks.md) · Blocked by: T2 Install and allow the worktree setup script, T4 Toolchain run starts services, T5 Step files name the script, T6 Project setup asks for it, T7 Standards coverage · Parallel with: None

**What to build:** Someone reading the scaffold's own documents learns that every worktree is created and set up by one script, what a project declares to use it (a setup command, a copy list, service commands), which isolation values its commands receive, and that the toolchain run starts services itself. The changelog records the change.

**Seam:** the root documents as text, checked by `lint/md-links` and the lint suites that read them.

**Acceptance criteria:**

- [ ] `README.md` describes worktree setup in the section on what the workflow does in a target project: the three settings, `.worktreeinclude`, the five isolation values, the link check, and that a project declaring nothing behaves as before. Its list of `.gitignore` lines includes the slot file.
- [ ] `.agents/README.md` lists `worktree-setup.sh` among the feature-workflow scripts with one line on what it does.
- [ ] `AGENTS.md` names the slot file in its line about the `.gitignore` block, matching `GI_ENTRIES`.
- [ ] `.codex/README.md` tells the Codex orchestrator to create each worktree with `worktree-setup.sh agent`, not a raw git command.
- [ ] `CHANGELOG.md` has one entry under the unreleased version: what changed, the settings a project can declare, and that nothing changes for a project that declares none.
- [ ] Every statement matches the merged scripts and step files; a behaviour the documents and the code disagree on is reported in the result, not papered over.
- [ ] `lint/md-links`, `lint/symlinks` and `lint/frontmatter` pass.

**Predicted files:** `README.md`, `.agents/README.md`, `AGENTS.md`, `.codex/README.md`, `CHANGELOG.md`

**Phase 1 tests:** None.

**Size:** S (5 files, about 70 changed lines). L is a split signal: more than 15 files, more than 400 lines, or too big for one fresh context window.

**Mode:** afk.

**Notes:** Plain sentences; explain each name on first use; use the glossary term "Worktree setup". Do not name a target project.
