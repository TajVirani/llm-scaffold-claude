# T05: `move-to-done.sh` check, move and sweep

Index: [../tasks.md](../tasks.md) · Blocked by: T1 (Done folder path and write deny), T4 (Sign-off, discovery and large-path docs) · Parallel with: None

**What to build:** One script closes a finished spec into the Done folder. `--check` says whether the spec and every sub-item are finished. The move puts a `done` spec at `.workflow/specs/done/NNN-slug/`, and every link to it in `.workflow/` still resolves. `--sweep` moves every top-level `done` spec. Nothing changes when a check fails.

**Seam:** The `move-to-done.sh --check <spec-dir> | <spec-dir> | --sweep [--cwd <dir>]` CLI (stdout, stderr, exit code, resulting tree and commit), driven by `tests/scripts/move-to-done.sh` against the fixture project in `tests/fixtures/done-folder.sh`.

**Acceptance criteria:**

- [ ] `--check <spec-dir>` exits 0 when every task record is `done` or `split-out` and every work-backlog item whose `origin_spec` is this spec is `open`, `promoted`, `moved-to-deferred` or `dismissed`, whatever the spec's own status (5.7 runs it on an `in-review` spec, D8). Otherwise it exits 1 and names each open task (`T<n>` and status) and item, and changes no file (D4, D12). A spec with no `tasks.md` (none in this repo) passes the task half.
- [ ] `<spec-dir>` runs the check, refuses (exit 1, nothing changed) a spec whose status is not `done` or whose `done/NNN-slug` already exists, then moves the folder with plain `mv` (not `git mv`), deletes `.step`, and leaves `spec_branch` unchanged.
- [ ] The rewrite changes only the moved spec's path string, in `.workflow/` files (tracked and untracked, not ignored) outside `cache/` and `initiatives/`. The forms are `.workflow/specs/NNN-slug`, `../specs/NNN-slug`, `../../specs/NNN-slug`, `specs/NNN-slug`, and `../NNN-slug/` from `work-backlog/` or a sibling spec. It includes the moved spec's own files and its `pr-body.md` (D3, D10, D12, D14). It never rewrites a longer name that shares the prefix (`012-alpha` vs `012-alphabet`), and never a path already under `done/`.
- [ ] Inside the moved spec, every relative Markdown link that leaves the spec folder gets one more `../`; links inside the folder are unchanged; afterwards every such link resolves (D7).
- [ ] The move stages the old path, the new path and the rewritten files with `git add`, and commits on the current (spec) branch; it never commits to the main branch.
- [ ] `--sweep` moves every top-level `done` spec (any digit count), leaves `draft`/`in-progress`/`ready-for-dev` specs, `work-backlog/` and `done/` itself in place, and is a no-op on a second run. A done spec that fails the check is reported and left in place while the rest move.
- [ ] Usage: no argument, an unknown option, or a folder that is not a spec exits 2. The Done folder path comes from `WF_SPECS_DONE` (TGT-004). Bash 3.2, yq v4.
- [ ] Header block per the shell-scripts profile (File, Purpose, Usage, Exit, Called by: sign-off 5.7 and 5.8, large-path 6.13; Notes; Sources); a `PROVENANCE.md` row for the script (first-party).
- [ ] `tests/scripts/move-to-done.sh` passes (sweep-time TGT-007 is measured at 4.3); shellcheck clean.

**Predicted files:** `.agents/skills/feature-workflow/scripts/move-to-done.sh`, `PROVENANCE.md`

**Phase 1 tests:** `tests/scripts/move-to-done.sh`

**Size:** M (2 files, about 300 changed lines).

**Mode:** afk.

**Notes:** Data model migration M3 (the script). Reuse from `codebase-map.md` Module audit: the `commit-workflow-data.sh` skeleton and header, `wf_main_root`, `wf_path`, the `die`/exit-code style; the task-record read through `yq --front-matter=extract`; the backlog glob `work-backlog/<NNN-slug>-disc-*.md`; `git ls-files -c -o --exclude-standard` to list files without the ignored local state. `commit-workflow-data.sh` cannot commit the moved spec (it rejects `done/` and excludes `$WF_SPECS`), so stage explicitly. Nothing after the move may call a `wf_norm_folder` script on the old path. The sweep of this repo is not part of this task: it runs at sign-off 5.8 (D16). The 0.1.1 and `spec_done_on_main` cases in the suite read the snippets T4 writes.
