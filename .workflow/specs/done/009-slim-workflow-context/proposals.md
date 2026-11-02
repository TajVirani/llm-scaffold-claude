# Proposals: Slim the workflow context

Spec: [spec.md](spec.md) · Report: [report.md](report.md)

Status values: `proposed` · `approved` · `modified` · `rejected`

## Capabilities

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | `.workflow/capabilities.md` | CAP-012 \| Lean workflow load: a feature-workflow session loads the router, `references/conventions.md` and the one step file its step needs (`references/launching.md` only at a launch), and the term list in place of the whole glossary; a new-feature start loads at most 45,000 bytes and an implementation resume at most 55,000 (`wc -c`, hook output included), and `lint/workflow-load-size` fails above either \| [.workflow/specs/done/009-slim-workflow-context](specs/done/009-slim-workflow-context/spec.md) | Without it, 0.3.1 would not find this capability when a later request touches the router or the step-file split, and could re-inline rules or grow the start load without seeing the limits it breaks. | spec.md § Capabilities (CAP-012) | approved | |

## Decisions

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P2 | `.workflow/decisions/adr/0004-workflow-load-budget.md` | New ADR: feature-workflow is a router plus `references/` and per-step step files, held to a 45,000-byte new-feature start and a 55,000-byte implementation resume that count the term list and are enforced by `lint/workflow-load-size`. When the lint goes over, trim or move text to the step that needs it; raise a limit only by a new decision. Alternatives weighed: one SKILL.md with progressive-loading keys (never read by the host), a token count (needs a new dependency), limits without the term list. | Without it, the first change that pushes the start load over (it is at 44,733 of 45,000, about five glossary terms of room) is likely met by raising the limit or by moving a rule back into the router, undoing the split; the ADR says to trim instead and why the term list is counted. | design-log D14, D15, D19, D21; handoff open point on the load margin | approved | |

## Pitfalls

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P3 | `.workflow/decisions/pitfalls.md` | **Leave no copy of a rule in the step file it moved out of.** What happened: the Claude launch rule and the agent-worktree confinement rule moved to `references/launching.md`, but verification-setup 1.2/1.3 kept its own copy beside a new pointer, so the rule had two homes (F3, medium, fixed in rework 1). Where: `.agents/skills/feature-workflow/modules/verification-setup.md`. Spec: .workflow/specs/done/009-slim-workflow-context. Prevented by: none yet (`lint/shared-rule-homes` checks only its listed marker lines). | Without it, the next split (slimming another skill is planned follow-on work) checks only the marker lines the lint knows and misses a paraphrased copy, as here. | finding F3 | approved | |

## Profiles

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P4 | `.workflow/profiles/shell-scripts.md` § Language and style rules | replace: "- Test syntax: match the file being edited; new files use `[[ ]]`. Never convert a file for style. No line-length limit." -> "- Test syntax: match the file being edited; new files use `[[ ]]`. A file is new when it is absent at the spec's `baseline_revision`, even if an earlier task or the Phase 1 harness added it. Never convert a file for style. No line-length limit." | Without it, a mini-review compares against the task branch, treats a file the spec created as an edit and asks for `[ ]`, as T1's first round did; review then has to reverse it (F1). | finding F1; T1 mini-review round 1 | approved | |
