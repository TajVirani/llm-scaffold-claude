# T03: Settings deny in-place frontmatter extract

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** A Claude session in an installed project, and in this repo, cannot run `yq --front-matter=extract` with an in-place flag. Add four rules at the top of the `permissions.deny` array of `.agents/hooks/claude-settings.template.json` and of `.claude/settings.json`: `Bash(yq *--front-matter=extract* -i*)`, `Bash(yq *-i* --front-matter=extract*)`, `Bash(yq *--front-matter=extract* --inplace*)`, `Bash(yq *--inplace* --front-matter=extract*)`. Keep the existing deny entries and the `Bash(yq --front-matter=extract:*)` allow entry. Document the rules and their reason (a deny is checked before an allow, so reads still pass while an in-place extract that truncates the file to its frontmatter is refused; text matching, so other spellings such as `-Pi` are not covered) in the permission section of `claude-settings.template.md`.

**Seam:** the settings JSON files and `install.sh --host claude`'s merged `.claude/settings.json` in a target; tests read the files with jq and run the installer into fixture targets.

**Acceptance criteria:**

- [ ] Each of the two settings files holds the four rules once, first in its deny array, and no other `--front-matter=extract` deny entry.
- [ ] The template's other deny entries equal those on `main`, in order; template line 148 is unchanged.
- [ ] `install.sh` into an empty target and over a target with a user deny entry, then a re-run, leaves each rule and the user entry exactly once, exit 0 (JRN-007).
- [ ] `claude-settings.template.md` describes the four rules and why.
- [ ] `tests/scripts/install-claude-settings.sh` passes in full.

**Predicted files:** `.agents/hooks/claude-settings.template.json`, `.agents/hooks/claude-settings.template.md`, `.claude/settings.json`

**Phase 1 tests:** `tests/scripts/install-claude-settings.sh`

**Size:** S (3 files, about 20 changed lines).

**Mode:** afk.

**Notes:** Spec 007 edits template line 148 (a deny entry) in parallel: insert the new rules directly after the `"deny": [` line and touch no other deny line. No `install.sh` change: it already unions `permissions.deny`.
