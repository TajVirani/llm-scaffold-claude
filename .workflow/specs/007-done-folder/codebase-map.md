---
cache_stamps:
  modules: 99801e506b428a1ac3c3f7fb0170191cb6fa45ae
  flows: 99801e506b428a1ac3c3f7fb0170191cb6fa45ae
  architecture: 65ae1c501fe154e76b5dea5a3372718b3510cde6
---

# Codebase map: Done folder for finished specs

Affected area: feature-workflow (`.agents/skills/feature-workflow`), lib (`.agents/lib`), hooks (`.agents/hooks`), retrospective (`.agents/skills/retrospective`), standalone-skills handoff (`.agents/skills/handoff`), installer (`install.sh`), tests (`tests`).

## Relevant code

| Item | What it does today | Source |
| --- | --- | --- |
| Sign-off 5.7 | Runs the retrospective, reads its `verdict`, then `status ... done --step 5.7` for `accepted` or `accepted-with-open-items`. `done` is reached only from `in-review`. | `.agents/skills/feature-workflow/modules/sign-off.md` § 5.7 (lines 140-157) |
| Sign-off 5.8 | Commits leftovers on the spec branch, pushes, opens the PR (`gh pr create` / `glab mr create` to main), or merges locally with `git merge --no-ff`. Removes worktrees under `.workflow/.worktrees/`. Does not delete the spec branch or move the folder. `done` is in the spec branch before the merge. | `sign-off.md` § 5.8 (lines 159-165) |
| Sign-off 5.9 | Lists `.workflow/specs/work-backlog/NNN-slug-disc-*.md` with `status: open`. Start / Keep / Move rulings. Runs before 5.7. | `sign-off.md` line 100, § 5.9 lines 122-138 |
| 0.1.1 numbering scan | Counts top-level `.workflow/specs/[0-9][0-9][0-9]-*/` folders, `spec/*` branches (local and `origin`), and every initiative's `origin` and `slices[].spec`. | `.agents/skills/feature-workflow/modules/discovery.md` lines 11-25 |
| Done is terminal | Step marker, task records and frontmatter refuse changes once `done`. Spec branch name is derived from the folder path. `done` only from `in-review` at step 5.7. | `.agents/skills/feature-workflow/scripts/status-transition.sh` lines 229, 244, 337, 341, 407, 432, 438 |
| Folder validator | `wf_norm_folder spec` requires `$WF_SPECS/` plus a direct child matching `^[0-9]{3,}-[A-Za-z0-9][A-Za-z0-9._-]*$`. `specs/done/NNN-slug` and `z_NNN-slug` are refused. | `.agents/lib/workflow-paths.sh` lines 73-100, regex line 95 |
| Path constants | `WF_SPECS=$WF_DIR/specs`, `WF_WORK_BACKLOG=$WF_SPECS/work-backlog`. | `.agents/lib/workflow-paths.sh` lines 32-34 |
| Commit script | Normalises `SPEC_DIR` through `wf_norm_folder`; local-state leak check on `$SPEC_DIR/.step`; stages the spec dir, the backlog, and `.workflow` minus the `$WF_SPECS` subtree; branch name derived from path. | `.agents/skills/feature-workflow/scripts/commit-workflow-data.sh` lines 54-85 |
| Backlog write guard | Origin step read from `$ROOT/$WF_SPECS/$ORIGIN/.step`; fallback scan of `$WF_SPECS/*/.step`. | `.agents/skills/feature-workflow/scripts/check-write.sh` lines 255-278 |
| spec.md / tasks.md guard | Reads step from `$WF_SPECS/$SPEC_NAME/.step`. | `check-write.sh` lines 281-300 |
| Tier A in-flight scan | Loops `$ROOT/$WF_SPECS/*/spec.md` (top level only); skips `work-backlog` and `done` status. | `check-write.sh` lines 335-350 |
| Session-start resume | Scans `$root/$WF_SPECS/*/spec.md`; skips `work-backlog`; display slug `$WF_SPECS/<basename>`; backlog count from `$WF_WORK_BACKLOG/*.md`. | `.agents/hooks/session-start-resume.sh` lines 61-62, 204-207, 236-261 |
| Done-on-main for emitted specs | `spec_done_on_main` runs `git show <main>:$WF_SPECS/$1/spec.md`; a missing path returns false. | `session-start-resume.sh` lines 152-165; `large-path.md` line 46 |
| Launch header spec_dir regex | `lenient_spec_dir` accepts only `.workflow/specs/<NNN>-<slug>` as a direct child. | `.agents/hooks/post-implementation-audit.sh` line 173 |
| Codex task name to spec | `s<NNN>_t<N>` resolves `$main_root/$WF_SPECS/$num-*/`; zero matches warns. | `post-implementation-audit.sh` lines 134-136 |
| Codex pre-spawn | `spec_folder NNN` globs `$root/$WF_SPECS/$1-*/`; zero or several matches deny. | `.agents/hooks/codex-pre-spawn.sh` lines 92-96 |
| Evidence capture | Fallback scans top-level `$WF_SPECS/*/spec.md`, skips `work-backlog`, selects only active statuses. | `.agents/hooks/evidence-capture.sh` lines 182-193 |
| Standalone resume router | Scans `.workflow/specs/*/spec.md` and the backlog; `done` row: read as context only. | `.agents/skills/feature-workflow/SKILL.md` lines 32, 44, 83 |
| Standalone retrospective | Offers specs with `status: done`; scan location not stated. | `.agents/skills/retrospective/SKILL.md` line 12 |
| Review lessons origin | `origin_spec` must match `^\.workflow/specs/[0-9]{3}-[a-z0-9-]+$`. | `.agents/skills/feature-workflow/scripts/review-lessons.sh` lines 80-81 |
| Deferred back-link lookup | Finds shelf files whose `origin_spec` or `superseded_by` equals `.workflow/specs/<NNN-slug>` by exact match. | `.agents/skills/feature-workflow/modules/deferred-handoff.md` lines 59-62 |
| Installer gitignore | `GI_ENTRIES` includes `$WF_SPECS/*/.step`; single `*` does not match `specs/done/NNN/.step`. | `install.sh` line 52 |
| Claude deny rule | `Edit(.workflow/specs/*/.step)`, same single-`*` shape. | `.agents/hooks/claude-settings.template.json` line 148 |
| Test fixture | `FOLDER_SPEC=.workflow/specs/001-alpha`, gitignore block. | `tests/fixtures/workflow-folders.sh` lines 22, 33 |
| Budget exclusion | Excludes the spec folder and `.workflow/specs/work-backlog/`. | `.agents/skills/feature-workflow/scripts/budget-check.sh` line 26 |

## Seams and interfaces

| Interface | Shape (signature, type, contract) | Callers | Source |
| --- | --- | --- | --- |
| `wf_norm_folder spec <arg>` | Prints `.workflow/specs/NNN-slug` or status 1; only a direct child of `$WF_SPECS` passes. | `status-transition.sh`, `commit-workflow-data.sh`, `open-task-pr.sh`, `task-waves.sh`, `budget-check.sh`; `run-toolchain.sh` has its own copy | `.agents/lib/workflow-paths.sh` lines 75-100 |
| `WF_SPECS`, `WF_WORK_BACKLOG`, `wf_path` | Repo-relative constants and a join helper. | Hooks and skill scripts (sourced) | `.agents/lib/workflow-paths.sh` lines 32-34, 52-55 |
| `status-transition.sh status\|step\|set-task <spec-dir>` | `<spec-dir>` is `.workflow/specs/NNN-slug` or an absolute path ending in it; exit 2 illegal transition. | Sign-off, discovery, guard messages | `status-transition.sh` lines 6-21, 78 |
| `.step` marker | Gitignored YAML with `step`, `updated_at`, `blocked_from`. | `check-write.sh`, `resolve-launch.sh`, `evidence-capture.sh` | `status-transition.sh` line 73 |
| `check-write.sh --cwd --path [--proposed]` | Exit 0 allow, 2 deny. | `spec-single-writer-guard.sh`, `tier-a-write-guard.sh`, `tier-b-write-guard.sh`, `codex-write-guard.sh` | `check-write.sh` lines 6-8 |
| `commit-workflow-data.sh <spec-dir> -m <msg> [--cwd]` | Exit 0 committed or nothing; 1 not on spec branch or merge in progress; 2 usage/env or local state not ignored. Stages spec dir, backlog, `.workflow` minus `specs/` and `initiatives/`. | `implementation-orchestrator.md:121,202,297` (not sign-off) | `scripts/commit-workflow-data.sh:11-21` |
| `review-lessons.sh validate\|next-id <file>` | Exit 0 ok; 1 broken rule; 2 usage/missing file/tool. | retrospective routing | `scripts/review-lessons.sh:9-16` |
| `spec_done_on_main <NNN-slug>` (shell function in module prose) | True when spec.md status on `$main_ref` is `done`; missing path is false. | large-path 6.3, 6.13 | `modules/large-path.md:46` |
| `step-progress.sh --spec-dir <dir> [<id>]` | Reads `.step` and `light_path`; exit 1 when either is missing. | every module's progress line | `scripts/step-progress.sh:8-20` |
| `check-write.sh` path classes | `SPEC_REST` regex `^[^/]+/(\.step\|spec\.md\|tasks\.md\|tasks/.+)$` decides the spec class; anything else under `specs/` (except `work-backlog`) is `other` (allowed). | guard hooks; Codex advisory calls | `scripts/check-write.sh:192-226` |

## Prior decisions

| Decision or item | What it says | Source |
| --- | --- | --- |
| Initiative conversion | A converted spec's folder is deleted; its number is never reused; 0.1.1 counts initiative `origin`. | `large-path.md` line 82; `discovery.md` line 11 |
| Shelf archive pattern | Superseded shelf files move to `.workflow/deferred/archive/` with `superseded_by` and are excluded from shelf scans. Closest precedent for a subfolder. | `deferred-handoff.md` lines 49-50; `discovered-work.md` line 120 |
| Back-links in shelf files | `origin_spec: .workflow/specs/NNN-slug` and relative link `../specs/NNN-slug/spec.md`. | `.workflow/deferred/per-task-scoped-runs.md` lines 2, 10 |
| Retrospectives and pitfalls | Frontmatter `spec:` and body links use `.workflow/specs/NNN-slug`. | `.workflow/decisions/retrospectives/005-cache-build-followups.md` lines 2, 11-13; `.workflow/decisions/pitfalls.md` |
| Capabilities | Rows link `specs/NNN-slug/spec.md`. | `.workflow/capabilities.md` lines 4-6, 13-17 |
| Rules | No spec-path entries in Ownership or Shared core; budget excludes the spec folder and backlog. | `.workflow/rules.md` line 119 |
| Deferred: main-checkout resolver (partial match) | Shelved refactor covering `wf_norm_folder`, the validator that rejects a subfolder. | `.workflow/deferred/main-checkout-resolver.md` lines 18, 22 |
| Deferred: sign-off scoped commit (related) | 5.8 stages everything untracked; same commit a 5.8 move would make. | `.workflow/deferred/sign-off-scoped-commit.md` lines 8-10, 20, 35 |

No ADR constrains the spec folder layout (`.workflow/decisions/adr/0001-project-baseline.md` scanned).

## Library options

Concerns: bash 3.2, moving a folder, reading frontmatter with yq; settled by rules (`.workflow/rules.md` lines 153-155). No new library needed. One real choice: `git mv` versus plain `mv`.

**Verdict: use existing.** Plain `mv` plus `git add` (the deferred-handoff pattern). `git mv` moves only tracked files; `.step` is gitignored and would be left behind.

| Option | Fit | Licence | Maintenance | Security | Cost |
| --- | --- | --- | --- | --- | --- |
| plain `mv` + `git add` (incumbent pattern) | pass: `deferred-handoff.md:50` already uses it; moves ignored `.step` too | n/a (POSIX) | n/a | no dependency | ~0.5 day |
| `git mv` | caution: tracked files only; fails on untracked source | GPL-2.0 (CLI use) | git any version | none found | ~0, but leaves `.step` behind |
| yq mikefarah v4 (incumbent, reads only) | pass: frontmatter reads | MIT | v4.54.1, 2026-09-29 | unknown (deps.dev response truncated) | already required |

Evidence: https://git-scm.com/docs/git-mv · https://api.deps.dev/v3/systems/go/packages/github.com%2Fmikefarah%2Fyq%2Fv4 · https://github.com/mikefarah/yq/blob/master/LICENSE · `install.sh` lines 93-103 · `deferred-handoff.md` lines 45-53.

Risks: archive path should derive from `WF_SPECS`, not a literal.

## Module audit

Owning module: feature-workflow

| Kind | Finding | Source |
| --- | --- | --- |
| reuse | Script skeleton: source `lib/workflow-paths.sh`, `wf_main_root`, `wf_path`, `die`/exit-code style, header block (File/Purpose/Usage/Exit/Called by/Notes/Sources). | `scripts/commit-workflow-data.sh:1-31,53-55`; git `ea03be7` |
| reuse | Task-record read for `--check`: `yq --front-matter=extract '[.tasks[] \| select(...)] \| length'`; statuses `pending in-progress done blocked split-out`. | `SKILL.md:85`; `scripts/status-transition.sh:90`; `assets/tasks.md:6` |
| reuse | Origin backlog listing: glob `work-backlog/NNN-slug-disc-*.md` plus `.status` read. | `modules/sign-off.md:100` |
| reuse | Precedent for rewriting a spec path in `.workflow/`: "Re-point at conversion" (`origin_spec`/`superseded_by`), large-path re-points `promoted_to`. | `modules/deferred-handoff.md:55-64`; `modules/large-path.md:81` |
| reuse | Listing `.workflow/` files while skipping gitignored local state: `git ls-files -c -o --exclude-standard`; local-state constants `WF_WORKTREES WF_HANDOFF WF_CACHE_STAGING WF_STANDARDS_STAGING`. | `scripts/commit-workflow-data.sh:35-37,68-70`; `scripts/run-toolchain.sh:73` |
| reuse | `spec_done_on_main` is the one done-on-main helper, defined in large-path Conventions; covers 6.3 and 6.13. | `modules/large-path.md:46,119,272` |
| gap | `commit-workflow-data.sh` cannot commit the moved spec (`wf_norm_folder` rejects `specs/done/...`; stages `.workflow` with `:(exclude)$WF_SPECS`). The 5.8 commit must be a plain `git add` of old path, new path and rewritten files. | `scripts/commit-workflow-data.sh:54,83-85`; `modules/sign-off.md:161` |
| gap | `check-write.sh` has no class for `specs/done/`: `done/NNN-slug/spec.md` fails every `^[^/]+/...` pattern, so a moved spec's `spec.md`, `tasks.md`, `tasks/**`, `.step` become `CLASS=other` (allowed, sub-agents too). | `scripts/check-write.sh:205-216,226` |
| gap | Relative forms without `specs/`: work items link `../NNN-slug/spec.md` from `work-backlog/`; sibling specs likewise. Others: `../specs/NNN-slug` (shelf), `../../specs/NNN-slug` (initiative), `specs/NNN-slug` (capabilities). | `assets/work-item.md:58-59`; `assets/deferred.md:29,49`; `assets/initiative.md:73`; `assets/design-log.md:110`; `assets/proposals.md:26` |
| gap | Outbound links inside a spec take several forms (`../../deferred/`, `../../decisions/adr/`, `../work-backlog/`); in-spec repo-relative strings `.workflow/specs/NNN-slug` would go stale since the rewrite covers only files outside the spec. | `assets/spec.md:102,108-109`; `assets/design-log.md:26,43,130,138,154,168` |
| gap | No `WF_SPECS_DONE` or `specs/done` reference; discovery 0.1.1, large-path and review-lessons hard-code `.workflow/specs/`. | `modules/discovery.md:15`; `modules/large-path.md:46`; `scripts/review-lessons.sh:80` |
| gap | No `.step` after the move, so `step-progress.sh --spec-dir` without an id exits 1; the 5.8 progress line must pass `5.8`. | `scripts/step-progress.sh:9,19` |
| constraint | Work-item status enum includes `dismissed`, a valid end state the D4 check as written would fail. | `assets/work-item.md:5,15,37` |
| constraint | Initiative files are committed only on `initiative/NNN-slug`; sign-off writes nothing into the initiative on the spec branch. A rewrite of all `.workflow/` would edit `initiatives/*/initiative.md` and its design-log there. | `modules/sign-off.md:157`; `modules/large-path.md:50,293` |
| constraint | `.workflow/cache/**` is edited only by `publish-cache.sh`. | `SKILL.md:151`; `scripts/check-write.sh:15-16,229-231` |
| constraint | Guarded files the rewrite can touch: Tier A, `review-lessons.md`, `work-backlog/**`, other specs' `spec.md`/`tasks.md`; 5.8 is a writer step for none, so the guarded-write table needs a row. | `SKILL.md:139-153`; `scripts/check-write.sh:55` |
| constraint | Order 5.1-5.5, 5.9, 5.7, 5.8; `done` only from `in-review` at 5.7 and terminal (step, set-task, set-spec refuse). | `modules/sign-off.md:3,154`; `scripts/status-transition.sh:226-229,244,337,438` |
| constraint | `review-lessons.sh` and the template header state the `origin_spec` rule together ("a change to the rules changes both"); the retrospective writes it at 5.7 before the move. | `scripts/review-lessons.sh:3-5,80-81`; `assets/review-lessons.md:9,15-16` |
| constraint | `spec_done_on_main` must still accept the old top-level location for specs merged before this feature and not swept. | `modules/large-path.md:46,119,271-273` |
| constraint | 0.1.1 counts by basename; `done/` must be listed by its children. | `modules/discovery.md:15,22,25` |
| constraint | Spec branch names derive from the folder path and `spec_branch`; the move must not change `spec_branch`. | `scripts/status-transition.sh:341`; `scripts/commit-workflow-data.sh:58-59` |
| constraint | `.step` changes only through `status-transition.sh`; removing it in the move script is a new writer. | `SKILL.md:128,151`; `scripts/status-transition.sh:2-3,80` |
| constraint | `.step` and workflow data live in the main checkout; scripts take `--cwd` and resolve via `wf_main_root`. | `scripts/status-transition.sh:23-24,199` |

## Not found

- Any existing "done folder" or `z_` concept: `.agents/`, `.workflow/rules.md`, `.workflow/capabilities.md`, `.workflow/decisions/`, `.workflow/deferred/`. Reported by retrieval.
- Shelf match by concept: none (two partial matches under Prior decisions). Reported by retrieval.
- Read by grep only: `implementation-orchestrator.md`, `review-triage.md`, `.agents/agents/*.md` (six reference `.workflow/specs`), `codex-write-guard.sh`, `worktree-write-guard.sh`, tests beyond the fixture. Reported by retrieval.
- Unverified: yq advisories and Scorecard (deps.dev response truncated). Reported by library-evaluation.
- A test directory inside the owning module: none; tests live in `tests/`. Reported by module-audit.
- An existing whole-tree path-rewrite or link-depth helper: `scripts/`, `modules/`, `assets/`, `references/`, `SKILL.md`. Reported by module-audit.
- module-audit flagged two Relevant code rows as incomplete (not a Tier B cache problem; 0.2.7 found every cache fresh): `spec_done_on_main` also gates the 6.3 frontier (`large-path.md:119`), and the "Deferred back-link lookup" row is the "Re-point at conversion" procedure used only at 0.3.23 (`deferred-handoff.md:55-64`). Reported by module-audit.
