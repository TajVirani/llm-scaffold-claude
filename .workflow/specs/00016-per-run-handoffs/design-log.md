# Design log: Per-run session handoffs

Spec: [spec.md](spec.md)

## 2026-11-12 Assumed: the term for the file a fresh session resumes from

- Step: 0.2.2
- Question: What is the canonical term for the file the handoff skill writes: **Session handoff**, or another name?
- Answer taken: **Session handoff**, written to [.workflow/GLOSSARY.md](../../GLOSSARY.md) at 0.2.3. The handoff skill and the session-start hook already use it; the glossary held only **Deferred handoff**.
- Why safe to assume: it names an existing concept with the name the code already uses, and no glossary entry competes. Undone by editing the one glossary entry.

## 2026-11-12 Assumed: placement across the handoff skill, the hooks and the installer

- Step: 0.3.4
- Question: The change touches more than one module. Which module owns what: the handoff skill (`standalone-skills`), the session-start hook (`hooks`), the path constant (`lib`) and the ignore entry (`installer`)?
- Answer taken: each part stays in the module that owns it today. The handoff skill owns where and how a session handoff is written and resumed; `hooks` owns the session-start offer; `lib` keeps `WF_HANDOFF`; `installer` keeps the `.gitignore` block. The handoff skill keeps its commands inline, because `standalone-skills` may depend on no module ([.workflow/rules.md](../../rules.md) Ownership).
- Why safe to assume: it moves no code between modules and adds no dependency, so no ADR or rule is in conflict (0.3.5) and the three-part ADR test fails (not hard to reverse). Undone by moving the affected text.

## 2026-11-12 Deeper prompt

**What this changes:** A session writes its session handoff into a local, ignored folder under `.workflow/` in the checkout it works in, under a name of its own, so it never writes into another checkout and never overwrites another agent's file. A fresh session can be pointed at one handoff and resume from exactly that one.

**Why:** Today the handoff skill always writes into the main checkout, which breaks the rule against writing files to main, and its file names collide when several agents run at once.

**Ask:** Let any run, wherever it works, leave a session handoff that only it owns and that the run continuing its work can find and load, without the file ever entering git.

**Goals:**
- A session in a spec worktree writes its handoff without writing a file into the main checkout.
- A handoff is never tracked or committed, in a new install and in an install made before this change.
- Two agents that hand off at the same time, on the same spec or topic or on different ones, each keep their own file.
- A fresh session given one handoff resumes from that one, and can tell it apart from the others on offer.

**Downstream:** asked in the first questioning ask

**Tools and technologies:** asked in the first questioning ask

**Gotchas:** asked in the first questioning ask

**Not asked for:** building the loop in which an agent hands off, resets its context and reloads by itself (the stakeholder says agents "will eventually" do this); moving the main-checkout lookup onto `wf_main_root` ([.workflow/deferred/main-checkout-resolver.md](../../deferred/main-checkout-resolver.md)).

**Original request:** "Handoff issues. Writing a handoff breaks the rule for writing a file to main. Handoffs however should never be checked in or tracked. We need a folder in the workflow folder where handoffs can be written to, is git ignored (by the setup script or added later) and where runs can write handoffs so that work can continue. Handoffs are interesting in that I could have multiple agents running that will eventually auto handle creating a handoff, resetting their context, and loading the specific handoff."

Agreement: pending, asked in the first questioning ask

## 2026-11-12 Questioning round 1

- Offered for veto: the term for the file a fresh session resumes from, placement across the handoff skill, the hooks and the installer; vetoed: none

**Q2. Pass the deeper prompt on as written?**

- Why now: first ask of the loop.
- Options: Yes · Change it
- Recommended: Yes
- Answer: "yes to all, Q4 and Q5 none"
- Decision: **D1** The deeper prompt stands as written.

**Q3. Downstream: what will be built on this?**

- Options: the automatic hand off, reset and reload loop, driven by an outer orchestrator that starts the fresh session and names the handoff path · something else · none
- Recommended: the loop, as assumed
- Answer: "yes to all, Q4 and Q5 none"
- Decision: **D2** Downstream is the automatic loop: an outer orchestrator starts the fresh session and names the handoff path. This spec leaves room for it and does not build it.

**Q4. Tools and technologies / Q5. Gotchas**

- Answer: "Q4 and Q5 none"
- Decision: **D3** No tool preference; no known gotchas.

**Q6. Which rule broke?**

- Why now: the repo could not settle it; no guard names the handoff folder ([codebase-map.md](codebase-map.md) Not found).
- Options: A: a session in a spec worktree wrote into the main checkout, outside its own folder · B: the handoff showed up untracked on main where the ignore block was missing · C: something else
- Recommended: A, because the skill's step 1 always resolves to the main checkout (codebase-map.md, Handoff skill, Write)
- Answer: "yes to all, Q4 and Q5 none"
- Decision: **D4** The break is the write into the main checkout from a session working in another checkout.

**Q7. Where does the file go?**

- Options: A: `.workflow/.handoff/` in the checkout the session works in; session start lists that checkout's handoffs first and, from the main checkout, those in the spec worktrees too · B: stay in the main checkout and exempt the folder
- Recommended: A, because no write leaves the checkout (codebase-map.md, Session-start root)
- Answer: "yes to all, Q4 and Q5 none"
- Decision: **D5** A handoff is written to `.workflow/.handoff/` in the session's own checkout. Session start lists the session's checkout first; from the main checkout it also lists the handoffs in each spec worktree. A spec worktree's handoffs go when the worktree is removed.

**Q8. File name per run?**

- Options: A: `<NNN-slug or topic>--<UTC timestamp>-<4 random chars>.md`, every handoff a new file, a resumed handoff deleted once its successor is written · B: one file per spec or topic, replaced
- Recommended: A, because it is the only option where two agents on the same work cannot collide (codebase-map.md, Handoff file name)
- Answer: "yes to all, Q4 and Q5 none"
- Decision: **D6** The name is `<NNN-slug | topic>--<YYYYMMDDTHHMMSSZ>-<4 random chars>.md`. A session never replaces another handoff; a session that resumed from one deletes it once it has written its successor or finished the work.

**Q9. Ignoring in existing installs?**

- Options: A: the skill writes a `.gitignore` holding `*` inside the folder whenever it creates it, and the install.sh block stays · B: rely on re-running install.sh
- Recommended: A, because it needs no setup step (codebase-map.md, Installer gitignore)
- Answer: "yes to all, Q4 and Q5 none"
- Decision: **D7** The handoff skill writes `.workflow/.handoff/.gitignore` holding `*` when it creates the folder. The install.sh block stays.

**Q10. Resuming a named handoff?**

- Options: resume without asking when the session's first message names a handoff path; the offer keeps "do not resume unasked" for the rest · always ask
- Recommended: resume a named handoff directly
- Answer: "yes to all, Q4 and Q5 none"
- Decision: **D8** A handoff named by path in the session's first message is resumed without asking. The session-start offer names each handoff's path and still says not to resume unasked.

**Q11. Summary**

- Answer: "yes to all, Q4 and Q5 none"
- Decision: **D9** Settled design confirmed: handoffs are per checkout, per run and self-ignoring; the offer shows this checkout's handoffs first with their paths; a handoff named by path is resumed directly; the automatic loop is out of scope.

Facts looked up instead of asked (0.3.10): None.

## 2026-11-12 Deeper prompt

**What this changes:** A session writes its session handoff into a local, ignored folder under `.workflow/` in the checkout it works in, under a name of its own, so it never writes into another checkout and never overwrites another agent's file. A fresh session can be pointed at one handoff and resume from exactly that one.

**Why:** Today the handoff skill always writes into the main checkout, which breaks the rule against writing files to main, and its file names collide when several agents run at once.

**Ask:** Let any run, wherever it works, leave a session handoff that only it owns and that the run continuing its work can find and load, without the file ever entering git.

**Goals:**
- A session in a spec worktree writes its handoff without writing a file into the main checkout.
- A handoff is never tracked or committed, in a new install and in an install made before this change.
- Two agents that hand off at the same time, on the same spec or topic or on different ones, each keep their own file.
- A fresh session given one handoff resumes from that one, and can tell it apart from the others on offer.

**Downstream:** the automatic hand off, reset and reload loop, driven by an outer orchestrator that starts the fresh session and names the handoff path.

**Tools and technologies:** no preference

**Gotchas:** none known

**Not asked for:** building that loop; moving the main-checkout lookup onto `wf_main_root` ([.workflow/deferred/main-checkout-resolver.md](../../deferred/main-checkout-resolver.md)).

**Original request:** "Handoff issues. Writing a handoff breaks the rule for writing a file to main. Handoffs however should never be checked in or tracked. We need a folder in the workflow folder where handoffs can be written to, is git ignored (by the setup script or added later) and where runs can write handoffs so that work can continue. Handoffs are interesting in that I could have multiple agents running that will eventually auto handle creating a handoff, resetting their context, and loading the specific handoff."

Agreement: agreed in Questioning round 1

## 2026-11-12 Impact classification

| Part | Classification | Note |
| --- | --- | --- |
| Session handoff location | refactor | The session's own checkout, not the main checkout; see data-model.md § Session handoff |
| Session handoff file name | refactor | One name per run; see data-model.md § Session handoff |
| Handoff folder `.gitignore` | create | Holds `*`; written by the handoff skill |
| Handoff skill Resume | extend | Resume by named path; delete the resumed file |
| Session-start offer, handoff list | extend | Own checkout first, other checkouts after, path per entry |
| Handoff frontmatter and body | unchanged | Same keys and sections |
| `WF_HANDOFF` | unchanged | Still `.workflow/.handoff` |
| install.sh ignore block, repo `.gitignore` | unchanged | Entry stays |

## 2026-11-12 Assumed: which rules.md names the main branch for the drift check

- Step: 0.4.6
- Question: Once `root` is the session's own checkout, the drift check reads `main_branch` from that checkout's `.workflow/rules.md`, which in a spec worktree is the spec branch's copy. Read that copy, or keep resolving the main checkout only for this read? (module-audit, can-wait)
- Answer taken: read the session's own checkout's copy. Resume gets its own `root` line and no longer borrows Write's.
- Why safe to assume: both copies name the same branch unless the spec itself changes `main_branch`, and `main` applies when the key is absent. It keeps every read inside the checkout, which is the point of the change. Undone by changing one line of the skill.

## 2026-11-12 Assumed: the hook's doc row is part of the hook change

- Step: 0.4.6
- Question: module-audit noticed that `.agents/hooks/claude-settings.template.md:9` describes the SessionStart hook only as offering in-flight specs (can-wait). Shelve it, or correct the row with the hook change?
- Answer taken: correct the row in the task that changes the hook's handoff list, for the handoff part only.
- Why safe to assume: it is one doc line about the behaviour this spec changes, in the same module and file set. Undone by reverting the line.

## 2026-11-12 Assumed: which checkouts a session's offer covers

- Step: 0.4.6
- Question: D5 lists the session's own checkout first. Which other checkouts follow?
- Answer taken: a session in the main checkout also sees each spec worktree's handoffs, found through `git worktree list` as the spec scan finds them; a session in a spec worktree sees its own and then the main checkout's, not other worktrees'.
- Why safe to assume: it is D5 made exact, using the list the hook already builds ([codebase-map.md](codebase-map.md), Module audit, hooks). Undone by changing the list the handoff scan walks.

## 2026-11-12 Assumed: no numeric targets beyond the offer's size cap

- Step: 1.1
- Question: Which performance, error and coverage thresholds does this spec carry?
- Answer taken: the existing 10,000-character cap on the session-start offer, and exit 0 for every input; no coverage threshold.
- Why safe to assume: the change adds file globs and text to one hook and rewrites prose in one skill; the cap and the exit code are the hook's existing contract, and the repo has no coverage tool. Undone by adding a row to the Targets table.

## 2026-11-12 Assumed: the seams the tasks are tested at

- Step: 2.3
- Question: Which public interface do each slice's tests drive?
- Answer taken: the handoff skill slice is tested at the Locate command block of `.agents/skills/handoff/SKILL.md`, run as written, plus the literal Resume wording. It catches a wrong folder, name or ignore file; it misses whether an agent follows the prose around the block. The session-start slice is tested at the SessionStart hook's input and output (payload `cwd` in, `additionalContext` out), the existing seam of `tests/hooks/audit-sync-resume.sh`. It catches wrong order, paths and caps; it misses how a host shows the text.
- Why safe to assume: both are the highest existing seams that reach the behaviour, and no interface changes to make them testable. Undone by moving a test.

## 2026-11-12 Breakdown quiz

- Asked at: 1.2, beside the harness build
- Breakdown: T1 Handoff skill writes per-run handoffs in the session's checkout (standalone-skills; seam: the Locate command block and the Resume wording; S, 2 files, ~60 lines; afk; blocked by none). T2 Session-start offer lists handoffs per checkout (hooks; seam: SessionStart hook I/O; S, 2 files, ~50 lines; afk; blocked by none). Wave 1: T1, T2; no overlap.
- Granularity, edges, splits, hitl, overlaps: "Yes, two parallel tasks (Recommended)"
- Specifiable (2.2): yes, every acceptance criterion comes from spec.md, D5-D8 and the journeys.
- Offered for veto: no numeric targets beyond the offer's size cap, the seams the tasks are tested at, which rules.md names the main branch for the drift check, the hook's doc row is part of the hook change, which checkouts a session's offer covers; vetoed: none
- Size: within the project defaults: 2 tasks, 4 predicted files
- Decision: **D10** Two tasks in one wave: T1 (handoff skill) and T2 (session-start offer), run in parallel.

## 2026-11-12 Discovered work: step-list-lint-in-agent-worktree

- Found at: step 3.4 by implementation T1 (`artifacts/T1/implementation.yaml`), and seen in the 1.4 scratch worktree. Kind: bug
- Problem and evidence: `lint/step-list` fails in any agent or scratch worktree: `tests/lint/step-list.sh:117` requires every path `checklist.md` names to exist, and `checklist.md:328` names `.workflow/.worktrees/`, an ignored folder that exists only in a checkout that holds agent worktrees. Reproduction: `run-toolchain.sh --task-id T1` in `s00016_t1` prints `FAIL every file path the decision flow, assetlist.md and checklist.md name exists got=checklist.md:328: .workflow/.worktrees/`.
- Assessment and ruling: to ask (out of scope), recommended keep for later because it predates this spec, touches neither of its modules and no journey needs it. For this spec's gates the folder is created empty in each task worktree (it is ignored), so the lint check runs as it does in the spec checkout.

- 2026-11-12 3.16: task PRs skipped for T1 and T2 (`open-task-pr.sh`: gh not installed); both merged locally, `pr` stays null.

- 2026-11-12 3.14: browser gate skipped; no e2e-browser profile. Added a Later requests line to [.workflow/deferred/browser-suite.md](../../deferred/browser-suite.md).

## 2026-11-12 Triage, review pass 1

| Id | Source lens | Finding | Location | Verdict | Evidence | Route |
| --- | --- | --- | --- | --- | --- | --- |
| F1 (RS-1) | review-standards | The Locate step says "a task worktree", an alias the glossary tells us to avoid for **Agent worktree** | `.agents/skills/handoff/SKILL.md:21` | low | `.workflow/GLOSSARY.md`, Agent worktree: "_Avoid_: Task worktree"; the line reads "(a spec worktree, a task worktree or the main checkout)" | patch (T1) |
| F2 (RS-2) | review-standards | The lineage entry for the handoff skill still records the main-checkout location and the install.sh ignore block | `upstream-lineage.json:2372` | low | `.workflow/rules.md` Cross-cutting policy requires the entry's `changes` to describe the asset; the line reads "a gitignored .workflow/.handoff/ in the main checkout (install.sh's .gitignore block)" | patch (T1) |
| F3 (RE-1) | review-end-state | The JRN-003 check runs the Locate block twice without fixing the clock, so it does not prove two names made in the same second differ | `tests/scripts/handoff-skill.sh:82-90` | low | verification-plan.md JRN-003 step 1 says "with the clock fixed"; the suite puts no stub `date` on PATH and never compares the two timestamps | patch (T1) |

Failed lenses: none
Gaps: review-targets: the three Targets rows are not measurable (offer size and exit 0 are asserted by the suite; no coverage tool); review-end-state: whether a live SessionStart payload's `cwd` for a session started in a spec worktree is the worktree path, settled by starting a real session there and reading the offer.
Outcome: rework 1 of 5
