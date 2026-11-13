# Design log: Worktree provisioning

Spec: [spec.md](spec.md)

## 2026-11-12 Assumed: name for the step that creates and readies a worktree

- Step: 0.2.2
- Question: What is the canonical term for the scripted step that creates a spec worktree or agent worktree and makes it ready to run and test? Options: Worktree setup · Worktree provisioning · Worktree bootstrap.
- Answer taken: **Worktree setup**, written to [.workflow/GLOSSARY.md](../../GLOSSARY.md) at 0.2.3.
- Why safe to assume: neither the glossary nor the code holds a competing term; "bootstrap" already names the greenfield bootstrap order. A veto is a rename of one glossary entry and the spec's files.

## 2026-11-12 Assumed: owning module for worktree setup

- Step: 0.3.4
- Question: The change touches several modules (feature-workflow, lib, hooks, agents, project-setup, project-standards, installer, tests, root-docs). Which one owns worktree setup? Options: feature-workflow · lib · a new module.
- Answer taken: **feature-workflow** owns it. The new script sits beside `spec-worktree.sh` in `.agents/skills/feature-workflow/scripts/`; path constants go in `.agents/lib/workflow-paths.sh`; the other modules get only the edits that call or describe it. No ADR conflict (no ADR covers worktrees, [codebase-map.md](codebase-map.md) § Prior decisions), and no placement ADR: the placement is easy to reverse, so it fails the three-part test.
- Why safe to assume: `spec-worktree.sh` and every `git worktree add` call site already live in feature-workflow. A veto moves one script.

## 2026-11-12 Deeper prompt

**What this changes:** Every spec worktree and agent worktree is created by one script that also makes it ready to run and test: dependencies installed, gitignored config copied in, and its own ports and service names set. The workflow starts and stops the services a test run needs.

**Why:** Worktrees start bare today, so agents improvise with copies and symlinks into the main checkout, share the main checkout's ports and databases, and stop to ask the stakeholder to start environments.

**Ask:** Make a worktree a self-contained place to build and test a spec, set up by the workflow without asking, that cannot collide with the main checkout or with another spec.

**Goals:**
- A new spec worktree or agent worktree can run the profile's `test` command straight after creation, with no step taken by an agent or the stakeholder.
- No file in a worktree is a symlink into the main checkout or another worktree; a check fails when one is.
- Two specs can run their app and services at the same time without sharing a port, a container or a database.
- The orchestrator never asks the stakeholder to start, restart or stop an environment; services come up before a test or browser run and go down at sign-off.
- A project with no setup declared behaves as it does today.

**Downstream:** asked in the first questioning ask

**Tools and technologies:** asked in the first questioning ask

**Gotchas:** asked in the first questioning ask

**Not asked for:** changes to the Athena repo (its ports, Taskfile and `.env` stay as they are); a container or VM per worktree; fixing a project's tests that write to its dev database (the scaffold gives guidance only).

**Original request:** "We keep running into weird work tree problems where files are being linked out to main, then causing problems. I am constantly being asked to run environments so it do tests when that should be automatic (whole reason we run in work trees). Worktree should have everything it needs to run and test and shouldn't colide with other work." … "Fix the issues within this project, don't touch athena"

Revisions: first restatement.

Agreement: pending, asked in the first questioning ask

## 2026-11-12 Assumed: where a project declares its worktree setup

- Step: 0.3.8
- Question: Where does a project say how to set up a worktree and run its services? Options: project-wide, in `.workflow/rules.md` § Workflow settings plus a copy list file · per work type, as Toolchain keys in each work profile.
- Answer taken: project-wide. Workflow settings gain `worktree_setup`, `services_up` and `services_down` (one command each, `""` by default); the files to copy are listed one pattern per line in `.worktreeinclude` at the repo root, and only gitignored files that match are copied.
- Why safe to assume: a worktree is set up once for the whole checkout, not once per work type, and `rules-setting.sh` already reads project-wide settings ([codebase-map.md](codebase-map.md) § Relevant code). A veto moves three keys.

## 2026-11-12 Assumed: when services start and stop

- Step: 0.3.8
- Question: Who starts and stops the services a test run needs, and when? Options: `run-toolchain.sh` runs `services_up` before `test` and `--e2e`, sign-off 5.8 runs `services_down` · the orchestrator runs them as named steps · each agent worktree gets its own services.
- Answer taken: `run-toolchain.sh` runs `services_up` before `test` and `--e2e` whenever it is set, so the command must be safe to run twice. Services belong to the spec, not to each agent worktree: an agent worktree gets the same isolation values and reaches the spec's services. `spec-worktree.sh remove` (5.8) runs `services_down`. A failing `services_up` fails the gate with its output; nobody is asked to start anything.
- Why safe to assume: it is the smallest change that removes the ask, and one stack per spec keeps the cost of a wave flat. A veto changes where two commands are called from.

## 2026-11-12 Assumed: the isolation values

- Step: 0.3.8
- Question: What does a spec get to keep its app and services apart from other work? Options: a slot number taken when the spec worktree is created · values computed from the spec number.
- Answer taken: a slot. Creating the spec worktree takes the lowest free slot from 1 up and records it in the spec worktree; removing it frees the slot. Every setup, service and toolchain command runs with `WF_SLOT` (the number), `WF_INSTANCE` (`s<NNN>`, a name fit for a compose project) and `WF_PORT_OFFSET` (slot × 100) in its environment. The main checkout is slot 0. The project's own commands turn these into ports and names; the scaffold sets nothing project-specific.
- Why safe to assume: slots stay small and never collide, where a number computed from a five-digit spec number can. A veto changes one function.

## 2026-11-12 Assumed: what the symlink check refuses

- Step: 0.3.8
- Question: Which symlinks fail the check? Options: any symlink that resolves outside the worktree · only one that resolves into the main checkout or another worktree of the same repository.
- Answer taken: the second. The check runs at the end of worktree setup and at the start of `run-toolchain.sh`, and fails naming each link. A link to a system path (a Python venv's interpreter, a package cache) passes.
- Why safe to assume: the harm seen was a link into the main checkout; refusing every outside link would fail ordinary dependency folders. A veto tightens one test.

## 2026-11-12 Assumed: setup failures, projects with no setup, and what agents are told

- Step: 0.3.8
- Question: What happens when setup fails, when a project declares none, and when an agent finds its worktree is missing something?
- Answer taken: a failing `worktree_setup` exits non-zero with the command's output and the orchestrator stops and reports it; it never falls back to a bare worktree. With no setting and no `.worktreeinclude`, the script only adds the worktree, as today. The agent definitions and step files say: never install, copy or link anything into a worktree by hand; a worktree that cannot run its tests is reported as a setup gap. `project-setup` asks for the three commands and the copy list, and the profile template says tests use a throwaway database, never the dev one.
- Why safe to assume: each follows from the goals in the deeper prompt and none changes scope. A veto is a wording change.

## 2026-11-12 Questioning round 1

- Offered for veto: name for the step that creates and readies a worktree, owning module for worktree setup, where a project declares its worktree setup, when services start and stop, the isolation values, what the symlink check refuses, setup failures, projects with no setup, and what agents are told; vetoed: none

**Q1. Pass the deeper prompt on as written?**

- Options: Yes · Change it
- Recommended: Yes
- Answer: "Recomended all looks good."
- Decision: D1. The deeper prompt stands as written.

**Q2. Downstream: will other features be built on this one?**

- Recommended: none
- Answer: "Recomended all looks good."
- Decision: D2. None known.

**Q3. Tools and technologies: anything to use or avoid?**

- Recommended: none (bash 3.2, git and yq, as the scaffold already uses)
- Answer: "Recomended all looks good."
- Decision: D3. No preference beyond what the scaffold already uses.

**Q4. Gotchas: anything already known to bite?**

- Recommended: none
- Answer: "Recomended all looks good."
- Decision: D4. None known.

**Q5. Keep the assumptions?**

- Recommended: keep them all
- Answer: "Recomended all looks good."
- Decision: D5. All seven Assumed entries above stand.

**Q6. Do scratch worktrees (a reviewer's probe, the orchestrator's rerun at an older commit, the 1.4 known-bad build) go through the same setup?**

- Why now: the setup script and its copy list are settled (D5).
- Options: Yes, dependencies and config, no services · No, they stay bare
- Recommended: Yes, because a rerun of the test suite at an older commit needs the same dependencies and config.
- Answer: "Recomended all looks good."
- Decision: D6. Scratch worktrees are created through worktree setup: dependencies and config, the spec's isolation values, no services of their own.

**Q7. Summary: one script creates every spec, agent and scratch worktree, copies the listed gitignored files, sets the slot values, runs the project's setup command and refuses links back into the main checkout; `run-toolchain.sh` brings services up before tests; sign-off takes them down. Right?**

- Recommended: yes
- Answer: "Recomended all looks good."
- Decision: D7. Confirmed as the settled design, one feature.

Facts looked up instead of asked: the module audit in [codebase-map.md](codebase-map.md) § Module audit. Three follow from it and bind the build: setup also runs on the `create` re-run path; everything setup writes must be gitignored, since `remove` refuses untracked files; services start only for keys that will run, and stop on every exit path of the run that started them unless the spec keeps them up.

## 2026-11-12 Deeper prompt

**What this changes:** Every spec worktree and agent worktree is created by one script that also makes it ready to run and test: dependencies installed, gitignored config copied in, and its own ports and service names set. The workflow starts and stops the services a test run needs.

**Why:** Worktrees start bare today, so agents improvise with copies and symlinks into the main checkout, share the main checkout's ports and databases, and stop to ask the stakeholder to start environments.

**Ask:** Make a worktree a self-contained place to build and test a spec, set up by the workflow without asking, that cannot collide with the main checkout or with another spec.

**Goals:**
- A new spec worktree or agent worktree can run the profile's `test` command straight after creation, with no step taken by an agent or the stakeholder.
- No file in a worktree is a symlink into the main checkout or another worktree; a check fails when one is.
- Two specs can run their app and services at the same time without sharing a port, a container or a database.
- The orchestrator never asks the stakeholder to start, restart or stop an environment; services come up before a test or browser run and go down at sign-off.
- A project with no setup declared behaves as it does today.

**Downstream:** none known

**Tools and technologies:** no preference; bash 3.2, git and yq as the scaffold already uses

**Gotchas:** none known

**Not asked for:** changes to the Athena repo (its ports, Taskfile and `.env` stay as they are); a container or VM per worktree; fixing a project's tests that write to its dev database (the scaffold gives guidance only).

**Original request:** "We keep running into weird work tree problems where files are being linked out to main, then causing problems. I am constantly being asked to run environments so it do tests when that should be automatic (whole reason we run in work trees). Worktree should have everything it needs to run and test and shouldn't colide with other work." … "Fix the issues within this project, don't touch athena"

Revisions: first restatement.

Agreement: agreed in Questioning round 1

## 2026-11-12 Scope decision: usage exit code of the settings reader

- Item: the module audit noticed that `rules-setting.sh` exits 1 for a usage error while sibling scripts exit 2 (decision; evidence `scripts/rules-setting.sh:33-34,49`).
- Ruling: deferred, because changing an exit code is a contract change for every caller of the settings reader, outside a spec about setting up worktrees. The new settings keys inherit exit 1.
- Handoff: [.workflow/deferred/rules-setting-usage-exit-code.md](../../deferred/rules-setting-usage-exit-code.md) (HITL), also listed in spec.md `deferred`

## 2026-11-12 Scope decision: the 3.10 browser run starts nothing

- Item: the module audit noticed that 3.10 runs `run-toolchain.sh --e2e` with no app start, while 1.4 and `review-targets` start `serve` (bug; evidence `modules/implementation-finish.md:7`).
- Ruling: in scope, not deferred: the goal "the orchestrator never asks the stakeholder to start an environment" covers it. `run-toolchain.sh` runs `services_up` before `--e2e`, and a project whose browser suite needs the app running starts it there.

## 2026-11-12 Impact classification

| Part | Classification | Note |
| --- | --- | --- |
| `worktree-setup.sh` | create | The one script that creates, sets up, checks and removes agent and scratch worktrees and sets up a spec worktree; see data-model.md § Interfaces |
| Slot | create | A spec's number for keeping its app and services apart; see data-model.md § Slot |
| `.worktreeinclude` | create | The project's list of gitignored files to copy; see data-model.md § Copy list |
| Workflow settings `worktree_setup`, `services_up`, `services_down` | extend | Three new keys read by `rules-setting.sh`; see data-model.md § Workflow settings |
| `spec-worktree.sh` | extend | `create` runs worktree setup, on the re-run path too; `remove` runs `services_down` and frees the slot |
| `run-toolchain.sh` | extend | Symlink check first; isolation values exported to every key; `services_up` before a `test` or `e2e` that will run |
| Step files and agent definitions | refactor | Raw `git worktree add` and `remove` prose replaced by calls to the script; agents told never to set up by hand |
| `project-setup`, `project-standards`, profile template | extend | Ask for and document the settings, the copy list and the throwaway-database rule |
| `install.sh` `GI_ENTRIES`, `.gitignore`, install manifest, Claude settings template | extend | The slot file is ignored; the new script is installed and allowed |
| `check-worktree-scope.sh`, `worktree-write-guard.sh` | unchanged | The guard's path rule stays as it is |

## 2026-11-12 Assumed: the seam each task is tested at

- Step: 2.1
- Question: Which public interface do each task's tests drive?
- Answer taken:
  - T1 settings keys: the `rules-setting.sh <key>` command line. Catches a wrong default or a rejected value; misses how callers use the value.
  - T2 worktree setup script: the `worktree-setup.sh` command line in a throwaway repository. Catches wrong files, slots, links and exit codes; misses a real project's setup command.
  - T3 spec worktree: the `spec-worktree.sh create` and `remove` command line. Catches a skipped setup, changed stdout and a missed `services_down`; misses the step files that call it.
  - T4 toolchain run: the `run-toolchain.sh` command line and its evidence files. Catches a missing link check, missing isolation values and a wrong `services_up` call; misses the stop-audit hook that calls it.
  - T5 install: `install.sh` run against a fixture target, and the settings templates read as data. Catches a missing ignore line or allow rule; misses a live host.
  - T6 to T10 documents: the lint suites over the document text. They catch a raw worktree command or a missing rule; they miss whether an agent follows the text.
- Why safe to assume: each is an existing seam with an existing suite, and the highest one that reaches the behaviour. A veto moves a task's tests before any is written.

## 2026-11-12 Assumed: targets that are not measured

- Step: 1.1
- Question: What threshold do the performance and line-coverage targets take?
- Answer taken: neither is measured. The cost of setup with nothing declared is one `git worktree add` and three file checks, proven unchanged by JRN-002; no bash coverage tool is installed, so the script-coverage target stands in, as in earlier specs.
- Why safe to assume: neither changes what is built. A veto adds a row to the Targets table.

## 2026-11-12 Phase 1 notes

- 1.2 discovered-work report (requirement, can-wait): `tests/lint/agent-worktree-docs.sh:97-110` expects the raw worktree add and remove wording that JRN-008 removes. Assessed as current work, not outside the scope: the task that rewrites the step files (T6) updates those checks in the same change.
- 1.3 not run: no `e2e-browser` profile; every journey is a harness suite.
- 1.4: the merged suites are red on the known-bad build, 72 new failures, all assertions ([record.md](artifacts/phase-1-known-bad/record.md)).

## 2026-11-12 Breakdown quiz

- Asked at: 1.2, beside the harness build
- Slices: approved as shown: "Questions look fine"
- Edges, parallel_with and hitl modes: approved; no `parallel_with`, no `hitl` task
- Offered for veto: "the seam each task is tested at", "targets that are not measured"; vetoed: none
- Size: over (10 tasks, 37 predicted files against 10 / 30): kept as one spec, budget raised to max_tasks 10, max_changed_files 37
- Decision: **D8** ten tasks in four waves, the setup script kept as one large task, built as one spec

## 2026-11-12 Assumed: the breakdown follows the Phase 1 suites

- Step: 2.5
- Question: A Phase 1 test is a whole suite and belongs to one task. Three suites need more than one of the approved tasks to pass. Which task owns each, and what changes?
- Answer taken: nine tasks in four waves, the same work and the same files as D8.
  - `tests/scripts/worktree-setup.sh` and `tests/scripts/spec-worktree.sh` both create a spec worktree through `spec-worktree.sh create`, so the setup script cannot pass its own suite without that change. The spec-worktree task folds into the setup script task (T3).
  - The suites check that setup leaves `git status` empty, reading the ignore lines from `install.sh`. The install task (T2) therefore moves to wave 1, before the setup script, and carries the shared-core request for the two path constants.
  - `tests/lint/worktree-setup-docs.sh` covers the step files and the agent definitions. The agent-definitions task (T8) owns it and runs after the step-files task (T5).
  - `tests/scripts/run-toolchain.sh` goes to the toolchain task (T4), which runs after T3.
  - `.codex/README.md` names the raw worktree command; the root-docs task (T9) updates it.
- Why safe to assume: no work is added or dropped and no decision changes; only the order and the grouping follow from how the suites were cut. A veto regroups the task files before any is launched.
