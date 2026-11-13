---
status: done
baseline_revision: "0900278de2857d40567e08e21a3d9c2ba10f94b0"
spec_branch: "spec/00016-per-run-handoffs"
impl_base_revision: "f297896c689ad954ae7df6e9fbdbb8b336bdd4d3"
light_path: false
followup_review_recommended: false
deferred: [".workflow/deferred/browser-suite.md"]
tracker_issue: ""
budget: {max_tasks: 10, max_changed_files: 30}
---

# Per-run session handoffs

## Why

A session that runs in a spec worktree writes its session handoff into `.workflow/.handoff/` at the main checkout, outside the checkout it works in. That breaks the rule that a run does not write files to main, and it stops an unattended run. The file name is the spec folder or a topic, so two agents working at once overwrite each other's handoff, and the session-start offer does not say which handoff belongs to which checkout. The stakeholder runs several agents at once. Any run, wherever it works, must be able to leave a session handoff that only it owns and that the run continuing its work can find and load, without the file ever entering git, in existing installs as well as new ones.

## Capabilities

- **CAP-015** Per-run session handoffs
  - **intent:** A session writes its session handoff into its own checkout under a name no other run uses, and a fresh session resumes from the one handoff it is given.
  - **success:** From a spec worktree the handoff skill's commands create the file under that worktree's `.workflow/.handoff/` and nothing in the main checkout; `git status --porcelain` shows no handoff file with or without the install.sh ignore block; two handoffs for the same spec made in the same second have different names; the session-start offer lists the session's own checkout first and names each handoff's path.

## Constraints

- The handoff skill stays self-contained: `standalone-skills` may depend on no module, so its commands stay inline ([.workflow/rules.md](../../rules.md) Ownership).
- The folder stays `.workflow/.handoff/` (`WF_HANDOFF`); the install.sh ignore block and this repo's `.gitignore` keep their entry.
- The session-start offer stays inside its size cap and still says not to resume unasked.
- A handoff already in a main checkout's `.workflow/.handoff/` under an old name is still listed and can be resumed.

## Non-goals

- The loop in which an agent hands off, resets its context and reloads by itself. An outer orchestrator will start the fresh session and name the handoff path; this spec only makes that possible (design-log D2).
- Moving the handoff skill's main-checkout lookup onto `wf_main_root`: shelved in [.workflow/deferred/main-checkout-resolver.md](../../deferred/main-checkout-resolver.md).
- Changing what a handoff holds, beyond what its location and name need.

## Success signal

A session working in a spec worktree hands off and the main checkout is untouched; a second agent handing off on the same spec at the same moment leaves a second file; neither file shows in `git status`, even where the install.sh ignore block is missing. A fresh session started in that worktree sees its handoffs first, each with its path, and resumes the one it is given. The objectives and journeys are in [verification-plan.md](verification-plan.md).

## Links

- Codebase map: [codebase-map.md](codebase-map.md)
- Design log: [design-log.md](design-log.md)
- Data model: [data-model.md](data-model.md)
- Verification plan: [verification-plan.md](verification-plan.md)
- Tasks: [tasks.md](tasks.md)

## Known gaps

- Gate skipped (3.10 browser suite): this repo has no browser suite; every journey is a harness check. Handoff: [.workflow/deferred/browser-suite.md](../../deferred/browser-suite.md)
