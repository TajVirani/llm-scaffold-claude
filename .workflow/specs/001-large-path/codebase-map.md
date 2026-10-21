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

<!-- From `module-audit` (0.4.6) on the owning module only. -->

Owning module: pending (0.3.3).

## Not found

- "large path", "initiative": no occurrence in `.agents/`, `tests/`, `AGENTS.md`, `README.md`, `.agents/README.md`, `PLAN/decision-flow*`. Reported by retrieval.
- "medium path": appears only as the rejected `--path medium` usage-error case in `tests/scripts/step-progress.sh:62`; `step-progress.sh:48` accepts only `full|light`. Reported by retrieval.
- Tier B caches: `.workflow/cache/modules.md`, `flows.md`, `architecture.md` do not exist (and were flagged stale); stamps null, code read instead. Reported by retrieval.
- Retrospectives: `.workflow/decisions/retrospectives/` does not exist; only ADR-0001 and `pitfalls.md` under `.workflow/decisions/`. Reported by retrieval.
- Any hook, lib or agent file reading `light_path` or a path term, other than `.agents/agents/implementation.md:30`: searched `.agents/hooks/`, `.agents/lib/`, `.agents/agents/`. Reported by retrieval.
- Path terms in root docs: `AGENTS.md` and `.agents/README.md` name neither path; `README.md:23` only says "sizes a request". Reported by retrieval.
- A third track value or a sizing step beyond 0.0.1/0.3.20: `references/steps.tsv` tracks are `both|full|light` only, pinned by `tests/lint/step-list.sh:27,56-57` and tied to `PLAN/decision-flow-reference.md` and `PLAN/decision-flow.mermaid` ids. Reported by retrieval.
