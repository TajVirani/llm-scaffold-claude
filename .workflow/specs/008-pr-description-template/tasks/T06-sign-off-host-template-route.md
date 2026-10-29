# T06: Sign-off routes an unusable host template and points at one path list

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** At 5.4, when `check-pr-body.sh` exits 2 on the host template (unreadable, or no headings), sign-off stops and asks as for a failing setting: the workflow template for this PR, or a fixed path through a `pr_template` proposal at 5.2/5.3 (D20). Sign-off 5.2 takes the host template locations from project-setup's one list instead of spelling them out (F2).

**Seam:** Text checks of `modules/sign-off.md` and `project-setup/modules/files.md` in `tests/scripts/sign-off-pr.sh` (`JRN-006` cases).

**Acceptance criteria:**

- [ ] One paragraph of 5.4 holds the exit-2 handling and both choices: it names "exit 2", `pr_template` or "host template", "stop", "workflow template" and "5.2" (the test reads them per paragraph). Today's "broken install: stop and report" wording no longer applies to the host template.
- [ ] 5.2 names none of `pull_request_template.md`, `PULL_REQUEST_TEMPLATE`, `merge_request_templates`, and points at `.agents/skills/project-setup/modules/files.md` for the locations.
- [ ] The 5.8 publish block and every other JRN-005/JRN-006 case still pass; `tests/scripts/sign-off-pr.sh` passes (30 cases); agent-docs lint suites pass, `lint/step-list` included.

**Predicted files:** `.agents/skills/feature-workflow/modules/sign-off.md`

**Phase 1 tests:** `tests/scripts/sign-off-pr.sh`

**Size:** S (1 file, about 15 changed lines).

**Mode:** afk.

**Notes:** Triage pass 1 F4 (D20) and F2. feature-workflow may depend on project-setup (`.workflow/rules.md` Ownership). The suite selector is the same one T4 (done) lists.
