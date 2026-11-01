# T04: The initiative single writer

Index: [../tasks.md](../tasks.md) · Blocked by: T3 Templates admit initiatives; T9 The large-path module and its entry points · Parallel with: None

**What to build:** `initiative-transition.sh`, the one writer of an initiative's status, step marker, slice records, question records and PR URL, replacing the Phase 1 stub. A stakeholder's session calls it at every large-path step that changes state; nothing else writes `initiative.md`'s frontmatter or `.step`. It mirrors `status-transition.sh`: same exit contract (0 done, 1 environment error, 2 illegal transition with the reason on stderr), same `.step` format (`step`, `updated_at`), same validate-then-move write, and it never calls the spec writer or is called by it.

**Seam:** The script's command line as `data-model.md` fixes it (`status`, `step`, `set-slice`, `set-question`, `set-pr`), its exit code and stderr, and the `initiative.md`, `questions.md` and `.step` it writes, read back with `yq --front-matter=extract`.

**Acceptance criteria:**

- [ ] `status <dir> exploring|planned|done [--step <6.x>]`: the only legal moves are (none) → `exploring` (folder exists, no `initiative.md` status yet, or the template status), `exploring` → `planned` only when every slice is `emitted` or `done` and no question is `open` or `researching`, `planned` → `exploring` (reopen), `planned` → `done` only when every slice is `done`; `done` is terminal and every later subcommand exits 2. Any other pair exits 2 with the reason.
- [ ] `step <dir> <6.x>` writes `.step` in the spec marker's format, in the main checkout, and accepts a folder that has no `initiative.md` yet (the pre-file idiom); a non-`6.x` id exits 2.
- [ ] `set-slice <dir> S<n> [--status planned|emitted|done] [--spec <NNN-slug>]`: `planned` → `emitted` requires every question in the slice's `questions` to be `settled` and `--spec`; `emitted` → `done` is allowed; `emitted` with `spec: null` and `planned` with a non-null `spec` are refused; an unknown slice id exits 1.
- [ ] `set-question <dir> IQ<n> [--state open|researching|settled] [--settled <text>] [--launched <task_type>|clear]`: `open` → `researching` only for `kind: research` and writes `launched: {task_type, at}`; `researching` → `settled` and `open` → `settled` require `--settled`; `researching` → `open` clears `launched`; a `decision` in `researching`, `settled` without a settled line, or an unknown id are refused (2 for an illegal transition, 1 for an unknown id, as the spec writer does).
- [ ] `set-pr <dir> <url>|null` writes `merge_pr`, accepts only `^https?://[^[:space:]]+$` or `null`, exits 1 otherwise, and is refused after `done`.
- [ ] Every write passes the template validators (T3) before it lands; on a validator failure nothing is written and the exit is 2.
- [ ] `<dir>` is `.workflow/initiatives/NNN-slug` relative to the project root or absolute; the initiatives root comes from `WF_INITIATIVES` in `workflow-paths.sh`, never spelled out; the script resolves the main checkout from `--cwd` as the spec writer does.
- [ ] `tests/scripts/initiative-emission.sh` passes; the JRN-002 transition and `set-pr` cases in `tests/scripts/initiative-transition.sh` pass (the suite's resume-offer cases need T6 and are owned there).

**Predicted files:** `.agents/skills/feature-workflow/scripts/initiative-transition.sh`.

**Phase 1 tests:** `tests/scripts/initiative-emission.sh`.

**Size:** M (1 file, about 380 changed lines).

**Mode:** afk.

**Notes:** Carries the script half of migration M4 (D7, D9, D32). Model it on `status-transition.sh`: `die`/`illegal`, `in_list`, `valid_node`, `require_yq`, `main_root`, `need_step`, the `case "$CUR>$NEW"` table, `yq --front-matter=process -i` and validate-then-`mv`; the project convention copies these helpers per script and sources only `workflow-paths.sh`. The `6.x` ids `status` and `step` accept are whatever `steps.tsv` will hold after T2; validate the shape (`6.<n>`), not the list, so T4 does not wait for T2. The exit-1 cases (`--settled` text missing with `--state settled`, bad URL, unknown id) follow the fixture's expectations in `tests/fixtures/initiative.sh` and `tests/scripts/initiative-transition.sh`.
