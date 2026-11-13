# T02: Install and allow the worktree setup script

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** A target project that installs the scaffold ignores the slot file (the one-line file in which a spec worktree records its slot), and its host settings let the orchestrator run `worktree-setup.sh` without a permission prompt. This repo gets the same ignore line and allow rule, and the new script is recorded in the provenance and asset lists.

**Seam:** `install.sh` run against a fixture target (`tests/scripts/install-payload.sh`), and the settings template read as data (`tests/scripts/install-claude-settings.sh`).

**Acceptance criteria:**

- [ ] `GI_ENTRIES` in `install.sh` holds the slot file's path, built from the new path constant, and the `install.sh` header comment that lists the ignored paths names it.
- [ ] After `install.sh` runs against a fixture target, the target's `.gitignore` marker block holds the slot file line; an upgrade run adds it to an older block.
- [ ] This repo's `.gitignore` marker block holds the same lines as `GI_ENTRIES`.
- [ ] `.agents/hooks/claude-settings.template.json` and `.claude/settings.json` allow `.agents/skills/feature-workflow/scripts/worktree-setup.sh`, in the form the neighbouring script rules use, and no longer allow `git worktree add`.
- [ ] `PROVENANCE.md` names `worktree-setup.sh`, and `assetlist.md` records the script and the decision that every worktree is created through it.
- [ ] The tests for the first four criteria are written first and fail before the change.

**Predicted files:** `install.sh`, `.gitignore`, `.agents/hooks/claude-settings.template.json`, `.claude/settings.json`, `PROVENANCE.md`, `assetlist.md`, `tests/scripts/install-payload.sh`, `tests/scripts/install-claude-settings.sh`

**Phase 1 tests:** None.

**Size:** M (8 files, about 90 changed lines). L is a split signal: more than 15 files, more than 400 lines, or too big for one fresh context window.

**Mode:** afk.

**Notes:** Shared-core change requested (`touches_core`), in `.agents/lib/workflow-paths.sh`: two path constants with their header-comment lines. (1) The slot file, a gitignored file directly under the workflow folder of a spec worktree (for example `WF_SLOT_FILE="$WF_DIR/.slot"`). (2) The copy list at the repository root (`WF_COPY_LIST=".worktreeinclude"`). Contract for the consumers: `install.sh` puts the slot file constant in `GI_ENTRIES`; `worktree-setup.sh` (T3) reads and writes the slot file and reads the copy list through these names only. `tests/scripts/lib-workflow-paths.sh` gains a case for each constant.

The allow rule for `git worktree add` goes only if no step file still needs it once T5 is merged; if removing it now breaks a suite, keep it and say so in the result, and T5 removes it.
