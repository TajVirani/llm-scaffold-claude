#!/usr/bin/env bash
# File: Fixture builder for the Tracker adoption suite: a project already under way, about to move onto tracker numbering.
#   Sourced after lib/common.sh, fixtures/pr-template.sh, fixtures/done-folder.sh (done_render, step_marker) and
#   fixtures/fake-trackers.sh (TRACKER_*, tracker_settings); defines variables and functions only. bash 3.2 compatible.
# Provides:
#   adoption_project DIR BARE   builds the project in DIR, checked out on main, with GitLab tracker settings and an origin
#                               remote on GitLab whose pushes go to the local bare repository BARE (main pushed there):
#                                 - 012-alpha and 014-gamma, done, in the Done folder, each with a backlog list; the shelf,
#                                   the retrospective, capabilities.md and the review lessons point at 012-alpha, and
#                                   012-alpha's list names the draft spec it seeded;
#                                 - 015-delta, a draft in the main checkout, untracked as discovery leaves it, with its own
#                                   backlog list and shelf file, step 0.1.6;
#                                 - 013-beta, past 1.1: its folder only on spec/013-beta, pushed to BARE, checked out in the
#                                   spec worktree .workflow/.spec-worktrees/013-beta at step 3.16, with task files and
#                                   task records naming task/013-beta/ branches and no issue: T1 done, T2 pending, T3
#                                   split-out;
#                                 - 016-epsilon, mid-wave: its folder on spec/016-epsilon in its spec worktree, step 3.4,
#                                   with a live task worktree .workflow/.worktrees/s016_t1 inside it.
#                               The task records carry the fields the tasks.md validator requires, so set-task can write
#                               them.
#   ADOPTION_BETA_WT, ADOPTION_EPSILON_WT, ADOPTION_EPSILON_TASK_WT   those worktrees (set by adoption_project)
#   adoption_old_refs ROOT      prints each line under ROOT/.workflow, outside initiatives/ and the worktree
#                               folders, that still names a spec or backlog list by its path before adoption: 012-alpha or
#                               014-gamma under specs/done/, 015-delta under specs/ or ../, any of the three lists; a path
#                               ending a sentence counts, while link text and prose naming a spec are not paths
# shellcheck disable=SC2034  # the variables are read by the suite that sources this file

adoption_main_manifest() {
  printf '=== .gitignore\n%s\n' "$TRACKER_GITIGNORE"
  cat <<'EOF'
=== .workflow/GLOSSARY.md
# Glossary
=== .workflow/capabilities.md
# Capabilities

| Id | Capability | Spec |
| --- | --- | --- |
| CAP-001 | Alpha feature | [012-alpha](specs/done/012-alpha/spec.md) |
| CAP-002 | Gamma feature | [014-gamma](specs/done/014-gamma/spec.md) |
=== .workflow/review-lessons.md
# Review lessons

```yaml
lessons:
  - id: RL-001
    symptom: "A script opens a path from its arguments without checking it exists."
    paths: ["src/**"]
    origin_spec: .workflow/specs/done/012-alpha
    date: 2026-10-30
```
=== .workflow/decisions/retrospectives/012-alpha.md
---
spec: .workflow/specs/done/012-alpha
verdict: accepted
---

# Retrospective: 012-alpha

Spec: [spec.md](../../specs/done/012-alpha/spec.md)
=== .workflow/deferred/alpha-shelf.md
---
origin_spec: .workflow/specs/done/012-alpha
created: 2026-10-29
---

# Alpha follow-up

Shelved from [012-alpha](../specs/done/012-alpha/spec.md).
=== .workflow/specs/done/012-alpha/spec.md
---
status: done
spec_branch: spec/012-alpha
---

# Alpha feature

Design log: [design-log.md](design-log.md) · Glossary: [GLOSSARY.md](../../../GLOSSARY.md) · Backlog: [012-alpha.md](../../work-backlog/012-alpha.md)
=== .workflow/specs/done/012-alpha/tasks.md
---
tasks:
  - id: T1
    title: "Alpha"
    status: done
---

# Tasks
=== .workflow/specs/done/012-alpha/design-log.md
# Design log: Alpha feature

- Folder: .workflow/specs/done/012-alpha
=== .workflow/specs/done/014-gamma/spec.md
---
status: done
spec_branch: spec/014-gamma
---

# Gamma feature

Glossary: [GLOSSARY.md](../../../GLOSSARY.md)
=== .workflow/specs/done/014-gamma/tasks.md
---
tasks:
  - id: T1
    title: "Gamma"
    status: done
---

# Tasks
=== .workflow/specs/work-backlog/012-alpha.md
- [promoted] B1 requirement (5.9): Delta follow-up, now .workflow/specs/015-delta. Evidence: .workflow/specs/done/012-alpha/design-log.md
=== .workflow/specs/work-backlog/014-gamma.md
- [open] B1 bug (3.4): Retry the flaky fetch. Evidence: tests/fetch.sh:12
EOF
}

adoption_draft_manifest() {
  cat <<'EOF'
=== .workflow/specs/015-delta/spec.md
---
status: draft
spec_branch: ""
---

# Delta feature

Glossary: [GLOSSARY.md](../../GLOSSARY.md) · Seeded from [012-alpha's backlog](../work-backlog/012-alpha.md)
=== .workflow/specs/work-backlog/015-delta.md
- [open] B1 decision (0.1.4): Pick the export format. Evidence: .workflow/specs/015-delta/spec.md
=== .workflow/deferred/delta-shelf.md
---
origin_spec: .workflow/specs/015-delta
created: 2026-11-01
---

# Delta follow-up

Shelved from [015-delta](../specs/015-delta/spec.md).
EOF
}

adoption_beta_manifest() {
  cat <<'EOF'
=== .workflow/specs/013-beta/spec.md
---
status: in-progress
spec_branch: spec/013-beta
---

# Beta feature

Glossary: [GLOSSARY.md](../../GLOSSARY.md) · Tasks: [tasks.md](tasks.md)
=== .workflow/specs/013-beta/tasks.md
---
tasks:
  - id: T1
    title: "Build"
    status: done
    capability: CAP-NEW-beta
    depends_on: []
    touches_core: false
    work_type: null
    file: tasks/T01-build.md
    branch: task/013-beta/T01-build
  - id: T2
    title: "Wire"
    status: pending
    capability: CAP-NEW-beta
    depends_on: [T1]
    touches_core: false
    work_type: null
    file: tasks/T02-wire.md
    branch: task/013-beta/T02-wire
  - id: T3
    title: "Export"
    status: split-out
    capability: CAP-NEW-beta
    depends_on: []
    touches_core: false
    work_type: null
    file: tasks/T03-export.md
    branch: task/013-beta/T03-export
---

# Tasks
=== .workflow/specs/013-beta/tasks/T01-build.md
# T01: Build
=== .workflow/specs/013-beta/tasks/T02-wire.md
# T02: Wire
=== .workflow/specs/013-beta/tasks/T03-export.md
# T03: Export
=== .workflow/specs/013-beta/design-log.md
# Design log: Beta feature

- Folder: .workflow/specs/013-beta
EOF
}

adoption_epsilon_manifest() {
  cat <<'EOF'
=== .workflow/specs/016-epsilon/spec.md
---
status: in-progress
spec_branch: spec/016-epsilon
---

# Epsilon feature
=== .workflow/specs/016-epsilon/tasks.md
---
tasks:
  - id: T1
    title: "Wave"
    status: in-progress
    capability: CAP-NEW-epsilon
    depends_on: []
    touches_core: false
    work_type: null
    file: tasks/T01-wave.md
    branch: task/016-epsilon/T01-wave
---

# Tasks
=== .workflow/specs/016-epsilon/tasks/T01-wave.md
# T01: Wave
EOF
}

# adoption_spec_worktree DIR NAME MANIFEST_FN STEP : spec/NAME forked from main and checked out in its spec worktree,
#   holding the folder MANIFEST_FN renders, committed, with the step marker at STEP; prints the worktree path.
adoption_spec_worktree() {
  local p=$1 name=$2 wt=$1/.workflow/.spec-worktrees/$2
  git -C "$p" worktree add -q "$wt" -b "spec/$name" main
  "$3" | done_render "$wt"
  git_commit_all "$wt" "docs(workflow): spec $name"
  step_marker "$wt/.workflow/specs/$name" "$4"
  printf '%s' "$wt"
}

adoption_project() {
  local p=$1 bare=$2
  git_init_repo "$p"
  copy_agents "$p"
  adoption_main_manifest | done_render "$p"
  tracker_settings "$p" gitlab
  git -C "$p" remote add origin "$TRACKER_ORIGIN_GITLAB"
  git init -q --bare "$bare"
  git -C "$p" config remote.origin.pushurl "$bare"
  git_commit_all "$p" "fixture: adoption project"
  env GIT_ALLOW_PROTOCOL=file git -C "$p" push -q -u origin main
  ADOPTION_BETA_WT=$(adoption_spec_worktree "$p" 013-beta adoption_beta_manifest 3.16)
  env GIT_ALLOW_PROTOCOL=file git -C "$ADOPTION_BETA_WT" push -q -u origin spec/013-beta
  ADOPTION_EPSILON_WT=$(adoption_spec_worktree "$p" 016-epsilon adoption_epsilon_manifest 3.4)
  ADOPTION_EPSILON_TASK_WT=$ADOPTION_EPSILON_WT/.workflow/.worktrees/s016_t1
  git -C "$ADOPTION_EPSILON_WT" worktree add -q "$ADOPTION_EPSILON_TASK_WT" -b task/016-epsilon/T01-wave
  adoption_draft_manifest | done_render "$p"
  step_marker "$p/.workflow/specs/015-delta" 0.1.6
}

adoption_old_refs() {
  grep -rnE --exclude-dir=initiatives --exclude-dir=.spec-worktrees --exclude-dir=.worktrees \
    "(specs/done/(012-alpha|014-gamma)|(specs|\.\.)/015-delta)([^A-Za-z0-9._-]|\.([^A-Za-z0-9]|$)|$)|work-backlog/(012-alpha|014-gamma|015-delta)\.md" \
    "$1/.workflow" 2>/dev/null
}
