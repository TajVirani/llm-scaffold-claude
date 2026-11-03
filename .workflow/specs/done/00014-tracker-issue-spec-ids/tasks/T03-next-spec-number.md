# T03: next-spec-number.sh

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** Discovery's 0.1.1 numbering becomes one call: `.agents/skills/feature-workflow/scripts/next-spec-number.sh [--cwd DIR]`.

- **No tracker** (no `.workflow/issue-tracking.yaml`, or `issue_tracker: none`): the script runs today's 0.1.1 scan and prints the next number on one line, the same number the old fenced block printed. It calls no gh or glab.
- **Tracker set up:** the script calls `.agents/skills/issue-tracking/scripts/issue-tracker.sh create-spec`. It prints the issue number from the URL's last path segment, padded to five digits, then the URL on a second line.
- **Failures:** a tracker failure exits 1 with the cause on stderr and nothing on stdout; a usage error or bad settings exits 2.

The 0.1.1 text shrinks to the call, which frees new-feature start bytes for T10. The existing tests that ran the fenced scan block, and the `next_spec_number` copy in `tests/fixtures/initiative.sh`, call the script instead and keep their expected numbers.

**Seam:** the `next-spec-number.sh` CLI on fixture repos, with fake gh and glab on PATH logging calls (`tests/scripts/next-spec-number.sh`). Catches scan regressions and any tracker call without a tracker. It misses the tracker branch's issue creation, which T05 proves in `tests/scripts/issue-tracking.sh`.

**Acceptance criteria:**

- [ ] With no settings file, and again with `issue_tracker: none`, the script prints the scan's next number (`002`, `00010`, `00011` for the existing fixtures, matching what the old block printed), and the fake call log is empty.
- [ ] With a tracker set up, it delegates to `issue-tracker.sh create-spec` and prints the padded number and the URL; with the stub, the output is the stub's.
- [ ] `discovery.md` 0.1.1 is one call to the script, and the start load stays at or under 45,000 bytes (`tests/lint/workflow-load-size.sh`).
- [ ] `tests/scripts/move-to-done.sh`, `tests/scripts/spec-worktree.sh` and `tests/fixtures/initiative.sh` call the script instead of the fenced block, and the initiative suites keep their pinned numbers.
- [ ] A suite ends with `shellcheck_files` over the script.

**Predicted files:** `.agents/skills/feature-workflow/scripts/next-spec-number.sh`, `.agents/skills/feature-workflow/modules/discovery.md`, `tests/scripts/move-to-done.sh`, `tests/scripts/spec-worktree.sh`, `tests/fixtures/initiative.sh`.

**Phase 1 tests:** `tests/scripts/next-spec-number.sh`.

**Size:** S (5 files, 2 of them non-test, about 140 changed lines).

**Mode:** afk.

**Notes:** touches_core. Shared-core request for `.agents/lib/workflow-paths.sh` (integration, before wave 1): a `WF_` variable for `.workflow/issue-tracking.yaml`, built like its siblings, so every script finds the settings file through the lib.
