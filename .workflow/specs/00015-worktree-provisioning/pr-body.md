## Link to issue

No tracker issue yet: the workflow does not create one when a spec starts.

## What changed

- A new script, `worktree-setup.sh`, creates every agent worktree and scratch worktree and sets up every spec worktree. Setup gives the spec a slot, copies the gitignored files the project lists in `.worktreeinclude` from the main checkout as real files, runs the project's `worktree_setup` command, and refuses a symlink that reaches back into the main checkout or another worktree.
- Three new workflow settings in `.workflow/rules.md`: `worktree_setup`, `services_up` and `services_down`. Each is one shell command and defaults to empty.
- The project's commands receive five isolation values: `WF_SLOT`, `WF_INSTANCE`, `WF_PORT_OFFSET` (slot × 100), `WF_MAIN_ROOT` and `WF_SPEC_ROOT`. The project turns them into ports, container names and database names.
- `run-toolchain.sh` runs the link check first, hands every key the isolation values, and runs `services_up` once before the first `test` or `e2e` key that will run.
- `spec-worktree.sh create` sets the spec worktree up, also on a re-run; `remove` runs `services_down`.
- The step files, the launching reference and the agent definitions call the script. No document tells a reader to run a raw `git worktree add` or `git worktree remove`, and the coding agents are told never to install, copy or link anything into a worktree by hand.
- `project-setup` and the standards interview ask a project for its setup command, copy list and service commands, and say that tests use a throwaway database.
- `install.sh` ignores the slot file (`.workflow/.slot`), and the host settings allow `worktree-setup.sh` in place of `git worktree add`.
- A project that declares nothing behaves as before.

## Why the change

- The workflow created worktrees with a plain `git worktree add` and never set them up, so each one started without the project's dependencies, its gitignored config or a running environment.
- Agents improvised. In a live project one agent copied the main checkout's `.env`, the orchestrator symlinked it, the symlink made the worktree write guard block an edit, and the run stopped to ask the stakeholder.
- The worktree ran the app on the main checkout's ports and shared database containers, so the stakeholder was asked to start and restart environments, and a test run damaged the shared dev database.
- A worktree must be a self-contained place to build and test a spec, set up without asking, that cannot collide with the main checkout or another spec.

## Why this approach

- The owning module is feature-workflow: it already owns `spec-worktree.sh`, `run-toolchain.sh` and the settings reader, and the step files that created worktrees by hand.
- One script, not prose repeated in five step files: the worktree lifecycle was split between one script and hand-run commands, which is where the improvising came from.
- The scaffold sets nothing project-specific. It hands the project's own commands a slot, an instance name and a port offset; a container or virtual machine per worktree was ruled out as far more than the problem needs.
- Copies, never links, and only files the project already ignores, so a copy can never be committed or block removing the worktree. The link check makes the old symlink failure loud instead of silent.
- Commands live in the Workflow settings block of `.workflow/rules.md`, not in the work profiles, because they belong to the project, not to one work type. The copy list is its own file because the settings reader takes scalars only.
- Created: the script, the slot, the copy list, the isolation values. Extended: the settings reader, `spec-worktree.sh`, `run-toolchain.sh`, the installer's ignore list, project-setup and project-standards. Refactored: the step files and agent definitions. Unchanged: the worktree write guard.

## Special things to note

- Report: [report.md](.workflow/specs/00015-worktree-provisioning/report.md). Tasks were merged locally with no task PRs, by the stakeholder's ruling for this spec.
- Proven in fixture projects only. No project that declares a setup command and services has run a spec through it yet; the first such run is the real test of the success signal.
- This repo declares no setup command, copy list or services, so its own use of the script exercises the nothing-declared path.
- A stop audit on a worktree holding a link into the main checkout may block the same stop three times before giving up. Not proven; a fixture run would settle it.
- Two spec worktrees created at the same instant may take the same slot. Accepted: it shows at once as a port already in use.
- `worktree-setup.sh` and `spec-worktree.sh` drop the settings reader's error text and stop with a generic message.
- `run-toolchain.sh` now exits 2 for a folder that is neither the main checkout nor a spec worktree nor inside one.
- The implementation-resume load is a few bytes under its 55,000-byte lint limit after this change.
- Deferred: [rules-setting-usage-exit-code](.workflow/deferred/rules-setting-usage-exit-code.md), the settings reader's usage exit code.

## How to test

1. Run `tests/run-all.sh`. Expected: `TOTAL passed=4860 failed=0`, 79 suites.
2. Run `tests/run-all.sh --suite scripts/worktree-setup`. Expected: 60 passed, 0 failed.
3. Run `tests/run-all.sh --suite lint/worktree-setup-docs`. Expected: 40 passed, 0 failed.
4. In a throwaway project with the scaffold installed, put `worktree_setup: "touch .setup-ran"` in the Workflow settings block of `.workflow/rules.md`, add `.env` to `.gitignore` and to `.worktreeinclude`, create a `.env`, then create a spec worktree. Expected: the worktree holds `.env` as a regular file and `.setup-ran`.

## Blast radius

- 36 reviewed files, tests apart: three scripts changed and one new under `.agents/skills/feature-workflow/scripts/`, two constants in `.agents/lib/workflow-paths.sh`, six step files and the launching reference, seven agent definitions, five project-setup files, the standards coverage list, `install.sh`, `.gitignore`, the two Claude settings files and the root documents.
- Every spec, every task launch and every toolchain run goes through the changed scripts. With nothing declared they add one link check and one read of the isolation values per toolchain run.
- A target project picks the change up at its next install or upgrade: one new `.gitignore` line, and an allow rule for the script.
- Untouched: the worktree write guard and its scope check, the status and task-record scripts, the tracker scripts, and every target project's own files.

## Risk and reversibility

Risk: Medium - every worktree and toolchain run now passes through new code, and it is proven in fixtures, not yet in a project that declares a setup; a fault would stop a run loudly, not corrupt work.
Reversibility: Easy - revert the merge commit; no data is migrated, and the only state left behind is a gitignored one-line slot file in each spec worktree.

## Areas, concepts and seams changed

- Interfaces whose shape changed: `run-toolchain.sh` (a link check before any key, a `services_up` entry in the evidence, exit 2 for a folder outside the repository's checkouts); `spec-worktree.sh create` (runs setup, exits 1 when it fails) and `remove` (runs `services_down`); `rules-setting.sh` (three new keys).
- New interface: `worktree-setup.sh agent | scratch | setup | check | env | remove`.
- Modules: feature-workflow, lib (shared core, through the integration agent), agents, project-setup, project-standards, installer, root-docs, tests.
- Glossary: the new term Worktree setup; Spec worktree, Agent worktree and scratch worktree keep their meaning.
- New files a project may own: `.worktreeinclude` (tracked) and `.workflow/.slot` (gitignored).

## How to undo this PR

Revert the merge commit on `main`. No data is migrated, so nothing needs restoring. A project that declared the new settings or a `.worktreeinclude` can leave them in place; after the revert nothing reads them. Delete any `.workflow/.slot` files left in spec worktrees, or leave them: they are gitignored.
