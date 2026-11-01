# Discovered work (00.21–00.29)

Work found outside the agreed scope while a feature is under way is **never** folded into the current `spec.md` or `tasks.md` on your own. A new requirement, a bug found along the way, a needed refactor, scope spreading into another module, a decision nobody in the session can answer, or a crossed size budget all come here. Every report is proven by whoever raised it. You route each one by what it needs: a fix the worker makes now, a stop for a **blocker**, or one batched question to the stakeholder. Nothing is filed without the stakeholder's ruling; what they keep becomes one line on this spec's backlog list. You run in the main session; agents only report (`discovered-work` return status, finding kind or `out_of_scope_noticed`) and never fix.

Not for Phase 0: an out-of-scope item raised while framing goes through the scope gate 0.3.16–0.3.17 to `.workflow/deferred/` ([deferred-handoff](deferred-handoff.md)).

`ST` below is `.agents/skills/feature-workflow/scripts/status-transition.sh`; type the full path every time. `NNN-slug` is the current spec.

## What the caller hands you

Before loading this module, the caller holds:

| Field | Discovered work | Size budget |
| --- | --- | --- |
| Origin node | the node it was found at (1.2, 1.3, 2.1, 3.2, 3.4, 3.7, 4.4, ...) | 2.6 or 3.15 |
| Found by | the agent and its return, or the reviewer finding `F<n>` | `budget-check.sh` |
| Problem | one or two sentences | which limit, the count and the limit |
| Evidence | the proof: a command and its output, a failing test, or a quoted rule, spec or checklist line with the `path:line` that breaks it | the `budget-check.sh` JSON |
| Kind | `bug` \| `requirement` \| `refactor` \| `scope-expansion` \| `decision` | `budget-split` (used only if you split) |
| Agent's assessment | the return's `blocker_assessment` (`blocks-this-task` or `can-wait`) and `reason`, or the caller's own assessment | none |

Keep these in the session until the report is routed or, for a blocker, until 00.28: the `--step` calls below overwrite the step marker, so the origin node lives here and, once decided, in the design-log entry.

## Assess each report first

A size-budget report skips this section and goes to [00.21](#0021-block).

Take each discovered-work report through these questions in order. The agent's assessment is your starting point, not the answer; the first question that fits routes the report:

1. **Unproven?** Its evidence is neither a reproduction (a command and its output, or a failing test) nor a quoted rule, spec or checklist line with the `path:line` that breaks it, and you cannot supply one with a single command yourself. Append the one-line "Unproven report" record to `design-log.md`. Nothing else happens: no question, no file, no fix.
2. **Current work?** It sits on lines or files this spec changes, or inside one of its capabilities, and the fix is simple: unambiguous, a few lines in files the spec already changes, no new public surface. Hand it back to the caller as **current work**: the worker that owns those lines fixes it, in a fix round at 3.8 (Phases 1–3) or as a patch for the 4.7 rework (Phase 4). The stakeholder is not asked; the fix round or the triage row is the record.
3. **Blocker?** A capability's success line or a journey in `verification-plan.md` cannot be met without it, or continuing would build on something known to be wrong. Go to [00.21](#0021-block).
4. **For the stakeholder.** Everything else that is proven falls in one of three classes:
   - **convoluted**: it touches the current work, but the fix is not simple: it needs a lot of rework, may not behave the way the stakeholder expects, or is hard to follow;
   - **scope-expanding**: fixing it means doing more than the spec agreed;
   - **out of scope**: outside the spec's capabilities (pre-existing behaviour this change did not cause, another module, a new requirement or refactor).

   Write its **Discovered work** entry with the ruling `to ask (<class>)` and your recommendation (fold in, keep for later or drop, with the reason), and return to the caller at once. It never blocks, holds no launch and gets no question of its own: [00.25](#0025-batched-ask) asks it with the others.

| Route | Next |
| --- | --- |
| Unproven | one design-log line; back to the caller |
| Current work | back to the caller as a fix for the owning worker |
| Blocker | [00.21](#0021-block) block → [00.22](#0022-present) present every blocker in one call → [00.23–00.24](#0023-0024-blocker), or [00.25](#0025-batched-ask) when the stakeholder overrules → [00.28](#0028-resume) |
| For the stakeholder | a `to ask` entry in `design-log.md`; back to the caller; asked at the next ask the session already makes, or at 5.5 at the latest |

Done when every report has a route and its reason.

## 00.21 Block

Blockers and size-budget reports only.

1. Pick a slug: two to four lowercase kebab-case words naming the problem (`stale-cache-on-retry`).
2. Block the spec. The script keeps the prior status in `.step` as `blocked_from`.

   ```bash
   ST status .workflow/specs/NNN-slug blocked --step 00.21 --blocked "discovered work: <slug>"
   # size budget:
   ST status .workflow/specs/NNN-slug blocked --step 00.21 --blocked "size budget: <what>"   # e.g. "size budget: 12 tasks, max_tasks 10"
   ```

   Exit 2 (illegal transition, e.g. the spec is already `blocked`): another report is already being handled; add this one to the same 00.22 presentation instead of blocking again.
3. **Mid-wave rule (Phase 3), while the spec is `blocked`.** Tasks already running finish and pass through their gates. Start no new launch, integration batch or wave until the stakeholder answers 00.22. A further blocker that arrives while you wait joins the same presentation; any other report is assessed and routed at once.

Done when the spec is `blocked` with the condition and nothing new is launching.

## 00.22 Present

Present every blocker and size-budget report that has arrived, together. For each, tell the stakeholder, in this order:

1. **Problem**, in plain words, without the implementation approach.
2. **Evidence**: the reproduction or the quoted line with its `path:line`.
3. **Assessment**: **blocker**, with the capability's success line or the journey it stops, or what continuing would build on.
4. **Recommendation** with its reason.

Then ask one question per report whose options are the routes, recommended option first and marked "(Recommended)", worded so "yes" accepts the recommendation:

| Condition | Options (each maps to a node) |
| --- | --- |
| `discovered work:` | Blocker, go to discovery (00.24 Yes) · Blocker, keep the spec blocked until I resolve it (00.24 No) · Not a blocker, keep it for later (00.26) · Not a blocker, drop it (00.25 drop) |
| `size budget:` | Split: remaining work to the backlog list (00.29 Split) · Re-scope through discovery (00.29 Re-scope) · Approve the overrun for this spec (00.29 Approve) |

This is an ask the session already makes, so it also carries the [batched ask](#0025-batched-ask) for every item waiting.

- **Claude Code:** AskUserQuestion, one question per report plus the batched question, all in one call (a second call straight after when past four).
- **Codex, or chat:** one message per round, then wait:

  ```text
  Q1 - Discovered work: <slug> (found at <origin node> by <agent>)
  Problem: <...>  Evidence: <...>
  Assessment: blocker, because <...>
  Recommended: <route> (<reason>)
  Or: <the other routes>
  ```

If the stakeholder's answer contradicts your assessment, follow the answer; it is their call (00.23). "Not a blocker" overrules it: keep it (00.26) or drop it, as they chose, then 00.28.

## 00.23-00.24 Blocker

**00.24 Go to discovery? Yes.** Log the decision (see [Record the decision](#record-the-decision)), then move the spec back to discovery and load [questioning-loop](questioning-loop.md) with the problem as the first frontier question:

```bash
ST status .workflow/specs/NNN-slug draft --step 00.24
```

Tasks still running in Phase 3 finish their gates first; record their results through the orchestrator as usual. The rest of the build is re-planned after discovery (0.3.20 or 0.6, then Phases 1–2).

**00.24 No.** Log the decision. The spec stays `blocked` with its condition; there is no route out until a human resolves it. Stop and tell the stakeholder how to resume: resolve the condition, then ask to continue this spec; the router brings it back here for [00.28](#0028-resume).

## 00.25 Batched ask

Every `to ask` item waits for one question. Ask it at the next ask the session already makes (a 00.22 presentation, the round of a loop back to 0.3.8, the 5.3 approval round), or at 5.5 at the latest. Never stop the work only to ask it.

1. **List the waiting items:** every **Discovered work** entry in `design-log.md` whose ruling reads `to ask` and that no later `Ruling:` line names.

   ```bash
   grep -n '^## .* Discovered work: \|to ask (\|^- Ruling: ' .workflow/specs/NNN-slug/design-log.md
   ```

2. **Ask one question over all of them.** One line per item: `<slug> (<class>, found at <node>): <problem>. Recommended: <fold in | keep for later | drop> (<reason>)`. The options are "As recommended (Recommended)", "Keep them all for later" and "Drop them all"; per-item exceptions come back as `<slug>: fold in | keep | drop` lines. At 5.5 this is the sign-off's list question, which also covers the open lines already on the backlog list (`modules/sign-off.md`).
3. **Log each ruling** as one `Ruling:` line in the entry of the ask that carried it (the Sign-off entry at 5.5).
4. **Carry it out:**
   - **Fold in:** a scope change through the normal route. At 5.5 it is a change request (5.6); at a loop back it joins that round's frontier at 0.3.8; at any other ask it waits for 5.5 as a recommended change request.
   - **Keep for later:** [00.26](#0026-add-the-backlog-line) adds its line to the backlog list (at 5.5 the write happens at 5.9).
   - **Drop:** nothing is written beyond the ruling.

   A shelf file under `.workflow/deferred/` is written only when the stakeholder asks for one: load [deferred-handoff](deferred-handoff.md#write) **Write** with the item.

Done when every waiting item has a `Ruling:` line and its outcome is carried out or handed to the step that carries it out.

## 00.26 Add the backlog line

Used for an item the stakeholder kept (at 00.22, at a batched ask, or at 5.9 from the 5.5 rulings) and for a size-budget split (00.29). The list is `.workflow/specs/work-backlog/NNN-slug.md`, one per spec, from [../assets/work-backlog.md](../assets/work-backlog.md).

1. **Set the step.** The work-backlog write guard admits a write only while the origin spec's `.step` is 00.26 or 5.9; while the spec is `blocked`, step mode keeps `blocked_from`. At 5.9 the step is already set.

   ```bash
   ST step .workflow/specs/NNN-slug 00.26
   ```

2. **Match by concept** (skip for a `budget-split` item). List `.workflow/deferred/*.md` (not `.workflow/deferred/archive/`), the open lines of every backlog list and every older open item file, and open any that could be the same concept. Match by concept, not keyword: "night theme" matches `dark-mode.md`.

   ```bash
   ls .workflow/deferred/*.md 2>/dev/null
   grep -H '^- \[open\]' .workflow/specs/work-backlog/*.md 2>/dev/null
   for f in .workflow/specs/work-backlog/*-disc-*.md; do [ -f "$f" ] && [ "$(yq --front-matter=extract '.status' "$f")" = open ] && echo "$f"; done
   ```

   - **Match on a shelf file:** append one line to its **Later requests** section, `- .workflow/specs/NNN-slug, <origin node>: <one line>`, without asking.
   - **Match on an open line or item of this spec:** add nothing; the existing line stands.
   - **Match on another spec's line or item:** add nothing to it (the guard admits only this spec's list) and name it in the design-log line.
   - Then append the one-line duplicate record to `design-log.md` (shape "Duplicate discovered work" in [../assets/design-log.md](../assets/design-log.md)) and skip steps 3–4.
   - **No match:** continue.
3. **Append the line.** Create the list from the template when it does not exist yet (delete its comment and example line), then add one line at the end with Edit, `B<n>` the highest number on the list plus one (`B1` for the first):

   ```text
   - [open] B<n> <kind> (<origin node>): <problem>. Evidence: <the reproduction or the quoted line with its path:line>.
   ```

   On Codex, run `.agents/skills/feature-workflow/scripts/check-write.sh --cwd "$PWD" --path .workflow/specs/work-backlog/NNN-slug.md` before the write and write only on exit 0. Then run the line check from the template's comment; it must print nothing.
4. **Log it:** the item's `Ruling:` line names the line (`kept for later (B<n>)`); a split item gets its **Discovered work** entry with the line.
5. **Leave.** Set the caller's step back (`ST step .workflow/specs/NNN-slug <origin node>`; for a spec that is `blocked`, go to 00.28 instead) and return with what was written or appended.

The line waits on the list. The next spec that picks it up starts from it ([discovery](discovery.md#seeded-from-a-work-item)).

## 00.29 Size budget crossed

- **Split.** The work this spec still needs for its capabilities' success lines stays; the remaining `pending` tasks leave the spec. A task that stays may not depend on one that leaves.
  1. Add one line per piece through [00.26](#0026-add-the-backlog-line) with kind `budget-split` and the task ids it takes over after its node: `(00.29, split out of T<n>, T<m>)`.
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

Only for a spec this module blocked at 00.21. Read the status held before the block and restore it:

```bash
yq '.blocked_from' .workflow/specs/NNN-slug/.step
ST status .workflow/specs/NNN-slug <blocked_from> --step 00.28
```

Then hand back to the caller at the origin node; the current work continues unchanged. In Phase 3 the orchestrator resumes its wave (pending launches start again). On exit 1 or 2, stop and report; never retry with another `--step`.

## Record the decision

Every report gets exactly one design-log record (full shapes in [../assets/design-log.md](../assets/design-log.md)); `design-log.md` is append-only.

- The one-line **Unproven report** record for a report with no proof.
- No record here for **current work**: the fix round or the triage row records it.
- A **Discovered work** entry for a blocker, a `to ask` item and a split: found at `<origin node>` by whom, kind, problem and evidence, the assessment, and the ruling (`to ask (<class>)` with the recommendation until it is asked). The answer arrives later as a `Ruling:` line in the entry of the ask that carried it, and a kept item names its backlog line there.
- The one-line duplicate record for an item matched at 00.26 step 2; the overrun record for 00.29 Approve.

**00.24 Yes, from any phase**: end the entry with the line `Outcome: loop back (00.24 discovered work)`. review-triage counts `loop back` outcome lines to restart its pass count, so a loop back from Phases 1–3 must leave one too. Exception: when the origin node is `4.4`, review-triage 6.0 writes that same line under its triage pass; leave it out of the Discovered work entry so it is not written twice.

**00.29 Re-scope** ends its entry the same way with `Outcome: loop back (00.29 budget re-scope)`. Its origin is always 2.6 or 3.15, never a triage pass, so it is always written here.

## Resuming a blocked spec here

The router loads this module for a `blocked` spec whose `blocked_condition` starts `discovered work:` or `size budget:`.

1. Read the condition from `spec.md`, `blocked_from` from `.step`, and the newest **Discovered work** entry for that slug in `design-log.md`.
2. **The entry says "stays blocked, human resolves"** (00.24 No): ask whether the condition is resolved. Yes → [00.28](#0028-resume), then route again by status. No → stop.
3. **No decision is logged** (the session ended at 00.22): rebuild the problem and evidence from the slug, `artifacts/`, `tasks.md` and the design log, say which parts you could not recover, and present [00.22](#0022-present) again. The origin node is unknown, so after 00.28 the router resumes by status as usual: in Phase 3 task records say where the build stands, in Phase 4 the open triage pass has no `Outcome:` line yet.

A spec that is not `blocked` but whose `.step` reads `00.26` was adding a backlog line when the session ended: check that the line (or the appended shelf line) and its `Ruling:` line exist, finish the one that is missing from the design log, then route by status as usual.

## Done

- **Unproven, current work or for the stakeholder:** the report has its route and record; the spec's status never changed, nothing was written outside `design-log.md`, and the caller has its step back.
- **Kept for later:** the item is one well-formed `- [open]` line on `.workflow/specs/work-backlog/NNN-slug.md`, or one appended Later requests line on the matching shelf file, with its `Ruling:` line.
- **Blocker or size budget:** the spec left `blocked` through 00.24 (`draft`) or 00.28 (`blocked_from`), or stays `blocked` by the stakeholder's choice with its condition shown; every report has exactly one design-log record; every kept or split item is a backlog line, and every split task is `split-out`.
- Nothing was added to the current `spec.md` or `tasks.md`; a raised `budget` is the only spec.md change, made at 00.29.
