# T06: Project setup asks for it

Index: [../tasks.md](../tasks.md) · Blocked by: T3 Worktree setup script · Parallel with: None

**What to build:** A project that runs `project-setup` learns that worktree setup exists and is asked for what it needs: the command that makes a new worktree ready, the gitignored files to copy, and the commands that start and stop the services its tests need. The rules file it receives carries the three settings as commented lines with their defaults, and the profile template says that tests use a throwaway database, never the dev one.

**Seam:** the shipped rules template read by `rules-setting.sh` (`tests/scripts/task-breakdown.sh`), and the project-setup documents as loaded text.

**Acceptance criteria:**

- [ ] `assets/docs/rules.md` § Workflow settings carries commented `worktree_setup`, `services_up` and `services_down` lines. Each says when the command runs, which isolation values it receives (`WF_SLOT`, `WF_INSTANCE`, `WF_PORT_OFFSET`, `WF_MAIN_ROOT`, `WF_SPEC_ROOT`) and that the project turns them into ports, container names and database names. `services_up` must be safe to run when the services are already up.
- [ ] `rules-setting.sh` reads each of the three from that template as its empty default; the case is written first in `tests/scripts/task-breakdown.sh`, beside the existing `pr_template` case.
- [ ] `modules/files.md` asks for the three commands and the copy list in the setup questions, each with a recommended answer and "none" as a valid one, and writes `.worktreeinclude` at the repository root only when the project names files to copy. It says only files the project's `.gitignore` ignores are copied, as copies.
- [ ] `assets/profiles/TEMPLATE.md` and `modules/profiles.md` say that the `test` and `e2e` commands use a throwaway database and the ports derived from `WF_PORT_OFFSET`, and that `services_up` starts what they need.
- [ ] Nothing project-specific is set by default: a project that answers "none" gets a rules file that behaves as today.
- [ ] The existing lint suites over these files pass.

**Predicted files:** `.agents/skills/project-setup/assets/docs/rules.md`, `.agents/skills/project-setup/assets/profiles/TEMPLATE.md`, `.agents/skills/project-setup/modules/files.md`, `.agents/skills/project-setup/modules/profiles.md`, `tests/scripts/task-breakdown.sh`

**Phase 1 tests:** None.

**Size:** S (5 files, about 80 changed lines). L is a split signal: more than 15 files, more than 400 lines, or too big for one fresh context window.

**Mode:** afk.

**Notes:** Use the glossary term "Worktree setup"; avoid "provisioning", "bootstrap" and "environment setup". The Toolchain keys of the profile template do not change: the three commands are workflow settings in `rules.md`, not profile keys.
