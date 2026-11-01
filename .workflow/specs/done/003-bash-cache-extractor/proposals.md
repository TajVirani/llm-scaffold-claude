# Proposals: Tier B caches for bash projects

Spec: [spec.md](spec.md) · Report: [report.md](report.md)

Status values: `proposed` · `approved` · `modified` · `rejected`

## Capabilities

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P6 | `.workflow/capabilities.md` | CAP-004 \| Graph extractor per work profile: the Tier B cache build runs the graph extractor each work profile names (`graph_extractor`: `bash`, `dependency-cruiser` or `none`) and merges their graphs; a profile without the key is a breaking-change error \| [.workflow/specs/done/003-bash-cache-extractor](specs/done/003-bash-cache-extractor/spec.md) | Without it, 0.3.1 would not see that per-language cache builds already exist and could plan a second mechanism | spec.md § Capabilities | approved | |
| P7 | `.workflow/capabilities.md` | CAP-005 \| Bash graph extractor: a file graph from `source`/`.` lines and script calls, with unresolved calls listed under Unresolved edges and sourced files' functions as Public interface \| [.workflow/specs/done/003-bash-cache-extractor](specs/done/003-bash-cache-extractor/spec.md) | Without it, a request for bash caches or a shell call graph would not be matched to this capability at 0.3.1 | spec.md § Capabilities | approved | |

## Decisions

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P8 | `.workflow/decisions/adr/0003-graph-extractor-per-profile.md` | New ADR: each work profile names its graph extractor; every extractor is `scripts/extractors/<name>.sh --root DIR --scope PATH...` printing dependency-cruiser's JSON shape, which `build-architecture.sh` merges and canonicalises as the one reader; a missing key is a breaking-change error, not a silent default (D1, D2, D5, D12) | Without it, the next language's extractor could add a second graph format or a silent default extractor, and the breaking-change error would look like an accident to remove | design-log D1, D2, D5, D12 | approved | |
| P9 | `.workflow/GLOSSARY.md` § Graph extractor | replace: Each **work profile** names one; dependency-cruiser is the JS/TS one. -> Each **work profile** names one with `graph_extractor`: `dependency-cruiser` for JS/TS, `bash` for shell scripts, or `none`. | Without it, an agent reading the glossary would think dependency-cruiser is the only extractor and the key does not exist | spec 003 T1, T3 | approved | |

## Pitfalls

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P10 | `.workflow/decisions/pitfalls.md` | Report a detected call as unresolved; never filter it out. What happened: the bash extractor dropped script calls it had detected (extensionless targets, cwd-relative paths, `--norc`, `$(...)`, `-o pipefail`) through filters, found over one review finding and three fix rounds. Where: `extractors/bash.sh`. Spec: 003-bash-cache-extractor. Prevented by: the forms cases in `tests/scripts/extractor-bash.sh`. | Without it, the next extractor may again filter odd-looking calls and silently lose edges | F5 (RE-1); T3 rework 1 rounds | approved | |
| P11 | `.workflow/decisions/pitfalls.md` | Never pipe a gate checker into `head` inside a `&&` chain. What happened: at 3.16 `check-task-result.sh ... \| head -1 && git merge ...` merged T3 although the checker exited 1, because the pipe returned head's exit. Where: implementation-orchestrator 3.16. Spec: 003-bash-cache-extractor. Prevented by: none yet. | Without it, the orchestrator can merge a task whose result file failed its check | design-log 2026-10-23 rework 1 | approved | |
| P12 | `.workflow/decisions/pitfalls.md` | Fork a Phase 1 build's worktree from the spec branch. What happened: the 1.2 harness agent's `isolation: "worktree"` worktree started at `main`, without the spec folder; the agent fast-forwarded it, and the worktree guard then refused its result-file write to the main checkout. Where: verification-setup 1.2 launch. Spec: 003-bash-cache-extractor. Prevented by: none yet (needs `worktree.baseRef: head` or a wave-start-style worktree for Phase 1). | Without it, Phase 1 builds keep starting from the wrong base and losing their result files | design-log 2026-10-23 Phase 1 harness reports | approved | |

## Profiles

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | `.workflow/profiles/shell-scripts.md` § File locations | replace: Depth stops at `.agents/skills/<s>/scripts/<file>`: no subfolders. -> Depth stops at `.agents/skills/<s>/scripts/<file>`, except `scripts/extractors/<name>.sh`, one graph extractor per file. | Without it, a mini-review or review-standards pass flags the agreed `scripts/extractors/` folder (D1) as a layout violation | 1.2 harness report (design-log 2026-10-23) | approved | |
| P2 | `.workflow/profiles/shell-scripts.md` § Mini-review checklist, item 1 | Say whether the "never spell a new `.workflow/` path" rule covers test fixtures; the test-harness convention spells fixture paths in every suite | Without it, each reviewer decides afresh whether a fixture path under `tests/` breaks item 1 | T1 mini-review r2 `out_of_scope_noticed` (`tests/scripts/graph-extractor-selection.sh:100,105`) | approved | |
| P3 | `.workflow/profiles/shell-scripts.md` § Toolchain | add: `graph_extractor: bash`; replace: `test_patterns: []` -> `test_patterns: ["tests/"]` | Without the key the cache build exits 2 on this repo (D5); without `tests/` the test suites become entry-point candidates in flows.md | spec M3; review-end-state pass 1 `not_verifiable` | approved | |
| P4 | `.workflow/profiles/test-harness.md` § Toolchain | add: `graph_extractor: bash`; replace: `test_patterns: []` -> `test_patterns: ["tests/"]` | Same as P3, for the harness profile | spec M3 | approved | |
| P5 | `.workflow/profiles/agent-docs.md` § Toolchain | add: `graph_extractor: none` | Without the key the cache build exits 2 on this repo (D5) | spec M3 | approved | |
| P13 | `.workflow/profiles/shell-scripts.md`, `.workflow/profiles/test-harness.md`, `.workflow/profiles/agent-docs.md` § Toolchain | move: the `graph_extractor:` line goes after the two `#` continuation lines of `test_patterns`, so the default pattern list stays under the key it explains | Without it, the default test-pattern list reads as a note on `graph_extractor`, and an agent editing `test_patterns` may miss its defaults | F7 (review pass 2, RS-2); P3-P5 placed the key at 5.3 | approved | |
| P15 | `.workflow/profiles/shell-scripts.md` § Mini-review checklist, item 8 | replace: "each shellcheck directive has its reason" -> "each shellcheck `disable=` directive has its reason; a `source=` path hint needs none" | Without it, reviewers fail a bare `# shellcheck source=` hint that every suite uses, and fix rounds add reasons to one hint while its siblings stay bare | T9 mini-review r1 (design-log "Wave 4 (T9, T10)") | approved | |

## Agent instructions

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P14 | `.agents/agents/implementation.md` § Rules | add: Commit subjects are Conventional Commits (`feat:`, `fix:`, `test:`, `docs:`, `refactor:`, `chore:`), never a bare task id such as `T9:`; name the task in the body. | Without it, implementers keep writing `T<n>:` subjects against `.workflow/rules.md:145`, as in specs 004 and 003 | F11 (review pass 2, RL-3); retrospective 004 process lesson | approved | |
