# T01: Initiative paths, ignore block and installer entries

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** A target project installed from this scaffold, and this repo itself, ignore an initiative's step marker the same way they ignore a spec's: `.workflow/initiatives/*/.step` sits beside `.workflow/specs/*/.step` in the gitignore block that `install.sh` writes from `GI_ENTRIES`, and in this repo's hand-kept copy of that block. Every script builds the initiatives root from the shared path library (`WF_INITIATIVES` through `wf_path`), never from a spelled-out `.workflow/initiatives` string.

**Seam:** `tests/scripts/install.sh`: the gitignore block an install writes into the fixture project (the entries loop at its line 79, and the "block added once" check), and `wf_path` resolving `WF_INITIATIVES` in a fixture.

**Acceptance criteria:**

- [ ] `.agents/lib/workflow-paths.sh` exports `WF_INITIATIVES` (`.workflow/initiatives`) beside `WF_SPECS`, with the same `wf_path` behaviour; this is the shared-core request below, applied by the integration agent before this task runs.
- [ ] `GI_ENTRIES` in `install.sh` gains `"$WF_INITIATIVES/*/.step"`, so a fresh install's gitignore block lists `.workflow/initiatives/*/.step`, and an idempotent re-run adds it once.
- [ ] This repo's `.gitignore` block carries the same line, in step with `GI_ENTRIES` (the repo rule: `install.sh` refuses to target this repo, so the block is kept by hand).
- [ ] `tests/scripts/install.sh` expects the new entry wherever it enumerates the block (line 79 loop and the "block added once" check), and the whole install suite passes.
- [ ] No file spells `.workflow/initiatives` in code; the only literal is the `.gitignore` line, which the lib header allows for static files.

**Predicted files:** `.agents/lib/workflow-paths.sh` (integration agent, shared core), `install.sh`, `.gitignore`, `tests/scripts/install.sh`.

**Phase 1 tests:** None. The install suite is the existing guard for this change.

**Size:** S (4 files, about 40 changed lines).

**Mode:** afk.

**Notes:** Shared-core request (`touches_core: true`): add `WF_INITIATIVES=".workflow/initiatives"` to `.agents/lib/workflow-paths.sh` next to `WF_SPECS`, exported and resolvable through `wf_path`, with its line in the file's path table. Consumers: `install.sh` (this task), `check-write.sh` and `resolve-launch.sh` (T7), `session-start-resume.sh` and `codex-pre-spawn.sh` (T6), `initiative-transition.sh` (T4). Carries migration M1 from `data-model.md`. `.gitignore` has no owning module in `.workflow/rules.md`; the 2.1 quiz granted it to this task (proposals.md P2 proposes the ownership row). The settings templates' deny entries for the same path belong to T6.
