# Design log: Handoffs found from session worktrees

Spec: [spec.md](spec.md)

## 2026-11-13 Assumed: the name for a host's per-session worktree

- Step: 0.2.2
- Question: what to call the worktree Claude Code desktop creates for each session (`.claude/worktrees/<name>`): Session worktree (new entry), or reuse "isolation worktree" as the code comments do?
- Answer taken: **Session worktree**, written to `.workflow/GLOSSARY.md` under step 0.2.3, with "isolation worktree" kept for a sub-agent launch's `isolation: "worktree"`.
- Why safe to assume: no glossary entry names this concept, and "isolation worktree" already means a single sub-agent launch in the code and is an alias to avoid under **Agent worktree**. A veto renames one glossary entry and the spec text.

## 2026-11-13 Assumed: reframe as a change to CAP-015

- Step: 0.3.1
- Question: is this a new capability or a change to CAP-015 (per-run session handoffs)?
- Answer taken: a change to **CAP-015**; it keeps its id.
- Why safe to assume: CAP-015 already owns which checkouts' handoffs the session-start offer lists; this widens that rule for session worktrees. A veto gives the spec a `CAP-NEW-<slug>` instead.

## 2026-11-13 Placement: hooks

- Owning module: `hooks` (`.agents/hooks/session-start-resume.sh` decides which checkouts' handoffs are offered). The `handoff` skill text (`standalone-skills`) and `tests` change alongside, as in spec 00016.
- Alternatives considered: `lib` (a new helper in `workflow-paths.sh` to name a session worktree): not needed unless the questioning loop decides the rule needs one; it is shared core and would go through integration.
- Conflict with an ADR or rule: none (no ADR covers worktrees, handoffs or session start; `hooks` may depend on `lib`).
- Decision: **D1** the change lives in `hooks`, with the matching `handoff` skill text and tests. No placement ADR: the placement is easy to reverse and fails the three-part test. Assumed, offered for veto at the first ask.

## 2026-11-13 Deeper prompt

**What this changes:** A session started in a session worktree (Claude Code desktop's `.claude/worktrees/<name>`) is offered every spec worktree's handoffs at session start, as a session in the main checkout already is, and resuming one moves the session into that spec worktree.

**Why:** Every desktop session starts in a fresh session worktree, so today it never sees the handoff for the spec it should resume.

**Ask:** Make a session handoff reachable from wherever the host starts the next session, so picking work back up never depends on which checkout the session happened to open in.

**Goals:**
- From a session worktree, the session-start offer lists the handoffs saved in every spec worktree, by absolute path, as the main checkout's offer does.
- A spec worktree still never lists a sibling spec worktree's handoffs.
- Resuming a handoff whose spec runs in a spec worktree moves the session into that spec worktree before anything else runs.
- Tests pin the offer from a session worktree; the Commonplace case (00031 missing from `.claude/worktrees/quirky-yonath-09ed4f`) no longer reproduces.

**Downstream:** asked in the first questioning ask

**Tools and technologies:** asked in the first questioning ask

**Gotchas:** asked in the first questioning ask

**Not asked for:** cleaning up Commonplace's existing worktrees (nested initiative worktree, stale handoff path, leftover session worktrees); moving older nested spec worktrees automatically; the shelved main-checkout-resolver refactor.

**Original request:** "Take a look at the common place project. I am still running into problems with worktrees when doing handoffs. What is going on with it?" then "1" (option 1: "the session-start hook should treat any checkout that isn't a spec worktree, such as a Claude worktree, like the main checkout, so it lists every spec worktree's handoffs. The resume step should also tell the session to move into the spec worktree.")

Revisions: first restatement.

Agreement: pending, asked in the first questioning ask

## 2026-11-13 Questioning round 1

- Offered for veto: Assumed: the name for a host's per-session worktree; Assumed: reframe as a change to CAP-015; Placement: hooks (D1); vetoed: none

**Q1. Pass the deeper prompt on as written?**

- Options: A: yes · B: change it
- Recommended: A
- Answer: "all recommended."
- Decision: **D2** the deeper prompt passes as written; Downstream, Tools and Gotchas are "none" (filled block below).

**Q2-Q4. Downstream, tools and technologies, gotchas**

- Recommended: none, none (bash in the existing hook), none
- Answer: "all recommended."
- Decision: **D3** none known for each.

**Q5. Which handoffs does a session see when it is not in a spec worktree?**

- Why now: the hook's own/other rule (`session-start-resume.sh:102-107`) is the cause.
- Options: A: every other registered worktree's handoffs (main, every spec worktree, other session worktrees) · B: main and spec worktrees only, with the handoff skill writing to main from a session worktree
- Recommended: A, because a handoff written in a session worktree is otherwise invisible to the next desktop session and to main, and B breaks the 00016 constraint that the handoff skill stays self-contained (codebase-map.md, Prior decisions)
- Answer: "all recommended."
- Decision: **D4** a checkout that is not a spec worktree lists its own handoffs, then every other registered worktree's; a spec worktree keeps its own plus main's. The cap of 3 listed stays.

**Q6. Does Resume move into the handoff's checkout first?**

- Why now: Resume (`handoff/SKILL.md` Resume) has no move step; only a spec handoff moves, through feature-workflow.
- Options: A: yes, a new first step (EnterWorktree on Claude Code; ask to reopen elsewhere) · B: leave it to feature-workflow
- Recommended: A
- Answer: "all recommended."
- Decision: **D5** Resume step 1 moves the session into the checkout the handoff file sits in when that is not the session's own.

**Q7. Settled design summary**

- Answer: "all recommended." Confirmed as one feature on the light path.

Facts looked up instead of asked (0.3.10): None.

## 2026-11-13 Deeper prompt

**Ask:** Make a session handoff reachable from wherever the host starts the next session, so picking work back up never depends on which checkout the session happened to open in.

**Goals:**
- From a session worktree, the session-start offer lists the handoffs saved in every spec worktree, by absolute path, as the main checkout's offer does.
- A spec worktree still never lists a sibling spec worktree's handoffs.
- Resuming a handoff whose spec runs in a spec worktree moves the session into that spec worktree before anything else runs.
- Tests pin the offer from a session worktree; the Commonplace case (00031 missing from `.claude/worktrees/quirky-yonath-09ed4f`) no longer reproduces.

**Downstream:** none known

**Tools and technologies:** no preference (bash in the existing hook)

**Gotchas:** none known

**Not asked for:** cleaning up Commonplace's existing worktrees; moving older nested spec worktrees automatically; the shelved main-checkout-resolver refactor.

**Original request:** "Take a look at the common place project. I am still running into problems with worktrees when doing handoffs. What is going on with it?" then "1".

Revisions: Downstream, Tools and Gotchas filled from round 1.

Agreement: agreed in Questioning round 1

## 2026-11-13 Merge route

- T1: task PR skipped (open-task-pr.sh: gh not installed); merged locally.
- Discovered work: design-log-asset-step-ref: current work; the design-log asset named the handoff skill's Resume step 3, renumbered to 4 by T1; patched in T1 at 3.8.

## 2026-11-13 Suite gap at 3.14

- Browser suite missing (no e2e-browser profile): 3.10-3.11 skipped; Later requests line added to .workflow/deferred/browser-suite.md.
