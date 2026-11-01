# T01: Done folder path and write deny

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** Once a spec sits in the **Done folder** (`.workflow/specs/done/NNN-slug/`), no Write or Edit can change anything under it, from the main session or a sub-agent (D11). The shared path library names the Done folder and accepts a spec folder there, so scripts can build its path from `WF_SPECS` and normalise a moved spec's folder.

**Seam:** The `check-write.sh --cwd <dir> --path <file>` CLI (exit 0 allow, 2 deny), driven by `tests/scripts/check-write-paths.sh`; and the `WF_SPECS_DONE` variable and `wf_norm_folder spec <arg>`, driven by `tests/scripts/lib-workflow-paths.sh`.

**Acceptance criteria:**

- [ ] `check-write.sh` denies a Write/Edit of every path under `.workflow/specs/done/**`, for the main session and for a sub-agent, with a message naming the Done folder as finished work; `spec.md`, `tasks.md`, `tasks/**`, `design-log.md`, `pr-body.md` and any other file are all denied.
- [ ] The edge paths `.workflow/specs/done/.step` and `.workflow/specs/done/spec.md` are denied as Done folder paths, not classed as a spec named `done`; the `done/**` rule is checked before the any-depth glossary rule.
- [ ] Look-alike folders (`.workflow/specs/donex/`, `.workflow/specs/012-done/`) keep their current classes.
- [ ] Integration request applied: `WF_SPECS_DONE=$WF_SPECS/done` and `wf_norm_folder spec` accepts `$WF_SPECS_DONE/NNN-slug` (any digit count, same slug class), printing it repo-relative from relative or absolute input; it still refuses `done/` itself, `done/work-backlog` and deeper paths.
- [ ] `tests/scripts/check-write-paths.sh` and `tests/scripts/lib-workflow-paths.sh` pass; shellcheck clean.

**Predicted files:** `.agents/skills/feature-workflow/scripts/check-write.sh`

**Phase 1 tests:** `tests/scripts/check-write-paths.sh`, `tests/scripts/lib-workflow-paths.sh`

**Size:** S (1 file, about 40 changed lines; plus the shared-core change below, made by integration).

**Mode:** afk.

**Notes:** Shared-core change requested (`touches_core: true`, for integration at 3.2): in `.agents/lib/workflow-paths.sh`, add `WF_SPECS_DONE` (built from `WF_SPECS`, documented in the header's variable list) and extend `wf_norm_folder spec` to accept a direct child of `$WF_SPECS_DONE` named `NNN-slug` (the same `^[0-9]+-[A-Za-z0-9][A-Za-z0-9._-]*$` class). Contract for consumers: `move-to-done.sh` (T5) and `check-write.sh` build every Done folder path from `WF_SPECS_DONE`, never a literal (spec Constraints, TGT-004). The script callers of `wf_norm_folder spec` keep their behaviour for top-level specs. Data model migration M1.
