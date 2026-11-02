# T09: Package the issue-tracking skill

Index: [../tasks.md](../tasks.md) · Blocked by: T5 (Tracker script), T6 (Tracker setup), T8 (Tracker adoption) · Parallel with: None

**What to build:** The `issue-tracking` skill installs into target projects. `.agents/install-manifest.txt` lists `skills/issue-tracking` as a directory entry. `PROVENANCE.md` has a row for every file the skill holds: `SKILL.md`, `issue-tracker.sh`, `tracker-setup.sh`, `tracker-adoption.sh` and any reference file T05-T08 added. It also has a row for `feature-workflow/scripts/next-spec-number.sh`, so the asset-coverage target prints 0.

**Seam:** the install suites (`tests/scripts/install-payload.sh` and siblings) and the JRN-014 manifest and PROVENANCE checks in `tests/lint/issue-tracking-docs.sh` (owned by T10).

**Acceptance criteria:**

- [ ] The manifest lists `skills/issue-tracking`, and an install into a fixture target copies the skill (`tests/run-all.sh --suite scripts/install-payload` passes).
- [ ] `PROVENANCE.md` names `skills/issue-tracking` and every new `.agents/` file this spec added. The Targets `asset-coverage` command in `verification-plan.md` prints `0`.
- [ ] `tests/run-all.sh --suite lint/upstream-lineage --suite lint/symlinks` pass.

**Predicted files:** `.agents/install-manifest.txt`, `PROVENANCE.md`.

**Phase 1 tests:** None. The JRN-014 manifest and PROVENANCE tests turn green in `tests/lint/issue-tracking-docs.sh`, owned by T10.

**Size:** S (2 files, about 15 changed lines).

**Mode:** afk.

**Notes:** Cross-cutting policy (`.workflow/rules.md`): a new first-party asset goes in the manifest and `PROVENANCE.md`. They land here, after the skill's files exist, as one change on the spec branch.
