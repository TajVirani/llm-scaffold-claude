<!--
Module: discovered-work (shared). Nodes 00.21-00.29: the scope-creep guardrail (D56), the work backlog (D57) and the size-budget halt (D58).
Entered from: verification-setup (1.2-1.3 discovered work), task-breakdown (2.1 discovered work, 2.6 task count over budget), implementation-orchestrator (a non-empty `discovered_work[]` or a `discovered-work` status from implementation or integration, a profile-mini-review `out_of_scope_noticed` entry, 3.15 changed files over budget), review-triage (a `discovered-work` finding at 4.4), and SKILL.md on resume of a spec `blocked` with a `discovered work:` or `size budget:` condition.
Exits to: the caller at the node the block interrupted (00.28); questioning-loop at 0.3.8 with status draft (00.24 Yes, 00.29 Re-scope); stays blocked until a human resolves the condition (00.24 No).
Sources: first-party. PLAN/decision-flow-reference.md "Discovered work: the scope-creep guardrail (00.21-00.29)", "Status" (legal transitions), "Per-feature files" (.workflow/specs/work-backlog/, design-log.md, spec.md budget); PLAN/decision-flow.mermaid subgraph DiscWork and its edges; assetlist D16, D56, D57, D58, D68. Host question UI (AskUserQuestion on Claude Code, numbered chat round on Codex) as in modules/questioning-loop.md 0.3.11. Phase 0 framing keeps the 0.3.16-0.3.17 deferred path (D56).
-->

# Discovered work (00.21–00.29)

Work found outside the agreed scope while a feature is under way is **never** folded into the current `spec.md` or `tasks.md`. A new requirement, a bug found along the way, a needed refactor, scope spreading into another module, a decision nobody in the session can answer, or a crossed size budget all stop here for one human decision. You run in the main session; agents only report (`discovered-work` return status or finding kind) and never fix.

Not for Phase 0: an out-of-scope item raised while framing goes through the scope gate 0.3.16–0.3.17 to `.workflow/deferred/` ([deferred-handoff](deferred-handoff.md)).

`ST` below is `.agents/skills/feature-workflow/scripts/status-transition.sh`; type the full path every time (D36). `NNN-slug` is the current spec.

## What the caller hands you

Before loading this module, the caller holds:

| Field | Discovered work | Size budget |
| --- | --- | --- |
| Origin node | the node it was found at (1.2, 1.3, 2.1, 3.2, 3.4, 3.7, 4.4, ...) | 2.6 or 3.15 |
| Found by | the agent and its return, or the reviewer finding `F<n>` | `budget-check.sh` |
| Problem | one or two sentences | which limit, the count and the limit |
| Evidence | `path:line`, a failing test with its output, or the agent's return quoted | the `budget-check.sh` JSON |
| Kind | `bug` \| `requirement` \| `refactor` \| `scope-expansion` \| `decision` | `budget-split` (used only if you split) |

Keep these in the session until 00.28: the `--step 00.21` call below overwrites the step marker, so the origin node lives here and, once decided, in the design-log entry.

## 00.21 Block

1. Pick a slug: two to four lowercase kebab-case words naming the problem (`stale-cache-on-retry`).
2. Block the spec. The script keeps the prior status in `.step` as `blocked_from`.

   ```bash
   ST status .workflow/specs/NNN-slug blocked --step 00.21 --blocked "discovered work: <slug>"
   # size budget:
   ST status .workflow/specs/NNN-slug blocked --step 00.21 --blocked "size budget: <what>"   # e.g. "size budget: 12 tasks, max_tasks 10"
   ```

   Exit 2 (illegal transition, e.g. the spec is already `blocked`): another report is already being handled; add this one to the same 00.22 presentation instead of blocking again.
3. **Mid-wave rule (Phase 3).** Tasks already running finish and pass through their gates. Start no new launch, integration batch or wave until the stakeholder answers 00.22. A further `discovered-work` return that arrives while you wait joins the same presentation.

Done when the spec is `blocked` with the condition and nothing new is launching.

## 00.22 Present

Tell the stakeholder, in this order:

1. **Problem**, in plain words, without the implementation approach.
2. **Evidence**: the `path:line`, the failing test and its output, or the agent's return quoted.
3. **Assessment**: **blocker** or **can be solved later**. It is a blocker when a capability's success line or a journey in `verification-plan.md` cannot be met without it, or when continuing would build on something known to be wrong. Otherwise it can be solved later; name the capability or journey that is unaffected.
4. **Recommendation** with its reason.

Then ask one question whose options are the routes, recommended option first and marked "(Recommended)", worded so "yes" accepts the recommendation:

| Condition | Options (each maps to a node) |
| --- | --- |
| `discovered work:` | Blocker, go to discovery (00.24 Yes) · Blocker, keep the spec blocked until I resolve it (00.24 No) · Not a blocker, tackle it as a next feature (00.25 Yes) · Not a blocker, ignore it (00.25 No) |
| `size budget:` | Split: remaining work to the backlog (00.29 Split) · Re-scope through discovery (00.29 Re-scope) · Approve the overrun for this spec (00.29 Approve) |

- **Claude Code:** AskUserQuestion, one question per report, all reports in one call.
- **Codex, or chat:** one message per round, then wait:

  ```text
  Q1 - Discovered work: <slug> (found at <origin node> by <agent>)
  Problem: <...>  Evidence: <...>
  Assessment: <blocker | can be solved later>, because <...>
  Recommended: <route> (<reason>)
  Or: <the other routes>
  ```

If the stakeholder's answer contradicts your assessment, follow the answer; it is their call (00.23).

## 00.23-00.24 Blocker

**00.24 Go to discovery? Yes.** Log the decision (see [Record the decision](#record-the-decision)), then move the spec back to discovery and load [questioning-loop](questioning-loop.md) with the problem as the first frontier question:

```bash
ST status .workflow/specs/NNN-slug draft --step 00.24
```

Tasks still running in Phase 3 finish their gates first; record their results through the orchestrator as usual. The rest of the build is re-planned after discovery (0.3.20 or 0.6, then Phases 1–2).

**00.24 No.** Log the decision. The spec stays `blocked` with its condition; there is no route out until a human resolves it. Stop and tell the stakeholder how to resume: resolve the condition, then ask to continue this spec; the router brings it back here for [00.28](#0028-resume).

## 00.25-00.27 Not a blocker

**00.25 Tackle it as the next feature? No.** Append the one-line dismissed record to `design-log.md` (shape "Dismissed item" in [../assets/design-log.md](../assets/design-log.md)), then 00.28.

**Yes → 00.26 Write the work item** (00.27 `.workflow/specs/work-backlog/<NNN-slug>-disc-<###>.md`; D57):

1. Number it: `###` is the highest existing number for this origin spec plus one, three digits (`001` when there are none):

   ```bash
   ls .workflow/specs/work-backlog/NNN-slug-disc-*.md 2>/dev/null | sed -E 's/.*-disc-([0-9]+)\.md$/\1/' | sort -n | tail -1
   ```

2. Set the step, then write the file from [../assets/work-item.md](../assets/work-item.md) with Write (`mkdir -p .workflow/specs/work-backlog` first). On Codex, run `.agents/skills/feature-workflow/scripts/check-write.sh --cwd "$PWD" --path <file>` before the write and write only on exit 0.

   ```bash
   ST step .workflow/specs/NNN-slug 00.26
   ```

   - Frontmatter: `origin_spec: .workflow/specs/NNN-slug`, `origin_step: "<origin node>"` (quoted), `discovered_at: <today>`, `status: open`, `kind: <kind>`. No `promoted_to`.
   - Body: Problem, Evidence, Why not a blocker, Suggested scope and size (compared with the `## Size budget` defaults in `.workflow/rules.md`), Links. Delete the template comment.
3. Validate with the yq command in the template's comment; it must print `true`.
4. Log the decision with a link to the item, then 00.28.

The item waits for this spec's sign-off, where 5.9 offers it as the next feature.

## 00.29 Size budget crossed

- **Split.** The work this spec still needs for its capabilities' success lines stays; the remaining `pending` tasks leave the spec (D68). A task that stays may not depend on one that leaves.
  1. Write one work item per piece through [00.26](#0025-0027-not-a-blocker) with `kind: budget-split`; its **Links** names the task ids it takes over (`- Split out of: .workflow/specs/NNN-slug tasks T<n>, ...`).
  2. Mark each of those tasks, one call per task:

     ```bash
     ST set-task .workflow/specs/NNN-slug T<n> --status split-out --step 00.29
     ```

  3. Log the decision, then 00.28. The orchestrator never launches a `split-out` task.

  If what is left no longer meets a capability's success line, this is a re-scope, not a split.
- **Re-scope.** Log the decision (ending the entry with `Outcome: loop back (00.29 budget re-scope)`, see [Record the decision](#record-the-decision)), then return to discovery as 00.24 Yes does, with the budget crossing and the proposed reduction as the first frontier question. The step is `00.29`, so the questioning loop seeds from the budget crossing:

  ```bash
  ST status .workflow/specs/NNN-slug draft --step 00.29
  ```

- **Approve the overrun.** Raise the budget for this spec only, then 00.28:

  ```bash
  ST step .workflow/specs/NNN-slug 00.29
  ```

  Edit the `budget:` line in the `spec.md` frontmatter (Edit, never Bash; leave `status` and `blocked_condition` alone) to the agreed value, and append the "Approved budget overrun" record to `design-log.md` with the stakeholder's reason verbatim. On Codex, run `check-write.sh --cwd "$PWD" --path .workflow/specs/NNN-slug/spec.md --proposed <file with the new content>` first.

## 00.28 Resume

Read the status held before the block and restore it:

```bash
yq '.blocked_from' .workflow/specs/NNN-slug/.step
ST status .workflow/specs/NNN-slug <blocked_from> --step 00.28
```

Then hand back to the caller at the origin node; the current work continues unchanged. In Phase 3 the orchestrator resumes its wave (pending launches start again). On exit 1 or 2, stop and report; never retry with another `--step`.

## Record the decision

Every ruling except 00.25 No appends one **Discovered work** entry to `design-log.md` (full shape in [../assets/design-log.md](../assets/design-log.md)): found at `<origin node>` by whom, kind, problem and evidence, assessment and ruling, and the backlog item link when one was written. 00.25 No uses the one-line dismissed record; 00.29 Approve uses the overrun record. `design-log.md` is append-only.

**00.24 Yes, from any phase** (D69): end the entry with the line `Outcome: loop back (00.24 discovered work)`. review-triage counts `loop back` outcome lines to restart its pass count, so a loop back from Phases 1–3 must leave one too. Exception: when the origin node is `4.4`, review-triage 6.0 writes that same line under its triage pass; leave it out of the Discovered work entry so it is not written twice.

**00.29 Re-scope** ends its entry the same way with `Outcome: loop back (00.29 budget re-scope)`. Its origin is always 2.6 or 3.15, never a triage pass, so it is always written here.

## Resuming a blocked spec here

The router loads this module for a `blocked` spec whose `blocked_condition` starts `discovered work:` or `size budget:`.

1. Read the condition from `spec.md`, `blocked_from` from `.step`, and the newest **Discovered work** entry for that slug in `design-log.md`.
2. **The entry says "stays blocked, human resolves"** (00.24 No): ask whether the condition is resolved. Yes → [00.28](#0028-resume), then route again by status. No → stop.
3. **No decision is logged** (the session ended at 00.22): rebuild the problem and evidence from the slug, `artifacts/`, `tasks.md` and the design log, say which parts you could not recover, and present [00.22](#0022-present) again. The origin node is unknown, so after 00.28 the router resumes by status as usual: in Phase 3 task records say where the build stands, in Phase 4 the open triage pass has no `Outcome:` line yet.

## Done

- The spec left `blocked` through 00.24 (`draft`) or 00.28 (`blocked_from`), or stays `blocked` by the stakeholder's choice with its condition shown.
- Every report has exactly one design-log record; every "next feature" or split item is a valid `.workflow/specs/work-backlog/` file with `status: open`, and every split task is `split-out`.
- Nothing was added to the current `spec.md` or `tasks.md`; a raised `budget` is the only spec.md change, made at 00.29.
