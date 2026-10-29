# T05: Staged-cache check runs the Mermaid validator

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** `check-staged-cache.sh` runs the Mermaid validator on the staged body when node, `mermaid` and `jsdom` are present (D7). When any of them is missing it still prints `ok` on a valid body but says on stderr that the diagrams are `not machine-validated`, naming the checklist path. When the validator runs and rejects the body, the check exits 1 with the validator's error on stderr, so the cache-regeneration agent fixes the Mermaid and re-runs it (D11). The stdout `ok` contract and exit codes 0/1/2 stay as they are.

**Seam:** `check-staged-cache.sh flows <staged body>` CLI (stdout, stderr, exit code) in `tests/scripts/cache-scripts.sh`, with a node stand-in and stub `node_modules/mermaid` and `jsdom`, and with node hidden or the packages missing.

**Acceptance criteria:**

- [ ] node and both packages present: the validator runs; valid body gives `ok`, exit 0; a validator failure gives exit 1 with its error on stderr (D11).
- [ ] Packages missing, or node not on PATH: `ok`, exit 0, stderr names `not machine-validated` and the checklist path.
- [ ] Exit codes 1 and 2 for the existing failures are unchanged.
- [ ] The JRN-007 check-staged-cache cases in `tests/scripts/cache-scripts.sh` pass (the agent-reference case there turns green at T06); shellcheck clean.

**Predicted files:** `.agents/skills/regenerate-caches/scripts/check-staged-cache.sh`

**Phase 1 tests:** None. (`tests/scripts/cache-scripts.sh` belongs to T06, which turns its last case green.)

**Size:** S (1 file, about 50 changed lines).

**Mode:** afk.

**Notes:** The validator and checklist stay in visual-change-report (`validate_mermaid.mjs`, `visual-library.md`); regenerate-caches may depend on standalone-skills under `.workflow/rules.md` Ownership.
