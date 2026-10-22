---
tasks:
  - id: T1
    title: "Scoped and parallel harness runs"
    status: done
    capability: CAP-001
    depends_on: []
    touches_core: false
    work_type: test-harness
    module: "tests"
    seam: "tests/run-all.sh CLI: --only-file, --exclude-file, -j; summary lines and exit codes 0/1/2"
    file: tasks/T01-scoped-parallel-runner.md
    branch: null
    predicted_files: [tests/run-all.sh, tests/scripts/run-all-selection.sh, tests/README.md]
    size: {files: 3, est_lines: 150, points: S}
    mode: afk
    parallel_with: []
    pr: null
---

# Tasks: Scoped test runs for the harness profiles

Spec: [spec.md](spec.md) · Task files: [tasks/](tasks/)

## Waves

| Wave | Task | Title | Size | Mode | Overlaps |
| --- | --- | --- | --- | --- | --- |
| 1 | [T1](tasks/T01-scoped-parallel-runner.md) | Scoped and parallel harness runs | S (3 files, ~150 lines) | afk | none |
