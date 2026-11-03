# T02: Tracker link keys

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** A spec and its tasks can record their **Tracker issue**. The spec template gains the frontmatter key `tracker_issue` (`""` or an `https://` URL) and a Links line. The task record gains `issue` (null or an `https://` URL), and the task file template gains a link line. `status-transition.sh set-task <spec-dir> T<n> --issue <url>|null` writes `issue` the way `--pr` writes `pr`, but a value that is not a URL exits 2. Both validators accept the new keys, and older files without them stay valid.

**Seam:** the `status-transition.sh set-task` CLI and the yq validators in `assets/spec.md` and `assets/tasks.md`, driven by `tests/scripts/status-transition-tasks.sh`. Catches writer and validator drift. It misses the step files that call `set-task --issue`, which T10 covers.

**Acceptance criteria:**

- [ ] `set-task --issue <https url>` records it, and the record passes `TASKS_VALIDATOR`.
- [ ] `set-task --issue null` clears it; a non-URL is refused with exit 2 and nothing is written.
- [ ] `TASKS_VALIDATOR` in `status-transition.sh` stays byte-identical to the validator in `assets/tasks.md`, and both check `issue` like `pr`.
- [ ] The spec validator in `assets/spec.md` checks `tracker_issue` as `""` or an `https://` URL when present, keeping the line shape that `tests/lint/small-path-docs.sh` and `tests/scripts/initiative-emission.sh` extract with awk.
- [ ] `assets/spec.md` documents `tracker_issue` and its Links line; `assets/task.md` documents the issue link line. The "Add no other keys" notes name the new keys.

**Predicted files:** `.agents/skills/feature-workflow/scripts/status-transition.sh`, `.agents/skills/feature-workflow/assets/tasks.md`, `.agents/skills/feature-workflow/assets/spec.md`, `.agents/skills/feature-workflow/assets/task.md`.

**Phase 1 tests:** `tests/scripts/status-transition-tasks.sh` (the JRN-006 `set-task --issue` tests).

**Size:** S (4 files, about 80 changed lines).

**Mode:** afk.

**Notes:** Migration M1 from data-model.md: an absent key reads as no tracker.
