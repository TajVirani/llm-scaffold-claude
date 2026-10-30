# Verification plan: Sub-agents can write their own result file

Spec: [spec.md](spec.md)

## End state

- [ ] CAP-007: `wf_` encoder and name builder in `.agents/lib/workflow-paths.sh` give byte-identical names to the old `codex_enc` for every work type and agent type used today, under a UTF-8 and a C locale; neither hook keeps a `codex_enc` copy.
- [ ] CAP-007: for an implementation sub-agent whose header has `work_type` and no `task_id`, and for an integration sub-agent, `worktree-write-guard.sh` confines to `.workflow/.worktrees/s<NNN>_phase_1_<enc>` / `s<NNN>_integration_<enc>`: a Write inside it is allowed, a Write to the main checkout or another agent worktree is denied.
- [ ] CAP-007: the exact result-file command each of `implementation.md` (Phase 1 and Phase 3) and `integration.md` prescribes, with the agent's cwd in the main checkout, is allowed by the guard and leaves the file at `<main checkout>/<spec_dir>/artifacts/<id>/`, which `check-task-result.sh` accepts.
- [ ] CAP-007: the stop audit, for a Claude Phase 1 or integration launch, runs in its agent worktree (integration with the full toolchain, Phase 1 with `--skip test`), and warns and allows when the worktree is missing; the SubagentStop matcher in the template and this repo's settings covers integration, and an `install.sh` upgrade leaves exactly one SubagentStop entry.
- [ ] CAP-007: the artifacts gate script exits 0 for a branch or commit with no change under `<spec_dir>/artifacts/` since the merge-base, and refuses (non-zero, reason naming each path) an add, a modify and a delete there; committed `artifacts/` already on the spec branch do not trip it.
- [ ] CAP-007: `verification-setup.md` and `implementation-orchestrator.md` contain no `isolation: "worktree"` launch and no isolation fallback; they create Phase 1 and integration agent worktrees with `-b wf/NNN-slug/<name> spec/NNN-slug`, merge that branch, remove worktree and branch after merge, and call the gate before each of the five merge sites.
- [ ] CAP-007: on an `install.sh` upgrade, every existing hook group that runs a template command under a matcher not covering the template's is resolved per D19-D29: `--matchers=merge|replace|keep` gives the merged, template or unchanged matcher with one group per command; without a terminal a template-only group is merged and a mixed group kept, each with a Warnings line; at a terminal the prompt shows current, replace and merge (and every hook in a mixed group) and Enter merges; match-all groups and covered matchers are untouched, so a re-run changes nothing; `--dry-run` previews and never reads input; `--force` leaves matchers alone; the four docs describe the rule.
- [ ] CAP-008: with cwd in the main checkout and a confinement root, `check-worktree-scope.sh --command` allows each allowlisted read and `|`/`&&` chains of them, and denies each per-tool writing flag and each shell form listed in the spec's success line; every existing allow and deny case in `tests/hooks/worktree-guard.sh` keeps its verdict.
- [ ] `tests/run-all.sh` passes and shellcheck is clean on every changed shell file.

## Journeys

The scaffold has no running application or browser suite. Each journey runs the real scripts and hooks against a fixture repo, checked by a harness suite under `tests/`.

| Id | Journey | Proves | Steps | Expected outcome | Check |
| --- | --- | --- | --- | --- | --- |
| JRN-001 | Names agree across hosts | CAP-007 | 1. Call the lib encoder and builder for work types and agent types (`shell-scripts`, `test-harness`, `Web.UI`, `fact-lookup`) under `LC_ALL=C` and a UTF-8 locale. 2. Compare with the recorded `codex_enc` output. | Identical bytes; malformed spec folders return status 1. | `tests/scripts/lib-workflow-paths.sh` (JRN-001 cases) |
| JRN-002 | Phase 1 agent files its result | CAP-007 | 1. Fixture repo with spec `007-demo`, worktree `.workflow/.worktrees/s007_phase_1_shell_scripts`. 2. Feed the guard a Phase 1 implementation sub-agent payload (cwd main checkout) running the brief's result-file command, then a Write inside, a Write to the main checkout, a Write to another worktree. 3. Run the command for real and `check-task-result.sh` on the file. | Command and inside Write allowed; outside Writes denied; the file exists in the main checkout and passes the checker. | `tests/hooks/worktree-guard.sh` (JRN-002 cases) |
| JRN-003 | Integration agent files its result | CAP-007 | Same as JRN-002 with `s007_integration_shell_scripts` and an integration header. | Same verdicts; `integration.yaml` passes the checker. | `tests/hooks/worktree-guard.sh` (JRN-003 cases) |
| JRN-004 | Phase 3 result lands in the main checkout | CAP-007 | 1. Phase 3 payload for `s007_t3`. 2. Run the brief's command. | Allowed; file in the main checkout, none in the worktree copy. | `tests/hooks/worktree-guard.sh` (JRN-004 cases) |
| JRN-005 | Stop audit finds the agent worktree | CAP-007 | 1. SubagentStop payloads for a Claude Phase 1 and an integration launch, worktree present and absent. 2. Run `post-implementation-audit.sh` with a stand-in toolchain. | Present: toolchain runs in the worktree (Phase 1 with `--skip test`); absent: warn and allow. | `tests/hooks/audit-sync-resume.sh` or a new audit suite (JRN-005 cases) |
| JRN-006 | Settings matcher upgrade | CAP-007 | 1. Target project installed with the old template. 2. Run `install.sh` again. | One SubagentStop entry, matching implementation and integration. | `tests/scripts/install-claude-settings.sh`, `install-upgrade.sh` (JRN-006 cases) |
| JRN-007 | Artifacts merge gate | CAP-007 | 1. Fixture spec branch with committed `artifacts/T1/implementation.yaml`. 2. Task branches that: change only code; add, modify and delete a file under `artifacts/`. 3. A detached light-path commit of each kind. 4. Run the gate on each. | Code-only passes; every artifacts change is refused with its path; the pre-existing committed file does not trip it. | new `tests/scripts/<gate-script>.sh` (JRN-007 cases) |
| JRN-008 | Orchestrator text matches the design | CAP-007 | 1. Grep `verification-setup.md`, `implementation-orchestrator.md`, `implementation.md`, `integration.md`. | No `isolation: "worktree"` launch or fallback; `-b wf/NNN-slug/` creation for Phase 1 and integration; gate call before each merge; absolute main-checkout result path in both briefs. | `tests/lint/` or a harness grep suite (JRN-008 cases) |
| JRN-009 | Read-only commands pass, writes do not | CAP-008 | 1. Confined payload, cwd main checkout. 2. Commands: each allowlisted read; `cat f \| head`; `grep x f && wc -l f`; each denied flag (`sed -i`, `sed -n 'w out'`, `find . -delete`, `find . -fprint x`, `yq -i`, `git diff --output=x`, `rg --pre cmd`); each shell form (`$(…)`, backtick, `<(`, `>`, `;`, `&`, `\|\|`, newline, `tee`). | Reads allowed; every flag and shell-form case denied with the `cd <worktree> &&` hint; existing cases unchanged. | `tests/hooks/worktree-guard.sh` (JRN-009 cases) |
| JRN-010 | A real launch files its own result | CAP-007 | 1. In the next spec that runs Phase 1 or a Phase 3 wave with integration, launch through the new steps. | Each result file is in the main checkout without a copy step; the design log records no hand copy. | Manual at 5.x of this spec's dogfood run, or the next spec's first wave (evidence under `artifacts/`) |
| JRN-011 | Upgrade resolves matchers without a terminal | CAP-007 | 1. Target installed with the old template, plus user groups: a mixed SubagentStop group (stop audit plus a user hook), a match-all group, a plain-alternation group already covering the template. 2. Run `install.sh` again with stdin not a terminal. 3. Run it a third time. | Template-only stop-audit group merged to cover `implementation` and `integration`, one SubagentStop entry for it; mixed group kept; match-all and covered groups untouched; a Warnings line per merged or kept group; the third run writes nothing. | `tests/scripts/install-upgrade.sh` (JRN-011 cases) |
| JRN-012 | `--matchers` answers every group | CAP-007 | 1. Same old target with a user matcher `implementation\|foo`. 2. Run with `--matchers=merge`, `--matchers=replace`, `--matchers=keep`, `--matchers=bogus`, and `--dry-run` with and without `--matchers`. | merge gives `implementation\|foo\|integration`; replace gives the template's; keep leaves it and warns; bogus exits 2; dry-run writes nothing, previews the outcome and never reads stdin; `--force` alone leaves matchers as the no-terminal rule sets them. A non-plain matcher (`(a\|b)c`) is never merged. | `tests/scripts/install-upgrade.sh` (JRN-012 cases) |
| JRN-013 | Terminal prompt | CAP-007 | 1. Same old target, run under a pseudo-terminal. 2. Answer Enter, `r`, `k`; for a mixed group check the prompt text. | The prompt names the event and command and shows current, replace and merge lines (and every hook for a mixed group); Enter merges, `r` replaces, `k` keeps. | `tests/scripts/install-upgrade.sh` (JRN-013 cases; skipped where no pseudo-terminal tool exists) |
| JRN-014 | Docs describe the rule | CAP-007 | 1. Grep the `install.sh` header and `--help`, README "Install and upgrade", `claude-settings.template.md` Merge rules and CHANGELOG 2.0.0 Migration. | Each names the matcher rule; `--help` lists `--matchers`; the Merge rules no longer say a group is skipped whatever its matcher. | `tests/lint/install-matcher-docs.sh` (JRN-014 cases) |

## Fixtures and oracles

| Fixture or oracle | What it provides | Source | Used by |
| --- | --- | --- | --- |
| Worktree-guard fixture repo | Git repo with `.agents/` copy, spec `007-demo`, agent worktrees `s007_t3`, `s007_t4`, `s007_phase_1_shell_scripts`, `s007_integration_shell_scripts`, sub-agent transcripts with launch headers | Extends `make_fixture_repo` and `mk_sub` in `tests/hooks/worktree-guard.sh` | JRN-002 to JRN-004, JRN-009 |
| Recorded `codex_enc` outputs | Expected names for the JRN-001 inputs | Run the old `codex_enc` at `baseline_revision` before Phase 3 | JRN-001 |
| Brief commands | The exact result-file command lines from `implementation.md` and `integration.md` | Extracted from the agent docs at test time, so a brief change re-tests | JRN-002 to JRN-004 |
| Toolchain stand-in | A `run-toolchain.sh` substitute that records its cwd and flags | Harness-written, as in the existing audit suites | JRN-005 |
| Old settings template | The pre-change `claude-settings.template.json` | `git show <baseline_revision>:.agents/hooks/claude-settings.template.json` | JRN-006 |
| Gate branches | Spec branch plus task branches and detached commits with each `artifacts/` change kind | Harness-written fixture repo | JRN-007 |
| Upgrade target with user groups | Old-template install plus a mixed stop-audit group, a match-all group, a covering group and an `implementation\|foo` matcher | Harness-written in `tests/scripts/install-upgrade.sh` from `tests/fixtures/claude-settings.sh` | JRN-011, JRN-012, JRN-013 |
| Pseudo-terminal | A terminal on stdin and stdout for the prompt | `script(1)` (`script -q /dev/null` on macOS, `script -qec` on Linux); the cases `skip` when neither works | JRN-013 |

## Targets

<!-- 1.1. Measured by review-targets (4.3); reported in report.md "Targets vs measured". -->

Run every command in bash from the repo root on a clean checkout of the feature's HEAD. Measured at the baseline `e049f4d`: guard-time 0.04 s; codex-enc-copies 6.

| Target | Kind | Threshold | How measured (exact command) | Source of the threshold |
| --- | --- | --- | --- | --- |
| Script lint clean | errors | exit 0; 0 shellcheck findings | the `script-lint` command below (the `lint` key of the shell-scripts profile) | `.workflow/profiles/shell-scripts.md` § Toolchain |
| Harness lint clean | errors | exit 0; 0 shellcheck findings | the `harness-lint` command below (the `lint` key of the test-harness profile) | `.workflow/profiles/test-harness.md` § Toolchain |
| Agent-docs lint clean | errors | exit 0; each of the four lint suites reports 0 failed | the `agent-docs-lint` command below (the `lint` key of the agent-docs profile) | `.workflow/profiles/agent-docs.md` § Toolchain |
| Every script this spec adds or changes has a suite | coverage | `0` printed (no uncovered script) | the `script-coverage` command below: scripts under `.agents/` and `install.sh` added or modified since `baseline_revision` whose file name no file under `tests/` mentions | `.workflow/profiles/test-harness.md` § Mini-review checklist ("A new or changed script has a suite ending in a `shellcheck_files` assertion") |
| Every new `.agents/` asset is in the manifest and `PROVENANCE.md` | coverage | `0` printed (no unlisted asset) | the `asset-coverage` command below: files added under `.agents/` since `baseline_revision` that are not a line of `.agents/install-manifest.txt` (or under a listed directory) or not named in `PROVENANCE.md` | `.workflow/rules.md` § Cross-cutting policy (manifest, PROVENANCE) |
| No `codex_enc` copy left in the hooks | errors | `0` printed | the `codex-enc-copies` command below: lines under `.agents/hooks/` that mention `codex_enc` | `spec.md` Constraints ("`wf_` functions ... replace both `codex_enc` copies") |
| Worktree scope check time on a long read-only chain | performance | real ≤ 0.2 s, best of 3 | the `guard-time` command below: `check-worktree-scope.sh --command` with a confinement root and the cwd in the main checkout, on a chain of every allowlisted read joined by `\|` and `&&` | stakeholder decision D16, 1.1 (2026-10-29) |
| Line coverage of changed shell code | coverage | not measured | Cannot be measured: no bash coverage tool is installed and `spec.md` Constraints ban new dependencies. The script-coverage target and the test-harness checklist at 3.7 stand in. | stakeholder decision D17, 1.1 (2026-10-29) |

Commands referenced above (pipes keep them out of the table cells); each runs from the project root:

```bash
# script-lint
git ls-files -z -co --exclude-standard -- '.agents/hooks/*.sh' '.agents/lib/*.sh' '.agents/skills/*/scripts/*.sh' install.sh 'scripts/*.sh' | xargs -0 shellcheck -x -P SCRIPTDIR
# harness-lint
git ls-files -z -co --exclude-standard -- 'tests/*.sh' | xargs -0 shellcheck -x -P SCRIPTDIR
# agent-docs-lint
tests/run-all.sh --suite lint/frontmatter && tests/run-all.sh --suite lint/step-list && tests/run-all.sh --suite lint/symlinks && tests/run-all.sh --suite lint/upstream-lineage
# script-coverage: prints the count of uncovered scripts; the threshold is 0
git diff --name-only --diff-filter=AM "$(yq --front-matter=extract '.baseline_revision' .workflow/specs/006-result-file-guard/spec.md)"..HEAD -- '.agents/hooks/*.sh' '.agents/lib/*.sh' '.agents/skills/*/scripts/*.sh' install.sh | while read -r f; do grep -rqF -- "$(basename "$f")" tests/ || echo "$f"; done | wc -l | tr -d ' '
# asset-coverage: prints the count of new .agents/ files missing from the manifest or PROVENANCE.md; the threshold is 0
git diff --name-only --diff-filter=A "$(yq --front-matter=extract '.baseline_revision' .workflow/specs/006-result-file-guard/spec.md)"..HEAD -- .agents | while read -r f; do r=${f#.agents/}; m=0; while IFS= read -r l; do case "$r" in "$l"|"${l%/}"/*) m=1;; esac; done < .agents/install-manifest.txt; [ "$m" = 1 ] || echo "manifest: $f"; grep -qF -- "$(basename "$f")" PROVENANCE.md || echo "provenance: $f"; done | wc -l | tr -d ' '
# codex-enc-copies: the threshold is 0
git grep -n 'codex_enc' -- .agents/hooks | wc -l | tr -d ' '
# guard-time: the printed value is the best real time of 3 runs; the threshold is 0.2
mkdir -p .workflow/.worktrees/s006_tgt && for i in 1 2 3; do /usr/bin/time -p .agents/skills/feature-workflow/scripts/check-worktree-scope.sh --cwd "$PWD" --worktree-name s006_tgt --command "cat spec.md | head -5 && grep -n x spec.md | wc -l && ls -la && git log --oneline -3 | sed -n 1p && git status --short && yq '.a' f.yaml | jq . && rg -n y . | tail -2 && find . -name '*.md'" 2>&1 >/dev/null; done | awk '/^real/{print $2}' | sort -n | head -1; rmdir .workflow/.worktrees/s006_tgt
```

## Suites

| Suite | Profile key | Command (copied from the profile) | CI check | Known-bad-build evidence (1.4) |
| --- | --- | --- | --- | --- |
| Harness | `test` in `.workflow/profiles/test-harness.md` | `tests/run-all.sh` | none (no CI; the run by hand is the whole gate) | [artifacts/phase-1-known-bad/record.md](artifacts/phase-1-known-bad/record.md) Run 1, log [harness.log](artifacts/phase-1-known-bad/harness.log): 123 failures across 3 new suites and 4 extended ones, all assertions; re-entry for JRN-011 to 014: record.md Run 4, log [harness-r2.log](artifacts/phase-1-known-bad/harness-r2.log): 35 new failures in `scripts/install-upgrade` and the new `lint/install-matcher-docs`, all assertions |
| Browser | `e2e`: not applicable (no e2e work type, no browser; JRN-001 to JRN-009 are harness suites, JRN-010 is manual on the first real launch) | none | none | not applicable; see record.md Run 2 |
