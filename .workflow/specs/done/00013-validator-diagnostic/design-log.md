# Design log: The single writers keep the validator's diagnostic

Spec: [spec.md](spec.md)

## 2026-10-30 Origin: 001-large-path-disc-002.md

- Work item: 001-large-path-disc-002.md
- Origin spec and step: .workflow/specs/done/001-large-path, step 3.7
- Problem: Both single writers validate a prepared copy of the file before moving it into place, and both send the validator's stderr to `/dev/null`. A yq runtime error during that check (a bad expression, a missing binary feature) is therefore reported as a validator refusal, "refusing to write ... fails the validator", and yq's own diagnostic is lost. The caller cannot tell a refused write from a broken validator.
- Evidence:
  - `.agents/skills/feature-workflow/scripts/initiative-transition.sh:189` (`write_validated`, on the T4 task branch at commit a5024b9, merged into `spec/001-large-path` at wave 2). At HEAD `cf04d10` the call is `initiative-transition.sh:163`.
  - `.agents/skills/feature-workflow/scripts/status-transition.sh:344`, the same pattern in the spec single writer. At HEAD `cf04d10` it is `status-transition.sh:318`.
  - Reported by the T4 profile-mini-review return (`out_of_scope_noticed`, kind bug, can-wait).
- Why not a blocker (from the item): no file is ever corrupted: the prepared copy is discarded before the move, so a misreported cause costs a diagnostic, not data.
- Suggested scope and size (from the item): in both writers, capture the validator's stderr and append it to the refusal message (or print it after the refusal line), with one suite case per writer that feeds a broken validator expression and expects the diagnostic. Leaves out any change to the validators themselves. One task in the feature-workflow module, two scripts and two suites.

## 2026-10-30 New capability: CAP-009

No capability in `.workflow/capabilities.md` covers the single writers or their validators (0.3.1 No), so the spec carries the provisional `CAP-009` until 5.3. Owning module: `feature-workflow` (both scripts); the suites under `tests` accompany it. No placement ADR (0.3.3 Yes).

## 2026-10-30 Deeper prompt

**What this changes:** When the yq validator in `status-transition.sh` or `initiative-transition.sh` fails, the refusal carries yq's own error text instead of dropping it.

**Why:** Today a broken validator reads as an ordinary refused write.

**Ask:** Make the single writers' refusals say why they refused, so a caller can tell a write the schema rejected from a validator that could not run.

**Goals:**
- When the validator cannot run (a yq runtime error), the writer's stderr includes yq's diagnostic.
- A write the validator rejects (the expression evaluates false) keeps today's refusal message.
- The prepared copy is still discarded, and the target file is byte-identical after any refusal.
- One suite case per writer feeds a broken validator and expects the diagnostic.

**Downstream:** none known.

**Tools and technologies:** bash and yq only; tests use the PATH yq-shim pattern.

**Gotchas:** `yq -e` exits non-zero both on false and on a runtime error, so the exit code alone cannot tell them apart; the two writers refuse with different exit codes today (1 and 2); the prepared copy must still be discarded.

**Not asked for:** changes to the validators themselves; changes to other yq calls in the writers.

**Original request:** "in both writers, capture the validator's stderr and append it to the refusal message (or print it after the refusal line), with one suite case per writer that feeds a broken validator expression and expects the diagnostic. Leaves out any change to the validators themselves." (the backlog item's Suggested scope)

Revisions: agreed as first restated.

## 2026-10-30 Questioning round 1

**Q1. How does a writer tell a rejection from a broken validator?**

- Why now: the deeper prompt asks the two to be told apart; with `-e`, yq gives rc 1 and an `Error:` line for both (`codebase-map.md` § Not found, probes).
- Options: A: run the validator without `-e` and read its output: `true` writes, `false` refuses as today, a non-zero exit or any other output is a validator error carrying yq's stderr · B: keep `-e` and append stderr to every refusal
- Recommended: A, because B would end every ordinary rejection with "Error: no matches found", and A depends on no message wording (`codebase-map.md` § Library options)
- Answer: "Drop -e, read the output (Recommended)"
- Decision: **D1** Both writers run their validator without `-e`; printed `true` writes, printed `false` refuses with today's message, and a non-zero yq exit or any other output is a validator error whose message includes yq's stderr. The validator expressions do not change.

**Q2. What exit code does a validator error give?**

- Why now: follows D1; the writers refuse with different codes today (`status-transition.sh:78` 1, `initiative-transition.sh:50-51` 2).
- Options: A: exit 1 (environment error) in both, rejections keep today's codes, `# Exit:` headers and tests updated together · B: keep each writer's refusal code
- Recommended: A, because a broken validator is an environment problem, as a missing yq is, and callers already stop on 1 or 2
- Answer: "Exit 1 for a broken validator (Recommended)"
- Decision: **D2** A validator error exits 1 in both writers; an ordinary rejection keeps exit 1 (status-transition) and exit 2 (initiative-transition); each `# Exit:` header names the case.

**Q3. How do the suites prove it?**

- Why now: follows D1-D2.
- Options: A: per writer, a PATH yq shim failing only the validator call (asserting exit code, diagnostic in stderr, file byte-identical, no temp copy), plus an ordinary rejection asserting today's message and no `Error:` text · B: shim cases only
- Recommended: A, reusing `tests/scripts/initiative-transition.sh:107-115`; the rejection check guards against yq noise in the message
- Answer: "Shim plus rejection checks (Recommended)"
- Decision: **D3** `tests/scripts/status-transition-tasks.sh` and `tests/scripts/initiative-transition.sh` each gain a broken-validator case (yq shim) and an ordinary-rejection message check.

Facts looked up instead of asked (main-session probes, yq v4.54.1): see `codebase-map.md` § Not found.

## 2026-10-30 Suite gap: browser suite

3.14: no `e2e-browser` profile, so the 3.10-3.11 browser gate was skipped and recorded as a known gap; the stakeholder confirmed it is the shelved item [.workflow/deferred/browser-suite.md](../../../deferred/browser-suite.md) (Later requests line appended). The 3.9 harness gate passed: 3623 passed, 0 failed (`artifacts/gate-3.9-w1/toolchain.txt`). The T1 mini-review passed with one out-of-scope note (a yq warning on stderr with exit 0 would refuse a valid write under D1); it concerns the task's own lines, so Phase 4 triage judges it.

## 2026-10-30 Triage, review pass 1

Lenses: review-standards, review-end-state, review-lessons (0 findings each); no targets (light path). F1 is the T1 mini-review's `out_of_scope_noticed` entry (`artifacts/T1/mini-review.yaml`), which concerns the task's own lines.

| Id | Source lens | Finding | Location | Verdict | Evidence | Route |
| --- | --- | --- | --- | --- | --- | --- |
| F1 | profile-mini-review (3.7) | With stderr merged into the verdict, a yq warning on stderr with exit 0 would refuse a valid write with exit 1, where the old `-e` check accepted it | `.agents/skills/feature-workflow/scripts/status-transition.sh:322-324`, `initiative-transition.sh:167-169` | maybe-false | Probes on yq v4.54.1 (valid file, no front matter, two documents, duplicate keys) printed nothing on stderr with exit 0. If it ever happens, the writer fails loudly with yq's text shown, which D1 chose on purpose ("any other output is a validator error"). Would be low if true. Settled by a yq release that warns on stderr with exit 0 | none (dismissed: maybe-false, low if true, fails loudly by design) |

Failed lenses: none
Outcome: clean, to sign-off

## 2026-10-30 Sign-off: stakeholder approval (5.5)

- Approval: yes
- PR description: approved. Changes asked before approval: none
- Backlog: no open items
- Going-in concerns: none
