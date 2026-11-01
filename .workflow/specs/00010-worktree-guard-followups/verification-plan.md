# Verification plan: Worktree guard and upgrade follow-ups

Spec: [spec.md](spec.md)

## End state

- [ ] CAP-007: an implementation or integration sub-agent payload whose cwd is the main checkout is denied by `worktree-write-guard.sh`, with a reason naming the cause, for a Write and for a non-read Bash command, when (a) the named agent worktree does not exist, (b) the sub-agent transcript is missing, (c) the launch header is missing or unparsable.
- [ ] CAP-007: under those causes reads and temp-dir writes are denied too, and a cwd outside any git repo is denied.
- [ ] CAP-007: the `--worktree-name` usage text names the Phase 1 and integration shapes, and `implementation-orchestrator.md` says a missing agent worktree is denied.
- [ ] CAP-007: the same agent launched with a linked-worktree cwd (isolation) is still confined to that worktree and allowed inside it.
- [ ] CAP-007: `worktree-write-guard.sh` prints a deny JSON for an unparsable payload, and a static deny JSON when jq is not on PATH (workflow installed).
- [ ] CAP-007: `check-worktree-scope.sh --confined` exits 2 when no root is found; without `--confined` it exits 0 as before, so the Codex guard's behaviour is unchanged.
- [ ] CAP-007: no deny or allow message of `check-worktree-scope.sh`, and neither script's `# File:` line, contains "task worktree".
- [ ] CAP-008: a confined agent's `sed -n '$p' f`, `sed -n -e '1p' -e '$p' f` and `grep 'x$' f` from the main checkout are allowed; `grep "x$" f`, `cat $HOME/f`, `grep \$ f`, `grep 'a'\''$' f` and an unterminated quote still deny without the `cd`.
- [ ] CAP-010: the template's and this repo's `permissions.deny` hold the four yq extract in-place rules, the template's line-148 entry is unchanged, and `install.sh` writes all four into a fresh target's `.claude/settings.json` and keeps them on a re-run.
- [ ] Records: the three "re-run writes nothing" checks in `tests/scripts/install-upgrade.sh` fail when the re-run exits non-zero; `assetlist.md` gives the stop-audit matcher as `implementation|integration`, says Phase 1 and integration run in orchestrator-made agent worktrees with no isolation fallback, and carries no "Amended by spec 006" note for them.

## Journeys

| Id | Journey | Proves | Steps | Expected outcome | Check |
| --- | --- | --- | --- | --- | --- |
| JRN-001 | Unconfinable agent denied | CAP-007 | 1. Fixture repo with spec `007-demo`. 2. Feed the guard implementation payloads (cwd main checkout) whose header names `s007_t9` with no worktree on disk; whose transcript path does not exist; whose first user message has no launch header; and an integration payload with no worktree. 3. Each as a Write to the main checkout, a Write to a temp dir outside the repo, a read-only `cat f` and `ls -la > x` Bash. 4. An implementation payload whose cwd is outside any git repo. | Every call denied, reads and temp-dir writes included; each reason names its cause (worktree missing, transcript not found, header not parsed, not in a git repo). | `tests/hooks/worktree-guard.sh` (JRN-001 checks) |
| JRN-002 | Isolation launch still confined | CAP-007 | 1. Linked worktree created with `git worktree add`. 2. Implementation payload with no named worktree and cwd in that worktree; a Write inside it and a Write to the main checkout. | Inside allowed; main checkout denied. | `tests/hooks/worktree-guard.sh` (JRN-002 cases) |
| JRN-003 | Guard fails closed on its own errors | CAP-007 | 1. Feed `worktree-write-guard.sh` a non-JSON payload and a JSON array. 2. Run it with a PATH that has no jq, workflow installed. | Deny JSON on stdout, exit 0, in all three runs; the jq case's reason names jq. | `tests/hooks/worktree-guard.sh` (JRN-003 cases) |
| JRN-004 | Scope check CLI contract | CAP-007 | 1. `check-worktree-scope.sh --cwd <main> --worktree-name s007_t9 --path <main>/a --confined`. 2. Same without `--confined`. 3. `--confined` with no name. 4. Codex guard payload for a task without a worktree. | 1 and 3 exit 2 with a reason; 2 exits 0; 4 allowed as today. | `tests/hooks/worktree-guard.sh` (JRN-004 cases) |
| JRN-005 | Agent worktree wording | CAP-007 | 1. Trigger each deny of the scope check (path outside, no `cd`, non-literal cd, relative cd, cd outside, `--confined` with no root). 2. grep the two scripts' `# File:` lines and `check-worktree-scope.sh --help`. 3. grep `implementation-orchestrator.md` for the missing-worktree line. | No output or header contains "task worktree"; deny reasons say "agent worktree"; `--help` names the Phase 1 and integration shapes; the orchestrator line exists. | `tests/hooks/worktree-guard.sh` (JRN-005 cases) |
| JRN-006 | Quoted `$` reads pass | CAP-008 | 1. Task agent payloads from the main checkout running `sed -n '$p' f`, `sed -n -e '1p' -e '$p' f`, `grep 'x$' f`, `grep 'a' f \| tail -n 1`. 2. Then `grep "x$" f`, `cat $HOME/f`, `grep \$ f`, `` grep '`' f `` (allowed: in single quotes), ``grep `id` f``, `grep 'a'\''$' f`, `grep 'x$ f`. | Group 1 and the single-quoted backtick allowed; the others denied with the `cd` instruction. | `tests/hooks/worktree-guard.sh` (JRN-006 cases) |
| JRN-007 | Extract in-place denied in installed settings | CAP-010 | 1. Read the template and `.claude/settings.json` deny arrays. 2. `install.sh --host claude` into an empty target, then over a target whose settings already have a user deny entry; re-run. | Both source files hold the four rules; the target holds them plus the user entry, once each, after every run; template line 148 matches main. | `tests/scripts/install-claude-settings.sh` (JRN-007 cases) |
| JRN-008 | Upgrade re-run checks catch a refusing re-run | Records | 1. In `tests/scripts/install-upgrade.sh`, the JRN-011 third run and the two-template-groups re-run capture the exit code. 2. Assert exit 0 beside the "writes nothing" snapshot check. | A re-run exiting 1 fails the suite (shown once by a stand-in that exits 1, recorded at 1.4). | `tests/scripts/install-upgrade.sh` (JRN-008 checks) |
| JRN-009 | Asset record matches 006 | Records | 1. grep `assetlist.md` for the stop-audit row, the worktree guard row and D85 item 6. | Matcher `implementation\|integration`; "agent worktree"; orchestrator-made Phase 1 and integration worktrees; no isolation fallback; no "Amended by spec 006" for these. | `tests/lint/agent-worktree-docs.sh` (JRN-009 cases) |

## Fixtures and oracles

| Fixture or oracle | What it provides | Source | Used by |
| --- | --- | --- | --- |
| Guard fixture repo | A git repo with `.agents/` copied in, spec `007-demo`, agent worktrees `s007_t3`, `s007_phase_1_shell_scripts`, `s007_integration_shell_scripts`, and sub-agent transcripts with launch headers | built by `tests/hooks/worktree-guard.sh` (`mk_sub`, `pl`) | JRN-001 to JRN-006 |
| No-jq PATH | A temp bin dir with bash, git and coreutils links but no jq | built in the suite | JRN-003 |
| Expected deny rules | The four rule strings, copied from spec.md CAP-010 | spec.md | JRN-007 |
| Main-branch template | `git show main:.agents/hooks/claude-settings.template.json` line 148 | git | JRN-007 |
| Install fixtures | Empty and pre-filled target repos | `tests/fixtures/claude-settings.sh`, `tests/scripts/install-upgrade.sh` | JRN-007, JRN-008 |

## Targets

Run every command in bash from the repo root on a clean checkout of the feature's HEAD. Measured at the baseline `1c5e46d`: guard-time 0.04 s on the 006 chain (no `$`).

| Target | Kind | Threshold | How measured (exact command) | Source of the threshold |
| --- | --- | --- | --- | --- |
| Script lint clean | errors | exit 0; 0 shellcheck findings | the `script-lint` command below (the `lint` key of the shell-scripts profile) | `.workflow/profiles/shell-scripts.md` § Toolchain |
| Harness lint clean | errors | exit 0; 0 shellcheck findings | the `harness-lint` command below (the `lint` key of the test-harness profile) | `.workflow/profiles/test-harness.md` § Toolchain |
| Agent-docs lint clean | errors | exit 0; each of the four lint suites reports 0 failed | the `agent-docs-lint` command below (the `lint` key of the agent-docs profile) | `.workflow/profiles/agent-docs.md` § Toolchain |
| Every script this spec changes has a suite | coverage | `0` printed | the `script-coverage` command below | `.workflow/profiles/test-harness.md` § Mini-review checklist |
| No "task worktree" in the guard scripts | errors | `0` printed | the `task-worktree-wording` command below | `spec.md` CAP-007 success line (D7) |
| Extract in-place deny rules in both settings files | errors | `8` printed (4 rules × 2 files) | the `extract-deny-rules` command below | `spec.md` CAP-010 success line (D6) |
| Worktree scope check time on a long read-only chain with single-quoted `$` | performance | real ≤ 0.5 s, best of 3 | the `guard-time` command below | stakeholder decision D13, 1.1 (2026-10-30) |
| Line coverage of changed shell code | coverage | not measured | Cannot be measured: no bash coverage tool is installed and no new dependency is allowed (spec Constraints). The script-coverage target and the test-harness checklist at 3.7 stand in. | stakeholder decision D14, 1.1 (2026-10-30) |

Commands referenced above; each runs from the project root:

```bash
# script-lint
git ls-files -z -co --exclude-standard -- '.agents/hooks/*.sh' '.agents/lib/*.sh' '.agents/skills/*/scripts/*.sh' install.sh 'scripts/*.sh' | xargs -0 shellcheck -x -P SCRIPTDIR
# harness-lint
git ls-files -z -co --exclude-standard -- 'tests/*.sh' | xargs -0 shellcheck -x -P SCRIPTDIR
# agent-docs-lint
tests/run-all.sh --suite lint/frontmatter && tests/run-all.sh --suite lint/step-list && tests/run-all.sh --suite lint/symlinks && tests/run-all.sh --suite lint/upstream-lineage
# script-coverage: prints the count of changed scripts no file under tests/ names; the threshold is 0
git diff --name-only --diff-filter=AM "$(yq --front-matter=extract '.baseline_revision' .workflow/specs/00010-worktree-guard-followups/spec.md)"..HEAD -- '.agents/hooks/*.sh' '.agents/lib/*.sh' '.agents/skills/*/scripts/*.sh' install.sh | while read -r f; do grep -rqF -- "$(basename "$f")" tests/ || echo "$f"; done | wc -l | tr -d ' '
# task-worktree-wording: the threshold is 0
grep -ci 'task worktree' .agents/skills/feature-workflow/scripts/check-worktree-scope.sh .agents/hooks/worktree-write-guard.sh | awk -F: '{n+=$2} END{print n}'
# extract-deny-rules: the threshold is 8
for f in .agents/hooks/claude-settings.template.json .claude/settings.json; do jq -r '.permissions.deny[]' "$f"; done | grep -cxF -e 'Bash(yq *--front-matter=extract* -i*)' -e 'Bash(yq *-i* --front-matter=extract*)' -e 'Bash(yq *--front-matter=extract* --inplace*)' -e 'Bash(yq *--inplace* --front-matter=extract*)'
# guard-time: the printed value is the best real time of 3 runs; the threshold is 0.5
mkdir -p .workflow/.worktrees/s00010_tgt && for i in 1 2 3; do /usr/bin/time -p .agents/skills/feature-workflow/scripts/check-worktree-scope.sh --cwd "$PWD" --worktree-name s00010_tgt --command "cat spec.md | head -5 && grep -n 'x\$' spec.md | wc -l && ls -la && git log --oneline -3 | sed -n '\$p' && git status --short && yq '.a' f.yaml | jq . && rg -n 'y\$' . | tail -2 && find . -name '*.md' && sed -n -e '1p' -e '\$p' spec.md && grep -n 'the \$HOME and \$PATH values in a long quoted pattern' spec.md" 2>&1 >/dev/null; done | awk '/^real/{print $2}' | sort -n | head -1; rmdir .workflow/.worktrees/s00010_tgt
```

## Suites

| Suite | Profile key | Command (copied from the profile) | CI check | Known-bad-build evidence (1.4) |
| --- | --- | --- | --- | --- |
| Harness | `test` in `.workflow/profiles/test-harness.md` | `tests/run-all.sh` | none (no CI; the run by hand is the whole gate) | [artifacts/phase-1-known-bad/record.md](artifacts/phase-1-known-bad/record.md) Run 1, log [harness.log](artifacts/phase-1-known-bad/harness.log): 79 failures across 3 suites, all assertions; Run 2, log [upgrade-standin.log](artifacts/phase-1-known-bad/upgrade-standin.log): the three JRN-008 checks red under a re-run-refusing installer |
| Browser | `e2e`: not applicable (no e2e work type; JRN-001 to JRN-009 are harness suites) | none | none | not applicable; see record.md |
