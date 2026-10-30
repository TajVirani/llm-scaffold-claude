---
origin_spec: .workflow/specs/00010-worktree-guard-followups
created: 2026-10-30
---

# Sub-agent payload without a transcript path

**Summary:** Confirm on a live Claude Code run how a sub-agent's PreToolUse payload looks when its transcript cannot be found, so the worktree guard's missing-transcript deny is checked against the real shape.
**Mode:** HITL
**Origin:** [00010-worktree-guard-followups](../specs/00010-worktree-guard-followups/spec.md), 4.8 review finding (remaining gap from review-end-state `not_verifiable`), design-log entry 2026-10-30 Triage, review pass 1

## Goal

The worktree guard's behaviour for a confined sub-agent whose transcript is missing is proven on a real host payload, not only on test fixtures.

## Background

Spec 00010 made the worktree guard deny a confined implementation or integration sub-agent when its transcript, and so its launch header, cannot be found. The suites drive the guard with fixture payloads; whether Claude Code ever omits `transcript_path` or points it at a missing file lives outside the repo, so the review could not verify it.

**Current behaviour:** the guard denies with a "sub-agent transcript not found" cause when `transcript_path` is absent or the derived sub-agent transcript does not exist (fixtures only).

**Desired behaviour:** a recorded live payload shows which of those cases the host produces, and the suite carries a fixture copied from it.

## Constraints

- Payload facts are recorded with the Claude Code version they were seen on, as `PLAN/hook-verification.md` does.

## Decisions already made

- Fail closed when no agent worktree can be established (design-log D3 in [.workflow/specs/00010-worktree-guard-followups/design-log.md](../specs/00010-worktree-guard-followups/design-log.md)).

## Evidence

- Review pass 1, `.workflow/specs/00010-worktree-guard-followups/artifacts/review/pass-1/review-end-state.yaml` `not_verifiable`; guard logic in `.agents/hooks/worktree-write-guard.sh` as of commit `6d40286`. Unverified: needs a live sub-agent launch.

## Acceptance criteria

- [ ] A live sub-agent PreToolUse payload is recorded with its Claude Code version, and the guard's verdict on it is noted.

## Out of scope

- Codex payloads.
