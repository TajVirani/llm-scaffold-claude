# Verification plan: Worktree provisioning

Spec: [spec.md](spec.md)

## End state

- [ ] CAP-015: in a fixture project that declares a setup command and a copy list, a new spec worktree and a new agent worktree each hold the listed gitignored file as a regular file with the main checkout's content, and the setup command has run there with the spec's isolation values.
- [ ] CAP-015: in a fixture project that declares nothing, creating a spec worktree and an agent worktree leaves the same files and prints the same stdout as before this change.
- [ ] CAP-015: a symlink in a worktree that resolves into the main checkout makes both worktree setup and `run-toolchain.sh` exit non-zero and name the link; a link to a path outside the repository passes.
- [ ] CAP-015: two spec worktrees of one repository hold different slots, and a spec worktree created after one is removed takes the freed slot.
- [ ] CAP-015: `run-toolchain.sh` runs `services_up` with the isolation values before `test` and before `e2e`, runs it for neither when both are skipped or served from reuse, and fails the run when it fails; `spec-worktree.sh remove` runs `services_down`.
- [ ] CAP-015: a failing setup command makes creation exit non-zero with the command's output, and running creation again after the command is fixed finishes the setup.
- [ ] CAP-015: a scratch worktree is set up with the copy list and the setup command and the spec's slot.
- [ ] CAP-015: no step file, launching reference or agent definition tells a reader to run a raw `git worktree add` or `git worktree remove`; the coding agents' definitions say never to install, copy or link by hand.

## Journeys

| Id | Journey | Proves | Steps | Expected outcome | Check |
| --- | --- | --- | --- | --- | --- |
| JRN-001 | A set-up spec and agent worktree | CAP-015 | 1. Fixture repo with `worktree_setup`, `.worktreeinclude` and an ignored `.env`. 2. `spec-worktree.sh create`. 3. `worktree-setup.sh agent`. | Both worktrees hold `.env` as a regular file equal to the main checkout's; the setup command's marker records `WF_SLOT`, `WF_INSTANCE`, `WF_PORT_OFFSET`. | `tests/scripts/worktree-setup.sh`, cases titled JRN-001 |
| JRN-002 | A project that declares nothing | CAP-015 | 1. Fixture repo with no settings and no copy list. 2. Create a spec worktree and an agent worktree. | Same stdout and same files as today; no copied file, no error. | `tests/scripts/spec-worktree.sh`, cases titled JRN-002 |
| JRN-003 | A link back into the main checkout is refused | CAP-015 | 1. In a worktree, link `.env` to the main checkout's. 2. `worktree-setup.sh check`. 3. `run-toolchain.sh`. 4. Replace it with a link outside the repository. | Steps 2 and 3 exit non-zero naming the link and no key runs; step 4 passes. | `tests/scripts/worktree-setup.sh` and `tests/scripts/run-toolchain.sh`, cases titled JRN-003 |
| JRN-004 | Two specs, two slots | CAP-015 | 1. Create two spec worktrees. 2. Remove the first. 3. Create a third. | Slots 1 and 2; the third takes 1. | `tests/scripts/worktree-setup.sh`, cases titled JRN-004 |
| JRN-005 | Services around a test run | CAP-015 | 1. Fixture with `services_up` and `services_down` that log their calls and environment. 2. `run-toolchain.sh` with `test`. 3. With `--e2e`. 4. With `test` skipped. 5. With a reuse hit. 6. With a failing `services_up`. 7. `spec-worktree.sh remove`. | One `services_up` call before the key in 2 and 3, with the isolation values; none in 4 and 5; 6 fails the run with the output in the evidence; 7 calls `services_down`. | `tests/scripts/run-toolchain.sh` and `tests/scripts/spec-worktree.sh`, cases titled JRN-005 |
| JRN-006 | A failing setup command | CAP-015 | 1. `worktree_setup` exits 3 with a message. 2. Create. 3. Fix the command. 4. Create again. | Step 2 exits 1 with the message on stderr and stdout unchanged; step 4 exits 0 and the worktree is set up. | `tests/scripts/spec-worktree.sh`, cases titled JRN-006 |
| JRN-007 | A scratch worktree | CAP-015 | 1. In a set-up spec worktree, `worktree-setup.sh scratch` at an older commit. 2. `worktree-setup.sh remove --force`. | Detached at that commit, copy list and setup applied, same slot as the spec; removed cleanly. | `tests/scripts/worktree-setup.sh`, cases titled JRN-007 |
| JRN-008 | The documents name the script | CAP-015 | 1. Search the step files, the launching reference and the agent definitions. | No raw `git worktree add` or `git worktree remove` instruction; every creation names `worktree-setup.sh`; the coding agents carry the no-improvising rule. | `tests/lint/worktree-setup-docs.sh` |

## Fixtures and oracles

| Fixture or oracle | What it provides | Source | Used by |
| --- | --- | --- | --- |
| Throwaway git repository | A project root with the scaffold's scripts, a rules file, a spec folder and a `main` branch | Built per test by the harness helpers the spec-worktree and run-toolchain suites already use | JRN-001 to JRN-007 |
| Marker-writing commands | `worktree_setup`, `services_up` and `services_down` that append their working folder and the isolation values to a log file outside the worktree | Written inline by each test | JRN-001, JRN-005, JRN-006, JRN-007 |
| Behaviour before the change | The stdout and file list of `spec-worktree.sh create` today | The existing cases in `tests/scripts/spec-worktree.sh`, which must keep passing unchanged | JRN-002 |
| Document search | The exact strings a document must and must not hold | A lint suite beside `tests/lint/agent-worktree-docs.sh` | JRN-008 |

## Targets

Run every command in bash from the project root on a clean checkout of the feature's HEAD.

| Target | Kind | Threshold | How measured (exact command) | Source of the threshold |
| --- | --- | --- | --- | --- |
| Worktree setup with nothing declared adds no work | performance | not measured | Cannot be measured as a number: with no settings the script runs `git worktree add` and three file checks. JRN-002 proves the behaviour is unchanged. | `spec.md` Constraints |
| Script lint clean | errors | exit 0; 0 shellcheck findings | the `script-lint` command below (the `lint` key of the shell-scripts profile) | `.workflow/profiles/shell-scripts.md` § Toolchain |
| Harness lint clean | errors | exit 0; 0 shellcheck findings | the `harness-lint` command below (the `lint` key of the test-harness profile) | `.workflow/profiles/test-harness.md` § Toolchain |
| Agent-docs lint clean | errors | exit 0; each lint suite reports 0 failed | the `agent-docs-lint` command below (the `lint` key of the agent-docs profile) | `.workflow/profiles/agent-docs.md` § Toolchain |
| Every script this spec adds or changes has a suite | coverage | `0` printed | the `script-coverage` command below | `.workflow/profiles/test-harness.md` § Mini-review checklist |
| Every new `.agents/` file is in `PROVENANCE.md` | coverage | `0` printed | the `asset-coverage` command below | `.workflow/rules.md` § Cross-cutting policy (PROVENANCE) |
| Line coverage of changed shell code | coverage | not measured | Cannot be measured: no bash coverage tool is installed. The script-coverage target and the test-harness checklist at 3.7 stand in. | `.workflow/rules.md` § Required versions (no coverage tool listed) |

Commands referenced above; each runs from the project root:

```bash
# script-lint
git ls-files -z -co --exclude-standard -- '.agents/hooks/*.sh' '.agents/lib/*.sh' '.agents/skills/*/scripts/*.sh' install.sh 'scripts/*.sh' | xargs -0 shellcheck -x -P SCRIPTDIR && git ls-files -z -co --exclude-standard -- '.agents/hooks/*.sh' '.agents/lib/*.sh' '.agents/skills/*/scripts/*.sh' install.sh 'scripts/*.sh' | xargs -0 .agents/skills/feature-workflow/scripts/check-comments.sh
# harness-lint
git ls-files -z -co --exclude-standard -- 'tests/*.sh' | xargs -0 shellcheck -x -P SCRIPTDIR && git ls-files -z -co --exclude-standard -- 'tests/*.sh' | xargs -0 .agents/skills/feature-workflow/scripts/check-comments.sh
# agent-docs-lint
tests/run-all.sh --suite lint/frontmatter && tests/run-all.sh --suite lint/step-list && tests/run-all.sh --suite lint/symlinks && tests/run-all.sh --suite lint/upstream-lineage
# script-coverage: prints the count of changed scripts no file under tests/ names; the threshold is 0
git diff --name-only --diff-filter=AM "$(yq --front-matter=extract '.baseline_revision' .workflow/specs/done/00015-worktree-provisioning/spec.md)"..HEAD -- '.agents/hooks/*.sh' '.agents/lib/*.sh' '.agents/skills/*/scripts/*.sh' install.sh | while read -r f; do grep -rqF -- "$(basename "$f")" tests/ || echo "$f"; done | wc -l | tr -d ' '
# asset-coverage: prints the count of new .agents/ files PROVENANCE.md does not name; the threshold is 0
git diff --name-only --diff-filter=A "$(yq --front-matter=extract '.baseline_revision' .workflow/specs/done/00015-worktree-provisioning/spec.md)"..HEAD -- .agents | while read -r f; do grep -qF -- "${f#.agents/}" PROVENANCE.md || echo "$f"; done | wc -l | tr -d ' '
```

## Suites

| Suite | Profile key | Command (copied from the profile) | CI check | Known-bad-build evidence (1.4) |
| --- | --- | --- | --- | --- |
| Harness | `test` in `.workflow/profiles/test-harness.md` | `tests/run-all.sh` | none (no CI; the run by hand is the whole gate) | [artifacts/phase-1-known-bad/record.md](artifacts/phase-1-known-bad/record.md), full log [harness.txt](artifacts/phase-1-known-bad/harness.txt): 72 failures across the 2 new suites and the 2 extended ones, all assertions |
| Browser | `e2e`: not applicable (no `e2e-browser` profile; every journey is a harness suite) | none | none | not applicable; see record.md § Steps not run |
