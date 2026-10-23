# Proposals: Tier B caches for bash projects

Spec: [spec.md](spec.md) · Report: [report.md](report.md)

Status values: `proposed` · `approved` · `modified` · `rejected`

## Profiles

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | `.workflow/profiles/shell-scripts.md` § File locations | replace: Depth stops at `.agents/skills/<s>/scripts/<file>`: no subfolders. -> Depth stops at `.agents/skills/<s>/scripts/<file>`, except `scripts/extractors/<name>.sh`, one graph extractor per file. | Without it, a mini-review or review-standards pass flags the agreed `scripts/extractors/` folder (D1) as a layout violation | 1.2 harness report (design-log 2026-10-23) | proposed | |
| P2 | `.workflow/profiles/shell-scripts.md` § Mini-review checklist, item 1 | Say whether the "never spell a new `.workflow/` path" rule covers test fixtures; the test-harness convention spells fixture paths in every suite | Without it, each reviewer decides afresh whether a fixture path under `tests/` breaks item 1 | T1 mini-review r2 `out_of_scope_noticed` (`tests/scripts/graph-extractor-selection.sh:100,105`) | proposed | |
| P3 | `.workflow/profiles/shell-scripts.md` § Toolchain | add: `graph_extractor: bash`; replace: `test_patterns: []` -> `test_patterns: ["tests/"]` | Without the key the cache build exits 2 on this repo (D5); without `tests/` the test suites become entry-point candidates in flows.md | spec M3; review-end-state pass 1 `not_verifiable` | proposed | |
| P4 | `.workflow/profiles/test-harness.md` § Toolchain | add: `graph_extractor: bash`; replace: `test_patterns: []` -> `test_patterns: ["tests/"]` | Same as P3, for the harness profile | spec M3 | proposed | |
| P5 | `.workflow/profiles/agent-docs.md` § Toolchain | add: `graph_extractor: none` | Without the key the cache build exits 2 on this repo (D5) | spec M3 | proposed | |
