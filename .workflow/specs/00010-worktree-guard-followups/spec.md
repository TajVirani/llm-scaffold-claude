---
status: draft # draft | ready-for-dev | in-progress | in-review | done | blocked. Changed only by scripts/status-transition.sh.
baseline_revision: "" # full SHA of the commit the work starts from; "" until captured, then never overwritten
spec_branch: "" # spec/NNN-slug, created off main at 1.1 (0.3.20 on the light path); "" until then
impl_base_revision: "" # full SHA of the spec-branch tip when Phase 3 starts (3.1); "" until then, never overwritten
light_path: false # true once the 0.3.20 light-path test passes
followup_review_recommended: false # true when triage recommends another review pass after this one
deferred: [] # repo-relative paths of the .workflow/deferred/ files this spec wrote, e.g. .workflow/deferred/csv-export.md
origin: 006-result-file-guard-disc-003.md # filename of the work-backlog item this spec was seeded from; the item is deleted after discovery
---
# Worktree guard and upgrade follow-ups

## Why

Origin: work items 006-result-file-guard-disc-003, -005, -007, -008, -009 and -010, combined at 006 sign-off. Spec 006 left the worktree guard and the installer upgrade working, with loose ends:
- the guard allows a write when it cannot confine the agent (an unparsable header, or a named worktree that is missing), against the profile's fail-closed rule;
- any `$` blocks a read chain, even a quoted one;
- the guard's messages still say "task worktree";
- three upgrade re-run checks ignore the exit code;
- `assetlist.md` still describes the removed isolation launch;
- the shipped settings let an in-place `yq -i` frontmatter rewrite through without a prompt.

Agents and maintainers who rely on the guard and the installer are affected. After this change the guard fails closed where it cannot confine, its messages and records match what 006 built, and the settings and tests no longer let these slips through.

## Capabilities

- **CAP-### or CAP-NEW-<slug>** <short name>
  - **intent:** <One sentence: user or system can do X to achieve Y. What, not how.>
  - **success:** <A criterion a test or a real demonstration can decide.>

## Constraints

- <A non-negotiable that rules out some design. If it rules nothing out, delete it.>

## Non-goals

- <An explicit out-of-scope item. At least one. Work that is shelved rather than refused goes to .workflow/deferred/ and is listed in the `deferred` frontmatter.>

## Success signal

<One or two sentences describing the moment the world has changed, concrete enough to test or demonstrate. The testable objectives and journeys that prove it live in verification-plan.md (0.5.1).>

## Assumptions

- <A call made without direct confirmation from the stakeholder.>

## Open Questions

- <A gap that needs a human decision, phrased so a human can answer it. Must be empty before 0.6 sets ready-for-dev.>

## Links

- Codebase map: [codebase-map.md](codebase-map.md)
- Design log: [design-log.md](design-log.md)
- Data model: [data-model.md](data-model.md)
- Verification plan: [verification-plan.md](verification-plan.md)
- Tasks: [tasks.md](tasks.md)
- Proposals: [proposals.md](proposals.md)
- Report: [report.md](report.md)

## Known gaps

- None.
