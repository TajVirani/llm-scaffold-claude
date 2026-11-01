---
cache_stamps:
  modules: 581e785c5e978c2b7db6d99626f5d42035531426
  flows: 581e785c5e978c2b7db6d99626f5d42035531426
  architecture: 581e785c5e978c2b7db6d99626f5d42035531426
---

# Codebase map: Worktree guard and upgrade follow-ups

Affected area: hooks (`.agents/hooks`: `worktree-write-guard.sh`, `codex-write-guard.sh`, `claude-settings.template.json`); feature-workflow (`.agents/skills/feature-workflow/scripts/check-worktree-scope.sh`); tests (`tests/hooks/worktree-guard.sh`, `tests/scripts/install-upgrade.sh`, `tests/scripts/install-claude-settings.sh`); unowned scaffold files `assetlist.md` and `.claude/settings.json`; Tier A `.workflow/profiles/shell-scripts.md` and `.workflow/decisions/pitfalls.md`.

## Relevant code

| Item | What it does today | Source |
| --- | --- | --- |
| worktree-write-guard.sh (Claude PreToolUse) | Acts only when the payload has `agent_id` and `agent_type` implementation or integration; other calls exit 0 silently. Parses the launch header from the sub-agent transcript, names the worktree, runs check-worktree-scope.sh. Exit 2 denies with its reason; any other non-zero exit denies, fail closed. | `.agents/hooks/worktree-write-guard.sh:65-69`, `:80-83`, `:92-127` |
| Header to worktree kind | `task_id` gives task; implementation without task gives phase_1 with work_type; integration gives integration. | `.agents/hooks/worktree-write-guard.sh:97-103` |
| Fail-closed exit trap | Denies on error only once `CONFINED=1` (set after the agent_type check). | `.agents/hooks/worktree-write-guard.sh:47-54`, `:70` |
| Hook wiring | Template group matcher `Bash\|Write\|Edit\|NotebookEdit`, timeout 10. Repo `.claude/settings.json` has the same group. | `.agents/hooks/claude-settings.template.json:60-69`; `.claude/settings.json:49-58` |
| codex-write-guard.sh | apply_patch adapter. Per patch path runs check-write.sh with `--only spec`, `tier-a`, `tier-b`. Worktree name comes from session_meta `agent_path`, must match `^s[0-9]+_[a-z0-9_]+$`, and confinement applies only when `.workflow/.worktrees/<name>` exists. | `.agents/hooks/codex-write-guard.sh:107-117`, `:134-157` |
| Codex spec.md status guard | An update patch that changes `status:` or `blocked_condition:` lines is denied. | `.agents/hooks/codex-write-guard.sh:126-131` |
| Codex fail closed | Unparsable payload, missing patch text, missing jq, or any unexpected failure gives a deny. | `.agents/hooks/codex-write-guard.sh:73-78`, `:86-88`, `:53-61` |
| check-worktree-scope.sh root | Named worktree if it exists; else top level of a linked-worktree cwd; else no confinement (allow). | `.agents/skills/feature-workflow/scripts/check-worktree-scope.sh:101-116` |
| check-worktree-scope.sh rules | Path: deny when inside main checkout but outside root. Command: allow read-only allowlist chains; otherwise require `cd <absolute path inside root> &&`. | `check-worktree-scope.sh:118-130`, `:204-225`, `:226-243` |
| Main root in check-worktree-scope | `dirname` of the git common dir, no worktree fallback. | `check-worktree-scope.sh:101-102` |
| Name builder | `wf_agent_worktree_name` returns status 1 on bad input. Spec folder check is `^[0-9]+-slug`, any digit count. | `.agents/lib/workflow-paths.sh:104`, `:122-124` |
| tests/hooks/worktree-guard.sh | Covers JRN-002/003/004/009, fail-closed case, CLI cases, Codex checks, template wiring and manifest checks. | `tests/hooks/worktree-guard.sh:2-13`, `:240-248`, `:250-255`, `:258-287`, `:290-296` |
| tests/scripts/install-upgrade.sh | JRN-011 to 013: matcher merge, including the worktree-write-guard group. | `tests/scripts/install-upgrade.sh:245-278`, `:283-` |
| tests/scripts/install-claude-settings.sh | Merge over user settings; every template hook command present; invalid JSON refused. Does not name the worktree group. | `tests/scripts/install-claude-settings.sh:56-70`, `:107-109` |
| Repo `.claude/settings.json` | Enables two plugins; allow list includes `Bash(yq --front-matter=extract:*)`; deny list has two entries. | `.claude/settings.json:3-6`, `:141`, `:156-159` |
| Template permissions | Allow list also has `initiative-transition.sh`; deny list also has `Edit(.workflow/initiatives/*/.step)`. | `.agents/hooks/claude-settings.template.json:130`, `:133`, `:146-150` |
| assetlist.md worktree row | Row has 7 cells in the 5-column Summary table (header at line 9). No Summary row for check-worktree-scope.sh; codex-write-guard.sh appears only in prose. | `assetlist.md:9`, `:47`, `:92`, `:124` |
| Ownership | hooks owns `.agents/hooks/**`; feature-workflow owns its skill folder; tests owns `tests/**`; installer owns `install.sh` and `install-manifest.txt`. No Ownership glob matches `assetlist.md` or `.claude/settings.json`. | `.workflow/rules.md:36-41`, `:85-93` |

## Seams and interfaces

| Interface | Shape (signature, type, contract) | Callers | Source |
| --- | --- | --- | --- |
| `check-worktree-scope.sh --cwd D [--worktree-name N] (--path P... \| --command C)` | Exit 0 allow (reason on stdout), exit 2 deny (reason on stderr), exit 1 usage or environment error. | worktree-write-guard.sh; codex-write-guard.sh | `check-worktree-scope.sh:8-16`, `:35`; `worktree-write-guard.sh:121-122`; `codex-write-guard.sh:136` |
| `resolve-launch.sh --parse-header --task-type T --prompt-file F` | Prints JSON header; hook reads `spec_dir`, `task_id`, `work_type`. Non-zero exit leaves the name unset. | worktree-write-guard.sh | `.agents/hooks/worktree-write-guard.sh:92-96` |
| `wf_agent_worktree_name SPEC_DIR task\|phase_1\|integration VALUE` | Prints the name without newline; status 1 on bad input. | worktree-write-guard.sh | `.agents/lib/workflow-paths.sh:122-124`; `worktree-write-guard.sh:104-105` |
| `check-write.sh --cwd --path --only spec\|tier-a\|tier-b [--agent] [--proposed]` | Exit 0 allow, 2 deny, other non-zero is a fail-closed error in the adapter. | codex-write-guard.sh | `codex-write-guard.sh:145-157` |
| Deny output | `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":...}}`, exit 0. Same shape in both adapters. | both hooks | `worktree-write-guard.sh:39-43`; `codex-write-guard.sh:46-51` |
| Claude sub-agent transcript | `<parent transcript without .jsonl>/subagents/agent-<agent_id>.jsonl`, or `agent_transcript_path` when given. | worktree-write-guard.sh | `worktree-write-guard.sh:80-82` |
| `check-worktree-scope.sh` CLI (two adapters) | Not sourceable: the body parses arguments and exits on load, so internals are tested only through the CLI, against a git repo with a linked or named worktree. A name with `/` or a leading `.` is exit 1. | `hooks/worktree-write-guard.sh`, `hooks/codex-write-guard.sh` | `check-worktree-scope.sh:8-16`, `:48-67`, `:35` |
| Confinement root resolution | Named dir under `$WF_WORKTREES` wins; else a linked-worktree cwd's top level; else empty. A named-but-missing worktree falls through silently. | internal | `check-worktree-scope.sh:104-112` |
| `read_only_chain COMMAND` | 0 when only `read_only_segment` reads joined by `\|` or `&&`; denials quote-blind today. | internal, `:222` | `check-worktree-scope.sh:202-220` |
| `read_only_segment` / `sed_print_only` | Per-tool allowlist and denylist; the sed check is the only quote-aware code. | internal | `check-worktree-scope.sh:138-200` |
| `WF_WORKTREES` | Sourced path constant from shared core `workflow-paths.sh`. | `check-worktree-scope.sh` | `check-worktree-scope.sh:42-43`, `:105` |
| git | `rev-parse --git-common-dir`, `--git-dir`, `--show-toplevel`; real temp repos in tests. | `check-worktree-scope.sh` | `check-worktree-scope.sh:101`, `:108`, `:110` |

## Prior decisions

| Decision or item | What it says | Source |
| --- | --- | --- |
| ADR-0001 (accepted) | Host-neutral core behind thin shims. `install.sh` ships only what the manifest lists. CI deferred; `tests/run-all.sh` run by hand is the gate. | `.workflow/decisions/adr/0001-project-baseline.md` § header line 2; § Deferred line 12 |
| Shared core | `.agents/lib/**` changes only through the integration agent, between batches. Affected: `workflow-paths.sh`. | `.workflow/rules.md` § Shared core, lines 99-109 |
| Cross-cutting policy | Scripts are bash. Body comments carry no decision IDs or doc/workflow paths. Adding under `.agents/` updates `PROVENANCE.md` and `install-manifest.txt` together. Nothing in `.agents/` depends on `tests/`. | `.workflow/rules.md` § Cross-cutting policy, lines 136-142 |
| Required versions | bash 3.2 (no bash 4 constructs); jq any; yq mikefarah v4 only. | `.workflow/rules.md` § Required versions, lines 153-155 |
| Shell-scripts profile, fail-closed line | "Guard hooks fail closed: on an unparsable payload or a helper error they print the host's deny JSON and exit 0." Conflicts with the Claude hook (see Not found). | `.workflow/profiles/shell-scripts.md` line 25 |
| Shell-scripts profile, checklist | Every error path reaches `die()` or the guard's deny output, except a silent exit the hook header documents. | `.workflow/profiles/shell-scripts.md` line 59 |
| Pitfall: `yq --front-matter=extract -i` | "Edit frontmatter with Edit or `yq --front-matter=process`, never `--front-matter=extract -i`." Source: `yq -i` rewrote two work-backlog items down to their frontmatter. Prevented by: none yet. Both settings files allow `Bash(yq --front-matter=extract:*)`. | `.workflow/decisions/pitfalls.md` lines 95-99; `.claude/settings.json:141`; template `:130` |
| Pitfall: worktree-guard placeholder | Guard suite filled `launched` placeholders with the agent worktree. Prevented by the `cd <agent worktree> &&` check. | `.workflow/decisions/pitfalls.md` lines 29-33 |
| Pitfall: Phase 1 worktree fork | Phase 1 `isolation: "worktree"` agents fork from main; the guard refuses their result file. Prevented by: none yet; text says it "needs `worktree.baseRef: head` in `.claude/settings.json`". No such key exists there or in the template. | `.workflow/decisions/pitfalls.md` lines 47-51 |
| Retrospective 006 | JRN-010 (live no-isolation Phase 1 or integration launch) not yet run; accepted, checked by next spec. F3, F4, F5 and disc-003, 005, 007 were started as spec 00010. Action item 3: lint that every `# shellcheck disable=` carries a reason (awaiting human). | `.workflow/decisions/retrospectives/006-result-file-guard.md` § Acceptance verdict lines 104-106; § Findings line 58; § Action items line 98 |
| Retrospective 006, disc-002 | Any digit count is valid in the lib and resolve-launch; new specs get 5-digit numbers. | `.workflow/decisions/retrospectives/006-result-file-guard.md` § Findings line 59; § Action items line 100 |
| CAP-007 | Sub-agents file their own result file; Phase 1 and integration run in orchestrator-made worktrees with no isolation, confined and audited by name. | `.workflow/capabilities.md:19` |
| CAP-008 | Read-only allowlisted commands pass the worktree guard without `cd`; writing flags and shell forms still need it. | `.workflow/capabilities.md:20` |
| assetlist.md D18 (amended by D85) | Hooks resolve paths from payload `cwd`; orchestrator creates worktrees at wave start instead of Claude `isolation`. | `assetlist.md:101` |
| assetlist.md D36 (amended 2026-10-21) | The repo's own `.claude/settings.json` wires the full template, not only block-destructive-git. | `assetlist.md:119` |
| Deferred: worktree-name-parser (match) | Hooks parse worktree names with their own regexes; the header-to-kind mapping is written twice (`worktree-write-guard.sh`, `post-implementation-audit.sh`). Shelved: spec 006 moved the builder to `workflow-paths.sh` and left the parsers out as a separate change. | `.workflow/deferred/worktree-name-parser.md` § Background; § Later requests |
| Deferred: main-checkout-resolver (partial match) | Every script and hook should use `wf_main_root`. `check-worktree-scope.sh:101-102` uses `dirname` with no fallback. Shelved: spec 005 moved only six scripts (D5). | `.workflow/deferred/main-checkout-resolver.md` § Background; § Evidence |
| Deferred: codex-spawn-profile-lookup (compared, no match) | Concerns `codex-pre-spawn.sh` profile lookup; not in the affected area. | `.workflow/deferred/codex-spawn-profile-lookup.md` |
| Deferred: session-start-timing-target (related constraint, no match) | "Hooks keep a 10 second timeout in the settings templates." The worktree group has timeout 10. | `.workflow/deferred/session-start-timing-target.md` § Constraints; template `:66` |
| Other shelf files (no match) | known-bad-evidence-path, concurrency-check-timing, bash-case-fallthrough, bash-line-coverage, comment-id-lint (related: body-comment lint, not built), harness-run-lint-target, per-task-scoped-runs, large-path-live-run, research-across-sessions, research-model-map, browser-suite, initiative-pr-template, spec-issue-creation, retrospective-template-drift, sign-off-scoped-commit, workflow-settings-home. | `.workflow/deferred/*.md` (archive excluded) |
| ADR search | No ADR, rule or pitfall other than the entries above names the worktree guard, `check-worktree-scope.sh` or the hook matcher. | `.workflow/decisions/adr/`, `pitfalls.md`, `retrospectives/`, `rules.md` |

## Library options

## Library options: worktree-guard follow-ups (spec 00010)

Concerns: (1) quote-aware `$` check for read-only shell commands; (2) permission-rule narrowing for `yq --front-matter=extract`. Settled by rules: jq (rules.md:154), yq mikefarah v4 (rules.md:155), bash 3.2 (rules.md:153), shellcheck lint-only (rules.md:156), test harness (homegrown bash, AGENTS.md). The `External systems` heading (rules.md:149) is empty, so no hosted API is in scope. No package manifest or lockfile exists. The agent had no shell tool, so installed binary versions are unverified.

### Already in the project

- yq (mikefarah v4, required): evidence-capture.sh:192, session-start-resume.sh:97, check-worktree-scope.sh:30 (denylist). Covers front-matter read and `-i`.
- jq (required): hooks/worktree-write-guard.sh:41,66; hooks/codex-write-guard.sh:48. Covers JSON parsing in hooks.
- Shell check, in-house: check-worktree-scope.sh:204-220 (`read_only_chain`). Line 208 denies any `$` in the whole command, quoted or not; not quote-aware. Header lines 32-34 say "a regex check, not a shell parser". Bash 3.2 regexes already in use at lines 138-176.

### Shell-command `$` check (quote-aware)

Verdict: Use existing (extend the in-house scanner in check-worktree-scope.sh:204-220 to skip single-quoted text); Reject mvdan.cc/sh/v3 for this concern (a new Go runtime for a deny-only guard).
Deprecation check: none found. Searched "mvdan sh deprecated 2026 sunset" and "mvdan sh breaking changes migration v3"; results were unrelated. deps.dev isDeprecated=false; repo not archived.

| Option | Fit | Licence | Maintenance | Security | Cost |
| --- | --- | --- | --- | --- | --- |
| in-house scanner (incumbent, extend) | pass: bash 3.2, no new runtime; needs a scanner plus tests | pass: first-party | pass: in-tree | pass: no third-party code; risk is scanner bugs, covered by tests/hooks/worktree-guard.sh | pass: estimate 1-2 days |
| mvdan.cc/sh/v3@v3.14.1 (new) | caution: parses POSIX, Bash, Zsh, mksh; but needs Go 1.26 and rules.md does not list Go | pass: BSD-3-Clause | pass: v3.14.1 published 2026-09-06; not archived; 75 open issues | caution: no GitHub advisories; Scorecard 4.7 overall, Code-Review 0; Vulnerabilities check not returned | fail: new required runtime plus install.sh checks; estimate 3+ days |

No third candidate: a Python parser would add a runtime rules.md does not list.

Evidence:
- official docs: https://github.com/mvdan/sh (README "Requires Go 1.26 or later")
- registry: https://api.deps.dev/v3/systems/go/packages/mvdan.cc%2Fsh%2Fv3/versions/v3.14.1
- scorecard: https://api.securityscorecards.dev/projects/github.com/mvdan/sh
- advisories: https://github.com/mvdan/sh/security/advisories
- local incumbent: check-worktree-scope.sh:204-220

Risks: the in-house scanner can miss shell forms; the guard is accident prevention only (header line 22). Would change the verdict if the team accepts Go 1.26 as a required version, or if the scanner cannot be made correct in bash 3.2 without a parser.
Unverified: Scorecard Vulnerabilities for mvdan; OSV not queried (POST-only API); the effort estimates.

### Permission rule for `yq --front-matter=extract` (host config, not a library)

Verdict: Trial deny rules for the write forms (`-i`, `--inplace`) plus a PreToolUse check for main-session Bash; do not keep the allow entry unchanged. An allow pattern cannot exclude a trailing flag, so narrowing the allow alone does not help.
Deprecation check: not applicable; the Claude Code permission syntax has no deprecation notice on the official page.

| Option | Fit | Licence | Maintenance | Security | Cost |
| --- | --- | --- | --- | --- | --- |
| keep `Bash(yq --front-matter=extract:*)` (.claude/settings.json:141; claude-settings.template.json:130) | fail: `:*` is a trailing wildcard, so `yq --front-matter=extract -i f` is auto-allowed; a real body loss happened (pitfalls.md:95-96) | n/a | n/a | n/a | pass: no change |
| narrow allow to fixed argument shapes | caution: fixes leading args only; a trailing `-i` still matches | n/a | n/a | n/a | pass: small |
| deny rules for `-i` / `--inplace` forms | caution: textual; docs say deny covers the form Claude usually writes, not every form, so enumerate flag positions | n/a | n/a | n/a | pass: small; test each form |
| PreToolUse hook on main-session Bash for yq `-i` | pass: docs say hooks can inspect the full command text; worktree-write-guard.sh:9-10 covers sub-agents only | n/a | n/a | n/a | caution: estimate ~1 day |

Evidence:
- official docs: https://code.claude.com/docs/en/permissions (`:*` equals a trailing `*`; compound-command matching; deny covers the usual form only; yq is not in the read-only list)
- official docs: https://mikefarah.gitbook.io/yq/ (quick usage `yq -i '.a.b[0].c = "cool"' file.yaml`; no warning about `-i`)
- official docs: https://mikefarah.gitbook.io/yq/usage/front-matter.md (extract "will only output the yaml contents"; process writes the whole file; `-i` not described)
- local: .workflow/decisions/pitfalls.md:95-96; .workflow/decisions/retrospectives/004-scoped-test-runs.md:66

Risks: each deny form must be checked against the installed Claude Code version; the docs say a deny rule is not a security boundary. A third-party guide and GitHub issue 29616 report wildcard rules prompting anyway (older behaviour possible).
Unverified: the installed Claude Code version; the body-loss incident was not reproduced on yq v4.54.1.

### YAML front-matter tool (yq, settled by rules)

Verdict: Use existing (mikefarah yq v4, rules.md:155). Not an adoption.
Deprecation check: none found.

| Option | Fit | Licence | Maintenance | Security | Cost |
| --- | --- | --- | --- | --- | --- |
| yq v4.54.1 (incumbent) | pass: front-matter extract/process and `-i` documented | pass: MIT (deps.dev) | pass: v4.54.1 published 2026-09-29 | pass: no GitHub advisories; Scorecard 7.7 (2026-10-27) | pass: no change; installed version unverified |

Evidence:
- registry: https://api.deps.dev/v3/systems/go/packages/github.com%2Fmikefarah%2Fyq%2Fv4/versions/v4.54.1
- scorecard: https://api.securityscorecards.dev/projects/github.com/mikefarah/yq
- advisories: https://github.com/mikefarah/yq/security/advisories
- releases: https://github.com/mikefarah/yq/releases
- official docs: https://mikefarah.gitbook.io/yq/usage/front-matter.md

Overall: no Hold.

## Module audit

Owning module: feature-workflow (change lands in `.agents/skills/feature-workflow/scripts/check-worktree-scope.sh`)

| Kind | Finding | Source |
| --- | --- | --- |
| reuse | Boolean flags follow `--x) VAR=1; shift ;;`; unknown arguments reach `usage_err` (exit 1), so an adapter denies if `--confined` reaches an older script. | `run-toolchain.sh:118-120`, `budget-check.sh:119`, `task-waves.sh:66`; `check-worktree-scope.sh:46`, `:57` |
| reuse | Quote-aware tokenising exists in `sed_print_only` (`re_word`: `'...'`, `"..."` without backslash, or an unquoted run), consumed through `BASH_REMATCH`. No character-by-character loop exists in the module's scripts. | `check-worktree-scope.sh:142`, `:148-153` |
| reuse | Bash 3.2 consume-a-prefix loop on parameter expansion. | `check-worktree-scope.sh:75-83`, `:215-219` |
| reuse | One case-glob does the whole-command denials; the scanner sits next to it or replaces its `$` and backtick arms. | `check-worktree-scope.sh:208` |
| reuse | Module docs already say "agent worktree" for Phase 1 and integration worktrees. | `modules/verification-setup.md:45`, `:63`, `:136`; `modules/implementation-orchestrator.md:13`, `:29` |
| gap | `--confined` has no state or arm; the no-root branch always prints `allow:` and exits 0. | `check-worktree-scope.sh:48-59`, `:113-116` |
| gap | The not-a-git-repo exit (allow, exit 0) runs before any root lookup. | `check-worktree-scope.sh:101` |
| gap | An error from `git rev-parse --git-dir` is swallowed (`\|\| true`) and read as "not a linked worktree". | `check-worktree-scope.sh:108` |
| gap | `deny_cmd` builds its message around `$root`; no deny helper exists for an empty root. | `check-worktree-scope.sh:233-236`, `:125` |
| gap | `\|`/`&&` splitting and the `;`/`\|\|` checks are quote-blind; a per-segment scanner would see `grep 'a\|b' f` as an unterminated quote, a whole-command scanner would not. | `check-worktree-scope.sh:208-219`, `:34` |
| gap | No module doc says what the guard does when the named worktree is missing. | `modules/implementation-orchestrator.md:29`; `modules/verification-setup.md:53` |
| gap | `--worktree-name` usage text lists only `s<NNN>_t<N>` and Codex `task_name`, not the Phase 1 and integration shapes. | `check-worktree-scope.sh:10` |
| constraint | Decision order: no-git allow (101), root lookup (104-116), path rules (118-130), cwd-inside-root or outside-main allow (132-136), read-only allow (222), `cd` rule (226-243). A `--confined` deny at the no-root branch comes before the outside-main and read-only allows. | `check-worktree-scope.sh:101-136`, `:222-225` |
| constraint | Exit contract: 0 allow (stdout), 2 deny (stderr), 1 usage/environment error. | `check-worktree-scope.sh:35`, `:46`, `:125-126`, `:234-235` |
| constraint | Deny messages start with `worktree guard:`. | `check-worktree-scope.sh:125`, `:234` |
| constraint | `--help` prints the header (lines 2 to `set -euo`): Usage (8-12), rule 3 (16), the sed `$` note (28) and "a regex check, not a shell parser" (32-34) go stale with this change. | `check-worktree-scope.sh:56`, `:8-34` |
| constraint | Once single-quoted `$` passes, `sed -n '$p' f` reaches `sed_print_only`, whose address regex accepts `$`. | `check-worktree-scope.sh:145`, `:28` |
| constraint | Today `\` outside quotes is denied only inside sed words (`grep "a\.b"` passes); the whole-command `\` rule tightens this. | `check-worktree-scope.sh:142`, `:191` |
| constraint | Every loop must consume input each pass (a recorded hang); the hook has a 10 s timeout, so a per-character loop runs after the cheap whole-command denials. | `check-worktree-scope.sh:213-214`, `:208` |
| constraint | The `&&` rewrite precedes the lone-`&` check; process substitution is caught by `<`. | `check-worktree-scope.sh:207`, `:210-212` |
| constraint | The `cd` target check keeps its own `$`, backtick and `~` denial. | `check-worktree-scope.sh:238` |
| constraint | Bash 3.2, `set -euo pipefail`; comments carry no decision IDs or paths. | `check-worktree-scope.sh:38`, `:40`; `references/readable-code.md` |
| constraint | "Task worktree" text: header lines 2 and 4, messages at 114, 125 (also "other tasks' worktrees") and 234. | `check-worktree-scope.sh:2`, `:4`, `:114`, `:125`, `:234` |

History: the last three commits to the script (`9e56a79`, `2bf4cc8`, `d612b9d`, spec 006 T4) changed the read-only chain or sed allowlist, each with additions to `tests/hooks/worktree-guard.sh`.

## Not found

- Worktree guard in the flows cache: searched `.workflow/cache/flows.md`. No section for `worktree-write-guard.sh` or `check-worktree-scope.sh`. Reported by retrieval.
- Hook file inventory: `.workflow/cache/modules.md` § `.agents/hooks` Files lists 16 hook files; a glob of `.agents/hooks/*` also finds `claude-settings.template.json`, `claude-settings.template.md`, `codex-config.template.toml`, `codex-hooks.template.json` and `context-bridge.cjs`. Reported by retrieval as "cache disagrees with code"; resolved: Files is generated from the bash graph extractor's source files (`.agents/agents/cache-regeneration.md:56`), so templates and the `.cjs` file are out of it by design. The cache was regenerated at `581e785` for this spec; not a stamp problem.
- Fail-closed claim, shell-scripts profile vs Claude hook: `shell-scripts.md:25` says guard hooks print deny JSON on an unparsable payload. `worktree-write-guard.sh:65` exits 0 silently on an unparsable payload; the test asserts allow (`tests/hooks/worktree-guard.sh:241-242`). The Codex guard denies the same case (`codex-write-guard.sh:78`). Reported by retrieval.
- Spec folder digit rule: `worktree-write-guard.sh:21-22` names "a spec folder number under three digits" as a case the lib rejects; `.agents/lib/workflow-paths.sh:104` accepts any digit count. Reported by retrieval.
- Pitfall "Prevented by" for the Phase 1 fork names `worktree.baseRef: head` in `.claude/settings.json`; the key appears only in `pitfalls.md:51`. Reported by retrieval.
- Repo vs template: `.claude/settings.json` omits the template's `initiative-transition.sh` allow and `Edit(.workflow/initiatives/*/.step)` deny, and adds `enabledPlugins`. Reported by retrieval.
- `assetlist.md`: no Summary row for `check-worktree-scope.sh`; `codex-write-guard.sh` is named only in prose (`:92`, `:124`). Reported by retrieval.
- `.claude/settings.json` and `assetlist.md` have no Ownership glob (searched `.workflow/rules.md` lines 32-97). Reported by retrieval.
- Test coverage of repo `.claude/settings.json` for the worktree group: only `tests/lint/symlinks.sh:44` and `tests/hooks/audit-agent-worktrees.sh:123-129` read it; neither checks the worktree group. Reported by retrieval.
- A character-by-character quote scanner or shared quote helper in feature-workflow scripts: only `re_word` at `check-worktree-scope.sh:142`. Reported by module-audit.
- An existing `--confined` or fail-when-unconfined mode in `.agents/skills/feature-workflow/**`. Reported by module-audit.
- Module docs on the guard when the named worktree is missing: `SKILL.md`, `modules/`, `references/`, `assets/`. Reported by module-audit.
- Cache disagrees with code: none for `check-worktree-scope.sh`. Reported by module-audit.
