---
name: issue-tracking
description: File and move a spec's and its tasks' tracker issues on the project's GitLab or GitHub tracker. Use when a feature-workflow step calls issue-tracker.sh, or when a tracker issue's title, body, parent or issue flow label needs fixing by hand.
---

# Issue tracking

A **Tracker issue** is the issue a spec or a task is filed as on the project's GitLab or GitHub tracker. Each moves through the project's **Issue flow**: three labels, one each for backlog, in progress and done. The settings live in `.workflow/issue-tracking.yaml`: `issue_tracker` (`gitlab`, `github` or `none`) and `issue_flow.backlog`, `issue_flow.in_progress` and `issue_flow.done`.

## Tracker script

`scripts/issue-tracker.sh [--cwd <dir>] <command>` is the one place the workflow talks to the tracker about issues. It uses glab for GitLab and gh for GitHub. The `origin` remote picks the host, and it must match the host the settings name.

| Command | What it does | When the workflow calls it |
| --- | --- | --- |
| `create-spec` | Opens the spec's issue with a placeholder title, an empty body and the backlog label, and prints its URL. | 0.1.1, through `feature-workflow/scripts/next-spec-number.sh`. The issue number names the spec folder. |
| `fill <issue-url> <spec.md>` | Sets the issue title from the file's first `# ` heading, after any frontmatter, and the body to the whole file. The body goes as a file, so it arrives unchanged. | 0.3.19, at ready-for-dev (0.6 on the full path, 0.3.20 on the light path) and at sign-off. |
| `create-task <spec-issue-url> <task-file>` | Opens the task's issue under the spec's issue, titled from the task file's heading, its body the task file, with the backlog label, and prints its URL. GitHub: a sub-issue. GitLab: a child task. When GitLab refuses the child task, it opens an issue linked `relates_to` the spec's issue instead and says so on stderr. | 2.5 and 0.3.20, one call per task. |
| `move <issue-url> backlog\|in_progress\|done` | Removes the other two flow labels and adds this one. `done` also closes the issue; `in_progress` reopens a closed one. | `in_progress` at 3.1 (the spec) and 3.3 (a task). `done` at 3.16 (a merged task) and 5.8 (the spec, on a local merge). `in_progress` again at 3.9, 3.11 and 4.7, when a task goes back to work. |

Output and exits:

- With no tracker set up (no settings file, or `issue_tracker: none`), every command prints `skipped: no tracker`, calls neither CLI and exits 0. Steps call it the same way either way.
- Exit 1: the tracker failed, for example the network or the login. Stderr gives the CLI's message and what the script was doing. Nothing is printed on stdout.
- Exit 2: a usage error; bad settings (an unknown `issue_tracker`, flow labels missing or not distinct, or a host the `origin` remote is not on); a file that cannot be read or has no `# ` heading; or the host's CLI not installed.
