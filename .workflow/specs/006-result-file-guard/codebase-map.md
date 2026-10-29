---
cache_stamps:
  modules: 99801e506b428a1ac3c3f7fb0170191cb6fa45ae
  flows: 99801e506b428a1ac3c3f7fb0170191cb6fa45ae
  architecture: 65ae1c501fe154e76b5dea5a3372718b3510cde6
---

# Codebase map: Sub-agents can write their own result file

Affected area: hooks (`.agents/hooks`), feature-workflow (`.agents/skills/feature-workflow`), agents (`.agents/agents`), tests (`tests`)

## Relevant code

| Item | What it does today | Source |
| --- | --- | --- |
| `check-task-result.sh` | Checks the shape of one result file (kind from file name or `--kind`: implementation, integration, mini-review). Prints `<field>: <problem>` lines or one bounded table; never writes. Enforces `task_id` equal to the `artifacts/<folder>/` name. | `.agents/skills/feature-workflow/scripts/check-task-result.sh:2-40`; `.workflow/cache/modules.md` § `.agents/skills/feature-workflow` |
| `check-review-findings.sh` | Checks the review-findings blocks the Phase 4 lenses write to pass files under `artifacts/review/pass-<n>/`. Adjacent; not a result file. | `.agents/skills/feature-workflow/modules/review-triage.md:47-53` |
| Worktree scope check | Denies a write whose path is inside the main checkout but outside the task worktree, which is the rule that refuses result files. A Bash command must start with `cd <dir> &&` unless cwd is inside the root or outside the main checkout. | `.agents/skills/feature-workflow/scripts/check-worktree-scope.sh:18-20`, `:110-113`, `:121-122` |
| Worktree write hook | Claude adapter. For implementation and integration sub-agents, denies Write/Edit outside `.workflow/.worktrees/s<NNN>_t<N>` and Bash not starting with `cd <worktree> &&`. Delegates to the scope check. | `.agents/hooks/worktree-write-guard.sh:2-7`, `:14-17`, `:22` |
| Result-file writes by sub-agents | Each agent writes its block with one quoted heredoc in one Bash call, `mkdir -p` first, into the main checkout via `main=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")`, then returns a summary with `result_file:`. The docs call the write allowed because `artifacts/` is unguarded. | `.agents/agents/implementation.md:82`, `:92-101`, `:135-139`; `.agents/agents/integration.md:72`, `:76-85`, `:121-125`; `.agents/agents/profile-mini-review.md:59`, `:67-70`, `:105-109` |
| Re-check file name | A re-check round writes `artifacts/<task_id>/mini-review-r<k>.yaml` with `previous:`; round one uses `mini-review.yaml`. | `.agents/agents/profile-mini-review.md:27`, `:32`; `check-task-result.sh:11`; `.workflow/decisions/pitfalls.md` § Write a mini-review re-check to the plain mini-review.yaml |
| Phase 1 and integration folders | `artifacts/phase-1-<work_type>/implementation.yaml` and `artifacts/integration-<work_type>/integration.yaml`, `task_id` = folder name. | `check-task-result.sh:8-9`; `.agents/skills/feature-workflow/modules/verification-setup.md:57-60` |
| Stop audit evidence | `post-implementation-audit.sh` writes `artifacts/<task-id>/audit.json` and `audit-warnings.jsonl`. | `.agents/hooks/post-implementation-audit.sh:6`, `:103-109`, `:238` |
| Evidence cleanup | The e2e evidence step deletes only `JRN-*`, `untagged`, `evidence-index.json`, `e2e-results.json` in its destination; it does not touch result files. | `.agents/hooks/evidence-capture.sh:22-23`, `:215` |
| Review pass files | Lenses write `artifacts/review/pass-<n>/<lens>.yaml` by heredoc; not result files. | `.agents/agents/review-standards.md:105-108`; `.agents/agents/review-end-state.md:74-77`; `.agents/agents/review-lessons.md:71-74`; `.agents/agents/review-targets.md:31`, `:118` |
| Checker tests | Valid files, Phase 1 folder naming, `task_id` mismatch, scope-expansion and profile-wrong, mini-review `task_id`, missing and unparseable files. | `tests/scripts/check-task-result.sh:54-126`, `:241-244`, `:312-313`, `:340-359` |
| Worktree guard tests | Cover the worktree hook and scope rules. | `tests/hooks/worktree-guard.sh`; `.workflow/cache/modules.md` § tests |

## Seams and interfaces

| Interface | Shape (signature, type, contract) | Callers | Source |
| --- | --- | --- | --- |
| `check-task-result.sh <file> [--kind implementation\|integration\|mini-review]` | Exit 0 valid; 1 with one line per shape error; 2 on usage, missing tool, unreadable file, unknown kind, unparseable YAML or jq failure. Read-only. | Orchestrator after each launch; integration and implementation resume; merge gate 3.16 | `check-task-result.sh:11-12`; `verification-setup.md:60`; `integration.md:85`; `implementation.md:101` |
| Result file path, implementation | `<spec_dir>/artifacts/<task_id>/implementation.yaml` in the main checkout | Implementation agent | `.agents/agents/implementation.md:92`; `check-task-result.sh:23` |
| Result file path, integration | `<spec_dir>/artifacts/integration-<work_type>/integration.yaml` | Integration agent | `.agents/agents/integration.md:76` |
| Result file path, mini-review | `<spec_dir>/artifacts/<task_id>/mini-review.yaml`, or `mini-review-r<k>.yaml` on re-check | Profile mini-review agent | `.agents/agents/profile-mini-review.md:67`, `:27` |
| Stop-audit hook | Command hook, Stop event; blocks on a failing toolchain; writes audit files under `artifacts/` | Session host | `.agents/hooks/post-implementation-audit.sh:1-10`, `:41-48` |
| `WF_WORKTREES`, `wf_path`, `wf_main_root`, `wf_norm_folder` | Worktree root; path join; main checkout root (status 1 outside git); `$WF_SPECS/NNN-slug` (status 1 with reason) | Hooks and skill scripts | `.agents/lib/workflow-paths.sh:49-100` |
| `worktree-write-guard.sh` | PreToolUse JSON; acts only for `agent_id` set and `agent_type` implementation or integration; deny JSON or nothing; fail closed | Claude PreToolUse `Bash\|Write\|Edit\|NotebookEdit` | `.agents/hooks/worktree-write-guard.sh:8-19`, `:69-112`; `claude-settings.template.json:65` |
| Stop-audit worktree resolution | Codex: `<task_name>` worktree; Claude with `task_id`: `s<NNN>_t<N>`, else linked cwd, else `warn_allow`; Claude without `task_id`: payload cwd, unchecked | SubagentStop, Claude matcher `implementation` | `post-implementation-audit.sh:162-164`, `:209-222`; `claude-settings.template.json:105-111` |
| `codex_enc <s>` (two copies) | Lowercase; every char outside `[a-z0-9]` → `_`; no newline; status 0 | `codex-pre-spawn.sh:77`, `:119`; `post-implementation-audit.sh:148` | `codex-pre-spawn.sh:70`; `post-implementation-audit.sh:125` |
| Merge sites | Phase 1 `git merge --no-ff <branch>` (1.2/1.3); integration `--no-ff` (3.2); task `--no-ff` (3.16); light path `--ff-only <head_commit>` | Orchestrator | `modules/verification-setup.md:75`; `modules/implementation-orchestrator.md:113`, `:190-197` |
| `commit-workflow-data.sh <spec-dir> -m <msg> [--cwd]` | Commits the spec folder incl. `artifacts/` on the spec branch; exit 0, 1 (off branch or mid-merge), 2 | Wave start, end of 3.16, hand off | `scripts/commit-workflow-data.sh:11-21` |

## Prior decisions

| Decision or item | What it says | Source |
| --- | --- | --- |
| Pitfall: Fork a Phase 1 build's worktree from the spec branch | The 1.2 harness agent's worktree started at `main`; the guard refused its result-file write and the orchestrator copied it by hand. Prevention: none yet. | `.workflow/decisions/pitfalls.md` § Fork a Phase 1 build's worktree from the spec branch |
| Pitfall: Never pipe a gate checker into head inside a && chain | `check-task-result.sh ... \| head -1 && git merge` merged despite exit 1. Prevention: none yet. | `.workflow/decisions/pitfalls.md` § Never pipe a gate checker into head |
| Pitfall: Write a mini-review re-check to the plain mini-review.yaml | A re-check reviewer wrote `mini-review-r2.yaml`; the orchestrator renamed it. | `.workflow/decisions/pitfalls.md` § Write a mini-review re-check to the plain mini-review.yaml |
| Retrospective 005, process lesson | The worktree guard denied every coding and review agent's own result file; copying each out was an extra step per launch. Points to this spec. | `.workflow/decisions/retrospectives/005-cache-build-followups.md` § Process lessons |
| Retrospective 003, L3 and L5 | L3: the Phase 1 launch itself must change; a pitfall alone did not stop the refused write. L5: mini-review writes the plain `mini-review.yaml`. | `.workflow/decisions/retrospectives/003-bash-cache-extractor.md` § Process lessons, § Action items |
| Retrospective 005, model observation | T5's first `mini-review.yaml` did not parse; agent resumed to rewrite it. | `.workflow/decisions/retrospectives/005-cache-build-followups.md` § Model observations |
| ADR-0001 Project baseline | Hooks are adapters over skill scripts; state is files in git; install ships what the manifest lists; tests run by hand. | `.workflow/decisions/adr/0001-project-baseline.md` |
| Rules, Cross-cutting policy | Scripts are bash; the `# File:` header is the interface doc; comments give reasons, no decision or task IDs; new `.agents/` assets need PROVENANCE and manifest entries. | `.workflow/rules.md` § Cross-cutting policy |
| Rules, Required versions | bash 3.2: no `declare -A`, `mapfile`, `${x,,}`, `declare -n`, `coproc`, `\|&`, `&>>`. | `.workflow/rules.md` § Required versions |
| Rules, Shared core | Shared core is `.agents/lib/**`; result-file paths are not shared core. | `.workflow/rules.md` § Shared core |
| Deferred shelf | No `.workflow/deferred/` file matches this concept by concept; nearest by area are `sign-off-scoped-commit.md`, `harness-run-lint-target.md`, `session-start-timing-target.md`. | `.workflow/deferred/` |

## Library options

Concerns: (1) result-file shape validation; (2) YAML front-matter parsing. Settled by rules: bash 3.2+, git, jq (any), yq (mikefarah v4), shellcheck (`.workflow/rules.md` § Required versions). "External systems" is empty.

No package manifest exists; the project is bash plus markdown.

### Already in the project

- jq (system binary, any version): `install.sh:94`; used in `.agents/hooks/evidence-capture.sh:55-71`. JSON parse, query, build; no schema language.
- yq (mikefarah v4): `install.sh:95-101`; used in `.agents/hooks/evidence-capture.sh:141-154`. YAML and front-matter read.
- bash 3.2+ and coreutils: `install.sh:89`. Covers the guard logic.

### JSON Schema validation (result-file shape)

Verdict: Use existing (jq checks in bash). Reject ajv: no Node runtime, no manifest, and the 8.17.x line carries GHSA-2g4f-4pwh-qvx6.

| Option | Fit | Licence | Maintenance | Security | Cost |
| --- | --- | --- | --- | --- | --- |
| jq 1.8.2 (incumbent) | pass: covers JSON used by hooks | pass: MIT core (COPYING) | pass: jq-1.8.2, 2026-06-20 | unknown | pass: 0 deps |
| ajv 8.17.1 (rejected) | fail: Node validator; no Node runtime | pass: MIT | caution: latest 8.20.0, 2026-04-24 | fail: GHSA-2g4f-4pwh-qvx6 (<8.18.0) | caution: new npm runtime |
| Build in-house (bash + jq) (chosen) | pass: matches shell-scripts profile | n/a | n/a | n/a | pass: no new dependency |

### YAML front-matter parsing

Verdict: Use existing (yq v4).

| Option | Fit | Licence | Maintenance | Security | Cost |
| --- | --- | --- | --- | --- | --- |
| yq v4.54.1 (incumbent) | pass | pass: MIT | pass: v4.54.1, 2026-09-29 | unknown | pass: already required |
| Python yq | fail: rejected by `install.sh:101` and rules | n/a | n/a | n/a | n/a |

### Evidence

- https://api.deps.dev/v3/systems/npm/packages/ajv
- https://api.deps.dev/v3/systems/npm/packages/ajv/versions/8.17.1
- https://api.github.com/advisories/GHSA-2g4f-4pwh-qvx6
- https://api.github.com/repos/jqlang/jq/releases/latest
- https://raw.githubusercontent.com/jqlang/jq/master/COPYING
- https://api.github.com/repos/mikefarah/yq/releases/latest
- https://raw.githubusercontent.com/mikefarah/yq/master/LICENSE

Risks: tests should not depend on `jq -e` behaviour that differs between 1.7 and 1.8. Unverified: jq and yq advisories and Scorecard.

## Module audit

Owning modules: feature-workflow, hooks, lib (shared core). One `module-audit` per module (0.4.6).

### feature-workflow

| Kind | Finding | Source |
| --- | --- | --- |
| reuse | The command rule is the place to extend: after a root is found, cwd-in-root or outside-main allows, then the `cd <dir> &&` regexes; a read-only allowlist goes between the cwd check and `deny_cmd`. | `.agents/skills/feature-workflow/scripts/check-worktree-scope.sh:101-104`, `:120-141` |
| reuse | Regex-in-variable with `BASH_REMATCH` is the bash 3.2-safe parsing style; `canon` and `under` resolve and compare paths. | `check-worktree-scope.sh:57-90`, `:125-131` |
| reuse | `commit-workflow-data.sh` is the closest pattern for a main-checkout git gate (`wf_main_root`, `wf_norm_folder`, spec-branch check, refuses mid-merge, literal pathspecs). | `scripts/commit-workflow-data.sh:52-66`, `:93` |
| reuse | Worktree creation for Phase 1 and integration already exists in the Codex branches: `git worktree add .workflow/.worktrees/<task_name> -b wf/NNN-slug/<task_name>`; wave start gives the explicit start point `spec/NNN-slug`. | `modules/verification-setup.md:46`; `modules/implementation-orchestrator.md:41`, `:122` |
| reuse | Result files carry `branch` and `worktree`; modules read the branch with `yq '.branch'`. | `scripts/check-task-result.sh:21`, `:30`, `:123`; `modules/verification-setup.md:75` |
| gap | No feature-workflow script builds or parses worktree names; `enc` exists only as prose. `resolve-launch.sh` validates header fields only and is untouched. | `SKILL.md:190`; `scripts/resolve-launch.sh:103-105` |
| gap | Pipes and `&&` are not parsed; every read from a main-checkout cwd is denied when a root exists. | `check-worktree-scope.sh:125-136` |
| gap | Allowlisted tools can write or run programs without `>`, `tee` or `;`: `sed -n` with `w`/`W` or `-i`; `find -fprint/-fprintf/-fls/-ok/-execdir`; `yq -i`; `git diff/log/show --output=`; `rg --pre`. Shell forms `$(...)`, backticks, `<(`/`>(`, `\|\|`, `&`, newlines also pass such a check. | `check-worktree-scope.sh:137` |
| gap | No merge gate exists. Five merge sites are prose `git merge` lines; the light-path site merges a commit (`--ff-only <head_commit>`, `branch: null`), not a branch. | `modules/verification-setup.md:75`; `modules/implementation-orchestrator.md:113`, `:193`, `:197` |
| gap | The spec branch already holds committed `artifacts/` and task branches fork from it, so the gate must diff from the merge-base; "adds" misses modified or deleted artifact files. | `modules/implementation-orchestrator.md:118-121`, `:199-205`; `scripts/commit-workflow-data.sh:3-6` |
| gap | Without isolation, Phase 1 and integration lose their branch source (`worktreeBranch` from the Agent result). | `modules/verification-setup.md:75`; `modules/implementation-orchestrator.md:113` |
| gap | No Phase 1 worktree cleanup or reuse rule; 1.3 must fork after the 1.2 merge, and a 1.4 loop-back relaunches a build. | `modules/verification-setup.md:90`, `:114`; `modules/implementation-orchestrator.md:126`, `:297` |
| constraint | Scope check exits: 0 allow, 2 deny, 1 usage (adapters deny); its `# File:` header is the interface doc. Other gates use 0/1 refused/2 usage; a new gate picks one and must not be piped into `head`. | `check-worktree-scope.sh:2-26`; `scripts/commit-workflow-data.sh:17-20`; `scripts/check-task-result.sh:55-57` |
| constraint | Accident prevention only; a regex check, not a parser; the main session is never confined. A cwd in a sibling worktree counts as "in the main checkout". | `check-worktree-scope.sh:18`, `:22`, `:101-104`, `:121` |
| constraint | `--worktree-name` must be a plain name (no `/`, no leading `.`). | `check-worktree-scope.sh:55` |
| constraint | Merges run in the main checkout on the spec branch, in task-id order, none while `blocked`; a conflict is `git merge --abort` then resume. | `modules/implementation-orchestrator.md:177`, `:207-209`; `modules/verification-setup.md:26` |
| constraint | Phase 1 must fork from the spec-branch tip; integration's launch-table row says `isolation: "worktree"`; the fallback text (`baseRef: head`) goes. | `modules/implementation-orchestrator.md:14`, `:29`; `modules/verification-setup.md:26`, `:45` |
| constraint | `steps.tsv` holds 1.2-1.5, 3.2, 3.16 as rows; a gate inside an existing node needs no new row. | `references/steps.tsv:74-77`, `:85`, `:92` |

### hooks

| Kind | Finding | Source |
| --- | --- | --- |
| reuse | The guard already parses integration headers; the header JSON has `spec_dir`, `task_id`, `work_type`, enough for all three names. Spec number comes from `${spec_dir%/}` → `##*/` → `%%-*`. | `.agents/hooks/worktree-write-guard.sh:83-87`; `.agents/hooks/post-implementation-audit.sh:203-211` |
| reuse | The two `codex_enc` copies are identical; reverse lookup (encode every profile, require one match) appears twice. | `codex-pre-spawn.sh:70`, `:115-122`; `post-implementation-audit.sh:125`, `:141-151` |
| reuse | Claude Phase 3 stop-audit lookup (named worktree, else linked-worktree cwd, else `warn_allow`) is the pattern for Phase 1. | `post-implementation-audit.sh:209-222` |
| gap | The guard names a worktree only for `task_id` `^T[0-9]+$`; once Phase 1 and integration launch without isolation, rule 2 no longer applies and the guard allows: those agents would be unconfined. | `worktree-write-guard.sh:88-90`, `:15-16` |
| gap | Header `work_type` is raw (`shell-scripts`); names need `enc(work_type)`; nothing on the Claude path encodes it. | `worktree-write-guard.sh:86-90`; `codex-pre-spawn.sh:15-16` |
| gap | Stop audit, Claude Phase 1: no named-worktree lookup; without isolation it silently audits the main checkout. | `post-implementation-audit.sh:29`, `:210`, `:224-232` |
| gap | Stop audit never runs for integration agents: the hook exits for any `agent_type` but `implementation`, and the Claude matcher is `implementation`. | `post-implementation-audit.sh:73`; `.agents/hooks/claude-settings.template.json:107` |
| constraint | Name builders: `worktree-write-guard.sh:87-89`, `post-implementation-audit.sh:211-212`. Name parsers: `post-implementation-audit.sh:127-165`, `codex-pre-spawn.sh:124-158`, `codex-write-guard.sh:114-115`. | as cited |
| constraint | `codex_enc` also encodes agent type names (`fact-lookup` → `fact_lookup`); a shared encoder must keep that call. | `codex-pre-spawn.sh:77` |
| constraint | Phase 1 evidence ids use the raw work type (`phase-1-<work_type>`); worktree name and artifacts folder stay distinct. | `post-implementation-audit.sh:161`, `:230` |
| constraint | Guard is fail-closed after `CONFINED=1`: new code under `set -e` must not exit non-zero by accident. | `worktree-write-guard.sh:35-46`, `:61` |
| constraint | `codex-pre-spawn.sh` sources lib only after confirming the workflow is installed. | `codex-pre-spawn.sh:63-66` |
| constraint | The stop audit never blocks on launch or environment problems (`warn_allow`); Phase 1 audits pass `--skip test`. | `post-implementation-audit.sh:38-49`, `:96-115`, `:231` |
| constraint | `codex-write-guard.sh` reads the same names; forms stay byte-identical to what Codex orchestrators create. | `codex-write-guard.sh:18-23`, `:107-117` |
| constraint | Docs that become wrong: `claude-settings.template.md:13`, guard header `worktree-write-guard.sh:4-7`, `:13-16`, audit header `post-implementation-audit.sh:29`. | as cited |

### lib

| Kind | Finding | Source |
| --- | --- | --- |
| reuse | `WF_WORKTREES` is the worktree root; `wf_`-prefixed pure helpers print to stdout and return 1 with a reason, never `exit`; each has a one-line header comment. | `.agents/lib/workflow-paths.sh:15-20`, `:49`, `:57-100` |
| reuse | `LC_ALL=C` already pins byte-stable coreutils results in lib. | `.agents/lib/test-paths.sh:78` |
| reuse | `wf_norm_folder` enforces `NNN-slug`, the source of `<NNN>`. | `.agents/lib/workflow-paths.sh:95` |
| gap | No encoder, name builder or `NNN` extractor in lib. | `.agents/lib/**` |
| constraint | bash 3.2 (no `${x,,}`); functions safe under `set -euo pipefail`, all variables `local`. | `.agents/lib/workflow-paths.sh:1`, `:20` |
| constraint | Lib file header (`# File:`/`# Purpose:`/`# Usage:`/`# API:`/`# Sources:`) is the interface doc; new functions join `# API:`. | `.agents/lib/workflow-paths.sh:2-22` |
| constraint | A function in `workflow-paths.sh` needs no manifest or PROVENANCE change and reaches every caller already (about 23 scripts source it); a new lib file needs a manifest line, two PROVENANCE rows and a `tests/scripts/lib-<name>.sh` suite. | `git show --stat 6a5644a`; `git show --stat 44d8e93` |
| constraint | Lib history lands stubs with failing tests first, real code after. | `git log --oneline -- .agents/lib` |

## Not found

- Capability entries for result files, artifacts, worktree or evidence: `.workflow/capabilities.md`. Reported by retrieval.
- Result-file references in ADR-0002, ADR-0003 and retrospectives 002-004 beyond the entries above: `.workflow/decisions/`. Reported by retrieval.
- Guard code that names `artifacts` (the agent docs say `artifacts/` is unguarded, but no code exempts it): `.agents/hooks/`, `.agents/skills/feature-workflow/scripts/check-worktree-scope.sh`. Reported by retrieval.
- Any existing merge gate, read-only allowlist, or `|`/`&&` segment parsing: `.agents/skills/feature-workflow/scripts/`, `modules/`. Reported by module-audit.
- Any hook besides `worktree-write-guard.sh`, `post-implementation-audit.sh`, `codex-pre-spawn.sh`, `codex-write-guard.sh` that builds or parses `s<NNN>_` names: `.agents/hooks/**`. Reported by module-audit.
- Cache disagrees with code: none. The "Worktree write hook" row omits the rule-2 fallback and the allow when neither rule applies (`worktree-write-guard.sh:15-16`); a retrieval summary gap, not a cache fault. Reported by module-audit.
