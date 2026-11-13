---
tasks:
  - id: T1
    title: "Offer every worktree's handoffs outside a spec worktree"
    status: pending
    capability: CAP-015
    depends_on: []
    touches_core: false
    work_type: shell-scripts
    module: "hooks"
    seam: "session-start-resume.sh stdin payload {cwd} -> additionalContext; handoff SKILL.md Resume text"
    file: tasks/T01-session-worktree-offer.md
    branch: task/00017-handoffs-from-session-worktrees/T01-session-worktree-offer
    predicted_files:
      - .agents/hooks/session-start-resume.sh
      - .agents/skills/handoff/SKILL.md
      - tests/hooks/audit-sync-resume.sh
      - tests/scripts/handoff-skill.sh
      - tests/README.md
    size: {files: 5, est_lines: 90, points: S}
    mode: afk
    parallel_with: []
    pr: null
    issue: null
---

# Tasks: Handoffs found from session worktrees

Spec: [spec.md](spec.md) · Task files: [tasks/](tasks/)

## Waves

| Wave | Task | Title | Size | Mode | Overlaps |
| --- | --- | --- | --- | --- | --- |
| 1 | [T1](tasks/T01-session-worktree-offer.md) | Offer every worktree's handoffs outside a spec worktree | S (5 files, ~90 lines) | afk | none |
