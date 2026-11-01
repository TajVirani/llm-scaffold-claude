---
origin_spec: .workflow/specs/009-slim-workflow-context
created: 2026-11-01
---

# Cache scope paths that name real paths

**Summary:** Publishing a Tier B cache refuses a scope path that does not exist, and the stamp check reports a cache whose scope names a missing path as invalid instead of fresh.
**Mode:** AFK
**Origin:** [009-slim-workflow-context](../specs/009-slim-workflow-context/spec.md), 0.3.17 scope decision, design-log entry 2026-11-01 Scope decision: cache scope paths

## Goal

A cache's `scope` is a list of paths that exist, one per item, so the stamp check can tell when code under it changed. A cache that cannot be checked is never reported fresh.

## Background

The three caches republished at 9e971ad hold their whole scope as one list item: every path joined by spaces into a single string. The publish script checks each scope path only for `..` and globs, so a single space-joined argument passes. The stamp check then compares a path that does not exist and reports every cache fresh, with the reason "scope does not intersect the affected area" or "no commit since generated_at_commit touched the scope", although many commits since 9e971ad changed files under those paths. A spec that trusts the check reads stale caches through retrieval. Shelved because 009 changes how the workflow loads instructions, not how caches are published or checked.

**Current behaviour:** `publish-cache.sh` accepts a scope path that names no file or folder; `cache-stamp-check.sh` reports such a cache fresh.

**Desired behaviour:** `publish-cache.sh` refuses a scope path that does not exist at the cache's commit (naming it), and `cache-stamp-check.sh` reports a cache whose scope names a missing path as `invalid` with that path in the reason. The published caches are regenerated with a correct scope.

## Constraints

- The regenerate-caches contract stays: `check-staged-cache.sh` and `publish-cache.sh` exit codes and the cache frontmatter keys are unchanged.
- The `architecture` stamp-only path `.workflow/tools/boundaries/dependency-cruiser.cjs` counts as a real path when it exists.

## Evidence

- `.workflow/cache/modules.md`, `flows.md` and `architecture.md` frontmatter `scope` is one item holding every path separated by spaces, as of commit `7a9b852926ecbc03b00ebf8408c2b2230341c72a`; the previous publish (`99801e5`) had one path per item.
- `cache-stamp-check.sh` with no `--area` prints `status: fresh` for all three caches at `7a9b852926ecbc03b00ebf8408c2b2230341c72a`, while `git diff --stat 9e971ad..7a9b852926ecbc03b00ebf8408c2b2230341c72a -- .agents/skills/feature-workflow` reports 42 files changed.
- The per-path check at `.agents/skills/regenerate-caches/scripts/publish-cache.sh:67-70` rejects only `..`, absolute paths and globs, as of commit `7a9b852926ecbc03b00ebf8408c2b2230341c72a`.

## Acceptance criteria

- [ ] `publish-cache.sh` exits 1 naming the path when a scope argument is not an existing file or folder, including one string holding several paths separated by spaces.
- [ ] `cache-stamp-check.sh` reports `invalid` (exit 2) for a cache whose scope names a missing path.
- [ ] The three caches on the main branch carry one existing path per scope item.

## Out of scope

- Changing what the caches contain or how `cache-regeneration` derives them.
