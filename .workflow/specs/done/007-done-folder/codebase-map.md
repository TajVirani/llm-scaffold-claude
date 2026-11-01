---
cache_stamps:
  modules: 9e971ade158b5e92da93bf2b150fd68dd55d7e9e
  flows: 9e971ade158b5e92da93bf2b150fd68dd55d7e9e
  architecture: 9e971ade158b5e92da93bf2b150fd68dd55d7e9e
---

# Codebase map: Done folder for finished specs

Affected area: feature-workflow (`.agents/skills/feature-workflow`), lib (`.agents/lib`), hooks (`.agents/hooks`), retrospective (`.agents/skills/retrospective`), standalone-skills handoff (`.agents/skills/handoff`), installer (`install.sh`), tests (`tests`).

## Relevant code

Refreshed by retrieval at 9e971ad (2026-10-30, caches republished after specs 006 and 008).

| Item | What it does today | Source |
| --- | --- | --- |
| `wf_norm_folder spec ARG` | Accepts only `.workflow/specs/NNN-slug`: digits of any count, then a slug of `[A-Za-z0-9._-]`. Refuses `specs/done/NNN-slug` and `specs/work-backlog`. | `.agents/lib/workflow-paths.sh:84-109` (regex l.104) |
| Path variables | `WF_SPECS=.workflow/specs`, `WF_WORK_BACKLOG=$WF_SPECS/work-backlog`. No Done-folder variable. | `.agents/lib/workflow-paths.sh:41-43` |
| Session-start scan | Reads `$root/.workflow/specs/*/spec.md` (one level); skips `work-backlog` and `done`. | `.agents/hooks/session-start-resume.sh:61, 204-205, 218` |
| `spec_done_on_main SPEC` | Reads `$WF_SPECS/SPEC/spec.md` from the main ref; a spec in `specs/done/` returns false. Used for `planned` initiatives. | `.agents/hooks/session-start-resume.sh:152-166, 188`; `.agents/skills/feature-workflow/modules/large-path.md:46, 119, 272` |
| Router entry scan | Lists `.workflow/specs/*/spec.md`; the `done` row says "Read it as context only". | `.agents/skills/feature-workflow/SKILL.md:32, 83` |
| 0.1.1 number scan | Prose snippet. Counts `.workflow/specs/[0-9]*-*/` (direct children), `spec/*` branches (local and origin), initiative `origin` and `slices[].spec`; new number is highest + 1, `%05d`. | `.agents/skills/feature-workflow/modules/discovery.md:11-25` (glob l.15, rule l.25) |
| Write guard, spec classes | Each spec regex takes one segment under `specs/` (`^[^/]+/spec\.md$`, `tasks\.md`, `tasks/.+`, `\.step`); a path under `specs/done/` matches none, so CLASS stays `other` and is allowed, for the main session and sub-agents. | `.agents/skills/feature-workflow/scripts/check-write.sh:199-212, 228` (sub-agent deny l.249-251) |
| Write guard, in-flight scan | `$ROOT/$WF_SPECS/*/spec.md`, skipping `done`; `done/` not scanned. | `check-write.sh:337-350` |
| Write guard, backlog origin | Origin step read from `$ROOT/$WF_SPECS/<origin>/.step`. | `check-write.sh:258-265` |
| `done` transition | Only from `in-review` with `--step 5.7`; once `done`, `.step` and frontmatter refuse changes. | `.agents/skills/feature-workflow/scripts/status-transition.sh:229, 337, 407, 432, 438` |
| Launch `spec_dir` | Must match `^\.workflow/specs/[0-9]+-[A-Za-z0-9._-]+/?$`; a `done/` path fails. | `.agents/skills/feature-workflow/scripts/resolve-launch.sh:101-103` |
| Stop audit lookup | Globs `"$main_root/$WF_SPECS/$num"-*/`, needs exactly one match; header regex l.181. | `.agents/hooks/post-implementation-audit.sh:142-144, 181` |
| Codex spawn lookup | `spec_folder NNN` counts `"$root/$WF_SPECS/$1"-*/`; must be exactly one. | `.agents/hooks/codex-pre-spawn.sh:90-94` |
| Evidence in-flight | Scans `"$main_root/$WF_SPECS"/*/spec.md` for active statuses. | `.agents/hooks/evidence-capture.sh:188` |
| Codex write guard | spec.md regex `(^|/)\.workflow/specs/[^/]+/spec\.md$`; `done/` not matched. | `.agents/hooks/codex-write-guard.sh:95-99` |
| review-lessons `origin_spec` | Must match `^\.workflow/specs/[0-9]+-[a-z0-9-]+$`; lowercase slug only; a `done/` path fails. | `.agents/skills/feature-workflow/scripts/review-lessons.sh:80-81` |
| Spec branch name | `spec/` + folder name, or the `spec_branch` key. | `scripts/check-merge-artifacts.sh:53`; `scripts/status-transition.sh:341`; `scripts/commit-workflow-data.sh:59`; `scripts/open-task-pr.sh:137` |
| 5.4 Sign-off PR body | Reads `rules-setting.sh pr_template`; fills `.workflow/specs/NNN-slug/pr-body.md` from `assets/pr-template.md`; runs `check-pr-body.sh`. | `.agents/skills/feature-workflow/modules/sign-off.md:98-114` |
| `check-pr-body.sh` | Workflow mode: the ten `##` headings in order, each non-empty; Risk and Reversibility on scale. `--project-template` checks a host template's headings. Exit 0, 1, 2. | `.agents/skills/feature-workflow/scripts/check-pr-body.sh:6-12, 210-237` |
| 5.5 backlog list | Glob `.workflow/specs/work-backlog/NNN-slug-disc-*.md` with `status: open`. | `sign-off.md:120-124` |
| 5.5 log | `Sign-off` design-log entry with `PR description:` and `Going-in concerns:` lines. | `.agents/skills/feature-workflow/assets/design-log.md:184-191` |
| 5.7 | Step 5.7, retrospective, then `status ... done --step 5.7` on an accepted verdict; before the 5.8 merge. | `sign-off.md:164-181` (status call l.178) |
| 5.8 check and publish | Re-runs `check-pr-body.sh`; publish block `gh pr create --body-file`, `glab mr create --description-file`, or local `git merge --no-ff -F`. No step moves the spec folder. | `sign-off.md:183-209` (block l.198-202) |
| 5.9 | Backlog rulings; `moved-to-deferred` writes a shelf file and edits the item. | `sign-off.md:146-162` |
| Retrospective | Standalone run offers specs with `status: done`; `origin_spec` example `.workflow/specs/NNN-slug`. | `.agents/skills/retrospective/SKILL.md:12`; `.agents/skills/retrospective/modules/routing.md:56` |
| Handoff | A spec-linked handoff reads `.workflow/specs/NNN-slug/spec.md` status and `.step`. | `.agents/skills/handoff/SKILL.md:22-25` |
| Installer gitignore | `GI_ENTRIES` holds `$WF_SPECS/*/.step` (one level). | `install.sh:85` |
| Slice and origin form | `initiative-transition.sh --spec` takes bare `NNN-slug`; `origin` is bare too. | `.agents/skills/feature-workflow/scripts/initiative-transition.sh:314`; `assets/initiative.md:3` |

## Seams and interfaces

| Interface | Shape (signature, type, contract) | Callers | Source |
| --- | --- | --- | --- |
| `wf_norm_folder spec\|initiative ARG` | Prints folder; status 1 with reason | budget-check, status-transition, check-merge-artifacts, task-waves, open-task-pr, commit-workflow-data, initiative-transition | `.agents/lib/workflow-paths.sh:84-109` |
| `wf_agent_worktree_name SPEC_DIR kind value` | Prints `s<NNN>_t<n>`, `s<NNN>_phase_1_<enc>` or `s<NNN>_integration_<enc>`; status 1 | worktree-write-guard, post-implementation-audit, codex-pre-spawn | `.agents/lib/workflow-paths.sh:124-161` |
| `check-write.sh --cwd --path [--only spec\|tier-a\|tier-b] [--proposed]` | Exit 0 allow, 2 deny, 1 error | spec-single-writer, tier-a, tier-b hooks; Codex advisory | `.agents/skills/feature-workflow/scripts/check-write.sh:4-55` |
| `spec_done_on_main SPEC` | Reads `<main_ref>:.workflow/specs/SPEC/spec.md` | session-start-resume; large-path 6.13 (copy) | `.agents/hooks/session-start-resume.sh:152` |
| `status-transition.sh status SPEC done --step 5.7` | Only from `in-review` | sign-off 5.7 | `status-transition.sh:407, 432` |
| `review-lessons.sh validate\|next-id FILE` | Exit 0, 1, 2 | retrospective routing | `.agents/skills/feature-workflow/scripts/review-lessons.sh:10-14` |
| `commit-workflow-data.sh <spec-dir> -m <msg> [--cwd]` | Exit 0 committed or nothing; 1 not on spec branch; 2 usage or local state not ignored. Rejects a `done/` path via `wf_norm_folder`. | `implementation-orchestrator.md:139,227` | `scripts/commit-workflow-data.sh:11-21` |
| `step-progress.sh --spec-dir <dir> [<id>]` | Reads `<dir>/spec.md` and `<dir>/.step`; exit 1 when missing. | every module's progress line | `scripts/step-progress.sh:44,53-63` |
| `check-pr-body.sh <file> [--project-template <t>]` | stdout `<field>: <problem>` lines; exit 0 valid, 1 faults, 2 usage, unreadable file or template, headingless project template, broken install. Reads no spec path. | `sign-off.md` 5.4, 5.5, 5.8 | `scripts/check-pr-body.sh:19-28` |
| 5.8 publish block | Shell lines after the marker; SPEC_DIR, SPEC_BRANCH, MAIN, SUBJECT; host from `git remote get-url origin`. | 5.8 go-ahead; `tests/scripts/sign-off-pr.sh` | `modules/sign-off.md:189-205` |
| `check-merge-artifacts.sh --spec-dir --rev [--cwd]` | Exit 0 clean; 1 refused; 2 usage or spec dir not `NNN-slug`. | `verification-setup.md:96`; `implementation-orchestrator.md:125,210,218` | `scripts/check-merge-artifacts.sh:7-18,52-53` |
| `resolve-launch.sh` spec_dir format | `^.workflow/specs/[0-9]+-[A-Za-z0-9._-]+/?$` | every sub-agent launch | `scripts/resolve-launch.sh:101-105` |

## Prior decisions

| Decision or item | What it says | Source |
| --- | --- | --- |
| ADR-0002 (accepted): review lessons placement | Only the retrospective writes `.workflow/review-lessons.md`, at 5.7; own write-guard class. | `.workflow/decisions/adr/0002-review-lessons-placement.md` l.2, l.5-7 |
| Retrospective 006: spec number digits | New spec folders take five-digit numbers from `00010`; the any-digit fix (lib, resolve-launch, 0.1.1) was a quick fix after 5.8. | `.workflow/decisions/retrospectives/006-result-file-guard.md` l.59, l.86, l.100 |
| Pitfall: shelf check at 00.26 | Two backlog items duplicated shelved items; a shelf check at 00.26 is a candidate. | `.workflow/decisions/pitfalls.md` l.89-93 |
| Pitfall: frontmatter edits | `yq --front-matter=extract -i` deleted two work-item bodies. | `.workflow/decisions/pitfalls.md` l.95-99 |
| Retrospectives: 5.8 merge subject | 003, 004 and 005 record a 5.8 merge subject that was not Conventional Commits. | `.workflow/decisions/retrospectives/003-bash-cache-extractor.md`; `004-scoped-test-runs.md`; `005-cache-build-followups.md` |
| Retrospective 008: 5.8 publish | Live `gh pr create --body-file` never run (no gh). | `.workflow/decisions/retrospectives/008-pr-description-template.md` l.15, l.46 |
| CAP-006 | Sign-off PR description; 5.8 publishes it unchanged (D14 changes this to "apart from the spec path"). | `.workflow/capabilities.md` l.18 |
| CAP-003 | Review lessons written at 5.7, retired in place once enforced. | `.workflow/capabilities.md` l.15 |
| Capability spec links | Rows link `specs/NNN-slug/spec.md` by relative path (CAP-001 to CAP-008). | `.workflow/capabilities.md` l.13-18 |
| Initiative conversion | A converted spec's folder is deleted; its number is never reused. | `large-path.md` l.82; `discovery.md` l.11 |
| Shelf archive pattern | Superseded shelf files move to `.workflow/deferred/archive/` with `superseded_by`. Closest precedent for a subfolder. | `deferred-handoff.md` § Archive |
| Deferred: `launch-against-done-spec.md` (direct match) | A launch with a Done-folder `spec_dir` is refused; shelved at 0.3.17 from 007. | `.workflow/deferred/launch-against-done-spec.md` |
| Deferred: `sign-off-scoped-commit.md` | 5.8 stages every untracked folder, including other specs' drafts. | `.workflow/deferred/sign-off-scoped-commit.md` |
| Deferred: `spec-issue-creation.md`, `initiative-pr-template.md`, `workflow-settings-home.md` | Sign-off PR concepts shelved from 008. | each file § Summary |
| Deferred: `codex-spawn-profile-lookup.md`, `worktree-name-parser.md` | Hook lookups of spec number and worktree name, shelved from 006. | each file § Summary |

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

### Refresh at 581e785 (2026-10-30, after specs 006 and 008)

Earlier rows, current lines: origin backlog listing `modules/sign-off.md:123`; commit-workflow-data gap `sign-off.md:185`; check-write gap `scripts/check-write.sh:192,204-217,228`; initiative constraint `sign-off.md:181`; cache constraint `check-write.sh:235-237`; order constraint `sign-off.md:3,178`; review-lessons and discovery rows same lines, text now any-digit; the rest unchanged.

| Kind | Finding | Source |
| --- | --- | --- |
| reuse | `check-pr-body.sh` reads only its `<file>`, its own template and an optional `--project-template`; nothing from the spec path or the file's location, so it runs on a body under `done/` as is. | `scripts/check-pr-body.sh:35-36,191-217` |
| reuse | The publish block takes the folder only through `SPEC_DIR`; setting it to the `done/` path is the only change the gh, glab and merge-message lines need. | `modules/sign-off.md:191,199-202,205` |
| reuse | 5.8 already has a body fix loop (fix, show, ask the 5.5 question again, log, commit). | `modules/sign-off.md:187` |
| reuse | The Sign-off design-log shape has a PR-description approval line. | `assets/design-log.md:189` |
| gap | `check-pr-body.sh` ("publishes it unchanged at 5.8") and `assets/pr-template.md` ("published unchanged at 5.8") state the old flow; both go stale under D14. | `scripts/check-pr-body.sh:3,28`; `assets/pr-template.md:3-4` |
| gap | `sign-off.md` also promises the exact approved text: "as 5.8 will publish it", "keep the approved text exactly". | `modules/sign-off.md:126,205` |
| gap | After the move, the D11 deny blocks every Write/Edit under `done/`, so a fault found by the post-move body check cannot be fixed by Edit, and no 5.8 design-log entry can be written by file tool. | `modules/sign-off.md:187`; `scripts/check-write.sh:192-228` |
| gap | `check-write.sh` edge cases: `specs/done/.step` (marker class) and `specs/done/spec.md` (KIND=spec, SPEC_NAME=`done`); the any-depth glossary rule must come after the `done/**` rule. | `scripts/check-write.sh:200,206-213,218-219` |
| gap | `resolve-launch.sh` requires `spec_dir` `^.workflow/specs/[0-9]+-[A-Za-z0-9._-]+/?$`, so no sub-agent can launch against a moved spec. | `scripts/resolve-launch.sh:101-103` |
| gap | Every spec-dir script rejects the `done/` path through `wf_norm_folder spec` (`status-transition.sh`, `commit-workflow-data.sh`, `check-merge-artifacts.sh`, `budget-check.sh`, `task-waves.sh`, `open-task-pr.sh`); 5.8 makes none of these calls today, so nothing after the move may. | `scripts/status-transition.sh:200`; `scripts/check-merge-artifacts.sh:52`; `scripts/budget-check.sh:131`; `scripts/task-waves.sh:80`; `scripts/open-task-pr.sh:126` |
| constraint | `tests/scripts/sign-off-pr.sh` runs the fenced block right after `<!-- 5.8 publish commands -->` with SPEC_DIR, SPEC_BRANCH, MAIN, SUBJECT; the marker must stay directly above that block. | `modules/sign-off.md:189-203`; `tests/scripts/sign-off-pr.sh:14,105` |
| constraint | 5.8 never passes `--template` and keeps `--no-edit --cleanup=verbatim` on the local merge. | `modules/sign-off.md:189,202,205` |
| constraint | 0.1.1 prose says a folder without a numeric prefix never counts; it must say `done/`'s children count. The glob `[0-9]*-*/` already skips `done/` itself. | `modules/discovery.md:11,15,25` |
| constraint | The backlog guard reads the origin's `.step` at its top-level path; a moved origin is never at 00.26 or 5.9, so no change. | `scripts/check-write.sh:258-278` |
| constraint | `origin_spec`, `promoted_to`, `superseded_by` store `.workflow/specs/NNN-slug`; the shelf back-link lookup matches by exact string. | `assets/work-item.md:2,6,14-16`; `assets/deferred.md:2,11,14`; `modules/deferred-handoff.md:59-62` |
| constraint | `step-progress.sh --spec-dir` reads `<dir>/spec.md` and `<dir>/.step` without `wf_norm_folder`; after the move pass the `done/` path and an explicit step id. | `scripts/step-progress.sh:44,53-63` |

## Not found

- Any existing "done folder" or `z_` concept: `.agents/`, `.workflow/rules.md`, `.workflow/capabilities.md`, `.workflow/decisions/`, `.workflow/deferred/`. Reported by retrieval.
- Shelf match by concept: none (two partial matches under Prior decisions). Reported by retrieval.
- Read by grep only: `implementation-orchestrator.md`, `review-triage.md`, `.agents/agents/*.md` (six reference `.workflow/specs`), `codex-write-guard.sh`, `worktree-write-guard.sh`, tests beyond the fixture. Reported by retrieval.
- Unverified: yq advisories and Scorecard (deps.dev response truncated). Reported by library-evaluation.
- A test directory inside the owning module: none; tests live in `tests/`. Reported by module-audit.
- An existing whole-tree path-rewrite or link-depth helper: `scripts/`, `modules/`, `assets/`, `references/`, `SKILL.md`. Reported by module-audit.
- module-audit flagged two Relevant code rows as incomplete (not a Tier B cache problem; 0.2.7 found every cache fresh): `spec_done_on_main` also gates the 6.3 frontier (`large-path.md:119`), and the "Deferred back-link lookup" row is the "Re-point at conversion" procedure used only at 0.3.23 (`deferred-handoff.md:55-64`). Reported by module-audit.
- Refresh at 581e785: spec-dir use or `.workflow/specs/*` globs in `check-worktree-scope.sh`, `check-task-result.sh`, `rules-setting.sh`: none. `check-merge-artifacts.sh` after 5.7: none. A status-transition or commit-script call inside 5.8: none. `specs/done` or `WF_SPECS_DONE` anywhere: none. Reported by module-audit.
- Refresh at 581e785: five `cache disagrees with code` lines (review-lessons regex, 0.1.1 scan, sign-off line ranges, check-write classes, commit-workflow-data callers), all from main moving since the 99801e5 stamps; resolved by rerunning 0.2.7-0.2.8 (2026-10-30). Reported by module-audit.
- Retrieval refresh at 9e971ad: no code writes, moves, numbers or scans `specs/done/`; no test runs the 0.1.1 snippet (numbering tested in `tests/scripts/lib-workflow-paths.sh:81-83, 126-127`). Reported by retrieval.
- Retrieval refresh, code vs comment: `.agents/hooks/worktree-write-guard.sh:21` says a spec number under three digits is denied, while `workflow-paths.sh:135` accepts any count (006's area; not this feature). `.workflow/review-lessons.md:9` says "three-digit number" while the asset and script say any (fixed with D13 at 5.7). `tests/fixtures/initiative.sh:134` `next_spec_number` counts only `[0-9][0-9][0-9]-*` folders, unlike `discovery.md:15` (this feature's 0.1.1 tests must not rely on it). Reported by retrieval.
- Retrieval refresh: cache versus code: no disagreement. Fixture spec `002-done` in `tests/hooks/audit-sync-resume.sh:228` and `tests/hooks/codex-adapters.sh:121` is a name, not the Done folder. Reported by retrieval.
