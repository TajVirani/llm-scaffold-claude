## Link to issue

No tracker issue yet: the workflow does not create one when a spec starts.

## What changed

- New PR template, `.agents/skills/feature-workflow/assets/pr-template.md`: ten fixed sections, each with guidance naming the evidence it is filled from.
- New `check-pr-body.sh`: checks a filled body. Workflow mode: the ten headings in order, none empty, `Risk: Low|Medium|High` and `Reversibility: Easy|Moderate|Hard|Irreversible`, and Irreversible needs Risk: High. Project mode (`--project-template <path>`): every heading `#` to `######` of the host template is present at the same level and non-empty.
- Sign-off: 5.4 fills and checks `pr-body.md` beside `report.md`; 5.5 asks a separate "Do you approve this PR description?"; 5.8 publishes the body unchanged through `gh pr create --body-file`, `glab mr create --description-file`, or a local `git merge --no-ff -F` whose message is the subject plus the body. 5.4 stops and asks when the template setting or the host template is unusable.
- New `pr_template` workflow setting, read by `rules-setting.sh`: `workflow` (default) or a repo-relative `.md` path to the project's host template, checked for shape and for the file in the main checkout.
- `project-setup` asks once which template to use when it creates `.workflow/rules.md` and finds a host template; sign-off 5.2 proposes a `pr_template` row when the key is unset and a host template exists.
- Tests: suites `scripts/check-pr-body` (47 cases) and `scripts/sign-off-pr` (30), `pr_template` cases in `scripts/task-breakdown`, fixture `tests/fixtures/pr-template.sh`.
- Workflow data applied at sign-off: capability CAP-006, the **Sign-off PR** glossary entry, the agent-docs profile `lint` key (adds `lint/step-list`), and three pitfalls.

## Why the change

- Before this, sign-off 5.8 opened the PR with a title and links only, and a local merge carried no message, so a reviewer had to open the spec folder to learn what the change was for.
- Every Sign-off PR now tells a reviewer, human or AI, what the change is for, the evidence that it works, what it could break and how to undo it.
- The stakeholder approves the exact text that ships, and a change whose undo steps cannot be written is flagged as Risk: High.

## Why this approach

- Placement: feature-workflow owns the template, the check script, the sign-off steps and the `rules-setting.sh` key; `project-setup` gains one setup question, which it may do because it may depend on feature-workflow. No placement ADR: easy to reverse, no real trade-off.
- Impact: two files created (the template and `check-pr-body.sh`); sign-off 5.2, 5.4, 5.5 and 5.8, `rules-setting.sh` and the project-setup flow extended; the report template, task PRs and `open-task-pr.sh` unchanged.
- Fill at 5.4 and approve at 5.5, rather than fill at 5.8, so the stakeholder signs off on the exact PR text and 5.8 only publishes it.
- The setting lives in the existing `## Workflow settings` block of `.workflow/rules.md` and holds the host template's path rather than a `project` flag, so 5.4 knows which headings to fill without searching.
- The body reaches the host through a file flag, never `gh --template` beside a body flag, which errors. The local merge uses `--cleanup=verbatim --no-edit` so the approved text survives exactly.
- A shape check in bash, with no new dependencies, matching the existing `check-*.sh` family.

## Special things to note

- Report: `.workflow/specs/done/008-pr-description-template/report.md`.
- Task PRs: none. `open-task-pr.sh` skipped every task because origin is a local path, neither GitHub nor GitLab, so tasks merged locally into the spec branch.
- `gh pr create --body-file` has not run against a live `gh` (not installed here); the 5.8 suite uses recording stand-ins for `gh` and `glab`, and this spec itself merges locally.
- Line coverage of the changed shell code is not measured: no bash coverage tool, and no new dependencies are allowed.
- A failed switch or merge in the 5.8 local merge leaves its message temp file in `$TMPDIR`.
- Drift between the text approved at 5.5 and the text published at 5.8 is not detected; 5.8 reruns only the shape check (a deliberate choice).
- `check-pr-body.sh` checks shape, not truth: filling from evidence rests on the template guidance and the 5.4 instructions.
- Deferred, each in its own shelf file: creating a tracker issue when a spec starts (`spec-issue-creation.md`), one home for workflow settings (`workflow-settings-home.md`), a filled description for the initiative PR (`initiative-pr-template.md`).

## How to test

1. Run `tests/run-all.sh`. Expected: it ends `TOTAL passed=3166 failed=0 skipped=0 xfail=0 (58 suites)`.
2. Run `tests/run-all.sh --suite scripts/check-pr-body`, then `--suite scripts/sign-off-pr`, then `--suite scripts/task-breakdown`. Expected: each reports `failed=0`.
3. Run `.agents/skills/feature-workflow/scripts/check-pr-body.sh .workflow/specs/done/008-pr-description-template/pr-body.md`. Expected: exit 0, no output.
4. Copy that body to a scratch file, change `Risk: Low` to `Risk: Severe`, and run the check on the copy. Expected: exit 1 and one line naming `Risk`.
5. Run `.agents/skills/feature-workflow/scripts/rules-setting.sh pr_template`. Expected: prints `workflow`, with a note on stderr that the default is used.
6. Run `git log -1 --format=%B` on the merge commit. Expected: the subject, a blank line, then this description verbatim.

## Blast radius

- Sign-off of every spec from now on: 5.2 may add a `pr_template` row, 5.4 writes and checks `pr-body.md`, 5.5 asks one more question, and 5.8's PR/MR and local merge carry the body (`modules/sign-off.md`, `SKILL.md`, `assets/design-log.md`).
- New files in feature-workflow: `assets/pr-template.md`, `scripts/check-pr-body.sh`; both installed into target projects through the existing `skills/feature-workflow/` manifest entry, and listed in `PROVENANCE.md`.
- `scripts/rules-setting.sh`: a new key; `task_review` and `main_branch` read as before, except that the outside-git message gains a prefix.
- `project-setup` (`SKILL.md`, `modules/files.md`, `assets/docs/rules.md`): one question, only when it creates rules.md and a host template exists. An existing rules.md is never touched.
- This repo's workflow data: `.workflow/GLOSSARY.md`, `capabilities.md`, `decisions/pitfalls.md`, `profiles/agent-docs.md`, and one line in `.workflow/deferred/comment-id-lint.md`.
- Untouched: task PR bodies and `open-task-pr.sh`, `assets/report.md`, the initiative PR, hooks, `install.sh`, and Phases 0-4.

## Risk and reversibility

Risk: Low - the change adds a sign-off step and a read-only check script; the worst case is a 5.4 that stops on a body fault or an unusable template, which the stakeholder resolves there, and the full harness passes.
Reversibility: Easy - reverting the merge commit restores the earlier sign-off; no data migrates, and a project that set `pr_template` keeps a key nothing reads.

## Areas, concepts and seams changed

- Interfaces whose shape changed: the 5.8 publish commands (now carry the body: `--body-file`, `--description-file`, `git merge -F`); `rules-setting.sh` gains the key `pr_template`; the design-log Sign-off entry gains a "PR description" line.
- New interfaces: `check-pr-body.sh <file> [--project-template <path>]` (exit 0 valid, 1 one `<field>: <problem>` line per fault, 2 usage or unusable template); the ten headings of `assets/pr-template.md`, which the check reads from the template itself.
- Modules: feature-workflow (sign-off, scripts, assets) and project-setup (setup files flow).
- Concepts: **Sign-off PR**, **PR template**, **Blast radius**.

## How to undo this PR

1. Revert the merge commit on the main branch: `git revert -m 1 <merge commit>`.
2. Run `tests/run-all.sh` and expect it to pass.
3. In any project that set `pr_template` under `## Workflow settings` in `.workflow/rules.md`, delete the line (optional: nothing reads it once reverted).
