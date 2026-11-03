# T06: Tracker setup

Index: [../tasks.md](../tasks.md) · Blocked by: T5 (Tracker script; both change `SKILL.md`) · Parallel with: None

**What to build:** `.agents/skills/issue-tracking/scripts/tracker-setup.sh [--cwd DIR] check|save` checks that the tracker can be used and saves the agreed **Issue flow**.

- `check` refuses with exit 1 and a named reason for each blocker: the CLI is missing, not logged in, issues are disabled on the project, or the CLI is older than the minimum (gh 2.94 for `--parent`, and the glab release with `issue update --description-file`). Otherwise it prints the host on its first line.
- `save --backlog L --in-progress L --done L [--create-labels]` writes `.workflow/issue-tracking.yaml` (`issue_tracker`, `issue_flow.backlog`, `issue_flow.in_progress`, `issue_flow.done`). When labels are missing it creates them only with `--create-labels`; without the flag it exits 1 naming them and writes nothing.
- `save --none` writes `issue_tracker: none`.

`SKILL.md` gets the setup section: run `check`, agree the three label names with the stakeholder, confirm creating missing ones, then `save`.

**Seam:** the `tracker-setup.sh` CLI against the fake CLIs, and the settings file it writes (`tests/scripts/issue-tracking-setup.sh`). Catches missing refusals, a file written on refusal and labels created without confirmation. It misses real CLI version strings beyond the fake's.

**Acceptance criteria:**

- [ ] JRN-010 step 1: CLI missing, not logged in and issues disabled each give a named refusal, and nothing is written.
- [ ] JRN-010 step 2: with all fine and two labels missing, `save` without `--create-labels` creates nothing and writes nothing; with it, the two labels are created and the settings file holds the host and the three labels.
- [ ] The settings file's `issue_tracker` matches the `origin` host.
- [ ] The suite ends with `shellcheck_files` over the script.

**Predicted files:** `.agents/skills/issue-tracking/scripts/tracker-setup.sh`, `.agents/skills/issue-tracking/SKILL.md`.

**Phase 1 tests:** `tests/scripts/issue-tracking-setup.sh`.

**Size:** M (2 files, about 200 changed lines).

**Mode:** afk.

**Notes:** Uses the T1 host choice and the T3 `WF_` settings path. Data model § Tracker settings: the three labels are required whenever the host is not `none`, and each is distinct.
