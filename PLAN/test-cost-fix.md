# Fix plan: harness runs and review context

> Scaffold-only design doc (D30). Written 2026-10-22 from a diagnostic of the 001-large-path and 004-scoped-test-runs runs. It records why the workflow spent hours on tests, the decisions that fix it (D91–D95, copied into `assetlist.md`), the contracts the build units share, and the units themselves. The build runs outside `feature-workflow` at the stakeholder's request; the profile lines it cannot change are listed as proposals at the end.

## What the diagnosis found

Measured from the session transcripts, the spec artifacts and a timed harness run.

| Item | 001-large-path | 004-scoped-test-runs |
| --- | --- | --- |
| Tasks, waves | 10, 3 | 1, 1 |
| Implementation launches | 32 (10 first attempts, 22 fix or rework rounds) | 2 |
| Full harness runs per launch | at least 2 | 2, plus 3 timing runs |
| Gate, integration, baseline and target runs | 9 | 2 |
| Implied full runs | about 73 | 9 |
| Cost per run at the time | 6.6 min serial | 2.4 min parallel |
| Implied harness time | about 8 h | 26 min of a 56-min build |

Causes, in order of minutes:

1. **Every launch runs the toolchain twice on the same tree.** The implementer runs `run-toolchain.sh` itself until it is green; the stop audit then runs the identical command again with no check of the tree or of the record the first run wrote. In 004 each hand-back was followed by a silent 142–155 s gap, one full run, invisible because a passing audit prints nothing. The brief also asks for a third "full module suite" run.
2. **Fix rounds relaunch the task.** 23 mini-review rounds and 8 rework rounds on 001, mostly comment wording and readable-code items. Every round is a fresh launch and so at least two more full runs.
3. **Lint checks a path set, not the changed files.** A test file edited in a shell-scripts task is first shellchecked at the 3.9 gate; T9 was reopened there. The agent-docs lint calls the runner four times and the `test` key runs the same four suites again.
4. **Runs that prove nothing.** Integration batches run unscoped. 5.4 re-runs the harness whenever HEAD moved, which the workflow-data commit guarantees. review-targets ran the whole harness as a target on 001 and was launched with nothing to measure on 004. Scoping applies only when other tasks' tests are excluded, so single-task specs and the last task of a wave run the full harness at 3.5 and in the stop audit.
5. **The parallel floor is two suites.** `scripts/install` 130 s and `scripts/status-transition-check-write` 88 s; the other 31 suites fit under them, so the 141 s run cannot drop until those two are split.

Review context: no tool result over 20K characters containing runner output exists in any transcript. Each review pass put about 70K characters into the orchestrator for about 20K of findings: the lens hand-back (uncapped, with checked and not-checked inventories and quoted hunks), the same text retyped into a heredoc to save it, and sections of `review-triage.md` re-read every pass. Four passes on 001 cost about 293K characters for 14 findings; two of the passes found one finding each.

## Decisions (D91–D95, authoritative copy in `assetlist.md`)

- **D91. Toolchain runs are reused by tree hash.** `run-toolchain.sh` records in `toolchain.json` a `tree` field: the hash of the checkout's content, tracked and untracked files alike, minus the workflow data folders (specs, initiatives, deferred, decisions, `.handoff`, `.worktrees`, `.cache-staging`, `.standards-staging`). With `--reuse` it looks, before running anything, for a passing record under `<spec>/artifacts/*/toolchain.json` whose `tree` and `profile` match and whose results cover every key this run would execute; a full (unscoped) record satisfies any request, a scoped record only a request for the same task id. On a hit it copies that record's `toolchain.txt` and `toolchain.json` into its own evidence dir, adds `reused_from`, and exits 0 without running a command. The stop audit always passes `--reuse`, so an implementer's own passing 3.5 run is the only run when nothing changed; the 3.9 gate and the 5.4 report pass it too. Decided 2026-10-22: on 001-large-path every launch ran the full harness at least twice on the same tree.
- **D92. Step 3.5 runs the task's own suites whenever the task record lists any.** (Amends D85's scoping rule.) `test_scoped` replaces `test` when the task's own list is non-empty or the excluded set is non-empty; `test` runs whole only when both are empty. The full harness is the 3.9 gate's job, once per wave, and the 5.4 report's. Integration batches pass `--exclude-unfinished`, so unfinished tasks' Phase 1 tests are excluded instead of judged by hand. Decided 2026-10-22.
- **D93. Review lenses file their own findings.** Each Phase 4 lens writes its full review-findings block to `<spec>/artifacts/review/pass-<n>/<lens>.yaml` itself, the pass number taken from its prompt line, and returns a summary block: lens, pass, file path, counts by severity, discovered-work count and one line per finding id. Evidence hunks in the file are at most three lines. The orchestrator never retypes a block: it checks each file with `check-review-findings.sh`, which validates the shape and prints a bounded table, and reads single findings with `yq` as triage needs them. Decided 2026-10-22: on 001-large-path each pass put about 70K characters into the orchestrator for about 20K of findings.
- **D94. A further review pass runs only after a high-severity patch.** `followup_review_recommended` is set, and 4.6 loops back, only when the pass patched a high-severity finding; a pass with nothing above medium ends Phase 4 at 4.8. review-targets is not launched when the spec has no `verification-plan.md` (light path); triage records "no targets (light path)". The harness run is never a Targets row: 3.9 proves it. Decided 2026-10-22: two of four passes on 001 found one low finding each.
- **D95. Mini-review returns verdicts, not the checklist.** `profile-mini-review` returns each item as its index, verdict and location, never the quoted checklist line. The implementer walks the profile's mini-review checklist and the readable-code lines itself before it stops, since the whole profile is already in its prompt. A fix round whose failing items are all wording or readable-code items resumes the same implementer with the item list instead of a fresh launch. Decided 2026-10-22: the 23 mini-review rounds on 001 were mostly comment wording, each a fresh launch plus two harness runs.

## Contracts the units build to

Every unit implements against these; none waits for another.

**C1 `run-toolchain.sh`** (owner: U1)

- New option `--reuse`: D91. New option `--tree-hash`: print the tree hash of `--cwd` and exit 0; needs no spec dir.
- Tree hash: in `--cwd`, build a temporary index (`GIT_INDEX_FILE` set to an absolute temp path) with `git add -A` plus `:(exclude)` pathspecs for the workflow data folders, then `git write-tree`. Ignored files stay out because `git add` honours `.gitignore`. The excluded folder names come from `.agents/lib/workflow-paths.sh`, never spelled out.
- `toolchain.json` gains `tree` (always) and `reused_from` (only on a reuse hit). The `test` result keeps `scoped` and `excluded` and gains `own` (count of the task's own selectors).
- Scoping: D92. `scoped: true` whenever `test_scoped` ran.
- Reuse match: `status == "pass"`, same `tree`, same `profile`, every key this run would execute is `pass` in the candidate (a candidate with that key `skipped` does not match), and either the candidate is unscoped or its `task_id` equals this one. Search order: this task's own dir first, then the others by name.
- Header comment, `# Exit:` and the CLI block updated. Shape of `toolchain.txt` unchanged.

**C2 `post-implementation-audit.sh`** (owner: U1): adds `--reuse` to the `run-toolchain.sh` arguments. Nothing else changes.

**C3 `check-review-findings.sh <file>`** (owner: U3), new helper at `.agents/skills/feature-workflow/scripts/`:

- Exit 0: prints one header line `lens: <name>  pass: <n>  findings: <t> (high <h>, medium <m>, low <l>)  discovered_work: <k>  checked: <c>  not_checked: <nc>  not_verifiable: <nv>`, then a tab-separated table `id category severity confidence location claim` with the claim cut to 120 characters. For review-targets it also prints `target measured verdict` rows.
- Exit 1: one line per shape error, naming the field. The shape rules are the ones `review-triage.md` lists today in its yq checks (ids unique and prefixed by lens, severity in high/medium/low, confidence an integer 0–100, location present, category in the allowed set, measurements rows complete for targets). The script replaces those prose checks; the module calls the script.
- Exit 2: usage, missing file, or yaml that does not parse.
- bash 3.2, `set -euo pipefail`, `# File:` header in the helper shape, listed in `.agents/install-manifest.txt` and `PROVENANCE.md`.

**C4 Lens return block** (owner: U4, consumed by the orchestrator), identical for the three lenses:

```yaml
lens: review-standards
pass: 1
file: .workflow/specs/NNN-slug/artifacts/review/pass-1/review-standards.yaml
findings: {total: 6, high: 1, medium: 2, low: 3}
discovered_work: 1
ids:
  - "RS-1 low: one-line claim"
```

The lens writes the full block to `file` with a Bash heredoc (`mkdir -p` the pass dir first, as review-targets already does for its `targets/` dir) before returning. The full block's fields are unchanged from today, so triage reads the same shape; only its destination moves and hunks are capped at three lines.

**C5 Mini-review return** (owner: U4): `items:` is a list of `{n, verdict, location, note}` where `n` is the item's position in the checklist (readable-code lines follow, numbered R1…), `verdict` is `pass | fail | tool-covered | not-applicable`, `location` is `file:line` and `note` is one line, present only on `fail` or `tool-covered`. No quoted checklist text.

**C6 `tests/run-all.sh`** (owner: U2): `--suite` may repeat; the named suites run together, in glob order, with the usual summary. `--suite` with `--only-file` or `--exclude-file` still exits 2.

## Work units

Each unit is one opus builder in its own git worktree on its own branch, with the file set below and nothing outside it. Every unit runs `tests/run-all.sh` and the shell lint for the files it touched before it reports, and commits with a Conventional Commits subject.

| Unit | Work type | Files | Done when |
| --- | --- | --- | --- |
| U1 Toolchain reuse and scoping | shell-scripts | `.agents/skills/feature-workflow/scripts/run-toolchain.sh`, `.agents/hooks/post-implementation-audit.sh`, `tests/scripts/run-toolchain.sh`, `tests/hooks/audit-sync-resume.sh` | C1 and C2 hold. Tests cover: `tree` recorded; `--tree-hash` stable across runs and changed by an untracked file, unchanged by a write under `.workflow/specs/`; `--reuse` hit copies and stamps `reused_from` and runs no command (a stub `test` command that writes a marker proves it); miss on tree change, profile change, failing candidate, skipped key, scoped candidate for another task; scoped run when own list non-empty and excluded empty; the hook passes `--reuse` so a stop after a passing self-run executes nothing. |
| U2 Harness floor | test-harness | `tests/run-all.sh`, `tests/scripts/install.sh` (split), `tests/scripts/status-transition-check-write.sh` (split), `tests/scripts/run-all-selection.sh`, `tests/README.md` | C6 holds with a test. `scripts/install` is split into three or four suites by concern, each self-contained (own `preflight`, fixtures, `shellcheck_files`, `finish`), with the same 138 assertions in total; `status-transition-check-write` likewise, 677 assertions in total. The longest suite in a default run is under 50 s and the full parallel run is under 70 s on the build machine; the serial sum does not grow by more than 10 percent. README suite table updated. |
| U3 Findings check script | shell-scripts, test-harness | new `.agents/skills/feature-workflow/scripts/check-review-findings.sh`, new `tests/scripts/check-review-findings.sh`, `.agents/install-manifest.txt`, `PROVENANCE.md`, one row in `tests/README.md` | C3 holds. The suite feeds it the three real pass-1 files of spec 004 (exit 0, header and table match), a targets file with measurements, and one malformed file per shape rule (exit 1, the message names the field), plus missing-file and bad-yaml (exit 2). |
| U4 Workflow docs | agent-docs | `.agents/agents/implementation.md`, `integration.md`, `profile-mini-review.md`, `review-standards.md`, `review-end-state.md`, `review-targets.md`; `.agents/skills/feature-workflow/modules/review-triage.md`, `implementation-orchestrator.md`, `sign-off.md`, `verification-setup.md`; `SKILL.md` only if it lists the lens return | D91–D95 are what the files say (details below). The four lint suites pass; no step is added or removed, so `references/steps.tsv` is untouched unless a step title changes. |
| U5 Design docs | scaffold docs | `assetlist.md`, `PLAN/decision-flow-reference.md`, `PLAN/decision-flow.mermaid` | D91–D95 appended after D90 verbatim from this file; D85's entry marked amended by D92; the hook, helper-script and agent rows updated; reference entries 00.20, 3.5, 3.6, 3.7, 3.8, 3.9, 4.1–4.4, 4.6, 5.4 updated; the "D1–D84" line reads "D1–D95"; mermaid labels for 3.5, 3.7, 4.4, 4.6 and 5.4 say what changed. Entries keep the "what it is, responsible for, not" shape. |
| U6 Integration | shell-scripts | none of its own | After U1–U5: branch `fix/test-cost` off `main`, the five branches merged, conflicts resolved in favour of this file's contracts, shellcheck over every tracked `.sh`, `tests/run-all.sh` green with its timing, and a report of what each unit changed. |

### U4 edit intents

- `implementation.md`: in the method, replace "run the module's full test suite once at the end" with running the toolchain at 3.5, which runs the task's own suites; add a self-check step before stopping: walk the profile's mini-review checklist and the readable-code lines against the diff, fix what fails; say that the stop audit reuses a passing toolchain record when the tree is unchanged, so the self-run is the only run in the normal case. Keep the return block.
- `integration.md`: add `--exclude-unfinished` to the 3.5 command.
- `profile-mini-review.md`: C5 replaces the quoted-line return.
- `review-standards.md`, `review-end-state.md`, `review-targets.md`: the Return section becomes "write the full block to the pass file, then return C4"; hunks capped at three lines; review-targets keeps its measurement files and lists the harness as something it never measures.
- `review-triage.md`: pass number stays in the prompt line; step 2 skips review-targets without `verification-plan.md`; after the lenses return, run `check-review-findings.sh` on each file (a shape failure relaunches that lens once with the message); the "save each block" step becomes "confirm the file exists"; triage reads the table and single findings by id; the yq shape checks move out; 4.6 and 4.8 follow D94.
- `implementation-orchestrator.md`: 3.5 wording for D92 (`own` and `excluded` in `toolchain.json`); 3.6 lists `tree` and `reused_from`; 3.7 fix rounds follow D95 (resume the same agent for wording-only items; a behaviour fix is still a relaunch); 3.9 passes `--reuse`; the "read toolchain.txt yourself" line stays for the unscoped case but says it is now rare.
- `sign-off.md` 5.4: run the toolchain with `--reuse` under the evidence id `sign-off-5.4` and paste the summary line plus the evidence path, not the whole output.
- `verification-setup.md` 1.1: a Targets row never names the harness or its pass count.

## Profile proposals awaiting a 5.3

The three profiles are Tier A and change only at sign-off, so these are recorded here for the next spec's 5.3, in the `proposals.md` shape.

| Id | Target | Proposed text | Why |
| --- | --- | --- | --- |
| P1 | `.workflow/profiles/shell-scripts.md` § Toolchain | `lint: "git ls-files -z -- '*.sh' | xargs -0 shellcheck -x -P SCRIPTDIR"` | A shell-scripts task that edits a test file is shellchecked at 3.5, not first at the 3.9 gate (T9 on 001 was reopened for this). 73 files, about 8 s. |
| P2 | `.workflow/profiles/test-harness.md` § Toolchain | same line as P1 | Same reason in the other direction. |
| P3 | `.workflow/profiles/agent-docs.md` § Toolchain | `lint: "tests/run-all.sh --suite lint/frontmatter --suite lint/step-list --suite lint/symlinks --suite lint/upstream-lineage"` | One runner call reports all four suites; the `&&` chain hid the later ones while step-list was red by design on 001. Needs C6. |

The managed block in `AGENTS.md` mirrors these lines and is refreshed by `project-standards` when they land.

## Expected effect

| Case | Today | After |
| --- | --- | --- |
| One implementation launch, clean | 2 full runs, about 280 s | 1 scoped run, about 16 s |
| Wording-only fix round | fresh launch, 2 full runs | resume, 1 scoped run |
| Wave gate 3.9 | 1 full run | 1 full run, reused when the merged tree matches a passing record |
| 5.4 report | 1 full run | reused unless code changed |
| Full run | 141 s | under 70 s after U2 |
| Review pass into the orchestrator | about 70K characters | about 15K |
| 001-sized feature, harness time | about 3 h at today's speed | under 30 min |

## Out of scope

- Populating a light-path task's own-suite list from its predicted files: today the list comes only from Phase 1, so a light-path task still runs the full harness at 3.5 (D6 of spec 004).
- Making `scripts/install` or `status-transition-check-write` themselves faster beyond splitting them.
- Any change to the launch header fields: the pass number stays in the prompt line.
