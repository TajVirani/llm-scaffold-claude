# Data model: Worktree provisioning

Spec: [spec.md](spec.md) · Placement: feature-workflow

## Summary

| Part | Kind | Classification | Owning module |
| --- | --- | --- | --- |
| `worktree-setup.sh` | interface | create | feature-workflow |
| Slot | entity | create | feature-workflow |
| Copy list (`.worktreeinclude`) | entity | create | feature-workflow (read), the project (owned) |
| Isolation values (`WF_SLOT`, `WF_INSTANCE`, `WF_PORT_OFFSET`, `WF_MAIN_ROOT`, `WF_SPEC_ROOT`) | interface | create | feature-workflow |
| Workflow settings `worktree_setup`, `services_up`, `services_down` | field | extend | feature-workflow |
| `spec-worktree.sh create` / `remove` | interface | extend | feature-workflow |
| `run-toolchain.sh` | interface | extend | feature-workflow |
| Path constants for the slot file and the copy list | field | extend | lib |
| `GI_ENTRIES` and this repo's `.gitignore` block | field | extend | installer |
| Step files, launching reference, agent definitions | interface | refactor | feature-workflow, agents |
| Shipped rules text, profile template, standards coverage | interface | extend | project-setup, project-standards |
| `check-worktree-scope.sh`, `worktree-write-guard.sh` | interface | unchanged | feature-workflow, hooks |

## Entities

### Slot (create)

The number a spec holds while its **Spec worktree** exists, used to keep its app and services apart from the main checkout and from other specs.

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| slot | integer, 1 or more | yes | The lowest number no other spec worktree of the same repository holds (CAP-NEW-worktree-setup). The main checkout is always 0 and holds no file. | create |

Stored as one line in a gitignored file inside the spec worktree's workflow folder. Its path is a constant in `workflow-paths.sh` and a line in `GI_ENTRIES`.

**State transitions:**

| From | Event | To | Guard |
| --- | --- | --- | --- |
| none | worktree setup of a spec worktree | held | no slot file yet; takes the lowest free number |
| held | worktree setup run again (a resume) | held | keeps the number already in the file |
| held | the spec worktree is removed | none | the file goes with the worktree |

**Invalid states ruled out:** an agent worktree or scratch worktree never holds a slot of its own; it reads its spec worktree's. Still representable: two sessions creating two spec worktrees at the same instant could take the same number; accepted, because spec worktrees are created by one orchestrator at a time and a clash shows at once as a port already in use.

### Copy list (create)

`.worktreeinclude` at the repository root: one gitignore-style pattern per line, `#` comments and blank lines ignored.

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| pattern | string | no | A file is copied only when it matches a pattern and git ignores it in the main checkout (CAP-NEW-worktree-setup). A matching tracked file is never copied. A match that is a symlink is copied as the file it points to. | create |

The file is tracked by the project. An absent or empty file copies nothing.

### Workflow settings (extend)

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| `worktree_setup` | string, one shell command | no | Default `""`. Run with `bash -c` in the new worktree after the copy, with the isolation values exported. Non-zero exit fails worktree setup. | create |
| `services_up` | string, one shell command | no | Default `""`. Run in the spec worktree before a `test` or `e2e` key that will run. Must be safe to run when the services are already up. Non-zero exit fails the toolchain run. | create |
| `services_down` | string, one shell command | no | Default `""`. Run in the spec worktree when it is removed. A non-zero exit is reported and does not stop the removal. | create |
| `task_review`, `main_branch`, `pr_template` | as today | no | as today | unchanged |

## Interfaces

### `worktree-setup.sh` (create)

Run from the spec checkout, or from the main checkout for `setup`. Progress and command output go to stderr; stdout carries only the lines named here.

| Call | Does | stdout |
| --- | --- | --- |
| `agent <name> <branch> [--cwd <dir>]` | Adds the agent worktree `<name>` on a new `<branch>` off the spec branch, or reuses one that exists, then sets it up. | `worktree <absolute path>` |
| `scratch <name> [<commit>] [--cwd <dir>]` | Adds a detached worktree `<name>` at `<commit>` (default `HEAD`) beside the agent worktrees, then sets it up. | `worktree <absolute path>` |
| `setup <worktree path>` | Sets up a worktree that already exists: takes or reads the slot, copies the copy list from the main checkout, runs `worktree_setup`, runs the link check. Safe to run again. | nothing |
| `check <worktree path>` | The link check alone: fails when any symlink in the worktree, tracked or not, resolves into the main checkout or another worktree of the same repository and outside this worktree. Dependency folders are searched too. | nothing; each bad link on stderr |
| `env <worktree path>` | Prints the isolation values for that worktree. | `export WF_SLOT=…` and the other four, one per line |
| `remove <name> [--force] [--cwd <dir>]` | Removes an agent or scratch worktree. `--force` only for a scratch worktree. | `removed worktree <path>` |

Exit: 0 done; 1 refused or a check failed (a bad link, a failing `worktree_setup`), with the reason; 2 usage or environment error.

Isolation values: `WF_SLOT` (the number), `WF_INSTANCE` (`s<NNN>`, the spec folder's number, lowercase letters and digits only), `WF_PORT_OFFSET` (slot × 100), `WF_MAIN_ROOT` (the main checkout), `WF_SPEC_ROOT` (the spec worktree). In the main checkout they are `0`, `main`, `0`, and both roots the main checkout.

### `spec-worktree.sh` (extend)

- `create`: after the worktree exists, on the first run and on a re-run, calls `worktree-setup.sh setup`. Its stdout stays `worktree <path>` and `baseline <sha>`. A setup failure exits 1 after the worktree is registered; running `create` again finishes it.
- `remove`: after its refusals pass and before the worktree goes, runs `services_down` in the spec worktree with the isolation values.

### `run-toolchain.sh` (extend)

- Runs the link check on `--cwd` first; a bad link is exit 1 with the links named, before any key runs.
- Exports the isolation values of `--cwd`'s spec worktree to every key's command.
- Before the first `test` or `e2e` key that will actually run (not skipped, not served from reuse), runs `services_up` in the spec worktree. Its result is recorded in the evidence like a key. A failure fails the run and the keys that need services are not run.
- Never runs `services_down`: services stay up for the spec until it is removed.

## Migrations

None. A project already using the workflow keeps working with no settings; this repository adds one line to its `.gitignore` block.
