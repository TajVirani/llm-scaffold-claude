---
cache_stamps:
  modules: 99801e506b428a1ac3c3f7fb0170191cb6fa45ae
  flows: 99801e506b428a1ac3c3f7fb0170191cb6fa45ae
  architecture: 65ae1c501fe154e76b5dea5a3372718b3510cde6
---

# Codebase map: PR template

Affected area: feature-workflow (`.agents/skills/feature-workflow`: `modules/sign-off.md` 5.8, `modules/implementation-orchestrator.md` 3.16, `scripts/open-task-pr.sh`, `assets/`); standalone-skills `glab` (`.agents/skills/glab`) and `pr-quality` (`.agents/skills/pr-quality`); `.agents/install-manifest.txt`.

## Relevant code

| Item | What it does today | Source |
| --- | --- | --- |
| Sign-off 5.4 report | Writes `report.md` from `assets/report.md`: Tests and CI, Targets vs measured, Journeys, Review outcome, Known gaps, Deferred. The stakeholder reads it at 5.5. | `.agents/skills/feature-workflow/modules/sign-off.md:74-91` |
| Sign-off 5.5 summary | Short summary to the stakeholder linking `report.md` and `proposals.md`. | `.agents/skills/feature-workflow/modules/sign-off.md:103` |
| Sign-off 5.8 merge PR | With the stakeholder's go-ahead, pushes `spec/NNN-slug` and opens a PR/MR into main with raw `gh pr create --base main --head spec/NNN-slug` or `glab mr create --target-branch main --source-branch spec/NNN-slug`. Title "after the feature"; links `report.md` and the task PRs. No body template. Without a remote or CLI, merges locally with `git merge --no-ff`. | `.agents/skills/feature-workflow/modules/sign-off.md:159-161` |
| Sign-off 5.8 done-when | "the PR is open (or the local merge has landed)". | `.agents/skills/feature-workflow/modules/sign-off.md:165` |
| Task PR at 3.16 | With `task_review` `pr` or `pr-blocking`, runs `open-task-pr.sh <spec-dir> T3 --record`. Title `T3: <task title>`; body names the task file and the mini-review verdict. Non-blocking for `pr`. | `.agents/skills/feature-workflow/modules/implementation-orchestrator.md:179-189` |
| 3.16 cleanup | Pushes the spec branch after the merge so the PR/MR shows as merged. | `.agents/skills/feature-workflow/modules/implementation-orchestrator.md:198` |
| Task PR body text | `Task <id> of <spec-dir> (review record).` plus `Task file:` and, when present, `Mini-review:` lines. | `.agents/skills/feature-workflow/scripts/open-task-pr.sh:145-153` |
| Generic PR body default | Without `--body`, the body is the title; `--body ""` gives an empty body. | `.agents/skills/feature-workflow/scripts/open-task-pr.sh:121-123` |
| PR create and reuse | Reuses an open PR/MR for the same head and base; otherwise `gh pr create ... --body` or `glab mr create ... --description ... --yes`. Host chosen from `origin` (github or gitlab); other hosts skip. | `.agents/skills/feature-workflow/scripts/open-task-pr.sh:25-27, 176-184` |
| Record URL | Task form: `status-transition.sh set-task ... --pr <url> --step 3.16`. Generic form with `--record <dir>`: `initiative-transition.sh set-pr`. | `.agents/skills/feature-workflow/scripts/open-task-pr.sh:186-191` |
| CLI choice comment | Host-to-CLI choice "mirrors the glab skill and the sign-off PR step". | `.agents/skills/feature-workflow/scripts/open-task-pr.sh:39` |
| Report template | Summary, Capabilities, Tests and CI, Targets vs measured, Journeys, Review outcome, Known gaps, Deferred, How to verify, Evidence. Read at 5.5 and by the retrospective at 5.7. | `.agents/skills/feature-workflow/assets/report.md:1-79` |
| glab MR body example | `glab mr create` body as a HEREDOC with `## Summary` and `## Test plan`. | `.agents/skills/glab/SKILL.md:82-93`, `:115` |
| glab project conventions | Projects layer conventions on top, including "MR template sections". | `.agents/skills/glab/SKILL.md:105` |
| pr-quality scope | Reviews the branch diff against `origin/main` with parallel sub-agents plus `.workflow/pr-quality/*.md` checks. Writes no PR description. | `.agents/skills/pr-quality/SKILL.md:26-34`, `:66-69`, `:160` |
| Review load measure | `max_changed_files` counts files a reviewer sees in the feature's PR/MR. | `.workflow/rules.md:112-120` |
| Blast radius usage | Used, undefined, in `feature-workflow/modules/task-breakdown.md:18`, `visual-change-report/SKILL.md:17, 68, 97`, `data-structure-audit/SKILL.md:72, 98`, `deps-update/SKILL.md:3, 10, 28`, `deps-audit/SKILL.md:23`. | paths as listed |
| Install payload | `skills/feature-workflow`, `skills/glab`, `skills/pr-quality` ship as whole directories; a new file under `feature-workflow/assets/` needs no manifest line. No PR template file exists under `.agents/`. | `.agents/install-manifest.txt:11, 77-78` |

## Seams and interfaces

| Interface | Shape (signature, type, contract) | Callers | Source |
| --- | --- | --- | --- |
| `open-task-pr.sh` task form | `open-task-pr.sh <spec-dir> <task-id> [--cwd <dir>] [--record] [--dry-run]`; prints a URL or `skipped: <reason>`; exit 0 | Orchestrator 3.16 | `.agents/skills/feature-workflow/scripts/open-task-pr.sh:11, 50`; `modules/implementation-orchestrator.md:185` |
| `open-task-pr.sh` generic form | `--head <branch> --base <branch> --title <text> [--body <text>] [--cwd] [--record <initiative-dir>] [--dry-run]` | `large-path.md` initiative PR | `.agents/skills/feature-workflow/scripts/open-task-pr.sh:17-22`; `modules/large-path.md:220` |
| Sign-off 5.8 PR | No script; raw `gh pr create` / `glab mr create` in prose; no body argument. | Sign-off only | `.agents/skills/feature-workflow/modules/sign-off.md:161` |
| `rules-setting.sh task_review` | Prints `pr`, `pr-blocking` or `local`; default `pr` | Orchestrator 3.16 | `modules/implementation-orchestrator.md:179-182` |
| `rules-setting.sh main_branch` | PR/MR target branch; default from origin/HEAD, else `main` | Sign-off 5.8 | `.workflow/rules.md:130-131`; `modules/sign-off.md:161` |

| `rules-setting.sh <key>` (key table) | `rules-setting.sh <key> [--cwd <dir>] [--rules <path>]`; stdout the value; absent → default with stderr note; exit 1 on unknown key, bad value, missing yq | 3.16, large-path, 1.1, 0.3.20, 5.8, `open-task-pr.sh`, `budget-check.sh` | `scripts/rules-setting.sh:5-27,41-48` |
| `check-*.sh` validator family | `<script> <file>`, read-only; exit 0 table, 1 shape errors on stdout, 2 usage/environment on stderr | review-triage, implementation-orchestrator | `scripts/check-review-findings.sh:33-35`; `scripts/check-task-result.sh:57-61` |
| Sign-off 5.4 report write | Heredoc from `assets/report.md` into `<spec>/report.md`; harness through `run-toolchain.sh --reuse` | sign-off | `modules/sign-off.md:74-91` |
| Sign-off 5.5 ask | One batched AskUserQuestion round (max 4 per call) or numbered chat; logged in the design-log Sign-off shape | sign-off | `modules/sign-off.md:95-116` |
| `budget-check.sh` changed-file set | `--spec-dir <dir> [--cwd] [--predicted]`; JSON `files` = reviewer-visible non-test files | 2.6, 3.15 | `scripts/budget-check.sh:6-30` |

## Prior decisions

| Decision or item | What it says | Source |
| --- | --- | --- |
| Workflow settings | `task_review` and `main_branch` decide task-PR behaviour and the sign-off PR target. Changed only at 5.3. | `.workflow/rules.md` § Workflow settings |
| Size budget | `max_changed_files` is measured against what the feature's PR/MR reviewer sees. | `.workflow/rules.md` § Size budget |
| New `.agents/` assets | Adding anything under `.agents/` needs a `PROVENANCE.md` update in the same change; a first-party asset targets need goes in `install-manifest.txt`. | `.workflow/rules.md` § Cross-cutting policy |
| Commit subject rule | Conventional Commits; no Co-Authored-By or AI mention. | `.workflow/rules.md` § Cross-cutting policy |
| 5.8 merge subject (retros 002, 003, 005) | "Use a Conventional Commits subject for the 5.8 merge" kept failing: partly, no, no. GitHub's default merge subject was used. | `.workflow/decisions/retrospectives/002-review-lessons.md:73`; `003-bash-cache-extractor.md:60`; `005-cache-build-followups.md:57` |
| Glossary | Spec branch "reaches main only through the sign-off PR (D85)". | `.workflow/GLOSSARY.md` § Branches and tasks |
| Wayfinder comparison | `gh`/`glab` used "only for task and sign-off PRs". | `wayfinder-comparison.html:246` |
| Deferred `sign-off-scoped-commit.md` | Sign-off's final commit stages every untracked folder; desired: stage only this spec's paths. Nearest shelf item; does not cover PR descriptions. | `.workflow/deferred/sign-off-scoped-commit.md` § Summary |
| Capabilities | CAP-001 to CAP-005 do not cover PR descriptions, the sign-off PR or the report template. | `.workflow/capabilities.md:13-17` |
| ADRs, pitfalls | None mention PR descriptions, sign-off PR, blast radius or the report template. | `.workflow/decisions/adr/`, `.workflow/decisions/pitfalls.md` |

## Library options

Concerns: (1) filling a fixed PR/MR description; (2) finding and selecting the host's template file. Settled by rules: none (`rules.md` "External systems" has no gh or glab entry). No package manifest exists.

**Already in the project:** `gh` (`open-task-pr.sh:179`, `gh pr create --base --head --title --body`) and `glab` (`open-task-pr.sh:182`, `glab mr create ... --description --yes`); glab HEREDOC body recipe (`.agents/skills/glab/SKILL.md:82-93`). No `.github/pull_request_template*` or `.gitlab/merge_request_templates/` in this repo.

### Concern 1: filling a fixed PR/MR body

Verdict: Use existing. Fill the template in bash and pass a file with gh `--body-file` / glab `--description-file`. Never pass gh `--template` with `--body` or `--body-file` (it errors).

| Option | Fit | Licence | Maintenance | Security | Cost |
| --- | --- | --- | --- | --- | --- |
| gh pr create `--body-file`/`-F` (incumbent) | pass: reads a file or stdin; `-T` errors with `--body`/`--body-file` | pass: MIT | pass: v2.103.3, 2026-10-26 | caution: Scorecard 6.8; advisories not checked | pass: already used |
| glab mr create `--description-file` (incumbent) | pass: documented; mutual exclusion with `--description` not verified | pass: MIT | pass: v1.126.0, 2026-10-28 | unknown: no Scorecard | pass: already used |
| In-house bash fill | pass: `cat`/`sed` substitution | n/a | n/a | pass: no new dependency; quoting is the only risk | caution: ~0.5 day plus shell tests |

Evidence: https://cli.github.com/manual/gh_pr_create; https://raw.githubusercontent.com/cli/cli/trunk/pkg/cmd/pr/create/create.go; https://docs.gitlab.com/cli/mr/create/; https://gitlab.com/gitlab-org/cli/-/raw/main/LICENSE; https://api.github.com/repos/cli/cli/releases/latest; https://api.github.com/repos/cli/cli; https://api.deps.dev/v3/projects/github.com%2Fcli%2Fcli; https://gitlab.com/api/v4/projects/gitlab-org%2Fcli; https://api.deps.dev/v3/systems/go/packages/gitlab.com%2Fgitlab-org%2Fcli; https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/releases?per_page=3

Risks: gh `--template` plus `--body-file` fails at runtime and opens no PR. Unverified: installed gh/glab versions; glab `--description` with `--description-file`; CLI advisories.

### Concern 2: finding and selecting the host's template

Verdict: Use existing. Read the template by repo path in bash (`.github/pull_request_template.md` or `.gitlab/merge_request_templates/<name>.md`) and pass it as in Concern 1. Use glab `--template` only as the sole body source.

| Option | Fit | Licence | Maintenance | Security | Cost |
| --- | --- | --- | --- | --- | --- |
| Read repo template path in bash | pass: both hosts | n/a | n/a | pass: reads a repo file | pass: ~0.5 day with an absent-template test |
| glab `--template` | caution: bare names resolve only in the local clone; `--description` combination unverified | pass: MIT | pass | unknown | pass |
| gh `--template` | fail for body-based flows: errors with `--body`/`--body-file`; ignored with `--fill` | pass: MIT | pass | caution | pass |

Evidence: https://docs.gitlab.com/user/project/description_templates/; https://docs.gitlab.com/cli/mr/create/; https://cli.github.com/manual/gh_pr_create; https://raw.githubusercontent.com/cli/cli/trunk/pkg/cmd/pr/create/create.go

Risks: gh auto-loading `pull_request_template.md` in non-interactive mode is unconfirmed; do not rely on it. A target project's own template may use headings sign-off cannot fill.

## Module audit

Owning module: feature-workflow (`.agents/skills/feature-workflow/**`)

| Kind | Finding | Source |
| --- | --- | --- |
| reuse | Validator shape for `check-pr-body.sh`: read-only, one `<field>: <problem>` line per failure on stdout, exit 0 valid / 1 shape errors / 2 usage or environment; `die`/`usage` helpers, `PROG=`, bash 3.2. | `scripts/check-review-findings.sh:33-50,189-207`; `scripts/check-task-result.sh:57-76` |
| reuse | awk section extractor (heading match, trailing spaces trimmed, stops at next `## `) can pull `## ` headings and bodies. | `scripts/rules-setting.sh:86-91` |
| reuse | A new key is one `setting_spec` case `"<default> <allowed...>"`, e.g. `workflow workflow project`; validation, defaulting and errors are generic. | `scripts/rules-setting.sh:41-48,83-105` |
| reuse | Host detection from `origin` (github → gh, gitlab → glab, else skip) plus CLI-installed and `auth status` checks. | `scripts/open-task-pr.sh:155-171`; `modules/sign-off.md:161` |
| reuse | Evidence sources: Why ← `spec.md` Why/Capabilities; Approach ← design-log Placement and Impact classification; Seams ← `codebase-map.md` Seams and Module audit; How to test ← report "How to verify"; Notes and risk ← report "Known gaps"/"Deferred"; Blast radius ← `budget-check.sh` `files`. | `assets/design-log.md:123-146`; `assets/codebase-map.md:43,67`; `assets/report.md:63-74`; `scripts/budget-check.sh:20-30` |
| reuse | 5.4 already writes `report.md` from an asset by Bash heredoc; `pr-body.md` beside it is unguarded. | `modules/sign-off.md:76`; `SKILL.md:152`; `scripts/check-write.sh:46` |
| reuse | A 5.2 `pr_template` row fits the Rules group (Target `.workflow/rules.md` § section), applied at 5.3. | `assets/proposals.md:28-32`; `modules/sign-off.md:69`; `scripts/check-write.sh:40-42` |
| gap | No issue link exists in the spec folder; `spec.md` frontmatter has no issue key. | `assets/spec.md:1-13,32` |
| gap | 5.8 gives no body argument and no merge message; the local merge is a bare `git merge --no-ff`. | `modules/sign-off.md:161` |
| gap | 5.2's candidate table has no source row for workflow settings. | `modules/sign-off.md:21-28` |
| gap | 5.5 shows only a short summary; no step shows full text for approval; the Sign-off design-log shape has no body-approval line. | `modules/sign-off.md:103-111`; `assets/design-log.md:184-190` |
| gap | No code reads `.github/pull_request_template.md` or `.gitlab/merge_request_templates/`; `open-task-pr.sh` passes bodies inline only. | `scripts/open-task-pr.sh:121-123,179,182` |
| constraint | Order 5.4 → 5.5 → 5.9 → 5.7 → 5.8: the approved body cannot cite later commits or the final sha. | `modules/sign-off.md:3,124,142,161` |
| constraint | A 5.6 change request returns through 5.4/5.5; a first-pass `pr-body.md` would be stale. | `modules/sign-off.md:114,120` |
| constraint | 5.3 replaces `CAP-NEW-` only in named files and greps them; a body written before 5.3 would escape. | `modules/sign-off.md:64-66` |
| constraint | Every claim points to evidence; a skipped gate is a gap, never a pass; unmeasured values say "not measured" with the reason. | `modules/sign-off.md:76,91`; `assets/report.md:5-10` |
| constraint | A `rules-setting.sh` key appears in five places: header table, `usage()`, `setting_spec`, unknown-key text, "Called by". | `scripts/rules-setting.sh:13-27,39,42-48,65` |
| constraint | 5.8 merges only with the stakeholder's go-ahead and pushes only what they asked for; target from `rules-setting.sh main_branch`. | `modules/sign-off.md:161` |
| constraint | Script header convention: File, Purpose, Usage, stdout, Exit, Called by, Notes, Sources; called with the full `.agents/skills/feature-workflow/scripts/` prefix. | `scripts/check-review-findings.sh:1-37`; `SKILL.md:128` |
| constraint | `SKILL.md` lists every per-feature template in `assets/`; the new asset and `pr-body.md` must be added. | `SKILL.md:213` |
| constraint | `open-task-pr.sh` says its host-to-CLI choice "mirrors ... the sign-off PR step"; keep that comment true. | `scripts/open-task-pr.sh:39` |

## Not found

- A PR/MR description template for sign-off or task PRs: `.agents/skills/feature-workflow/**`, `.agents/skills/glab/**`, `.agents/skills/pr-quality/**`, `.workflow/**`. Only the task-PR body in `open-task-pr.sh` and the glab example exist. Reported by retrieval.
- A sign-off PR body spec: `modules/sign-off.md` § 5.8 names title and links only. Reported by retrieval.
- A shelf match: all 14 `.workflow/deferred/*.md` compared by concept; none matches. Reported by retrieval.
- Cache coverage: `.workflow/cache/modules.md` and `flows.md` have no section for `glab`, `pr-quality`, or feature-workflow's `modules/` and `assets/`; code was read instead. Reported by retrieval.
- Code reading a host PR/MR template file; a markdown-heading validator; any `--body-file` / `--description-file` / `merge -F` use: `.agents/skills/feature-workflow/**`. Reported by module-audit.
- Module tests (`tests/scripts/rules-setting*`, `open-task-pr*`): outside the owning module's paths, not read. Reported by module-audit.
- cache disagrees with code: none. Reported by module-audit.
- Tests for PR body text (`tests/scripts/open-task-pr*`): not searched. Reported by retrieval.
