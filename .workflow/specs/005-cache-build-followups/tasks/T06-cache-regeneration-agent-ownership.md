# T06: Cache-regeneration agent calls only regenerate-caches

Index: [../tasks.md](../tasks.md) · Blocked by: T5 (Staged-cache check runs the Mermaid validator) · Parallel with: None

**What to build:** `.agents/agents/cache-regeneration.md` reaches the Mermaid check through `check-staged-cache.sh` and names no `.agents/skills/` path outside `regenerate-caches`. Its step 4 tells the agent that an exit 1 from the check means fix the staged body (the Mermaid included) and run the check again (D11), and that `not machine-validated` means checking the diagrams by hand against the checklist path the script prints.

**Seam:** The agent doc's content, checked by the JRN-007 grep in `tests/scripts/cache-scripts.sh`; the same suite drives T05's script.

**Acceptance criteria:**

- [ ] `grep -o -E '\.agents/skills/[a-z-]+' .agents/agents/cache-regeneration.md | grep -v -c regenerate-caches` prints 0 (TGT-006).
- [ ] Step 4 covers both outcomes above (D11, D7).
- [ ] `tests/scripts/cache-scripts.sh` passes; `tests/run-all.sh --suite lint/frontmatter` passes.
- [ ] Generated Codex tomls, if any are checked in for this agent, still match.

**Predicted files:** `.agents/agents/cache-regeneration.md`

**Phase 1 tests:** `tests/scripts/cache-scripts.sh`

**Size:** S (1 file, about 20 changed lines).

**Mode:** afk.

**Notes:** The remaining calls to regenerate-caches scripts need proposal P1 (`agents.may_depend_on` gains `regenerate-caches`) at 5.3.
