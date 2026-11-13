# Codebase map: Worktree provisioning

Affected area: feature-workflow (`.agents/skills/feature-workflow`), hooks (`.agents/hooks`), lib (`.agents/lib`), agents (`.agents/agents`), project-setup (`.agents/skills/project-setup`), project-standards (`.agents/skills/project-standards`), installer (`install.sh`, `.agents/install-manifest.txt`), tests (`tests`), root-docs (`AGENTS.md`, `README.md`, `.agents/README.md`)

## Relevant code

| Item | What it does today | Source |
| --- | --- | --- |
| `spec-worktree.sh create` | Creates `spec/NNN-slug` off main, commits the workflow data, then `git worktree add -q "$WT" "$BRANCH"` at `.workflow/.spec-worktrees/NNN-slug`; moves `.step` in; prints `worktree <path>` and `baseline <sha>`. No dependency install, no copy of gitignored files. | `.agents/skills/feature-workflow/scripts/spec-worktree.sh:71-111` |
| `spec-worktree.sh remove` | Requires the spec branch merged into main; refuses while agent worktrees are registered inside; `git worktree remove`, then `git branch -d`. Never force-deletes. | `.agents/skills/feature-workflow/scripts/spec-worktree.sh:114-138` |
| `spec-worktree.sh` refusals | Refuses create inside another spec's worktree, mid-merge, cherry-pick or revert, or on the spec branch. | `.agents/skills/feature-workflow/scripts/spec-worktree.sh:80-89` |
| Agent worktree creation | The orchestrator runs raw `git worktree add .workflow/.worktrees/<name> -b <branch> spec/NNN-slug` (task at wave start; Phase 1 build; integration batch) and raw `git worktree remove` after the merge. | `.agents/skills/feature-workflow/modules/implementation-waves.md:73`, `:126`; `modules/implementation-shared-core.md:10`, `:30`; `modules/verification-setup.md:65`, `:107` |
| Spec worktree call sites | verification-setup 1.1 and discovery-impact 0.3.20 run `spec-worktree.sh create`; sign-off 5.8 runs `remove`. | `modules/verification-setup.md:17,27`; `modules/discovery-impact.md:42,56`; `modules/sign-off.md:270` |
| Light path worktree | The light path makes its agent worktree on a task branch and merges it `--no-ff`, the same as the full path. | `modules/implementation-waves.md:69,123`; `modules/discovery-impact.md:56` |
| Known-bad scratch worktree | 1.4 runs `git worktree add --detach .workflow/.worktrees/s<NNN>_known_bad HEAD` and removes it with `--force`; the only detached worktree in the module. It counts as the spec checkout for evidence. | `modules/verification-setup.md:131` |
| Leftover removal | Finish and sign-off tell the orchestrator to remove leftover agent worktrees with `git worktree list` and `git worktree remove <path>`. | `modules/implementation-finish.md:30`; `modules/sign-off.md:259` |
| Path constants | `WF_WORKTREES="$WF_DIR/.worktrees"`, `WF_SPEC_WORKTREES="$WF_DIR/.spec-worktrees"`, `WF_ISOLATION_WORKTREES=".claude/worktrees"`; helpers `wf_main_root`, `wf_project_root`, `wf_agent_worktree_name`. | `.agents/lib/workflow-paths.sh:110-112,122,138,207` |
| Claude settings | Allow `Bash(git worktree add:*)` and `Bash(git worktree list:*)`. | `.agents/hooks/claude-settings.template.json:117-118` |
| Gitignore block | `GI_ENTRIES` lists the step markers, `.workflow/.worktrees/`, `.workflow/.spec-worktrees/`, `.workflow/.handoff/`, `.workflow/.standards-staging/`. No entry for copied config. | `install.sh:137`, `:704`, `:1055` |
| `run-toolchain.sh` Toolchain read | Takes the first fenced yaml block under `## Toolchain` in the profile with yq; exits 2 when it is missing or unparsable. | `.agents/skills/feature-workflow/scripts/run-toolchain.sh:195-203` |
| `run-toolchain.sh` keys | Runs `lint typecheck format boundary test`, plus `e2e` with `--e2e`; `test_scoped` replaces `test` when scoping applies. `serve`, `serve_ready`, `config`, `rule_set` are never run. A `TODO:` value exits 2. | `run-toolchain.sh:238-239`, `:253`, `:269-271` |
| `run-toolchain.sh` cwd and evidence | Runs each command with `bash -c` in `--cwd`; evidence goes to the spec checkout's `artifacts/<task-id>/`. | `run-toolchain.sh:75-80` |
| Scoped test env vars | `test_scoped` gets `WF_EXCLUDE_TESTS`, `WF_TASK_TESTS`, `WF_CHANGED_FILES`, `WF_CHANGED_BASE`, `WF_TASK_ID`, `WF_IMPL_BASE` (and `_FILE` forms). | `run-toolchain.sh:38-51`; `.agents/skills/project-setup/assets/profiles/TEMPLATE.md:30` |
| `worktree-write-guard.sh` | Thin hook: passes the sub-agent's worktree name to `check-worktree-scope.sh --confined`. Exit 0 allow, 2 deny, any other exit denies. | `.agents/hooks/worktree-write-guard.sh:1-34,67,127,145-150` |
| `check-worktree-scope.sh` path rule | Canonicalises paths, resolving symlinks through the deepest existing ancestor. A path inside the spec or main checkout but outside the agent worktree is denied; a path outside both is allowed. | `.agents/skills/feature-workflow/scripts/check-worktree-scope.sh:25`, `:83-107`, `:126-128`, `:161-163`, `:183` |
| `check-worktree-scope.sh` command rule | A command is allowed only when `cwd` is inside the root, or it starts with `cd <dir> &&` inside the worktree. | `check-worktree-scope.sh:31`, `:319` |
| `rules-setting.sh` | Reads the first fenced yaml block under `## Workflow settings` in `.workflow/rules.md` (a map of setting to scalar). Known keys `task_review`, `main_branch`, `pr_template`; scalars only (a sequence or map is rejected, `:136`); an unknown key exits 1; a missing key prints the default. | `.agents/skills/feature-workflow/scripts/rules-setting.sh:1-34,46-49`; `.workflow/rules.md:122-132` |
| Review scratch worktrees | Probes run `git worktree add --detach "$scratch/wt" HEAD` under `mktemp -d`, then `git worktree remove --force` and `rm -rf`. | `.agents/agents/review-end-state.md:35-36`; `review-combined.md:39-40`; `review-standards.md:44-45`; `profile-mini-review.md:55-56` |
| `review-targets` serve | Reads `serve` and `serve_ready` from the Toolchain yaml itself, starts `serve` with `nohup`, polls `serve_ready` for 120 s, kills the process group after. Runs in the spec checkout. | `.agents/agents/review-targets.md:28,43-46,52-66,100-103` |
| Profile keys | The Toolchain block lists `lint typecheck format boundary test test_scoped e2e serve serve_ready config rule_set test_patterns`; `serve` and `serve_ready` are descriptive, not commands. | `.agents/skills/project-setup/assets/profiles/TEMPLATE.md:3,21-43`; `modules/profiles.md:24` |
| Example profiles | e2e-browser sets `serve: "npm run start"`, `serve_ready: "http://localhost:3000"`; test-harness sets both `""`. | `.agents/skills/project-setup/assets/profiles/examples/e2e-browser.md:102-103`; `examples/test-harness.md:51-52` |
| deps-update skill | Uses the profile's `serve` and `serve_ready` to start the app for a UI-level change. | `.agents/skills/deps-update/SKILL.md:14-15,62` |

## Seams and interfaces

| Interface | Shape (signature, type, contract) | Callers | Source |
| --- | --- | --- | --- |
| `spec-worktree.sh create\|remove <spec-dir> [--cwd <dir>]` | stdout `worktree <abs path>`, `baseline <sha>`; `removed worktree <path>`, `deleted branch spec/NNN-slug`. Exit 0 done, 1 refused, 2 usage or environment error. | verification-setup 1.1, discovery-impact 0.3.20, sign-off 5.8 | `spec-worktree.sh:9-28`; `scripts/status-transition.sh:374` |
| raw `git worktree add` | Agent worktrees are made by the orchestrator with raw git, not a script. | implementation-waves, implementation-shared-core, verification-setup 1.2 | `modules/implementation-waves.md:73`; `modules/implementation-shared-core.md:10`; `modules/verification-setup.md:65` |
| `wf_agent_worktree_name SPEC_DIR task\|phase_1\|integration VALUE` | Prints the agent worktree name. | worktree-write-guard.sh, check-worktree-scope.sh (`:144`), post-implementation-audit.sh (`:239`) | `.agents/lib/workflow-paths.sh:35,205-209` |
| `check-worktree-scope.sh --cwd <dir> [--worktree-name <n>] [--confined] (--path <t>... \| --command <cmd>)` | Exit 0 allow, 2 deny with the reason on stderr. | worktree-write-guard.sh (`:145`), codex-write-guard.sh (`:118`) | `check-worktree-scope.sh:8,17-31` |
| `run-toolchain.sh --spec-dir --task-id --cwd [--work-type\|--profile] [--e2e] [--skip <key>] [--reuse\|--reuse-check]` | Runs the Toolchain keys; exit 0 clean; evidence to the spec checkout. | orchestrator at 3.5, 3.9, 3.10; sign-off 5.4 | `run-toolchain.sh:11-20,75-80` |
| `rules-setting.sh <key> [--cwd] [--rules]` | Prints one value. | implementation-waves 3.16, large-path, verification-setup 1.1, discovery-impact 0.3.20, sign-off 5.2 and 5.8, open-task-pr.sh, budget-check.sh | `rules-setting.sh:3-37` |
| Toolchain yaml block | First fenced yaml under `## Toolchain`. | run-toolchain.sh, review-targets, profile-mini-review | `TEMPLATE.md:21-43`; `review-targets.md:43` |
| `rules-setting.sh` `setting_spec KEY` | Prints `"<default> <allowed...>"`; `@branch` and `@template_path` are value classes. The one place to add a key, plus the two key lists in messages. | internal | `scripts/rules-setting.sh:53-60,141-151` |
| run-toolchain per-key run block | `( cd "$cwd"; [test: export WF_*]; bash -c "$cmd" ) >"$log" 2>&1`; rc recorded, every key run even after a failure. | internal | `scripts/run-toolchain.sh:388-427` |
| run-toolchain profile resolution | `--profile`, then `--work-type`, then the tasks.md `work_type`; looked up in `$cwd/$WF_PROFILES`, then the spec root. | internal | `scripts/run-toolchain.sh:178-193` |
| `spec-worktree.sh create` re-run path | When the worktree exists on the branch it runs `move_step` and prints the same two lines; on another branch exit 1; an unregistered directory exit 2. | discovery-impact loop-back, 1.1 resume | `scripts/spec-worktree.sh:73-78` |
| Agent worktree create (prose) | `git worktree add .workflow/.worktrees/<name> -b <branch> spec/NNN-slug` from the spec checkout; an existing worktree is reused. | 1.2/1.3, 3.2, wave start | `modules/verification-setup.md:65,68`; `modules/implementation-shared-core.md:10,13`; `modules/implementation-waves.md:73,76` |
| Agent worktree remove (prose) | `git worktree remove .workflow/.worktrees/<name>`, then `git branch -d <branch>`, after a gated `--no-ff` merge. | 1.2/1.3 merge, 3.2 merge, 3.16, hand-off, 5.8 | `modules/verification-setup.md:107-108`; `modules/implementation-shared-core.md:30-31`; `modules/implementation-waves.md:126`; `modules/implementation-finish.md:30`; `modules/sign-off.md:259` |
| `GI_ENTRIES` | The gitignore lines written into a target; must match this repo's `.gitignore` marker block. | install.sh | `install.sh:137`; `.workflow/rules.md:147` |

## Prior decisions

| Decision or item | What it says | Source |
| --- | --- | --- |
| Pitfall: fork a Phase 1 build's worktree from the spec branch | An `isolation: "worktree"` Phase 1 worktree started at main without the spec folder; a wave-start-style worktree under `.workflow/.worktrees/` is a named option. | `.workflow/decisions/pitfalls.md` § Fork a Phase 1 build's worktree from the spec branch |
| Pitfall: two homes for the launch and confinement rule | The rule moved to `references/launching.md` but verification-setup kept a copy. | `.workflow/decisions/pitfalls.md` (line 30) |
| Retrospective 00010 | The scope rule lives in `check-worktree-scope.sh`; hooks stay thin. Linked-worktree launches keep cwd confinement. | `.workflow/decisions/retrospectives/00010-worktree-guard-followups.md` § Constraints |
| Retrospective 006 | No result-file agent is launched with isolation; the light path keeps a detached worktree and `--ff-only`. | `.workflow/decisions/retrospectives/006-result-file-guard.md` § capabilities |
| Rules, Cross-cutting policy | Keep the `.gitignore` marker block in step with `GI_ENTRIES`. | `.workflow/rules.md` § Cross-cutting policy (line 147) |
| Rules, Workflow settings | Optional section; an absent key means its default. | `.workflow/rules.md` § Workflow settings (lines 122-132) |
| ADRs | No ADR mentions worktrees, toolchain keys, environment or services. | `.workflow/decisions/adr/` |
| Deferred: workflow-settings-home | Keep all project-wide workflow settings in one central place. | `.workflow/deferred/workflow-settings-home.md` § Summary |
| Deferred: main-checkout-resolver | About fifteen places compute the main checkout themselves; `wf_main_root` should be shared. | `.workflow/deferred/main-checkout-resolver.md` § Summary |
| Deferred: worktree-name-parser | Hooks that read an agent worktree name back use their own regexes. | `.workflow/deferred/worktree-name-parser.md` § Summary |
| Deferred: known-bad-evidence-path | Evidence from 1.4 known-bad runs lands in the main checkout's spec folder, not the throwaway worktree. | `.workflow/deferred/known-bad-evidence-path.md` § Summary |
| Deferred: in-review-hand-off | Every route to `in-review` runs the hand-off, agent worktree cleanup included. | `.workflow/deferred/in-review-hand-off.md` § Summary |
| Shelf match | No deferred file proposes worktree setup, a copy list, a symlink check, per-spec ports or setup and services keys. The request is not on the shelf. | `.workflow/deferred/` |

## Library options

Not evaluated: no new library named; shell-scripts work uses git, yq and jq, which the project already depends on.

## Module audit

Owning module: feature-workflow (`.agents/skills/feature-workflow`)

| Kind | Finding | Source |
| --- | --- | --- |
| reuse | Script-local `die MSG [CODE]` (default 2, 1 for a refusal) and `usage`, plus a `while/case` parser with `--cwd`, `-h`: the pattern for a new worktree script. | `scripts/spec-worktree.sh:42-45,140-156` |
| reuse | `registered_worktree PATH` asks git whether it knows a worktree; an awk scan finds agent worktrees nested under a spec worktree. | `scripts/spec-worktree.sh:47-50,129` |
| reuse | Root resolution with `wf_project_root` and `wf_main_root`; the spec worktree path is `$MAIN_ROOT/$WF_SPEC_WORKTREES/<NNN-slug>`; `wf_norm_folder spec` normalises the spec dir. | `scripts/spec-worktree.sh:158-162` |
| reuse | Section parse: awk takes the first fenced yaml under a `## <heading>`, then yq checks the tag. | `scripts/rules-setting.sh:124-135`; `scripts/run-toolchain.sh:196-203` |
| reuse | Per-key env export: the `test` key runs in a `( cd; export ...; bash -c "$cmd" )` subshell, the only place commands get env vars. | `scripts/run-toolchain.sh:390-403` |
| reuse | Evidence format: a `== key: cmd` / `== key exit N` section in `toolchain.txt`, a result object per key in `toolchain.json`, `warnings[]` for non-fatal notes. | `scripts/run-toolchain.sh:407-426,441-445` |
| reuse | EXIT-trap cleanup pattern. | `scripts/move-to-done.sh:115`; `scripts/task-waves.sh:172` |
| reuse | Agent worktree names `s<NNN>_t<N>`, `s<NNN>_phase_1_<enc>`, `s<NNN>_integration_<enc>`; branch `wf/NNN-slug/<name>` or the task record's `branch`, always off `spec/NNN-slug`. | `modules/verification-setup.md:62-66`; `modules/implementation-shared-core.md:7-10`; `modules/implementation-waves.md:69-73` |
| reuse | Gitignored-state leak check: `ls-files -o --exclude-standard` over local-state paths exits 2 when they are not ignored. | `scripts/commit-workflow-data.sh:69-72` |
| gap | `rules-setting.sh` accepts only scalars, so a list of files to copy cannot be read through it; known keys are hard-coded in `setting_spec` and two message strings. | `scripts/rules-setting.sh:49,53-60,90,136` |
| gap | `run-toolchain.sh` has no service lifecycle and no trap, so a `die` after a start would leave services running. | `scripts/run-toolchain.sh:94,238` |
| gap | The 3.10 browser run (`--e2e` on the merged spec branch) starts nothing; only 1.4 and `review-targets` start `serve`. | `modules/implementation-finish.md:7`; `modules/verification-setup.md:133` |
| gap | At 1.4 the orchestrator starts `serve` by hand and refuses when `serve_ready` already answers, which assumes one fixed port shared by every checkout. | `modules/verification-setup.md:133` |
| gap | No script creates agent worktrees: six raw `git worktree add` / `remove` lines are prose for the orchestrator. | `modules/verification-setup.md:65,107,131`; `modules/implementation-shared-core.md:10,30`; `modules/implementation-waves.md:73,126`; `modules/implementation-finish.md:30`; `modules/sign-off.md:259` |
| gap | `spec-worktree.sh create` returns early when the worktree already exists, before any setup point; a resumed spec would skip setup. | `scripts/spec-worktree.sh:73-78` |
| gap | `spec-worktree.sh remove` has no teardown step. | `scripts/spec-worktree.sh:114-138` |
| constraint | `create` runs refusals, switch, commit-workflow-data, switch back, `mkdir`, `worktree add`, `move_step`, then prints `worktree`/`baseline`. Callers parse that stdout, so setup output must not land on stdout; a setup failure after `worktree add` leaves a registered worktree the re-run path must finish. | `scripts/spec-worktree.sh:91-110`; `modules/verification-setup.md:30`; `modules/discovery-impact.md:42,56` |
| constraint | `remove` never uses `--force`: it refuses on any uncommitted or untracked change, so a setup command that writes untracked, non-ignored files blocks sign-off removal. | `scripts/spec-worktree.sh:23-27,121-131` |
| constraint | Exit codes differ by script: spec-worktree 0/1 refused/2 usage; run-toolchain 0/1 failed/2 usage or config; rules-setting puts usage and invalid values on 1. | `scripts/spec-worktree.sh:23-28`; `scripts/run-toolchain.sh:84-86`; `scripts/rules-setting.sh:33-34` |
| constraint | Script header format `File:` / `Purpose:` / `Usage:` / stdout / `Exit:` / `Called by:` / `Notes:` / `Sources:`; body comments cite no decision, task or journey ids and no `.workflow/` paths. | `scripts/spec-worktree.sh:1-32`; `scripts/check-comments.sh:2-16` |
| constraint | bash 3.2: no `mapfile`, `declare -A` or `${x,,}`; `${arr[@]+...}` guards empty arrays under `set -u`. | `scripts/run-toolchain.sh:339` |
| constraint | Evidence always goes to the spec checkout, never the agent worktree; `--cwd` is canonicalised with `cd && pwd`. | `scripts/run-toolchain.sh:79,155,170,236` |
| constraint | `--reuse` can skip `test` and `e2e` entirely and `--reuse-check` runs nothing: services must not start for keys that will not run. | `scripts/run-toolchain.sh:331-371` |
| constraint | The tree hash uses `git add -A`, which leaves ignored files out: copied files stay out of reuse matching and commits only if the target gitignores them. | `scripts/run-toolchain.sh:96-129` |
| constraint | The SubagentStop hook `post-implementation-audit.sh` calls `run-toolchain.sh --reuse` in agent worktrees, so a service start runs inside a hook's run. | `scripts/run-toolchain.sh:7` |
| constraint | `--skip` accepts only `lint typecheck format boundary test e2e`; Phase 1 stop audits skip `test`. | `scripts/run-toolchain.sh:140-143`; `modules/verification-setup.md:75` |
| constraint | Sign-off 5.8: `ExitWorktree` first, then `spec-worktree.sh remove` from the main checkout; with a PR still open the stakeholder is told to run the commands later. | `modules/sign-off.md:267-273` |
| constraint | Claude agents launch without `isolation`, confined by a `cd <wt> &&` prefix; the guard finds the worktree by name under `<spec checkout>/.workflow/.worktrees/`. | `references/launching.md:30,51` |

Friction: the worktree lifecycle is split between one script (spec worktree) and prose repeated in five step files (agent worktrees).

## Not found

- A unit test for `rules-setting.sh`: `tests/scripts/*rules-setting*`, `tests/**/*settings*`. Reported by retrieval.
- Any copy of gitignored config, dependency install or port allocation: `.agents/`, `install.sh`, `tests/`. Only `check-write.sh:126` and `check-worktree-scope.sh:25` mention symlinks, both for path canonicalisation. Reported by retrieval.
- Tests for `review-targets` serve startup: no suite found by name. Reported by retrieval.
- Tests for `check-worktree-scope.sh` symlink handling: `tests/hooks/worktree-guard.sh` and `tests/scripts/check-write-paths.sh` were listed, not read line by line. Reported by retrieval.
- Existing suites that cover the area: `tests/scripts/spec-worktree.sh:64-187`, `tests/scripts/run-toolchain.sh:353-373`, `tests/hooks/worktree-guard.sh:43-51,453-454`, `tests/hooks/audit-agent-worktrees.sh:40-41`, `tests/lint/agent-worktree-docs.sh:97-118`, `tests/lint/review-escalation-docs.sh:50-62`. Reported by retrieval.
- A worktree setup, copy-list, symlink check, port allocation or teardown helper in feature-workflow: `scripts/`, `modules/`, `references/`, `SKILL.md`. Reported by module-audit.
- Out of scope noticed: `rules-setting.sh` exits 1 for usage errors while sibling scripts use 2 (`scripts/rules-setting.sh:33-34,49`); 3.10 runs `--e2e` with no app start (`modules/implementation-finish.md:7`). Reported by module-audit.
