---
cache_stamps:
  modules: null
  flows: null
  architecture: null
---

# Codebase map: Large path: planning a large subject into several specs

Affected area: feature-workflow (`.agents/skills/feature-workflow`), agents (`.agents/agents`), hooks (`.agents/hooks`), lib (`.agents/lib`, shared core), tests (`tests`), root-docs (`AGENTS.md`, `README.md`, `.agents/README.md`).

All three Tier B caches were missing and could not be regenerated (the working tree under the scope had uncommitted changes), so `retrieval` read the code and the stamps are null.

## Relevant code

| Item | What it does today | Source |
| --- | --- | --- |
| Skill description | "Sizes a request (trivial edit, light path or full path)"; rule: "smallest amount of process that safely fits the change (design rule 1)" | `.agents/skills/feature-workflow/SKILL.md:3,19` |
| § 2 Size the request | Only intake gate is 0.0.1 trivial edit (Yes → 0.0.2 edit directly, No → discovery 0.1); "Light versus full path is decided later, at 0.3.20 ... Do not pick it at intake." | `.agents/skills/feature-workflow/SKILL.md:48-55` |
| § 3 Route by status | Reads `.status, .light_path, .blocked_condition`; `ready-for-dev` + `light_path: true` → implementation-orchestrator 3.1; `ready-for-dev` otherwise → verification-setup 1.1 | `.agents/skills/feature-workflow/SKILL.md:62,70-73` |
| § 6 Modules table | discovery exits to implementation-orchestrator (light) or verification-setup (full); orchestrator "Entered from ... discovery (light path)" | `.agents/skills/feature-workflow/SKILL.md:197,203` |
| 0.3.19 Settle the goal | Evaluates the three light-path facts and writes `light_path` into spec.md (`true` only when all three clean); budget written at 0.3.20 (light) or 2.5 (full) | `.agents/skills/feature-workflow/modules/questioning-loop.md:67-81,87` |
| 0.3.20 Light-path test | Reads `light_path`; facts table: Intent gaps, Irreversible actions, Footprint ("one owning module, one capability ... about 100 changed lines; more than five files that are not simple or mechanical is not small"); true → spec branch, budget, one-task `tasks.md` + `T01`, commit, `ready-for-dev --step 0.3.20`; false → 0.4 | `.agents/skills/feature-workflow/modules/discovery.md:126-171` |
| 0.4–0.6 | Headed "Model the impact (full path)"; Done-when lists light vs full outputs | `.agents/skills/feature-workflow/modules/discovery.md:173,234-237` |
| Orchestrator 3.1 / 3.13 | Light path also sets `baseline_revision` at 3.1; 3.13 suites "always yes" on full, looked up on light; missing suite skips its gate, recorded at 3.14 | `.agents/skills/feature-workflow/modules/implementation-orchestrator.md:65,67` |
| § 3.13-3.14 Light path without suites | Harness only → `in-review --step 3.14` after 3.9; neither → `in-review` at 3.14 straight to Phase 4 | `.agents/skills/feature-workflow/modules/implementation-orchestrator.md:215-220` |
| Light-path worktree/merge | `branch: null` → detached worktree at spec-branch tip; `git merge --ff-only`, no PR | `.agents/skills/feature-workflow/modules/implementation-orchestrator.md:103,162` |
| task-breakdown 2.5 | `tasks.md` and task files created "only at 2.5 (or 0.3.20 on the light path)" | `.agents/skills/feature-workflow/modules/task-breakdown.md:75` |
| spec.md template frontmatter | `light_path: false # true once the 0.3.20 light-path test passes`; `light_path: boolean`; "Add no other keys"; `in-review` at 3.11 or 3.14; `budget` written at 2.5 (0.3.20 light) | `.agents/skills/feature-workflow/assets/spec.md:6,10,21,28,34` |
| tasks.md / task.md templates | `branch: null` on the light path (T1 commits on the spec branch); task file written at 2.5 or 0.3.20 (T01 only) | `.agents/skills/feature-workflow/assets/tasks.md:13,35`; `.agents/skills/feature-workflow/assets/task.md:3` |
| steps.tsv | Columns `id, phase, track, title`; `track both \| full \| light`; 0.3.20 is `both`; 0.4.1–2.6 are `full`; 3.14 is the only `light` row; "Keep in step with the workflow's node ids; tests/lint/step-list.sh checks this" | `.agents/skills/feature-workflow/references/steps.tsv:4-5,11,57-80,92` |
| step-progress.sh | `--path full\|light`, default from spec.md `light_path`; light path "runs Phases 0, 3, 4 and 5 ... shows 'of 4'"; `die "--path must be full or light"` | `.agents/skills/feature-workflow/scripts/step-progress.sh:7-11,48,54-55,64` |
| status-transition.sh | `draft → ready-for-dev` at `0.6 \| 0.3.20`; `→ in-review` at `3.11 \| 3.14`; `spec_branch` set only at 1.1 (full) or 0.3.20 (light), else `illegal`; script never reads `light_path` | `.agents/skills/feature-workflow/scripts/status-transition.sh:16,35,37,61,366` |
| check-write.sh | `SPEC_STEPS` includes 0.3.19, 0.3.20, 1.1, 2.5, 3.1, 3.14; `TASKS_STEPS="2.5 0.3.20"` | `.agents/skills/feature-workflow/scripts/check-write.sh:56-62` |
| open-task-pr.sh, budget-check.sh | Skip PR when `branch` null ("light path: it commits on $SPEC_BRANCH"); budget note names 1.1 or 3.1 baseline | `.agents/skills/feature-workflow/scripts/open-task-pr.sh:77`; `.agents/skills/feature-workflow/scripts/budget-check.sh:296` |
| implementation agent | On light path `git branch --show-current` prints nothing (detached worktree) and passes | `.agents/agents/implementation.md:30` |
| hooks | No hook reads `light_path` or a path term; session-start-resume reads `[.status, .blocked_condition]` only | `.agents/hooks/session-start-resume.sh:104` |
| lib | `workflow-paths.sh` is path constants (`WF_DIR`, `WF_SPECS`, `WF_DEFERRED`, `WF_CACHE`...); no path-choice logic | `.agents/lib/workflow-paths.sh:2-13,18-30` |
| tests/lint/step-list.sh | Track enum regex; per-phase counts pinned: full `0:47 1:5 2:6 3:14 4:8 5:9`, light `0:35 3:15 4:8 5:9`; ids must equal `PLAN/decision-flow-reference.md` and `PLAN/decision-flow.mermaid`; every `--step` id in `.agents/` must be in the tsv | `tests/lint/step-list.sh:16-17,27,41,45,55-57,59-69` |
| tests/scripts/step-progress.sh | Expects "of 6" (full) and "of 4" (light); off-path ids exit 2; `--path medium` is a usage error (exit 1); `light_path: true` in spec.md selects light | `tests/scripts/step-progress.sh:20-49,62,72-76` |
| tests/scripts/status-transition-check-write.sh | Template validator requires `light_path` to be `!!bool`; `branch null (light path)` accepted | `tests/scripts/status-transition-check-write.sh:70,702` |
| tests/hooks fixtures | `light_path: false` used as the body-edit line in guard payloads | `tests/hooks/write-guards.sh:68,81,83,171`; `tests/hooks/codex-adapters.sh:112-114`; `tests/hooks/codex-shim.sh:26`; `tests/hooks/audit-sync-resume.sh:24` |
| root-docs | README one-liner: "sizes a request, runs discovery through sign-off"; AGENTS.md names the skill only; `.agents/README.md` does not mention it | `README.md:23`; `AGENTS.md:16,41` |
| Outside the area, consumes `light_path` | Retrospective evidence: on light path `verification-plan.md` "absent by design"; rules.md template Size budget names 0.3.20 | `.agents/skills/retrospective/modules/evidence.md:21`; `.agents/skills/project-setup/assets/docs/rules.md:54` |
| PLAN flow docs (scaffold-only, lint-bound) | `gLight` 0.3.20 node; Yes → light path → orch, No → full path → impact; 3.13 "Always yes on the full path"; 3.14 "Light path only" | `PLAN/decision-flow.mermaid:97,148-149,291-292,365,376`; `PLAN/decision-flow-reference.md:62,270,459` |

## Seams and interfaces

| Interface | Shape (signature, type, contract) | Callers | Source |
| --- | --- | --- | --- |
| `spec.md` frontmatter `light_path` | boolean, default `false`; written once at 0.3.19; "Add no other keys" | Writer: questioning-loop 0.3.19. Readers: SKILL.md route, discovery 0.3.20, step-progress.sh, retrospective evidence; validator in tests | `.agents/skills/feature-workflow/assets/spec.md:6,28,34`; `tests/scripts/status-transition-check-write.sh:70` |
| `status-transition.sh status <dir> ready-for-dev --step 0.6\|0.3.20`; `... in-review --step 3.11\|3.14`; `set-spec --spec-branch --step 1.1\|0.3.20` | Step ids are the only path signal the single writer validates; other pairs exit 2 | discovery, orchestrator, verification-setup | `.agents/skills/feature-workflow/scripts/status-transition.sh:14-19,35,37,366` |
| `step-progress.sh <id> [--path full\|light] [--at <id>]` | stdout one line; exit 2 for an id not on the chosen path; exit 1 for a bad `--path` | orchestrator before each update; `tests/scripts/step-progress.sh` | `.agents/skills/feature-workflow/scripts/step-progress.sh:7-17,48` |
| `references/steps.tsv` | 4 tab columns; `track` enum `both\|full\|light\|phase\|cross\|intake\|side`; counts per path pinned by lint | step-progress.sh; `tests/lint/step-list.sh` | `.agents/skills/feature-workflow/references/steps.tsv:4-12`; `tests/lint/step-list.sh:27,55-57` |
| `check-write.sh` `SPEC_STEPS` / `TASKS_STEPS` | Space-separated step lists gating spec.md and tasks.md writes | spec-single-writer-guard, codex-write-guard | `.agents/skills/feature-workflow/scripts/check-write.sh:61-62` |
| `tasks.md` record `branch` | `task/<NNN-slug>/T<nn>-<slug>` or `null` on the light path | open-task-pr.sh, implementation agent, orchestrator 3.3/3.16 | `.agents/skills/feature-workflow/assets/tasks.md:35`; `.agents/skills/feature-workflow/scripts/open-task-pr.sh:77`; `.agents/agents/implementation.md:30` |
| SKILL.md § 3 route table | `(status, .step, light_path)` → module + resume step | main session on every resume | `.agents/skills/feature-workflow/SKILL.md:66-80` |
| `status-transition.sh step <spec-dir> <node>` + `.step` file (module-audit) | `step: "<node>"`, `updated_at: "<UTC>"`, optional `blocked_from`; atomic `mktemp`+`mv`; node id `^[0-9]+(\.[0-9]+)*$` | every module before a guarded write; read by `check-write.sh`, `step-progress.sh` | `.agents/skills/feature-workflow/scripts/status-transition.sh:20-25,73-76,114,150-166` |
| Spec-dir shape (module-audit) | `.workflow/specs/<NNN-slug>` with `^[0-9]{3,}-[A-Za-z0-9][A-Za-z0-9._-]*$`; absolute paths accepted if the parent is `.workflow/specs` | 4 scripts (own copies) | `.agents/skills/feature-workflow/scripts/status-transition.sh:134-145` and copies in budget-check, task-waves, open-task-pr |
| `check-write.sh --cwd <d> --path <f> [--agent] [--only spec\|tier-a\|tier-b] [--proposed <f>]` (module-audit) | classifies to `CLASS`/`KIND` by lower-cased repo-relative path, whole-segment prefix tests; exit 0 allow / 2 deny / 1 error | hooks (adapters, `--only`), modules on Codex | `.agents/skills/feature-workflow/scripts/check-write.sh:5-12,43,162,181-211` |
| Tier A gate (module-audit) | allow when no `.workflow/specs/*/spec.md` has status != done; else newest `.step` among in-flight specs must be in `GLOSSARY_STEPS`/`TIER_A_STEPS`/profile steps | `domain-modeling` (0.3.15, 0.2.3, 0.4.3), sign-off 5.3/5.7 | `.agents/skills/feature-workflow/scripts/check-write.sh:65-68,300-331` |
| `resolve-launch.sh` requirements table (module-audit) | per type `{d31_fields[], shapes[{when, required[], optional[]}], header_optional, profile: whole\|checklist\|none}`; `FORMATS.spec_dir`; `spec_dir` must exist under the main checkout; model from `.agents/agents/<type>.md` → `model-map` | `hooks/pre-launch.sh`, `post-implementation-audit.sh`, Codex orchestrator mode | `.agents/skills/feature-workflow/scripts/resolve-launch.sh:48-97,122-129,265-267,288-307` |
| `step-progress.sh` output (module-audit) | `Phase %d of %d · step %d of %d — %s: %s (%s)`; `cross` rows appended as ` · <title> (00.x)`; `intake` prints nothing; exit 2 off-path | orchestrator progress line | `.agents/skills/feature-workflow/scripts/step-progress.sh:81-110` |
| `assets/spec.md` frontmatter validator (module-audit) | yq `-e` expression; optional keys via `((.k // "") \| tag) == "!!str"`; `blocked_condition` iff `blocked` | sign-off 5.3 Done check; tests | `.agents/skills/feature-workflow/assets/spec.md:43-55`; `modules/sign-off.md:65` |
| `design-log.md` contract (module-audit) | no frontmatter; `## YYYY-MM-DD <type>: <title>`; `Spec: [spec.md](spec.md)` line; entry shapes incl. Origin (first entry when seeded) | questioning-loop, discovery, review-triage, discovered-work, sign-off | `.agents/skills/feature-workflow/assets/design-log.md:1-28` |
| Deferred archive (module-audit) | `superseded_by: .workflow/specs/NNN-slug` first key, file moved to `.workflow/deferred/archive/`; prose contract only | discovery 0.1.5, 0.2.6 shelf match | `.agents/skills/feature-workflow/modules/deferred-handoff.md:43-51`; `assets/deferred.md:8-15` |
| Work-item lifecycle (module-audit) | `status open\|promoted\|moved-to-deferred\|dismissed`, `promoted_to` iff promoted; deleted at the new spec's 0.6/0.3.20 | discovery 0.1.4, sign-off 5.9, discovered-work 00.26 | `.agents/skills/feature-workflow/assets/work-item.md:1-34`; `modules/discovery.md:30-35` |
| Sign-off order (module-audit) | 5.1–5.5, 5.9, 5.7 (`done --step 5.7`, from `in-review` only), 5.8 merge | router `in-review` 5.x row | `.agents/skills/feature-workflow/modules/sign-off.md:3,124,127-131`; `SKILL.md:76` |
| Codex launch naming (module-audit) | `task_name` `s<NNN>_<enc(type)>`, checked against the `s<NNN>` spec folder by `hooks/codex-pre-spawn.sh` | every Codex launch | `.agents/skills/feature-workflow/SKILL.md:185` |
| External dependencies of the module (module-audit) | `.agents/lib/workflow-paths.sh` sourced in-process (`check-write.sh:53`, `status-transition.sh:86`, `resolve-launch.sh:43`, `budget-check.sh:55`, `task-waves.sh:51`); `.agents/agents/<type>.md` read at `resolve-launch.sh:295`; `domain-modeling`, `deeper-prompt`, `retrospective` skills invoked in-process (`questioning-loop.md:61`, `discovery.md:123`, `sign-off.md:118`); hooks as callers (tests call the scripts directly) | | |
| `open-task-pr.sh <spec-dir> <task-id> [--cwd <d>] [--record] [--dry-run]` (delta audit) | stdout one line: PR/MR URL or `skipped: <reason>`; exit 0 once args are valid, 1 usage; host from the `origin` URL substring; reuses an open PR for the same head/base; `--record` → `set-task --pr <url> --step 3.16`; never force-pushes | orchestrator 3.16 (`pr`, `pr-blocking`) | `.agents/skills/feature-workflow/scripts/open-task-pr.sh:7-25` |
| `rules-setting.sh <key> [--cwd <d>] [--rules <f>]` (delta audit) | keys `task_review` (`pr\|pr-blocking\|local`, default `pr`) and `main_branch` (default `origin/HEAD` target, else `main`); value on stdout; exit 1 unknown key, bad value, unparsable block | 1.1, 0.3.20, 3.16, 5.8, `open-task-pr.sh`, `budget-check.sh` | `.agents/skills/feature-workflow/scripts/rules-setting.sh:13-27,39-46` |
| `status-transition.sh set-spec <dir> --spec-branch <b> --step 1.1\|0.3.20` / `--impl-base <sha> --step 3.1` (delta audit) | branch must equal `spec/<NNN-slug>` and exist locally; impl base must contain `baseline_revision`; refused once `done`; writes `.step` | 1.1, 0.3.20, 3.1 | `.agents/skills/feature-workflow/scripts/status-transition.sh:14-19,358-399` |
| `status-transition.sh set-task <dir> T<n> --pr <url>\|null` (delta audit) | URL regex `^https?://[^[:space:]]+$`; any step; replaces with a stderr warning | `open-task-pr.sh --record` | `.agents/skills/feature-workflow/scripts/status-transition.sh:327-348` |
| Spec-branch lifecycle, prose contract (delta audit) | created off `main_branch` at 1.1 / 0.3.20 carrying the untracked folder; first commit = `baseline_revision`; folder-scoped commits at 1.5 and 2.6; task branches fork from and merge into it at 3.16; merged into main by PR at 5.8 with the stakeholder's go-ahead; never deleted | discovery, verification-setup, task-breakdown, orchestrator, sign-off | `.agents/skills/feature-workflow/modules/verification-setup.md:11-26,120-127`; `modules/task-breakdown.md:119`; `modules/sign-off.md:129` |

## Prior decisions

| Decision or item | What it says | Source |
| --- | --- | --- |
| ADR-0001 (accepted) | Workflow lives once in host-neutral `.agents/`; hooks are adapters over skill scripts; all state is files in git; `install.sh` ships only the manifest. Deferred list has no path-related item | `.workflow/decisions/adr/0001-project-baseline.md` § Deferred |
| rules.md Ownership | feature-workflow owns `.agents/skills/feature-workflow/**`, may depend on lib, regenerate-caches, domain-modeling, project-setup; agents → feature-workflow; hooks → lib, feature-workflow, project-setup; root-docs and lib depend on nothing; tests may depend on all | `.workflow/rules.md` § Ownership |
| rules.md Shared core | `.agents/lib/**`; "changes only through the integration agent, between batches" | `.workflow/rules.md` § Shared core |
| rules.md Size budget | Copied into `budget` "when tasks.md is written (2.5, or 0.3.20 on the light path)"; defaults 10 tasks / 30 files; "Changed only at 5.3" | `.workflow/rules.md` § Size budget |
| rules.md Cross-cutting policy | Scripts are bash; comments carry no decision IDs or doc paths; nothing in `.agents/` depends on `tests/`; README never restates the hooks/scripts tree; PROVENANCE, manifest and lineage updated with any `.agents/` change | `.workflow/rules.md` § Cross-cutting policy |
| rules.md Required versions | bash 3.2, no bash 4 constructs; yq mikefarah v4 | `.workflow/rules.md` § Required versions |
| rules.md External systems | Section is empty | `.workflow/rules.md` § External systems |
| Pitfall: README tree drift | README hooks/scripts lists drifted; prevented by the "point at the folder" rule (root-docs) | `.workflow/decisions/pitfalls.md` § Point at a folder instead of restating its tree in the README |
| capabilities.md | Table is empty; no CAP exists for sizing or paths | `.workflow/capabilities.md` |
| Deferred shelf | No match: folder holds only `.gitkeep` | `.workflow/deferred/` |

## Library options

Concerns: PR/MR hosting CLI (initiative/child-spec PRs at 3.16 and sign-off); bash test harness for new scripts; YAML frontmatter, JSON, git/worktrees, shell lint, child-spec DAG ordering. Settled by rules: YAML = mikefarah yq v4, JSON = jq, git any, shellcheck any, bash 3.2 with no bash-4 constructs, no second language without an ADR (`.workflow/rules.md:136,153-156`); DAG ordering is already in-house jq (`.agents/skills/feature-workflow/scripts/task-waves.sh:104-189`), no library needed. Note: the `rules.md` "External systems" section is empty.

### Already in the project

- bash 3.2+, git, jq, mikefarah yq v4: preflight `install.sh:89-103`, `tests/lib/common.sh:76-96`; covers YAML/JSON/git. Versions unpinned ("any", yq v4.x); installed versions not checked (no shell in this run).
- shellcheck (any): `tests/run-all.sh:63-64`, `tests/lib/common.sh:99-106`; lint only.
- gh / glab (unpinned, user-installed): `.agents/skills/feature-workflow/scripts/open-task-pr.sh:82-83,108-113` (`gh pr list/create`, `glab mr list/create`); host chosen from `origin` URL; absent CLI degrades to `skipped:`.
- In-house test harness: `tests/lib/common.sh:31-76` (`ok/ko/skip/eq/check/preflight`), `tests/run-all.sh`; covers suite running for all modules.
- node (context-bridge.cjs): `.agents/hooks/claude-settings.template.json:5`; hooks only, stdlib `fs/os/path`, no npm deps; not touched by this concern.

### PR/MR hosting CLI

Verdict: Use existing (gh + glab via `open-task-pr.sh`); extend the same host-switch for initiative-level PRs rather than adding a tool.
Deprecation check: gh: no sunset; `gh-copilot` extension retired 2025-10-25 (unused here); flags `--base/--head/--title/--body` and `pr list --head/--base/--state/--json/--jq` current and not deprecated. glab: no sunset (GitLab is retiring `release-cli` in favour of glab); v2.0.0 will require `GLAB_`-prefixed env vars (`NO_PROMPT`, `DEBUG`, `GLAMOUR_STYLE`, `FORCE_HYPERLINKS`; none used under `.agents/`); `glab mcp serve` deprecated in v1.124.0 (unused); `mr create --target-branch/--source-branch/--title/--description/--yes` and `mr list --source-branch/--target-branch` current. Searches run: "GitHub CLI gh deprecated 2026 sunset", "glab GitLab CLI deprecated 2026 sunset", "GitHub CLI gh breaking changes migration 2026", "glab GitLab CLI breaking changes migration 2026".

| Option | Fit | Licence | Maintenance | Security | Cost |
| --- | --- | --- | --- | --- | --- |
| gh@2.103.0 (incumbent) | pass: all flags used exist; GitHub only | pass: MIT | pass: v2.103.0 2026-10-21, weekly cadence | caution: Scorecard 7 (Code-Review 10, Maintained 10, Dangerous-Workflow 10, Token-Permissions 0); 10 advisories in 2026 (Low/Moderate), fixes from 2.97.0 (2026-07-31) and 2026-09-30; none on the `pr` commands used | pass: user-installed binary, 0 project deps; ~0 days |
| glab@1.124.0 (incumbent) | pass: all flags used exist; GitLab only | pass: MIT | pass: v1.124.0 2026-10-20, weekly cadence | caution: Scorecard 5.9 but stale (2023-11-20, Code-Review 5); deps.dev lists no advisories for v1.124.0 | pass: user-installed binary; ~0 days |
| git-spice@0.32.0 (new, stacked PRs) | fail: GitHub-only submit, no GitLab path; replaces the host switch | fail: GPL-3.0-only (process-invoked, so caution in practice, but outside the permissive set) | pass: v0.32.0 2026-10-13 | unknown: no Scorecard on deps.dev or scorecard.dev; no advisories | caution: new binary for every user, new mental model; ~2-3 days + docs |
| in-house (git only, no PR; `task_review: local`) | pass: already the fallback path | n/a | n/a | n/a | pass: 0 days; loses the review record |

Evidence:
- official docs: https://cli.github.com/manual/gh_pr_create ; https://cli.github.com/manual/gh_pr_list ; https://docs.gitlab.com/cli/mr/create/ ; https://docs.gitlab.com/cli/mr/list/
- registry (deps.dev): https://api.deps.dev/v3/systems/go/packages/github.com%2Fcli%2Fcli%2Fv2/versions/v2.102.1 ; https://api.deps.dev/v3/systems/go/packages/gitlab.com%2Fgitlab-org%2Fcli/versions/v1.124.0 ; https://api.deps.dev/v3/systems/go/packages/go.abhg.dev%2Fgs/versions/v0.32.0
- repository: https://api.github.com/repos/cli/cli/releases/latest ; https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/releases?per_page=3 ; https://github.com/cli/cli/security/advisories ; https://github.com/advisories/GHSA-cg6r-mpgc-h9mm ; https://github.com/abhinav/git-spice/blob/main/LICENSE
- scorecard: https://api.securityscorecards.dev/projects/github.com/cli/cli ; https://api.securityscorecards.dev/projects/gitlab.com/gitlab-org/cli
- community/vendor: https://github.blog/changelog/2025-09-25-upcoming-deprecation-of-gh-copilot-cli-extension/ ; https://gitlab.com/gitlab-org/cli/-/issues/7999 ; https://docs.gitlab.com/user/project/releases/release_cli/

Risks: users running gh < 2.97.0 carry the 2026 advisories (a preflight version warning in `open-task-pr.sh` would close this without a new dependency); glab v2.0.0 env-var rename only bites if the large path starts setting `NO_PROMPT` (use `--yes`, as today); a GitLab-licensed stacked-PR tool appearing, or the team dropping GitLab support, would reopen git-spice.
Unverified: patched version of GHSA-39wj-f2f4-978v (page and OSV record 404'd; listed Moderate, 2026-09-30 on the cli/cli advisories page); git-spice Scorecard; locally installed gh/glab/yq versions.

### Bash test harness (new suites for large-path scripts)

Verdict: Use existing (`tests/lib/common.sh` harness); do not adopt bats-core for this feature.
Deprecation check: none found. Searches run: "bats-core deprecated 2026 sunset" (only a Debian autoremoval notice for the `bats` package, dependency-related, not upstream); v1.14.0 notes `run` now honours `set -e`, flagged by upstream as possibly breaking.

| Option | Fit | Licence | Maintenance | Security | Cost |
| --- | --- | --- | --- | --- | --- |
| in-house harness (incumbent, `tests/lib/common.sh`) | pass: bash 3.2, preflight for jq/yq, shellcheck helper, fixture copy of `.agents/` per rules:138 | n/a | pass: in-repo | n/a | pass: 0 days |
| bats-core@1.14.0 (new) | caution: bash 3.2+ supported; TAP output; but rules:139-144 require lineage/PROVENANCE for anything vendored and AGENTS.md names the homegrown harness as the gate | pass: MIT | pass: v1.14.0 2026-07-21; 1.13.0 2025-11-07; 1.12.0 2025-05-18 | pass: Scorecard 8.4 (Maintained 10, Vulnerabilities 10, Code-Review 10, Dangerous-Workflow 10); no advisories | fail for this feature: brew/npm install for every contributor plus rewrite of every existing suite to mix in one runner; ~3-5 days, none of it large-path work |

Evidence:
- official docs: https://raw.githubusercontent.com/bats-core/bats-core/master/README.md ; https://bats-core.readthedocs.io/en/stable/installation.html
- registry: https://api.deps.dev/v3/systems/npm/packages/bats/versions/1.13.0
- repository: https://api.github.com/repos/bats-core/bats-core/releases/latest ; https://github.com/bats-core/bats-core/releases/tag/v1.14.0
- scorecard: https://api.securityscorecards.dev/projects/github.com/bats-core/bats-core
- community: https://tracker.debian.org/pkg/bats

Risks: if the large path adds many table-driven suites, the in-house `eq/check` helpers may feel thin; that is a reason for a separate harness ADR, not for bundling the switch into this feature.
Unverified: none material.

## Module audit

Owning module: feature-workflow (`.agents/skills/feature-workflow`). Paths below are under that folder unless they start with `.` or `/`.

| Kind | Finding | Source |
| --- | --- | --- |
| reuse | `.step` marker format (`step`, `updated_at`, `blocked_from`) and the `marker_get` / `write_marker` / `utc_now` helpers: write the initiative `.step` in this exact format and `check-write.sh`'s own `marker_get` reads it unchanged | `scripts/status-transition.sh:73-76,147-166`; `scripts/check-write.sh:141-145` |
| reuse | Single-writer skeleton for `initiative-transition.sh`: `die`/`illegal` (exit 1/2), `in_list`, `valid_node`, `require_yq`, `main_root`, `need_step` + `case "$CUR>$NEW"` transition table, `yq --front-matter=process -i` write, validate-then-`mv` for record edits | `scripts/status-transition.sh:92-131,172-191,341-348,420-428,451-476` |
| reuse | Pre-file step idiom: `step <dir> 0.1.4` accepted when only the folder exists; the same shape serves an initiative folder created before `initiative.md` | `scripts/status-transition.sh:231-238` |
| reuse | Guard-class pattern keyed on another folder's `.step` (backlog items keyed to the origin spec's marker, plus the "newest `.step` across specs" scan) is the closest model for an `initiative.md` class keyed to `6.x` | `scripts/check-write.sh:63-64,188-208,234-257` |
| reuse | `D31_TABLE` row shape for a `research` type and the `--requirements` printer; `fact-lookup`/`retrieval`/`library-evaluation` rows take `spec_dir` only | `scripts/resolve-launch.sh:51-93,126-129` |
| reuse | Optional-key validator idiom for `initiative:` (copy the `origin` clause); conditional-presence idiom `((.status == "promoted") == ((.promoted_to // "") != ""))` for `launched`/`settled` on `IQ<n>` records | `assets/spec.md:52`; `assets/work-item.md:33` |
| reuse | "Seeded from a work item" procedure (seed, `origin` at 0.1.4, Origin entry, delete when discovery finishes) and the Origin entry shape; mirror both for a slice | `modules/discovery.md:25-35`; `assets/design-log.md:21-28` |
| reuse | Round mechanics to restate for `questions.md`: frontier definition, fact-lookup launch body, one-round ask format with "(Recommended)" and "Defer to deep dive", Questioning-round log shape | `modules/questioning-loop.md:25-59`; `assets/design-log.md:51-63` |
| reuse | Archive procedure (`superseded_by` as first key, move to `archive/`); `deferred.md` has no yq validator, so a `.workflow/initiatives/...` value needs no validator change | `modules/deferred-handoff.md:45-51`; `assets/deferred.md:8-15` |
| reuse | `step-progress.sh` `lookup`/`linear` awk and track dispatch; `STEP_PROGRESS_STEPS` env override for tests | `scripts/step-progress.sh:26,67-110` |
| reuse | 5.9 "list and loop with yq" idiom for the 5.7 "every emitted spec is `done`" check | `modules/sign-off.md:96-98` |
| gap | No path normaliser accepts `.workflow/initiatives/`: four private copies of `norm_spec_dir` pin `.workflow/specs/NNN-slug`; `FORMATS.spec_dir` pins the same and `:265` denies a missing dir | `scripts/status-transition.sh:134-145`; `scripts/budget-check.sh:89-98`; `scripts/task-waves.sh:67-74`; `scripts/open-task-pr.sh:62`; `scripts/resolve-launch.sh:96-97,265-267` |
| gap | Every guarded root in `check-write.sh` comes from a `WF_*` constant sourced from `.agents/lib/workflow-paths.sh`; no `WF_INITIATIVES` exists (lib is shared core: change only through the integration agent) | `scripts/check-write.sh:53,185-187` |
| gap | `--only` enum is `spec\|tier-a\|tier-b`; the hook adapters pass `--only`, so an initiative class must fall under one of the three or no hook evaluates it | `scripts/check-write.sh:45,162,211` |
| gap | Tier A in-flight scan reads `.workflow/specs/*/spec.md` + `.step` only; with no spec in flight every Tier A write is allowed (`:316`), with one in flight the newest spec step decides. Term gates reached from the exploration loop (glossary writes) have no initiative-aware rule | `scripts/check-write.sh:300-331`; `modules/questioning-loop.md:61` |
| gap | `step-progress.sh`: `--path` enum `full\|light`; path derived from `light_path`; `--spec-dir` dies without `spec.md`; one printf format for all lines; `linear()` counts `both` rows into any path, so a `large` path would count all P0 rows. `Large path · step n of m — ...` is a second output shape | `scripts/step-progress.sh:48,52-60,78-92` |
| gap | `steps.tsv` header documents `both \| full \| light` only; phase rows stop at `P5` | `references/steps.tsv:5-10,13-18` |
| gap | `resolve-launch.sh` resolves the model from `.agents/agents/<type>.md` (agents module): a `research` type needs that file or denies with 00.14 | `scripts/resolve-launch.sh:295-306` |
| gap | Codex `task_name` form `s<NNN>_<enc(type)>` is keyed to a spec folder and `codex-pre-spawn.sh` (hooks) checks it; no form exists for a launch from an initiative | `SKILL.md:185` |
| gap | Conversion leaves dangling references: `.workflow/deferred/*.md` `origin_spec` written at 0.3.17 by the spec being deleted; a work item's `promoted_to` when a seeded spec converts before its 0.6/0.3.20 deletion; the moved `design-log.md` opens with `Spec: [spec.md](spec.md)` | `assets/deferred.md:2,11`; `modules/questioning-loop.md:62`; `assets/work-item.md:6,16`; `modules/discovery.md:35`; `assets/design-log.md:17` |
| gap | `budget-check.sh` excludes only the spec folder and `work-backlog/` from `changed_files`; initiative files changed on a slice's spec branch count against its budget | `scripts/budget-check.sh:172-177,333-339` |
| gap | No parameterised round: the loop's `ST` calls and the fact-lookup header hard-code `.workflow/specs/NNN-slug`, so `large-path.md` must restate 0.3.8–0.3.11 rather than call them | `modules/questioning-loop.md:9,30-33,63,72` |
| gap | No reader of `spec.md` `origin` exists beyond its writers; `initiative:` will likewise have no consumer unless the change adds one (router, 5.7) | `modules/discovery.md:31`; `assets/spec.md:9,31` |
| constraint | Exit contract 0 done / 1 environment / 2 illegal, reason on stderr, and "never retry with another `--step`"; the sibling must match | `scripts/status-transition.sh:78`; `scripts/check-write.sh:43`; `SKILL.md:134` |
| constraint | Scripts are self-contained: helpers are copied per script, only `workflow-paths.sh` is sourced; header block (File/Purpose/Usage/Exit codes/Called by/Notes/Sources), `set -euo pipefail`, `# shellcheck source=` directive, bash 3.2 | `scripts/status-transition.sh:1-86`; `scripts/check-write.sh:1-53` |
| constraint | `step` mode dies when `spec.md` is missing (except 0.1.4): the conversion node's marker must be set before the spec folder is deleted; after deletion there is no spec marker to resume from | `scripts/status-transition.sh:231-238` |
| constraint | `spec.md` `status`/`blocked_condition` never change by Write; `--proposed` denies it; "Add no other keys" plus the validator must admit `initiative` | `scripts/check-write.sh:280-294`; `assets/spec.md:34,44-55` |
| constraint | The spec.md step list is kept in four places; adding a spec.md writer step means all four | `SKILL.md:140`; `scripts/check-write.sh:61`; `scripts/status-transition.sh:21-22`; `assets/spec.md:37` |
| constraint | `design-log.md` is append-only, `D<n>` ids local to the feature, newest-entry readers (Deeper prompt, Discovered work) and `Outcome:` line counting in review-triage; a moved log keeps its ids | `assets/design-log.md:5-12`; `modules/questioning-loop.md:10`; `modules/discovered-work.md:155` |
| constraint | 5.7 is already a Tier A write step; `done` is set only from `in-review` at 5.7 and 5.8 merges the spec branch afterwards, so an initiative write at 5.7 lands on the spec branch | `scripts/check-write.sh:66`; `modules/sign-off.md:114-131` |
| constraint | Bash writes bypass the Write/Edit hooks (the single writer runs via Bash); `initiative.md` status via `initiative-transition.sh` needs no guard allowance at 5.7 or 0.1.4 | `scripts/status-transition.sh:80`; `scripts/check-write.sh:47` |
| constraint | `SKILL.md` frontmatter `modules:` list must name `large-path`; § 6 table is the module index | `SKILL.md:4-14,193-205` |
| constraint | 0.1.1 numbering counts `.workflow/specs/[0-9][0-9][0-9]-*/` only; a converted spec's number stays consumed | `modules/discovery.md:11` |
| constraint | `ST` is typed with the full repo-relative prefix on every call (sandbox allow-list) | `SKILL.md:125`; `modules/discovery.md:7` |

History (read-only): 7 commits touch the module; `assets/spec.md` (5), `resolve-launch.sh` (4), `discovery.md` (4), `SKILL.md` (4) churn most; `step-progress.sh` and `steps.tsv` (2 each) are newest and least settled. No uncommitted changes inside the module.

### Delta audit after round 4 (initiative branch, commits, push, PR/MR merge, emission on the branch)

| Kind | Finding | Source |
| --- | --- | --- |
| reuse | Branch-off-main idiom: `git switch -c <branch> "$(rules-setting.sh main_branch)"` branches off `main_branch` (not HEAD) and carries the untracked folder; first commit is folder-scoped `git add .workflow/specs/NNN-slug && git commit`; "already on the branch (loop-back): skip" guard; `git branch --show-current` then `git switch` otherwise | `modules/verification-setup.md:17-26`; `modules/discovery.md:146-147,162`; `modules/implementation-orchestrator.md:65` |
| reuse | `rules-setting.sh task_review` (enum `pr\|pr-blocking\|local`, default `pr`, exit 1 on a bad value) and `main_branch` (default the `origin/HEAD` target, else `main`); `--cwd` resolves the main checkout | `scripts/rules-setting.sh:39-46,69-79,99-103` |
| reuse | Host switch and PR mechanics, coded once: `git remote get-url origin` → `*github*` gh / `*gitlab*` glab / else `skip`; `auth status` precheck; `push -u origin`; reuse an open PR via `gh pr list --head --base --state open --json url` / `glab mr list`; create with `--base/--head` or `--target-branch/--source-branch --yes`; `first_url`; `skipped: <reason>` on stdout, exit 0 always | `scripts/open-task-pr.sh:35,80-86,103-115` |
| reuse | `pr-blocking` wait: `gh pr view <url> --json reviewDecision` / `glab mr approvers`; change requests are a fix round | `modules/implementation-orchestrator.md:153` |
| reuse | The only existing main-branch PR (5.8): push, `gh pr create --base main --head spec/NNN-slug` / `glab mr create --target-branch main --source-branch spec/NNN-slug`, titled after the feature, body links; local `git merge --no-ff` on main without remote/CLI or on request | `modules/sign-off.md:129` |
| reuse | "Remote exists" tests: `git remote get-url origin` (skip when absent); `show-ref --verify refs/remotes/origin/<main>` | `scripts/open-task-pr.sh:80`; `scripts/budget-check.sh:308-310` |
| reuse | Branch-key validation model for an `initiative_branch` key: computed name must match, `show-ref --verify --quiet refs/heads/<b>` must pass, a different existing value exits 2 | `scripts/status-transition.sh:365-372` |
| reuse | PR-URL record model: `set-task --pr <url>\|null` at any step, regex `^https?://[^[:space:]]+$`, warning on replace; same regex in the validator | `scripts/status-transition.sh:10-11,189,327-340` |
| reuse | Post-merge cleanup: push so the PR shows merged, `git worktree remove`, `git branch -d <branch>` (task branches only) | `modules/implementation-orchestrator.md:163` |
| reuse | Status listing loop over `.workflow/specs/*/spec.md` for the "all emitted specs `done`" check (working tree only) | `SKILL.md:30`; `modules/sign-off.md:97` |
| reuse | `budget-check.sh` needs no change: `changed_files` = `merge-base(HEAD, main)..HEAD` ∩ `impl_base..HEAD` minus spec folder, backlog and tests; initiative files reach a spec diff only through a catch-up merge of main and then drop out via `excluded.merge_base` | `scripts/budget-check.sh:21-30,172-177,316-349` |
| gap | No PR opener for anything but task→spec: `open-task-pr.sh` hard-wires `<spec-dir>` under `.workflow/specs`, a `T<n>` with a `tasks.md` record, `branch` from the record and base = `spec_branch`; spec→main is prose only. `initiative/NNN-slug → main` can call neither | `scripts/open-task-pr.sh:49-52,59-73,77-79,96-98,109-113`; `modules/sign-off.md:129` |
| gap | `task_review` is read only at 3.16 / `open-task-pr.sh`; the 5.8 main-branch merge ignores it and uses "stakeholder's go-ahead" + "push only what the stakeholder asked for". No precedent for a `task_review`-driven main-branch PR, and `local` means "no push" for tasks, which collides with "push the initiative branch when a remote exists" | `modules/implementation-orchestrator.md:152`; `modules/sign-off.md:129`; `scripts/rules-setting.sh:14-16`; `scripts/open-task-pr.sh:23-24,76` |
| gap | Every reader reads the main checkout's working tree; nothing reads a file from a git ref. "Emitted specs all `done` on main" while the checkout is on `initiative/*` or a spec branch, and "initiative status" while the folder exists only on `initiative/*`, have no idiom | `scripts/status-transition.sh:27-28,225-238`; `scripts/budget-check.sh:10-11,209-217`; `SKILL.md:30,62-63` |
| gap | No fetch/pull anywhere: after a host-side PR merge local `main` is stale for "re-create the branch off main" and the `done`-flip check; only `budget-check.sh` is `origin/`-aware | `scripts/budget-check.sh:308-310` |
| gap | No second-lifetime branch idiom: spec branches are created once and never deleted at 5.8; `git switch -c` fails while the old `initiative/*` branch exists; delete-after-merge exists only for task branches | `modules/discovery.md:147`; `scripts/status-transition.sh:372`; `modules/implementation-orchestrator.md:163`; `modules/sign-off.md:129` |
| gap | Branch position is never re-established on resume: the router reads status and `.step` only; `git branch --show-current` checks exist at 1.1 and 3.1 alone. A session alternating `initiative/*` and `spec/*` has no "switch first" step | `SKILL.md:59-64`; `modules/verification-setup.md:26`; `modules/implementation-orchestrator.md:29,65,96,142` |
| gap | Tier A gate goes blind on `initiative/*`: emitted specs committed on their own branches leave only a gitignored `.step` in the working tree; the scan iterates `*/spec.md`, sees no feature in flight and allows every Tier A write | `scripts/check-write.sh:301-316`; `scripts/status-transition.sh:80` |
| constraint | The spec folder must be untracked until the spec's own first commit: `baseline_revision` is that commit and `impl_base_revision` must contain it; a spec folder committed on `initiative/*` vanishes from the working tree at `git switch -c spec/… main` | `modules/verification-setup.md:17-24`; `scripts/status-transition.sh:383-384` |
| constraint | Ordering at emission: the initiative commit must land before the spec's 0.3.20/1.1 switch, and `git switch` refuses when a tracked file differs between the initiative tip and `main_branch` and has local edits, so the initiative branch must stay limited to `.workflow/initiatives/NNN-slug/**` | `modules/verification-setup.md:17,21`; `modules/discovery.md:146-147` |
| constraint | Untracked spec folders travel across every `git switch`; folder-scoped `git add .workflow/specs/NNN-slug` at 0.3.20, 1.1, 1.5 and 2.6 keeps a draft out of another spec's commits; 5.8 "commit what is left" is the one unscoped add | `modules/discovery.md:162`; `modules/verification-setup.md:22,123-124`; `modules/task-breakdown.md:119`; `modules/sign-off.md:129` |
| constraint | `done` is terminal in the sibling writer: afterwards `step`, `set-task` and `set-spec` exit 2. If `initiative-transition.sh` mirrors it, any post-merge key must be written before `done`, or the mirror must admit it | `scripts/status-transition.sh:255,270,363,464` |
| constraint | A spec is `done` on its branch before it is on main: 5.7 sets `done`, 5.8 then opens the PR. "All emitted specs `done` on main" is a main-ref check, not a working-tree `spec.md` check | `modules/sign-off.md:124,129`; `scripts/status-transition.sh:458` |
| constraint | 0.1.1 numbering counts `.workflow/specs/[0-9][0-9][0-9]-*/` directories; on `initiative/*` an emitted spec's folder survives only because its gitignored `.step` keeps the directory; a fresh clone or `git clean` reuses the number | `modules/discovery.md:11`; `scripts/status-transition.sh:80` |
| constraint | `open-task-pr.sh` contract if extended: exit 0 always once args are valid, `skipped: <reason>` on stdout, never force-push, `--dry-run` prints the commands, `--record` writes through the single writer; the "Called by:" headers of `rules-setting.sh` and `open-task-pr.sh` must be updated | `scripts/open-task-pr.sh:19-24,95-101,117-120`; `scripts/rules-setting.sh:24-25` |
| constraint | `resolve-launch.sh` denies a launch whose `spec_dir` is absent under the main checkout: a launch for a spec whose folder lives only on its branch is denied while the checkout is on `initiative/*` | `scripts/resolve-launch.sh:265-267` |
| friction | The gh/glab host switch is stated three times: coded in `open-task-pr.sh`, restated as the 3.16 bullets, restated at 5.8; an initiative→main PR adds a fourth unless it calls the code | `scripts/open-task-pr.sh:14-15,25`; `modules/implementation-orchestrator.md:152`; `modules/sign-off.md:129` |

History (delta): `verification-setup.md`, `discovery.md`, `implementation-orchestrator.md`, `sign-off.md` and `budget-check.sh` have 4 commits each, `status-transition.sh` and `rules-setting.sh` 3, `open-task-pr.sh` 2 (newest, least settled).

## Not found

- "large path", "initiative": no occurrence in `.agents/`, `tests/`, `AGENTS.md`, `README.md`, `.agents/README.md`, `PLAN/decision-flow*`. Reported by retrieval.
- "medium path": appears only as the rejected `--path medium` usage-error case in `tests/scripts/step-progress.sh:62`; `step-progress.sh:48` accepts only `full|light`. Reported by retrieval.
- Tier B caches: `.workflow/cache/modules.md`, `flows.md`, `architecture.md` do not exist (and were flagged stale); stamps null, code read instead. Reported by retrieval.
- Retrospectives: `.workflow/decisions/retrospectives/` does not exist; only ADR-0001 and `pitfalls.md` under `.workflow/decisions/`. Reported by retrieval.
- Any hook, lib or agent file reading `light_path` or a path term, other than `.agents/agents/implementation.md:30`: searched `.agents/hooks/`, `.agents/lib/`, `.agents/agents/`. Reported by retrieval.
- Path terms in root docs: `AGENTS.md` and `.agents/README.md` name neither path; `README.md:23` only says "sizes a request". Reported by retrieval.
- A third track value or a sizing step beyond 0.0.1/0.3.20: `references/steps.tsv` tracks are `both|full|light` only, pinned by `tests/lint/step-list.sh:27,56-57` and tied to `PLAN/decision-flow-reference.md` and `PLAN/decision-flow.mermaid` ids. Reported by retrieval.
- `questions.md`, `.workflow/initiatives`, `WF_INITIATIVES`, `initiative-transition`, a `research` task type, `exploring`/`planned` statuses, a "one feature?" or "several features" check: searched all of `.agents/skills/feature-workflow/**` (only a "re-planned" sentence at `modules/discovered-work.md:76`). Reported by module-audit.
- A second progress-line format or a track beyond `both|full|light`: `scripts/step-progress.sh:48,78-92`, `references/steps.tsv:5-10`. Reported by module-audit.
- Any reader of `spec.md` `origin` (only writers at `modules/discovery.md:31`, `assets/spec.md:9,31,52`, `assets/work-item.md:20`): searched `SKILL.md`, `modules/`, `scripts/`, `assets/`. Reported by module-audit.
- A yq validator for `assets/deferred.md` frontmatter (`superseded_by` is prose-only at `:14`): `assets/deferred.md`. Reported by module-audit.
- Path terms or step data in `references/REFERENCE-DOC.md`, `TEMPLATE.html`, `readable-code.md`: none. Reported by module-audit.
- cache disagrees with code: none; every extract about this module matches the code at the cited lines; Tier B stamps are null. Reported by module-audit.
- `initiative/`, `git fetch`, `git pull`, `git show <ref>:<path>`, `for-each-ref`, `git clean`: none in `SKILL.md`, `modules/`, `scripts/`, `assets/`, `references/`; `branch -d` appears only for task branches (`modules/implementation-orchestrator.md:29,163,253`). Reported by module-audit (delta).
- A PR/MR opener for any base other than `spec_branch` (task→spec), or prose for any head other than `spec/NNN-slug` (5.8): searched `scripts/*.sh`, `modules/*.md`. Reported by module-audit (delta).
- A `task_review` reader outside 3.16 and `scripts/open-task-pr.sh:75`: `modules/sign-off.md`, `modules/verification-setup.md`, `modules/discovery.md` read only `main_branch`. Reported by module-audit (delta).
- A `git push` outside `scripts/open-task-pr.sh:104` and the 3.16 / 5.8 prose: none at 0.3.20, 1.1, 1.5 or 2.6. Reported by module-audit (delta).
- cache disagrees with code: none for the delta. The first audit's `budget-check.sh` gap rested on initiative files sitting on a spec branch, which D22 rules out; `scripts/budget-check.sh:316-349` confirms no exclusion is needed. Reported by module-audit (delta).
