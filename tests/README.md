# Tests

Scaffold-only. This folder tests the scripts and hooks in `.agents/`, the root `install.sh` and `scripts/upstream-diff.sh`, and lints `upstream-lineage.json`, the `.claude/` shim and `PLAN/decision-flow*`. It is not part of the install payload: `install.sh` copies only what `.agents/install-manifest.txt` lists and leaves out `tests/`, like `PLAN/`, `assetlist.md`, `checklist.md`, `upstream-lineage.json`, `wayfinder-comparison.html`, `testprompt.md` and the scaffold repo's own `.workflow/` (D30). Nothing in `.agents/` may depend on it.

## Requirements

- bash 3.2 or newer (macOS default is fine; no bash 4 features are used)
- git
- jq
- [mikefarah yq](https://github.com/mikefarah/yq) v4 (not the Python `yq`)
- shellcheck

`run-all.sh` checks these first and exits 2 with an install hint if one is missing. A suite run directly skips its shellcheck assertion when shellcheck is absent and reports it as `skip`.

## Run

```sh
tests/run-all.sh                       # every suite, then a summary; exit 1 if any suite failed
tests/run-all.sh --suite pre-launch    # one suite (name without .sh; --list shows them)
tests/run-all.sh -v                    # stream full output instead of failures only
bash tests/hooks/write-guards.sh       # a suite directly
TEST_BASH=/bin/bash tests/run-all.sh --suite status-transition-check-write   # run the scripts under another bash
```

The status-transition suite makes many `yq` calls and takes a few minutes; the rest take under a minute each.

## CI

The runner is CI-agnostic: install the requirements above, run `tests/run-all.sh`, and treat a non-zero exit as failure. The last line of each suite is `RESULT passed=N failed=M skipped=K xfail=X`, which `run-all.sh` totals.

## Layout

| Path | Purpose |
|---|---|
| `lib/common.sh` | Shared helpers: tool preflight (bash, git, jq, yq v4), scratch dir (`new_workdir`), fixture builders (`copy_agents`, `make_fixture_repo`, `git_init_repo`), assertions (`t`, `eq`, `check`, `xfail`, `finish`), `shellcheck_files` |
| `scripts/*.sh` | One suite per shared script |
| `lint/*.sh` | Static checks over the repo itself (frontmatter, step list, symlinks, upstream lineage); read-only, never writing to the repo (step-list and upstream-lineage use a scratch dir from `new_workdir`) |
| `hooks/*.sh` | One suite per hook (the three write guards share a suite; so do the audit, sync and resume hooks, which share one fixture) |
| `run-all.sh` | Runs everything or one suite |
| `.shellcheckrc` | Lets `shellcheck tests/**/*.sh` follow `source` lines |

| Suite | Component |
|---|---|
| `scripts/status-transition-check-write` | `status-transition.sh`, `check-write.sh`, `budget-check.sh` (PR/MR file set, test exclusion) |
| `scripts/resolve-launch` | `resolve-launch.sh` |
| `scripts/step-progress` | `step-progress.sh` (the D84 progress line: full and light totals, run-order positions, loop steps, 00.x with `--at`, intake, unknown ids, `--spec-dir` defaults) |
| `scripts/run-toolchain` | `run-toolchain.sh` |
| `scripts/task-breakdown` | Task-breakdown helpers: `task-waves.sh` (overlaps, implied edges, `parallel_with`, cycles, waves, JSON), `rules-setting.sh` (`task_review`, `main_branch`), `open-task-pr.sh` (gh/glab stubs, no network) and `run-toolchain.sh` test scoping (`tests`, `test_scoped`, `--exclude-unfinished`, `unscoped`) |
| `scripts/cache-scripts` | `publish-cache.sh`, `cache-stamp-check.sh` |
| `scripts/generate-boundary-config` | `generate-boundary-config.sh` |
| `scripts/generate-codex-agents` | `hooks/generate-codex-agents.sh` |
| `scripts/install` | `install.sh` at the repo root (payload from `install-manifest.txt`, VERSION stamp, Claude and Codex shims, settings and config merges, `.gitignore`, refusals, `--dry-run`); runs against a copy of the scaffold inside the fixture |
| `scripts/build-architecture` | regenerate-caches `build-architecture.sh`, `check-staged-cache.sh` (dependency-cruiser and tsc output are fixtures; no node needed) |
| `scripts/upstream-diff` | `scripts/upstream-diff.sh` at the repo root (scaffold-only lineage diff): arguments, entry selection, `unknown`-commit skip, and a diff run against local `file://` upstreams; no network |
| `hooks/pre-launch` | `pre-launch.sh` |
| `hooks/audit-sync-resume` | `post-implementation-audit.sh`, `rules-boundary-config-sync.sh`, `session-start-resume.sh` |
| `hooks/block-destructive-git` | `block-destructive-git.sh` (blocked and allowed git forms, nested and wrapped commands, heredoc and quoted text not matched, Codex argv payload, fail closed without awk) |
| `hooks/evidence-capture` | `evidence-capture.sh` (Playwright JSON report → `artifacts/` evidence) |
| `hooks/write-guards` | `spec-single-writer-guard.sh`, `tier-a-write-guard.sh`, `tier-b-write-guard.sh`, `_guard-common.sh` |
| `hooks/worktree-guard` | `worktree-write-guard.sh`, the worktree check in `codex-write-guard.sh` and `check-worktree-scope.sh` (D85: task sub-agents confined to `.workflow/.worktrees/s<NNN>_t<N>` or their isolation worktree; Bash needs a leading `cd <worktree> &&`; main session unaffected) |
| `hooks/codex-adapters` | Codex adapters: `_codex-patch.sh` (apply_patch parser), `codex-write-guard.sh`, `codex-pre-spawn.sh`, `codex-rules-sync.sh` and their template wiring |
| `hooks/codex-shim` | Codex path of `post-implementation-audit.sh`, `codex-hooks.template.json`, `codex-config.template.toml` (live `codex sandbox` check when codex is installed, skipped otherwise) |
| `lint/frontmatter` | `.agents/skills/*/SKILL.md` and `.agents/agents/*.md` frontmatter (parses with yq; `name` matches folder or file; `description`; agents have no `model:` (D35) and only `claude`/`codex` under `models:`; `disable-model-invocation` only on stubs or the listed user-invoked skills (which also need a Codex `agents/openai.yaml` policy), STUB markers consistent with `PROVENANCE.md`; none exist today) |
| `lint/step-list` | `feature-workflow/references/steps.tsv` against the decision-flow reference and mermaid (same node ids, same ids per phase), the agreed per-phase counts, and every step id used by `status-transition.sh`, `check-write.sh` and the skills (D84) |
| `lint/symlinks` | `.claude/{skills,agents,output-styles}` symlinks into `.agents/`, no `.claude/commands`, every hook command in `.claude/settings.json` and both hook templates names an executable `.agents/hooks/` script |
| `lint/upstream-lineage` | `upstream-lineage.json` (schema per kind, enums, paths exist outside the vendored copies, no duplicates) and coverage: every upstream a first-party `Sources:` / `Adapted from` / `Copied from` line names has an entry, and no such line points at a missing `.agents/skills/<name>/` directory |

## Conventions

- Every suite sources `lib/common.sh`, calls `preflight`, and ends with `finish`.
- Fixtures live in a `mktemp` directory removed on exit. In the scripts and hooks suites, components under test are read from a copy of this repo's `.agents/` inside the fixture; lint suites read the repo directly and only read it. A test run never writes to the repo. No absolute or home paths.
- Paths are relative to the repo root (found from the suite's own location) or to the temp dir.
- An `xfail` records a known script defect. It does not fail the run, and it fails the run once the script is fixed, so the test gets updated. There are no current xfails.
- Keep every file shellcheck clean (`shellcheck tests/lib/*.sh tests/scripts/*.sh tests/hooks/*.sh tests/lint/*.sh tests/run-all.sh`).
