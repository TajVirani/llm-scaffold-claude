# T07: Docs describe the upgrade matcher rule

Index: [../tasks.md](../tasks.md) · Blocked by: T6 (Upgrade resolves hook matchers per group; T07 owns `tests/lint/install-matcher-docs.sh`, which also checks T1's Merge rules and T6's `install.sh` header) · Parallel with: None

**What to build:** A user upgrading a target project reads in the README and the CHANGELOG how `install.sh` treats a hook matcher that differs from the template's (spec Constraints, D19-D29; D24 names the four docs):
- **README "Install and upgrade":**
  - An upgrade resolves each hook group whose matcher does not cover the template's.
  - `--matchers=merge|replace|keep` sets the outcome. At a terminal the installer asks, and Enter merges. Without a terminal it merges with a Warnings line, but a mixed group is kept with a warning.
  - `--dry-run` previews and asks nothing. `--force` leaves matchers alone.
- **CHANGELOG 2.0.0 Migration:** one line saying an upgrade widens the SubagentStop matcher to integration through that rule, and naming `--matchers` and the no-terminal behaviour.

**Seam:** The doc text of the four docs, checked by grep in `tests/lint/install-matcher-docs.sh` (JRN-014).

**Acceptance criteria:**

- [ ] README "Install and upgrade" and the CHANGELOG 2.0.0 Migration section each name `--matchers`, the merge, replace and keep modes, and what happens without a terminal.
- [ ] Nothing else in either doc changes meaning. The README's install steps and flags stay correct for the new `install.sh` `--help`.
- [ ] `tests/lint/install-matcher-docs.sh` passes in full (with T1 and T6 merged), and agent-docs lint passes.

**Predicted files:** `README.md`, `CHANGELOG.md`

**Phase 1 tests:** `tests/lint/install-matcher-docs.sh`

**Size:** S (2 files, about 25 changed lines).

**Mode:** afk.

**Notes:**
- Lines to update (fact-lookup, round 6): README "Install and upgrade" L88-94, CHANGELOG 2.0.0 Migration L55-57.
- `CHANGELOG.md` has no owning module in the Ownership block. It goes with root-docs (design-log, goal re-settled after the loop-back).
- Keep the docs to the rule's outcome. The prompt wording belongs to `install.sh`.
