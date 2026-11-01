# T02: Unresolved edges in architecture

Index: [../tasks.md](../tasks.md) · Blocked by: T1 (Graph extractor per work profile) · Parallel with: None

**What to build:** Architecture gains a fourth section, `## Unresolved edges`, after Boundary violations: one sorted bullet per `couldNotResolve` dependency, `` - `<file>:<line>` `<source text>` ``, or `` - `<file>` `<source text>` `` when the edge has no `line`, or `None.` (D10, D15). `check-staged-cache.sh` accepts the section, checks it is sorted, and still accepts an old body without it (M3b).

**Seam:** build-architecture.sh --cache architecture output, and check-staged-cache.sh on an architecture body.

**Acceptance criteria:**

- [ ] A JS/TS graph keyed to `dependency-cruiser` renders today's architecture byte for byte plus `## Unresolved edges` reading `None.` (JRN-002).
- [ ] Unresolved bullets are byte-sorted and use the `line` field when present.
- [ ] `check-staged-cache.sh` accepts the four-section body and the old three-section body, and rejects unsorted Unresolved bullets.
- [ ] `arch-golden` and `viol-sorted-unique` in `tests/scripts/build-architecture.sh` expect the four-section body.

**Predicted files:** `.agents/skills/regenerate-caches/scripts/build-architecture.sh`, `.agents/skills/regenerate-caches/scripts/check-staged-cache.sh`, `tests/scripts/build-architecture.sh`

**Phase 1 tests:** `tests/scripts/build-architecture.sh`, `tests/scripts/cache-js-unchanged.sh`

**Size:** S (3 files, about 120 changed lines).

**Mode:** afk.

**Notes:** Overlap with T1 and T4 on `build-architecture.sh` is settled by edges. Updating the two existing golden tests is part of this task (design-log 2026-10-23).
