# T03: Session start sees done-on-main in the Done folder

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** At session start, an initiative whose emitted specs have all finished is recognised as finished even when those specs now sit in the Done folder on main. `spec_done_on_main` in the session-start hook is true for a `done` spec on main at the top level (`.workflow/specs/NNN-slug/spec.md`, specs merged before this feature) or in the Done folder (`.workflow/specs/done/NNN-slug/spec.md`) (D10).

**Seam:** The session-start hook's output (the resume offer for `planned` initiatives), driven by `tests/hooks/session-start-initiatives.sh`.

**Acceptance criteria:**

- [ ] A `planned` initiative whose every emitted spec is `done` on main in `done/` is treated as finished, the same as when they sit at the top level.
- [ ] A mix of top-level and `done/` specs, all `done`, is finished; one spec not `done` in either place keeps the initiative offered.
- [ ] A spec in `done/` is never offered as an in-flight spec.
- [ ] The Done folder path is built from `WF_SPECS` (no `specs/done` literal in the script; TGT-004).
- [ ] `tests/hooks/session-start-initiatives.sh` passes; shellcheck clean.

**Predicted files:** `.agents/hooks/session-start-resume.sh`

**Phase 1 tests:** `tests/hooks/session-start-initiatives.sh`

**Size:** S (1 file, about 15 changed lines).

**Mode:** afk.

**Notes:** `WF_SPECS_DONE` lands in the shared library only after wave 1 (T1's integration request), so build the path as `$WF_SPECS/done` here, or source the constant if it exists at your branch's base; both satisfy TGT-004. `modules/large-path.md` carries a copy of the same helper; T4 changes that copy.
