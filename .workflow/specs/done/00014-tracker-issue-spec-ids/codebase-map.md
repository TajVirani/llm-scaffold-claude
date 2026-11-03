---
cache_stamps:
  modules: 9e971ade158b5e92da93bf2b150fd68dd55d7e9e
  flows: 9e971ade158b5e92da93bf2b150fd68dd55d7e9e
  architecture: 9e971ade158b5e92da93bf2b150fd68dd55d7e9e
---

# Codebase map: Tracker issues as spec IDs

Affected area: feature-workflow (`.agents/skills/feature-workflow`), project-setup (`.agents/skills/project-setup`), standalone-skills/glab (`.agents/skills/glab`), lib (`.agents/lib`), hooks (`.agents/hooks`), installer (`install.sh`, `.agents/install-manifest.txt`).

## Relevant code

| Item | What it does today | Source |
| --- | --- | --- |
| Spec number scan (0.1.1) | Finds the highest number among top-level specs, `specs/done/`, spec worktrees, and each initiative's `origin` and `slices[].spec`, in the working tree and on `initiative/*` branches; `sort -n`. | `.agents/skills/feature-workflow/modules/discovery.md:11,14-21` |
| New spec number | Highest + 1, zero-padded with `printf '%05d'`; `00001` when none. Older specs keep three digits; any digit count is valid. | `.agents/skills/feature-workflow/modules/discovery.md:23` |
| Initiative number (0.3.23 step 2) | Separate scan: highest `NNN` among `.workflow/initiatives/[0-9][0-9][0-9]-*/`, `initiative/*` branches and the main ref; `001` when none. | `.agents/skills/feature-workflow/modules/large-path.md:71` |
| Converted spec number | The spec folder is deleted at 0.3.23 step 6; its number stays consumed because 0.1.1 counts the initiative `origin`. | `.agents/skills/feature-workflow/modules/large-path.md:89` |
| Folder name check | `wf_norm_folder` accepts `specs/NNN-slug`, `specs/done/NNN-slug`, `initiatives/NNN-slug`. Regex `^[0-9]+-[A-Za-z0-9][A-Za-z0-9._-]*$`. | `.agents/lib/workflow-paths.sh:117-149` (regex 144) |
| Agent worktree name | Spec number copied verbatim from the folder name: task `s<NNN>_t<n>`, Phase 1 `s<NNN>_phase_1_<enc>`, integration `s<NNN>_integration_<enc>`. `00014-x` gives `s00014_t1`. | `.agents/lib/workflow-paths.sh:162-201` (parse 170-179, output 187, 194) |
| Launch header `spec_dir` | Regex admits only a direct child of `.workflow/specs/`, so a Done-folder spec is refused. | `.agents/skills/feature-workflow/scripts/resolve-launch.sh:104-106` |
| Done move | `move_spec` moves `specs/NNN-slug` to `specs/done/NNN-slug`, sets `.step` aside, rewrites the spec path in every tracked `.workflow/` file except cache, initiatives, worktrees, handoff and staging. Commit subject `chore(workflow): move <name> into the Done folder`. | `.agents/skills/feature-workflow/scripts/move-to-done.sh:341-384` (rewrite 371-377), 418 |
| Sign-off PR body | Ten `##` headings in fixed order. The first, `## Link to issue`, holds an HTML-comment stub "No tracker issue yet: the workflow does not create one when a spec starts." | `.agents/skills/feature-workflow/assets/pr-template.md:15-18` |
| Sign-off PR check | Checks the ten headings in order and the section shape; nothing checks the link section's content. | `.agents/skills/feature-workflow/scripts/check-pr-body.sh:6-8` |
| Sign-off PR creation (5.8) | `gh pr create --base "$MAIN" --head "$SPEC_BRANCH" --body-file pr-body.md` or `glab mr create ... --description-file`. | `.agents/skills/feature-workflow/modules/sign-off.md:249-250` |
| Host choice for task PRs | `origin` URL containing `github` gives gh; containing `gitlab` gives glab; anything else is skipped. | `.agents/skills/feature-workflow/scripts/open-task-pr.sh:27-28,162-164` |
| Spec frontmatter | Keys status, baseline_revision, spec_branch, impl_base_revision, light_path, small_path, followup_review_recommended, deferred, origin, initiative, budget, blocked_condition. No issue key. "Add no other keys". | `.agents/skills/feature-workflow/assets/spec.md:2-13,38` |
| spec.md write steps | Single writer at 0.1.4, 0.1.6, 0.3.17, 0.3.19, 0.3.20, 0.5.1, 1.1, 2.5, 3.1, 3.14, 4.6, 4.8, 5.1, 5.3, 5.9, 00.29; `status` and `blocked_condition` only through status-transition.sh. | `.agents/skills/feature-workflow/assets/spec.md:41` |
| Origin keys | 0.1.4 writes `origin:` and `initiative:`; an "Origin:" line opens the Why. | `.agents/skills/feature-workflow/modules/discovery.md:44-46`; `assets/spec.md:34-35` |
| Task record | Keys id, title, status, capability, depends_on, touches_core, work_type, module, seam, file, branch, predicted_files, size, mode, parallel_with, tests, pr. `pr` is the only URL key (`^https?://`), set at 3.16. No issue key. | `.agents/skills/feature-workflow/assets/tasks.md:5-19,70` |
| Recording a URL | `open-task-pr.sh` warns and still exits 0 when the URL cannot be recorded. | `.agents/skills/feature-workflow/scripts/open-task-pr.sh` `main()`; `.workflow/cache/modules.md` § open-task-pr.sh |
| Session-start scan | Reads `.workflow/specs/*/spec.md` per checkout; top level only; `done` skipped. Glob order is lexical, not numeric, with mixed digit widths. | `.agents/hooks/session-start-resume.sh:4,15,77-85,233` |
| Done-on-main check | `spec_done_on_main` reads status from the main ref at `specs/` and `specs/done/`. | `.agents/hooks/session-start-resume.sh:190-196` |
| Codex task-name parse | `^s([0-9]+)_(.+)$`; spec folder by glob `$WF_SPECS/$num-*`, which must match exactly one top-level folder. | `.agents/hooks/codex-pre-spawn.sh:97-98,127-160`; `.agents/hooks/post-implementation-audit.sh:136-143` |
| Codex write guard | Worktree name must match `^s[0-9]+_[a-z0-9_]+$`. | `.agents/hooks/codex-write-guard.sh:115` |
| Worktree forms | Header lists `s<NNN>_t<N>`, `s<NNN>_phase_1_<work_type>`, `s<NNN>_integration_<work_type>`. | `.agents/hooks/worktree-write-guard.sh:16-18` |
| Initiative name in Codex | `^i([0-9]+)_.+$`; initiative folder by glob `$WF_INITIATIVES/$1-*`. | `.agents/hooks/codex-pre-spawn.sh:108,129-130` |
| Discovered-work item name | Accepts `NNN-slug-disc-NNN+.md` and `NNN-slug.md`; session-start glob `[0-9]*-disc-[0-9][0-9][0-9]*.md`. | `.agents/skills/feature-workflow/scripts/check-write.sh:262`; `.agents/hooks/session-start-resume.sh:280` |
| Installer | Never creates or touches `.workflow/`. Writes the `.gitignore` block from `GI_ENTRIES`. | `install.sh:34-35,86` |
| Manifest | Directory entries `skills/feature-workflow`, `skills/project-setup`, `skills/glab`; file entries `lib/workflow-paths.sh`, `hooks/session-start-resume.sh`. | `.agents/install-manifest.txt:11-12,38,47,78` |
| glab skill | Documents `glab issue list/view/create/update/note/close/reopen`; says feature-workflow plans and glab "files and updates the matching tracker items"; notes issue IDs versus work-item IDs. | `.agents/skills/glab/SKILL.md:3,17,54-67,118` |
| Host PR template paths | project-setup looks for host templates at four paths. | `.agents/skills/project-setup/modules/files.md:28-32` |
| Workflow settings | `rules-setting.sh` keys `task_review`, `main_branch`, `pr_template`. No issue key. | `.agents/skills/feature-workflow/scripts/rules-setting.sh:15-26,53-56` |

## Seams and interfaces

| Interface | Shape (signature, type, contract) | Callers | Source |
| --- | --- | --- | --- |
| `wf_norm_folder spec\|initiative ARG` | Prints the repo-relative folder; status 1 and reason on stderr otherwise. | `move-to-done.sh` `resolve_spec` (56), `commit-workflow-data.sh`, `open-task-pr.sh`, `budget-check.sh`, `task-waves.sh` | `.agents/lib/workflow-paths.sh:117-149` |
| `wf_agent_worktree_name SPEC_DIR task\|phase_1\|integration VALUE` | Prints the `s<NNN>_...` name; status 1 for a folder that is not `NNN-slug`. | `post-implementation-audit.sh` (header 25) | `.agents/lib/workflow-paths.sh:162-201` |
| `wf_project_root DIR`, `wf_main_root DIR` | Checkout holding a spec's data; main checkout. | `session-start-resume.sh:63-64`; `move-to-done.sh:108` | `.agents/lib/workflow-paths.sh:80-115` |
| `move-to-done.sh` CLI | `--check <spec-dir>`, `<spec-dir>`, `--sweep [--cwd]`. Exit 0 moved or passed; 1 refused; 2 usage or environment. | sign-off 5.7, 5.8 | `.agents/skills/feature-workflow/scripts/move-to-done.sh:10-13,27-33` |
| `status-transition.sh set-spec` | `<spec-dir> [--spec-branch] [--impl-base] [--step] [--cwd]`. No URL or issue argument. | sign-off, implementation-setup | `.agents/skills/feature-workflow/scripts/status-transition.sh:14-15` |
| `rules-setting.sh <key>` | Keys `task_review`, `main_branch`, `pr_template`. | sign-off 5.2, 5.4, 5.8; `open-task-pr.sh`; `budget-check.sh` | `.agents/skills/feature-workflow/scripts/rules-setting.sh:15-26,53-56` |
| `check-pr-body.sh BODY` | Checks the body against the ten-heading template or a host template. | sign-off 5.4, 5.8 | `.agents/skills/feature-workflow/scripts/check-pr-body.sh:6-8` |
| Spec frontmatter validator | `yq --front-matter=extract -e` over listed keys; does not reject unlisted keys. | status and check-write scripts | `.agents/skills/feature-workflow/assets/spec.md:47-62` |
| Shared core | `.agents/lib/**` changes only through the integration agent. | all modules | `.workflow/rules.md:99-101,108-109` |
| `status-transition.sh set-task` | `<spec-dir> <T<n>> [--status] [--work-type] [--capability] [--pr <url>\|null] [--step]`; result must pass `TASKS_VALIDATOR` or nothing is written; exit 2 when the spec is done; `done->in-progress` only at 4.7, 3.9, 3.11. | 3.1, 3.3, 3.16, 3.9, 3.11, 4.7, 00.29, `open-task-pr.sh` | `status-transition.sh:7-12,245-344` |
| `status-transition.sh set-spec` (correction) | `--spec-branch` only at 1.1 or 0.3.20, `--impl-base` only at 3.1. No module calls it: 1.1, 0.3.20 and 3.1 Edit the frontmatter. | none in modules | `status-transition.sh:347-387`; `verification-setup.md:32`; `discovery-impact.md:47`; `implementation-setup.md:15` |
| `open-task-pr.sh` exit contract | Prints a URL or `skipped: <reason>`, exit 0 once arguments are valid; usage errors exit 1 (task mode) or 2 (generic). | 3.16, 6.11, 6.13 | `open-task-pr.sh:32-36` |
| `move-to-done.sh` internals | `move_spec`, `point_at_done_folder FILE NAME`, `list_files_naming NAME`, `commit_moves SUBJECT`; script-local. | the script only | `move-to-done.sh:283-406` |
| `spec-worktree.sh create\|remove` | Derives `spec/<name>` and `<main>/.workflow/.spec-worktrees/<name>`; `remove` takes a Done path; exit 1 refused, 2 env. | 1.1, 0.3.20, 5.8 | `spec-worktree.sh:9-29,160-162` |
| `check-pr-body.sh` (detail) | `<file> [--project-template <f>]`; workflow mode reads `##` headings from `assets/pr-template.md`; exit 0 valid, 1 faults, 2 usage. | 5.4, 5.8 | `check-pr-body.sh:20-27` |
| `review-lessons.sh validate\|next-id` | `origin_spec` must match `specs/` or `specs/done/` then `[0-9]+-slug`. | retrospective 5.7 | `review-lessons.sh:88-90` |
| `wf_norm_folder` (extra callers) | Also called by `status-transition.sh` and `spec-worktree.sh`. | as cited | `status-transition.sh:205`; `spec-worktree.sh:160` |
| Load-budget measure | Start load: `AGENTS.md`, hook output, `SKILL.md`, `conventions.md`, `discovery.md`, term list (limit 45,000). Resume load: same with `implementation-waves.md` for `discovery.md`, no term list (limit 55,000). | `tests/run-all.sh` | `tests/lint/workflow-load-size.sh:48-55` |

## Prior decisions

| Decision or item | What it says | Source |
| --- | --- | --- |
| ADR-0001 (accepted) | Host-neutral `.agents/` core behind thin host shims; `install.sh` distributes exactly what the manifest lists. | `.workflow/decisions/adr/0001-project-baseline.md:8` |
| ADR-0004 (accepted) | New-feature start may load at most 45,000 bytes; at sign-off it sat at 44,733. Raised only by a new decision. | `.workflow/decisions/adr/0004-workflow-load-budget.md:7,18` |
| Retro 006 | New spec folders use 5-digit numbers from `00010`; any digit count is valid in the lib, `resolve-launch.sh` and the 0.1.1 scan. | `.workflow/decisions/retrospectives/006-result-file-guard.md:86,100` |
| Retro 007 | Constraint "any-digit numbers" for the Done folder. | `.workflow/decisions/retrospectives/007-done-folder.md:22` |
| CAP-006 | Sign-off PR description: ten-section template or the host template; 5.8 publishes it. | `.workflow/capabilities.md:18` |
| CAP-011 | Done folder: move at 5.8; the 0.1.1 scan, session start and 6.13 find a finished spec in either place. | `.workflow/capabilities.md:23` |
| Pitfall: no `.workflow/` path in an installed asset | The shipped `pr-template.md` issue stub once named a shelf file only this repo holds. | `.workflow/decisions/pitfalls.md:35-39` |
| Retro 008 non-goals | Issue creation out of scope; "Link to issue" stays a marked stub; shelf files `spec-issue-creation.md`, `workflow-settings-home.md`, `initiative-pr-template.md` written at 0.3.17. | `.workflow/decisions/retrospectives/008-pr-description-template.md:13,29` |
| rules.md Workflow settings | `task_review`, `main_branch`, `pr_template`; changed only at 5.3. | `.workflow/rules.md:124-131` |
| rules.md Ownership | lib (33-35), hooks (36-38), feature-workflow (39-41), project-setup (42-44), standalone-skills incl. glab (69-78), installer (85-87). | `.workflow/rules.md` as cited |
| rules.md cross-cutting | A new first-party asset goes in the manifest and `PROVENANCE.md` in the same change; `.gitignore` block in step with `GI_ENTRIES`. | `.workflow/rules.md:142,147` |
| rules.md External systems | Heading only; no content. | `.workflow/rules.md:149` |
| Scaffold-only docs | `assetlist.md:366` and `upstream-lineage.json:1344`: upstream `to-tickets` publishes to an issue tracker, this workflow writes `tasks.md` instead. `wayfinder-comparison.html:246`: the workflow does not file issues. | those files |
| Deferred: `spec-issue-creation` | Create a tracker issue when a spec starts and link it from the Sign-off PR. Archived at 0.1.5, superseded by this spec. | `.workflow/deferred/archive/spec-issue-creation.md` |
| Deferred: `worktree-name-parser.md` | One shared parser for `s<NNN>` names to spec number, task and work type; shelved at 006. `.agents/lib/` is shared core; names stay byte-identical to Codex. Parsers at `post-implementation-audit.sh:127-165`, `codex-pre-spawn.sh:124-158`, `codex-write-guard.sh:114-115`. | `.workflow/deferred/worktree-name-parser.md:8,18-20,26,36` |
| Deferred, adjacent: `launch-against-done-spec.md` | Launch against a Done spec is refused; which task types may run on one is undecided. | `.workflow/deferred/launch-against-done-spec.md:8,18` |
| Deferred, adjacent: `initiative-pr-template.md` | Initiative PR has a title-only body. | `.workflow/deferred/initiative-pr-template.md:8,20` |
| Deferred, adjacent: `codex-spawn-profile-lookup.md` | Pre-spawn check and stop audit resolve a Phase 1 work type against different profile sets. | `.workflow/deferred/codex-spawn-profile-lookup.md:8` |
| Deferred, adjacent | `session-start-timing-target.md`, `main-checkout-resolver.md`, `large-path-live-run.md`, `sign-off-scoped-commit.md`: neighbours of session start, `wf_main_root`, large path, sign-off commit staging. | line 8 of each |

## Library options

Concerns: create a tracker issue and read back its number; child issues; edit the body from a whole spec.md; move issues across board columns or scoped labels; check issues enabled and CLI auth. Settled by rules: none (`.workflow/rules.md:149-150` External systems is empty). Required versions: bash 3.2, jq, yq v4 (`.workflow/rules.md:153-155`). Installed versions not measured.

### Already in the project

- gh, no version pinned: `.agents/skills/feature-workflow/scripts/open-task-pr.sh:162-184`; `.agents/skills/feature-workflow/modules/sign-off.md:249`. PRs only.
- glab, no version pinned: `.agents/skills/glab/SKILL.md:20-119` (issue create, update, note, labels, `glab api`); `.agents/skills/glab/BOARDS.md:9-25` (boards API, label-backed lists); `open-task-pr.sh:163,186-187`; `sign-off.md:250`. Issues, labels, boards; not child items or the enabled check.
- curl: `.agents/agents/review-targets.md:63` (health probe only).
- No package manifest or lockfile.

### Candidates

| Option | Fit | Licence | Maintenance | Security | Cost |
| --- | --- | --- | --- | --- | --- |
| gh >= 2.97.0 (incumbent) | pass: issue create/edit flags, `gh api --jq`; `issue create` has no `--json` (U27, U28, U31) | pass: MIT (U3) | pass: v2.103.3, Oct 2026 (U1); deps.dev at v2.102.1 (U2) | caution: CVE-2026-64652, -64654 hit <=2.96.0, fixed 2.97.0 (U5, U6); GHSA-8xvp-7hj6-mcj9 range unverified (U7); Scorecard 6.8, Signed-Releases 0 (U4) | pass: one binary; ~1-2 days (estimate) |
| glab (incumbent) | caution: `--description-file` (U17), `glab api -F @file` (U20); `issue create` documents no JSON/URL output (U18); parent-child link GraphQL only | pass: MIT (U9) | pass: v1.127.0 on 2026-11-02 (U8) | caution: issue #8306 reports three CVEs in bundled deps, fixed version unknown (U10) | pass: Free covers tasks, links, labels, boards (U12, U14, U16); scoped labels Premium (U15); ~1-2 days (estimate) |
| curl REST (in-house) | caution: REST covers issue create/update/labels (U22), Projects (U35), sub-issues (U24); GitLab hierarchy has no REST path | unknown | unknown | caution: token and pagination handling would be ours | caution: ~3+ days (estimate) |

### 1. Create tracker issue and read back the number

Verdict: use existing gh and glab; read the number from the API response.

- gh: `gh api repos/<owner>/<repo>/issues -f title=... -F body=@spec.md --jq .number` (U31, U32).
- glab: `glab api "projects/<group>%2F<project>/issues" -X POST -f title=... -F description=@spec.md`, read `iid` (U20, U22). Do not parse `glab issue create` output (U18).
- Deprecation: none found for issue create. Avoid `glab work-items` for creates: GraphQL to REST move planned, no GA date (U11).

### 2. Child issues

Verdict: gh for GitHub (`gh issue create --parent <n>`, gh >= 2.94.0; U27, U29). Hold GitLab child-task linking; Free fallback is a `relates_to` link.

- GitHub REST fallback: `POST /repos/{o}/{r}/issues/{n}/sub_issues` takes numeric `sub_issue_id` (issue id, not number; U24). 100 per parent, 8 levels (U25). Secondary rate limits (U24). GA April 2025 (U26). Plan availability unknown.
- GitLab: tasks are Free (U12) and can be children of an issue (U13). Setting a parent is GraphQL only (`hierarchyWidget`, U36); schema unverified. Fallback: `glab issue create --linked-issues <iid> --link-type relates_to` (U18). `blocks` links need Premium (U14).

### 3. Edit the issue body with a whole spec.md

Verdict: use existing.

- gh: `gh issue edit <n> --body-file spec.md` (U28).
- glab: `glab issue update <iid> --description-file spec.md` (U17); minimum version unknown (U19). Fallback: `glab api "projects/<enc>/issues/<iid>" -X PUT -F description=@spec.md` (U20, U22; body limit 1,048,576 chars).
- Avoid `--description "$(cat spec.md)"` (U19; SKILL.md pitfall).

### 4. Move issues across columns or labels

Verdict: use existing; on GitLab Free, plain labels only.

- GitLab: a list is a label; move with `glab issue update <iid> --unlabel <old> --label <new>` (U17, U22). Scoped labels need Premium (U15), so on Free the script removes the old label itself. Multiple boards are Free (U16).
- GitHub Projects: `gh issue edit <n> --add-project <title>` (U28), needs the `project` scope (U34); field change via `gh project item-edit --id --project-id --field-id --single-select-option-id` (U33). ID lookup not verified. Projects REST API since Sep 2025 (U35).
- Deprecation: classic Projects only (U37).

### 5. Check issues enabled and CLI authenticated

Verdict: use existing.

- GitHub: `gh repo view --json hasIssuesEnabled` (U30); `gh auth status`, gh >= 2.97.0 (U5).
- GitLab: `glab api "projects/<enc>"`, read `issues_access_level` (`disabled|private|enabled`); `issues_enabled` is deprecated (U21). `glab auth status` (SKILL.md:22); exit code unverified.

Risks: GitLab parent-child verdict changes if a test call sets a child task through GraphQL; pin flag minimums from `--help` on a real install; `-F` may JSON-parse values starting with `[` or `{` (U20, U31); throttle bulk sub-issue creation (U24); gh Signed-Releases 0 (U4).

Unverified: installed gh/glab versions; `-F @file` behaviour (no commands run); GitLab child-item GraphQL shape; GHSA-8xvp-7hj6-mcj9 range; glab CVE fix versions; GitHub sub-issue and Projects API plan tiers; `gh project item-edit` ID lookup; glab auth-status exit code; glab repo JSON fields.

Evidence:

- U1 https://github.com/cli/cli/releases/latest
- U2 https://api.deps.dev/v3/systems/go/packages/github.com%2Fcli%2Fcli%2Fv2
- U3 https://api.github.com/repos/cli/cli/license
- U4 https://api.securityscorecards.dev/projects/github.com/cli/cli
- U5 https://github.com/cli/cli/security/advisories/GHSA-cg6r-mpgc-h9mm
- U6 https://github.com/cli/cli/security/advisories/GHSA-3m3g-3wcr-px46
- U7 https://github.com/cli/cli/security/advisories
- U8 https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/releases?per_page=3
- U9 https://gitlab.com/gitlab-org/cli/-/raw/main/LICENSE
- U10 https://gitlab.com/gitlab-org/cli/-/work_items/8306
- U11 https://gitlab.com/groups/gitlab-org/-/work_items/23916
- U12 https://docs.gitlab.com/user/tasks/
- U13 https://docs.gitlab.com/user/work_items/child_items/
- U14 https://docs.gitlab.com/user/project/issues/related_issues/
- U15 https://docs.gitlab.com/user/project/labels/
- U16 https://docs.gitlab.com/user/project/issue_board/
- U17 https://gitlab.com/gitlab-org/cli/-/raw/main/docs/source/issue/update.md
- U18 https://gitlab.com/gitlab-org/cli/-/raw/main/docs/source/issue/create.md
- U19 https://gitlab.com/gitlab-org/cli/-/merge_requests/3733
- U20 https://docs.gitlab.com/cli/api/
- U21 https://docs.gitlab.com/api/projects/
- U22 https://docs.gitlab.com/api/issues/
- U23 https://gitlab.com/gitlab-org/cli/-/raw/main/docs/source/repo/view.md
- U24 https://docs.github.com/en/rest/issues/sub-issues
- U25 https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/adding-sub-issues
- U26 https://github.blog/changelog/2025-04-09-evolving-github-issues-and-projects/
- U27 https://cli.github.com/manual/gh_issue_create
- U28 https://cli.github.com/manual/gh_issue_edit
- U29 https://github.blog/changelog/2026-06-10-manage-sub-issues-types-and-dependencies-from-github-cli/
- U30 https://cli.github.com/manual/gh_repo_view
- U31 https://cli.github.com/manual/gh_api
- U32 https://docs.github.com/en/rest/issues/issues
- U33 https://cli.github.com/manual/gh_project_item-edit
- U34 https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects
- U35 https://github.blog/changelog/2025-09-11-a-rest-api-for-github-projects-sub-issues-improvements-and-more/
- U36 https://gitlab.com/gitlab-org/gitlab/-/merge_requests/90908, https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91494
- U37 https://docs.github.com/ja/enterprise-server@3.15/rest/projects-classic/projects

## Module audit

Owning module: issue-tracking (new). Audited the modules it plugs into: feature-workflow (`.agents/skills/feature-workflow/**`), `.agents/lib/workflow-paths.sh`, project-setup (`.agents/skills/project-setup/**`).

| Kind | Finding | Source |
| --- | --- | --- |
| reuse | Host choice: `git remote get-url origin`, `*github*` to gh, `*gitlab*` to glab, then `command -v`, then `auth status`; prints `skipped: <reason>` and exits 0 when something is missing. | `.agents/skills/feature-workflow/scripts/open-task-pr.sh:160-166,176,51` |
| reuse | `first_url` pulls a URL out of CLI output. | `open-task-pr.sh:180` |
| reuse | Recording a URL with "warn, still exit 0" through `set-task --pr`. | `open-task-pr.sh:194-197` |
| reuse | `set-task --pr` is the pattern for a URL key: `^https?://` check, `null` clears, warning on replace; validator line `pr`. | `.agents/skills/feature-workflow/scripts/status-transition.sh:306-319,168` |
| reuse | Path rewrite in every tracked `.workflow/` file (except cache, initiatives, worktrees, handoff, staging), with full rollback (`roll_back`, `replace_file`, `SAVED_*`) and a scoped commit (`commit_moves`). | `.agents/skills/feature-workflow/scripts/move-to-done.sh:141-182,228-236,371-377,387-406` |
| reuse | Rewrites relative links when a folder changes depth. | `move-to-done.sh:240-278` |
| reuse | Checks a worktree is registered, refuses nested agent worktrees, refuses mid-merge, cherry-pick or revert. | `.agents/skills/feature-workflow/scripts/spec-worktree.sh:48-50,85-89,129-130` |
| reuse | Refuses to commit on the main branch, detached HEAD or mid-merge. | `move-to-done.sh:199-212` |
| reuse | One staged commit of the spec folder, work-backlog and the rest of `.workflow/`. | `.agents/skills/feature-workflow/scripts/commit-workflow-data.sh:69-95` |
| reuse | Reading a YAML setting block with a default and a stderr note: the pattern for a config reader. | `.agents/skills/feature-workflow/scripts/rules-setting.sh:104-149` |
| reuse | project-setup's "create only when absent, report as kept" table and its one-question settings step. | `.agents/skills/project-setup/modules/files.md:5-14,28-39` |
| gap | `point_at_done_folder` only rewrites `specs/NAME` to `specs/done/NAME`; it cannot rename `NAME` to `NEW` in place, or `done/NAME` to `done/old_NAME`. | `move-to-done.sh:283-306` |
| gap | The move rewrite leaves `NAME.md` alone, so the backlog list `<NNN-slug>.md` and `origin: <NNN-slug>.md#B<n>` in other specs are not rewritten. | `move-to-done.sh:286`; `assets/spec.md:10` |
| gap | No script renames a spec branch or moves a spec worktree; `BRANCH` and `WT` are built from the folder name. | `spec-worktree.sh:161-162` |
| gap | `set-spec --spec-branch` requires `spec/<folder>` and refuses a different existing value. | `status-transition.sh:355-360` |
| gap | `set-spec` has no issue flag; every mode refuses while the spec is `done`. | `status-transition.sh:14-19,249,351` |
| gap | Task-record `branch` has no writer after 2.5 / 0.3.20, so it keeps the old spec name after a rename. | `status-transition.sh:11-12`; `assets/tasks.md:35` |
| gap | `wf_norm_folder` regex `^[0-9]+-...` refuses `done/old_NNN-slug`. | `.agents/lib/workflow-paths.sh:144` |
| gap | `review-lessons.sh` `origin_spec` regex refuses `old_`. | `.agents/skills/feature-workflow/scripts/review-lessons.sh:89` |
| gap | No `WF_` variable for `.workflow/issue-tracking.yaml`. | `.agents/lib/workflow-paths.sh:45-73` |
| gap | `check-pr-body.sh` takes only a body file and a template, so it cannot know whether a tracker is set; in project-template mode the issue link has no home. | `.agents/skills/feature-workflow/scripts/check-pr-body.sh:20-22,211-216` |
| gap | Spec and task-record contracts say "Add no other keys"; the validators do not list the new keys. | `assets/spec.md:38,47-62`; `assets/tasks.md:47` |
| gap | Backlog list of a renamed Done spec: `open_sub_items` looks for `${spec_dir##*/}.md`; check-write allows only `^[0-9]+-` list names. | `move-to-done.sh:70,79`; `check-write.sh:262` |
| constraint | ADR-0004 start load counts `AGENTS.md`, hook output, `SKILL.md`, `references/conventions.md`, `modules/discovery.md`, term list. Estimated about 44,966 of 45,000 bytes with this spec's glossary edits: about 34 bytes spare. | `tests/lint/workflow-load-size.sh:18,47-49` |
| constraint | ADR-0004 resume load (`implementation-waves.md` with `SKILL.md`, `conventions.md`) was 54,360 of 55,000: about 640 bytes spare. The 3.3, 3.16 and 3.9 edits land there. | `tests/lint/workflow-load-size.sh:53-55` |
| constraint | Tests run the fenced block after `**0.1.1 Scan.**` and expect the highest local number; a tracker branch must not change that output with no tracker config. | `tests/scripts/move-to-done.sh:343-372`; `tests/scripts/spec-worktree.sh:85-90` |
| constraint | `tests/fixtures/initiative.sh` `next_spec_number` is a separate three-digit copy of the scan; initiative tests pin `002`, `003`. | `tests/fixtures/initiative.sh:130-142`; `tests/scripts/initiative-emission.sh:37,84`; `tests/scripts/initiative-conversion.sh:82-84` |
| constraint | `TASKS_VALIDATOR` must stay byte-identical to the validator in `assets/tasks.md`. | `status-transition.sh:147-170`; `tests/scripts/status-transition-tasks.sh:156-159` |
| constraint | Tests extract the spec validator with awk; new lines keep its shape. | `tests/lint/small-path-docs.sh:49`; `tests/scripts/initiative-emission.sh:25` |
| constraint | `wf_norm_folder` must still refuse `done/x01-short`, `done/done`, `done/work-backlog` and nested paths. | `tests/scripts/lib-workflow-paths.sh:110-140` |
| constraint | The PR fixture fills "Link to issue" with a non-URL stub; a content check must still pass it with no tracker. | `tests/fixtures/pr-template.sh:26` |
| constraint | `spec.md` writable only at 0.1.4, 0.1.6, 0.3.17, 0.3.19, 0.3.20, 0.5.1, 1.1, 2.5, 3.1, 3.14, 4.6, 4.8, 5.1, 5.3, 5.9, 00.29; task files only at 2.5, 0.3.20. | `check-write.sh:74-75,286-305`; `references/conventions.md:20-21` |
| constraint | `specs/done/**` denied to every writer; path-only rewrites only at 5.8 through move-to-done. An adoption rename outside 5.8 breaks this convention row. | `check-write.sh:237-239`; `references/conventions.md:28-29` |
| constraint | After the 5.8 move nothing writes into the spec folder; `pr-body.md` is published unchanged apart from the spec path. | `sign-off.md:213,231` |
| constraint | Folder names feed `s<NNN>_...` worktree names verbatim; initiative `slices[].spec` and `origin` name spec folders and only `initiative-transition.sh` writes them; the move skips initiatives. | `workflow-paths.sh:170-187`; `initiative-transition.sh:325`; `move-to-done.sh:371-373` |
| constraint | project-setup runs only when no spec is in flight and never overwrites project data; adoption renames active specs. | `.agents/skills/project-setup/SKILL.md:13,15` |
| constraint | Folder-name parsers tracker numbers must satisfy (`[0-9]+-slug`). | `resolve-launch.sh:106`; `move-to-done.sh:427`; `check-write.sh:262`; `status-transition.sh:162` |
| constraint | `commit-workflow-data.sh` and `open-task-pr.sh` require the current branch to equal `spec_branch`, falling back to `spec/<folder>`. | `commit-workflow-data.sh:58-61`; `open-task-pr.sh:138-139` |

## Not found

- Code that creates, reads or links a tracker issue: `.agents/`, `tests/fixtures/pr-template.sh`; only the glab playbook, the pr-template stub, the check-pr-body header and `tests/fixtures/pr-template.sh:26` mention one. Reported by retrieval.
- Spec-number parsing in `status-transition.sh` beyond the node-id regex (119) and the task branch regex (162), which accepts any digit count. Reported by retrieval.
- Cache disagrees with code: `.workflow/cache/modules.md` § `.agents/skills/feature-workflow` (89-105) omits `scripts/move-to-done.sh`, `scripts/spec-worktree.sh`, `scripts/check-comments.sh`. Reported by retrieval.
- Codex spec-folder lookup is top level only: `.agents/hooks/codex-pre-spawn.sh:97-98` does not look in `specs/done/`. Reported by retrieval.
- A generic in-place rename or path rewrite helper in feature-workflow or lib: `.agents/skills/feature-workflow/scripts/*.sh`, `.agents/lib/workflow-paths.sh`. Reported by module-audit.
- Any git branch rename or `git worktree move` call: same paths. Reported by module-audit.
- Any reader of a `.workflow/*.yaml` config besides rules.md blocks: `.agents/skills/feature-workflow/scripts`, `.agents/skills/project-setup`. Reported by module-audit.
- A project-setup mode for an already set-up project other than "Add a work type": `.agents/skills/project-setup/SKILL.md:18-21`. Reported by module-audit.
- Any issue or tracker code: `.agents/skills/feature-workflow`, `.agents/skills/project-setup`, `.agents/lib`. Reported by module-audit.
- The `set-spec` callers row from retrieval ("sign-off, implementation-setup") disagrees with the code: no module calls `set-spec`. Not a cache problem: 0.2.7 reports every cache fresh and out of this area's scope, so no cache was read for it; the module-audit correction row in Seams and interfaces holds the code fact. Reported by module-audit.
