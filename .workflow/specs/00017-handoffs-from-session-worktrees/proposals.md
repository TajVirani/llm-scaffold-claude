# Proposals: Handoffs found from session worktrees

Spec: [spec.md](spec.md) · Report: [report.md](report.md)

Status values: `proposed` · `approved` · `modified` · `rejected`

## Capabilities

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | `.workflow/capabilities.md` § Capabilities, row CAP-015 | replace: "the session-start offer lists the session's own checkout's handoffs first, then the other checkouts' by absolute path" -> "the session-start offer lists the session's own checkout's handoffs first, then, from a spec worktree, the main checkout's, and from any other checkout (the main checkout or a session worktree), every other worktree's, by absolute path; Resume first moves the session into the checkout the handoff sits in"; and append the link [.workflow/specs/00017-handoffs-from-session-worktrees](specs/00017-handoffs-from-session-worktrees/spec.md) to its spec column | Without it, 0.3.1 and the review lenses read CAP-015 as the old rule and would flag the session-worktree listing as unasked-for behaviour | spec.md § Capabilities | approved | |

## Pitfalls

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P2 | `.workflow/decisions/pitfalls.md` | New entry "Lint a task's tests with the test-harness profile too": What happened: T1 (work type shell-scripts) changed `tests/*.sh`; its toolchain linted only the shell-scripts paths, so a shellcheck SC2034 warning in the new test reached the merged spec branch and failed the 3.9 gate, costing a fix round. Where: implementation-setup 3.1 classification, run-toolchain.sh per-task lint. Spec: .workflow/specs/00017-handoffs-from-session-worktrees. Prevented by: none yet (brief the implementer to run the test-harness lint when its task changes `tests/`, or let run-toolchain.sh lint changed files by the profile that owns each path) | Without it, the next task whose work type differs from its test files' repeats the same late 3.9 failure | 3.9 gate failure, design-log Merge route entry | approved | |
