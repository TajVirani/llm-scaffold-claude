# Pre-change normaliser behaviour (JRN-006 oracle)

Recorded at 1.2 on commit 1f59f20 (the spec branch tip, before any Phase 3 change) by running the six scripts on the fixture that `tests/fixtures/workflow-folders.sh` builds (`folder_fixture_repo`, `folder_inputs`). `<tmp>` is the fixture's temp dir: the main checkout is `<tmp>/p`, its worktree `<tmp>/p-wt`, and `<tmp>/p-elsewhere` is a folder outside any repository holding `001-alpha` and `001-ini`.

Commands, each with `--cwd <cwd>`:

- spec `001-alpha`: `status-transition.sh step <dir> 1.2`, `budget-check.sh --spec-dir <dir>`, `task-waves.sh --spec-dir <dir>`, `commit-workflow-data.sh <dir> -m x`, `open-task-pr.sh <dir> T1 --dry-run`
- initiative `001-ini`: `initiative-transition.sh step <dir> 6.2`, `open-task-pr.sh --head spec/001-alpha --base main --title x --record <dir> --dry-run`

Inputs (initiative inputs are the same forms over `.workflow/initiatives/001-ini`):

- relative: `.workflow/specs/001-alpha`
- dot-relative: `./.workflow/specs/001-alpha/`
- absolute-main: `<tmp>/p/.workflow/specs/001-alpha`
- absolute-worktree: `<tmp>/p-wt/.workflow/specs/001-alpha`
- from-worktree: `.workflow/specs/001-alpha` with `--cwd <tmp>/p-wt`
- bare: `001-alpha`
- absolute-elsewhere: `<tmp>/p-elsewhere/001-alpha`
- outside-repo: `.workflow/specs/001-alpha` with `--cwd <tmp>/p-elsewhere`

Spec 005 keeps every row except the two marked *changes*: open-task-pr must then reject an absolute path whose parent is not the specs or initiatives root (task mode: exit 1, `open-task-pr.sh: spec dir must be .workflow/specs/NNN-slug: <arg>`; `--record`: exit 2, `open-task-pr.sh: --record must be .workflow/initiatives/NNN-slug: <arg>`). The harness pins these rows in the per-script suites (`status-transition-specs`, `budget-check`, `task-breakdown`, `commit-workflow-data`, `initiative-transition`).

| script / input | exit | first stderr line |
| --- | --- | --- |
| status-transition step / relative | 0 |  |
| budget-check / relative | 0 |  |
| task-waves / relative | 0 |  |
| commit-workflow-data / relative | 0 |  |
| open-task-pr task mode / relative | 0 | open-task-pr.sh: skipped: task branch task/001-alpha/T01-demo does not exist locally |
| status-transition step / dot-relative | 0 |  |
| budget-check / dot-relative | 0 |  |
| task-waves / dot-relative | 0 |  |
| commit-workflow-data / dot-relative | 0 |  |
| open-task-pr task mode / dot-relative | 0 | open-task-pr.sh: skipped: task branch task/001-alpha/T01-demo does not exist locally |
| status-transition step / absolute-main | 0 |  |
| budget-check / absolute-main | 0 |  |
| task-waves / absolute-main | 0 |  |
| commit-workflow-data / absolute-main | 0 |  |
| open-task-pr task mode / absolute-main | 0 | open-task-pr.sh: skipped: task branch task/001-alpha/T01-demo does not exist locally |
| status-transition step / absolute-worktree | 0 |  |
| budget-check / absolute-worktree | 0 |  |
| task-waves / absolute-worktree | 0 |  |
| commit-workflow-data / absolute-worktree | 0 |  |
| open-task-pr task mode / absolute-worktree | 0 | open-task-pr.sh: skipped: task branch task/001-alpha/T01-demo does not exist locally |
| status-transition step / from-worktree | 0 |  |
| budget-check / from-worktree | 0 |  |
| task-waves / from-worktree | 0 |  |
| commit-workflow-data / from-worktree | 0 |  |
| open-task-pr task mode / from-worktree | 0 | open-task-pr.sh: skipped: task branch task/001-alpha/T01-demo does not exist locally |
| status-transition step / bare | 1 | status-transition.sh: spec dir must be .workflow/specs/NNN-slug: 001-alpha |
| budget-check / bare | 1 | budget-check.sh: spec dir must be .workflow/specs/NNN-slug: 001-alpha |
| task-waves / bare | 1 | task-waves.sh: spec dir must be .workflow/specs/NNN-slug: 001-alpha |
| commit-workflow-data / bare | 2 | commit-workflow-data.sh: spec dir must be .workflow/specs/NNN-slug: 001-alpha |
| open-task-pr task mode / bare | 1 | open-task-pr.sh: spec dir must be .workflow/specs/NNN-slug: 001-alpha |
| status-transition step / absolute-elsewhere | 1 | status-transition.sh: spec dir must be .workflow/specs/NNN-slug: <tmp>/p-elsewhere/001-alpha |
| budget-check / absolute-elsewhere | 1 | budget-check.sh: spec dir must be .workflow/specs/NNN-slug: <tmp>/p-elsewhere/001-alpha |
| task-waves / absolute-elsewhere | 1 | task-waves.sh: spec dir must be .workflow/specs/NNN-slug: <tmp>/p-elsewhere/001-alpha |
| commit-workflow-data / absolute-elsewhere | 2 | commit-workflow-data.sh: spec dir must be .workflow/specs/NNN-slug: <tmp>/p-elsewhere/001-alpha |
| open-task-pr task mode / absolute-elsewhere | 0 | open-task-pr.sh: skipped: task branch task/001-alpha/T01-demo does not exist locally (*changes*) |
| status-transition step / outside-repo | 1 | status-transition.sh: not inside a git repository: <tmp>/p-elsewhere |
| budget-check / outside-repo | 1 | budget-check.sh: not inside a git repository: <tmp>/p-elsewhere |
| task-waves / outside-repo | 1 | task-waves.sh: not inside a git repository: <tmp>/p-elsewhere |
| commit-workflow-data / outside-repo | 2 | commit-workflow-data.sh: not inside a git repository: <tmp>/p-elsewhere |
| open-task-pr task mode / outside-repo | 1 | open-task-pr.sh: not inside a git repository: <tmp>/p-elsewhere |
| initiative-transition step / relative | 0 |  |
| open-task-pr --record / relative | 0 | open-task-pr.sh: skipped: no origin remote |
| initiative-transition step / dot-relative | 0 |  |
| open-task-pr --record / dot-relative | 0 | open-task-pr.sh: skipped: no origin remote |
| initiative-transition step / absolute-main | 0 |  |
| open-task-pr --record / absolute-main | 0 | open-task-pr.sh: skipped: no origin remote |
| initiative-transition step / absolute-worktree | 0 |  |
| open-task-pr --record / absolute-worktree | 0 | open-task-pr.sh: skipped: no origin remote |
| initiative-transition step / from-worktree | 0 |  |
| open-task-pr --record / from-worktree | 0 | open-task-pr.sh: skipped: no origin remote |
| initiative-transition step / bare | 1 | initiative-transition.sh: initiative dir must be .workflow/initiatives/NNN-slug: 001-ini |
| open-task-pr --record / bare | 2 | open-task-pr.sh: --record must be .workflow/initiatives/NNN-slug: 001-ini |
| initiative-transition step / absolute-elsewhere | 1 | initiative-transition.sh: initiative dir must be .workflow/initiatives/NNN-slug: <tmp>/p-elsewhere/001-ini |
| open-task-pr --record / absolute-elsewhere | 0 | open-task-pr.sh: skipped: no origin remote (*changes*) |
| initiative-transition step / outside-repo | 1 | initiative-transition.sh: not inside a git repository: <tmp>/p-elsewhere |
| open-task-pr --record / outside-repo | 2 | open-task-pr.sh: not inside a git repository: <tmp>/p-elsewhere |
