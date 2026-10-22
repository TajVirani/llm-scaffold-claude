# T10: Close recognises a reopened initiative by its branch status

Index: [../tasks.md](../tasks.md) · Blocked by: T9 The large-path module and its entry points (done; listed for the shared files) · Parallel with: None

**What to build:** When sign-off hands a merged spec to the close step, or a `planned` initiative is resumed, step 6.13 of the large path tells a reopened initiative apart by what its branch holds, never by whether the branch exists. If `initiative/NNN-slug` exists locally or as `origin/initiative/NNN-slug`, read `initiative.md` at that tip: `exploring` means the initiative was reopened and is still exploring, so the stakeholder is told, its emitted specs not yet `done` on main are named, and nothing is written. Any other status at the tip (the `planned` tip a `pr` merge leaves on origin) is not a reopen: the status on main decides as before, and when every emitted spec is `done` the branch is re-created from the main ref and the initiative flips to `done`. The hand-off sentence in sign-off says the same. The merge suite's replay of 6.13 (`close_check`) follows the same order, so the five JRN-005 step 5 checks go green and the reopened checks stay green.

**Seam:** Prose, checked two ways: the JRN-005 replay in `tests/scripts/initiative-merge.sh` (`close_check`, which replays 6.13 step by step: status on main, then the branch tip's status, then the emitted specs, then the flip) and the Phase 4 review lenses reading 6.13 against the suite.

**Acceptance criteria:**

- [ ] `modules/large-path.md` 6.13: the "`planned`, branch present" bullet is replaced by a rule that reads `initiative.md` at the branch tip (`git show refs/heads/initiative/NNN-slug:...` or `refs/remotes/origin/...`, whichever exists) and acts on its status: `exploring` reports "still exploring" with the open emitted specs and writes nothing; anything else falls through to the `planned` listing and flip. The "Empty or `exploring`" (on main) and `done` bullets are unchanged.
- [ ] `modules/sign-off.md`, the hand-off to 6.13: its one-sentence condition matches the new rule (a branch whose tip reads `exploring` means still exploring; a stale remote branch does not stop the close).
- [ ] `tests/scripts/initiative-merge.sh`: `close_check` reads the status at the branch tip instead of returning on the ref's existence; the five "JRN-005 under pr" checks pass; the four reopened checks (local branch and origin-only, `exploring`) still pass; the exploring-on-main check still passes; `# Covers:` header updated; no body comment names a document, step id or finding id.
- [ ] `tests/run-all.sh --suite scripts/initiative-merge` passes in full; `tests/run-all.sh --suite lint/step-list` passes (no step id changes); shellcheck over `tests/*.sh` exits 0.

**Predicted files:** `.agents/skills/feature-workflow/modules/large-path.md`, `.agents/skills/feature-workflow/modules/sign-off.md`, `tests/scripts/initiative-merge.sh`.

**Phase 1 tests:** `tests/scripts/initiative-merge.sh`, the five checks labelled `JRN-005 under pr ...` (Run 3 in `artifacts/phase-1-known-bad/record.md`); the rest of that suite belongs to T5 and is green.

**Size:** S (3 files, about 40 changed lines).

**Mode:** afk.

**Notes:** Carries decision D33 (design-log, Questioning round 6), which supersedes the "branch present" rule written at rework 2 for F14. Read the suite's reopened and stale fixtures before editing `close_check`: the reopened fixtures set `exploring` at the branch tip, the stale fixture leaves a `planned` tip on origin, and both must be told apart by the tip's status alone. No change to `initiative-transition.sh`, the fixture file, or any other module.
