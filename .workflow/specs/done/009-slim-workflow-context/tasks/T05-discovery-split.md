# T05: Discovery split and the 0.2.1 read

Index: [../tasks.md](../tasks.md) · Blocked by: T4 (Launching reference) · Parallel with: T6

**What to build:** A new feature loads only the before-the-loop half of discovery. `modules/discovery.md` keeps 0.1–0.3.7 and 0.3.22; the new `modules/discovery-impact.md` takes 0.3.20, 0.4–0.6 and the fresh-session offer (D4). At 0.2.1 discovery runs `.agents/skills/domain-modeling/scripts/term-list.sh` instead of reading `.workflow/GLOSSARY.md` whole (D11), and reads from `.workflow/rules.md` only the module names and their `owns` paths, through one fenced bash command under the `**0.2.1` step; the full Ownership block is read at 0.3.3 and Shared core at 0.3.20 (D22). The router's Route table names `discovery` or `discovery-impact` by `.step` node, and every link to the moved sections (`discovery.md#0320-light-path-test` from questioning-loop, the `#seeded-from-a-work-item` cross-links) is re-pointed. The lineage and PROVENANCE entries for `discovery.md` are split to match.

**Seam:** the 0.2.1 fenced command in `discovery.md`, extracted and run by `tests/lint/affected-area.sh` against this repo's `rules.md`; the Route table rows for draft steps.

**Acceptance criteria:**

- [ ] `tests/run-all.sh --suite lint/affected-area` passes: one line per Ownership module with exactly its `owns` paths, nothing else from `rules.md`.
- [ ] 0.2.1 runs the term-list script; no step before 0.3.3 reads the Ownership or Shared core block whole.
- [ ] The 0.1.1 scan block stays in `discovery.md` (`tests/scripts/spec-worktree.sh` and `tests/scripts/move-to-done.sh` extract it).
- [ ] `lint/md-links`, `lint/upstream-lineage` and every other existing suite pass.
- [ ] Asset headers that name a discovery step now in `discovery-impact.md` are re-pointed.
- [ ] `PROVENANCE.md` names `skills/feature-workflow/modules/discovery-impact.md`.

**Predicted files:** `.agents/skills/feature-workflow/modules/discovery.md`, `.agents/skills/feature-workflow/modules/discovery-impact.md`, `.agents/skills/feature-workflow/modules/questioning-loop.md`, `.agents/skills/feature-workflow/SKILL.md`, `.agents/skills/feature-workflow/assets/codebase-map.md`, `.agents/skills/feature-workflow/assets/design-log.md`, `.agents/skills/feature-workflow/assets/data-model.md`, `.agents/skills/feature-workflow/assets/verification-plan.md`, `PROVENANCE.md`, `upstream-lineage.json`

**Phase 1 tests:** `tests/lint/affected-area.sh`

**Size:** M (10 files, about 300 changed lines).

**Mode:** afk.

**Notes:** Shares `PROVENANCE.md` and `upstream-lineage.json` with T6 under an approved `parallel_with` (different entries; merged in id order). The small-path notes are T7's; move the existing text as it is. The agents' definitions name steps by number only, so `module-audit.md` needs no change.
