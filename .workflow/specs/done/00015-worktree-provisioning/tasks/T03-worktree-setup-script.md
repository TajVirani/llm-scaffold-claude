# T03: Worktree setup script

Index: [../tasks.md](../tasks.md) · Blocked by: T1 Settings keys, T2 Install and allow the worktree setup script · Parallel with: None

**What to build:** One script, `worktree-setup.sh`, creates and sets up every agent worktree and scratch worktree, sets up a spec worktree, checks a worktree for links back into the repository, prints a worktree's isolation values and removes agent and scratch worktrees. `spec-worktree.sh create` calls it, on the first run and on a re-run, and `spec-worktree.sh remove` runs the project's `services_down` first. A project that declares a setup command and a copy list gets worktrees that hold its gitignored config as real files and have had its setup command run; a project that declares nothing gets exactly what it gets today. The full contract is [data-model.md](../data-model.md) § Interfaces, § Slot and § Copy list; replace the Phase 1 stub.

**Seam:** the `worktree-setup.sh` and `spec-worktree.sh` command lines in a throwaway repository, driven by `tests/scripts/worktree-setup.sh` and `tests/scripts/spec-worktree.sh`.

**Acceptance criteria:**

- [ ] `agent <name> <branch>` adds the agent worktree on a new branch off the spec branch, or reuses one that exists, sets it up, and prints only `worktree <absolute path>` on stdout.
- [ ] `scratch <name> [<commit>]` adds a detached worktree beside the agent worktrees at that commit (default `HEAD`), sets it up with the spec's slot, and prints only `worktree <absolute path>`.
- [ ] `setup <path>` takes the lowest free slot for a spec worktree, or keeps the one it holds; copies each copy-list match that git ignores in the main checkout as a regular file (a tracked match is never copied, a match that is a symlink arrives as the file it points to); runs `worktree_setup` with `bash -c` in the worktree with the five isolation values exported; then runs the link check. It is safe to run again and leaves `git status` empty.
- [ ] `check <path>` exits 1 and names each symlink, tracked or not, dependency folders included, that resolves into the main checkout or another worktree of the same repository and outside this worktree. A link to a path outside the repository passes.
- [ ] `env <path>` prints the five `export` lines: slot, `s<NNN>`, slot × 100 and both roots in a spec, agent or scratch worktree; `0`, `main`, `0` and the main checkout twice in the main checkout.
- [ ] `remove <name>` removes an agent or scratch worktree and prints `removed worktree <path>`; `--force` works only for a scratch worktree and is refused for an agent worktree, which stays.
- [ ] A failing `worktree_setup` exits 1 with the command's output on stderr. Nothing falls back to a bare worktree.
- [ ] `spec-worktree.sh create` prints the same two stdout lines as before, runs setup on the first run and on a re-run, exits 1 when setup fails, and a second `create` after the command is fixed finishes the setup.
- [ ] `spec-worktree.sh remove`, once its refusals pass, runs `services_down` in the spec worktree with the isolation values; a failing `services_down` is reported and the removal goes on.
- [ ] Exit codes: 0 done, 1 refused or a check failed, 2 usage or environment error. Progress and command output go to stderr.
- [ ] `tests/run-all.sh --suite scripts/worktree-setup` and `--suite scripts/spec-worktree` pass whole, the shellcheck and executable cases included.

**Predicted files:** `.agents/skills/feature-workflow/scripts/worktree-setup.sh`, `.agents/skills/feature-workflow/scripts/spec-worktree.sh`

**Phase 1 tests:** `tests/scripts/worktree-setup.sh`, `tests/scripts/spec-worktree.sh`

**Size:** L (2 files, about 460 changed lines). L is a split signal: more than 15 files, more than 400 lines, or too big for one fresh context window. Kept as one task by the stakeholder (D8): the six calls share the slot and copy code, so a split would put two agents in one file.

**Mode:** afk.

**Notes:** Read the slot file and the copy list only through the path constants T2's shared-core request added to `.agents/lib/workflow-paths.sh`; do not edit that file. Constraints from the module audit ([codebase-map.md](../codebase-map.md) § Module audit): bash 3.2; the `File:` header format; setup output must never reach `create`'s stdout, which callers parse; everything setup writes must be gitignored, because `remove` refuses a worktree with untracked files; reuse `die`, `usage`, `registered_worktree` and the root resolution from `spec-worktree.sh`. Two spec worktrees created at the same instant may take the same slot; that is accepted.
