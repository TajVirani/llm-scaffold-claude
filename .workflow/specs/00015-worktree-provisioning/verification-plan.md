# Verification plan: Worktree provisioning

Spec: [spec.md](spec.md)

## End state

- [ ] CAP-NEW-worktree-setup: in a fixture project that declares a setup command and a copy list, a new spec worktree and a new agent worktree each hold the listed gitignored file as a regular file with the main checkout's content, and the setup command has run there with the spec's isolation values.
- [ ] CAP-NEW-worktree-setup: in a fixture project that declares nothing, creating a spec worktree and an agent worktree leaves the same files and prints the same stdout as before this change.
- [ ] CAP-NEW-worktree-setup: a symlink in a worktree that resolves into the main checkout makes both worktree setup and `run-toolchain.sh` exit non-zero and name the link; a link to a path outside the repository passes.
- [ ] CAP-NEW-worktree-setup: two spec worktrees of one repository hold different slots, and a spec worktree created after one is removed takes the freed slot.
- [ ] CAP-NEW-worktree-setup: `run-toolchain.sh` runs `services_up` with the isolation values before `test` and before `e2e`, runs it for neither when both are skipped or served from reuse, and fails the run when it fails; `spec-worktree.sh remove` runs `services_down`.
- [ ] CAP-NEW-worktree-setup: a failing setup command makes creation exit non-zero with the command's output, and running creation again after the command is fixed finishes the setup.
- [ ] CAP-NEW-worktree-setup: a scratch worktree is set up with the copy list and the setup command and the spec's slot.
- [ ] CAP-NEW-worktree-setup: no step file, launching reference or agent definition tells a reader to run a raw `git worktree add` or `git worktree remove`; the coding agents' definitions say never to install, copy or link by hand.

## Journeys

| Id | Journey | Proves | Steps | Expected outcome | Check |
| --- | --- | --- | --- | --- | --- |
| JRN-001 | A set-up spec and agent worktree | CAP-NEW-worktree-setup | 1. Fixture repo with `worktree_setup`, `.worktreeinclude` and an ignored `.env`. 2. `spec-worktree.sh create`. 3. `worktree-setup.sh agent`. | Both worktrees hold `.env` as a regular file equal to the main checkout's; the setup command's marker records `WF_SLOT`, `WF_INSTANCE`, `WF_PORT_OFFSET`. | MISSING |
| JRN-002 | A project that declares nothing | CAP-NEW-worktree-setup | 1. Fixture repo with no settings and no copy list. 2. Create a spec worktree and an agent worktree. | Same stdout and same files as today; no copied file, no error. | MISSING |
| JRN-003 | A link back into the main checkout is refused | CAP-NEW-worktree-setup | 1. In a worktree, link `.env` to the main checkout's. 2. `worktree-setup.sh check`. 3. `run-toolchain.sh`. 4. Replace it with a link outside the repository. | Steps 2 and 3 exit non-zero naming the link and no key runs; step 4 passes. | MISSING |
| JRN-004 | Two specs, two slots | CAP-NEW-worktree-setup | 1. Create two spec worktrees. 2. Remove the first. 3. Create a third. | Slots 1 and 2; the third takes 1. | MISSING |
| JRN-005 | Services around a test run | CAP-NEW-worktree-setup | 1. Fixture with `services_up` and `services_down` that log their calls and environment. 2. `run-toolchain.sh` with `test`. 3. With `--e2e`. 4. With `test` skipped. 5. With a reuse hit. 6. With a failing `services_up`. 7. `spec-worktree.sh remove`. | One `services_up` call before the key in 2 and 3, with the isolation values; none in 4 and 5; 6 fails the run with the output in the evidence; 7 calls `services_down`. | MISSING |
| JRN-006 | A failing setup command | CAP-NEW-worktree-setup | 1. `worktree_setup` exits 3 with a message. 2. Create. 3. Fix the command. 4. Create again. | Step 2 exits 1 with the message on stderr and stdout unchanged; step 4 exits 0 and the worktree is set up. | MISSING |
| JRN-007 | A scratch worktree | CAP-NEW-worktree-setup | 1. In a set-up spec worktree, `worktree-setup.sh scratch` at an older commit. 2. `worktree-setup.sh remove --force`. | Detached at that commit, copy list and setup applied, same slot as the spec; removed cleanly. | MISSING |
| JRN-008 | The documents name the script | CAP-NEW-worktree-setup | 1. Search the step files, the launching reference and the agent definitions. | No raw `git worktree add` or `git worktree remove` instruction; every creation names `worktree-setup.sh`; the coding agents carry the no-improvising rule. | MISSING |

## Fixtures and oracles

| Fixture or oracle | What it provides | Source | Used by |
| --- | --- | --- | --- |
| Throwaway git repository | A project root with the scaffold's scripts, a rules file, a spec folder and a `main` branch | Built per test by the harness helpers the spec-worktree and run-toolchain suites already use | JRN-001 to JRN-007 |
| Marker-writing commands | `worktree_setup`, `services_up` and `services_down` that append their working folder and the isolation values to a log file outside the worktree | Written inline by each test | JRN-001, JRN-005, JRN-006, JRN-007 |
| Behaviour before the change | The stdout and file list of `spec-worktree.sh create` today | The existing cases in `tests/scripts/spec-worktree.sh`, which must keep passing unchanged | JRN-002 |
| Document search | The exact strings a document must and must not hold | A lint suite beside `tests/lint/agent-worktree-docs.sh` | JRN-008 |

## Targets

## Suites
