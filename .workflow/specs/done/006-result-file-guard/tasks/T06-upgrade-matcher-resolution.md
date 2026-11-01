# T06: Upgrade resolves hook matchers per group

Index: [../tasks.md](../tasks.md) · Blocked by: T1 (Hooks build agent worktree names from the shared lib; it widens the template's SubagentStop matcher, which the JRN-006 upgrade case in T06's suite needs) · Parallel with: None

**What to build:** On an `install.sh` upgrade, a target whose existing hook group runs a template command under a matcher that does not cover the template's gets that matcher merged, replaced or kept, per group, on every hook event (spec Constraints, D19-D29). Upgraded targets then audit integration agents with one SubagentStop entry.
- **Which groups.** Each existing group that runs at least one command of a template group, under a matcher that does not cover the template's, is resolved on its own (D28). Missing commands are still appended as today.
- **Covered and match-all.** "Covers" means the existing matcher's `|` alternatives include all of the template's, so a re-run finds nothing to do (D29). A match-all group (no matcher, `""` or `"*"`) is never touched. A match-all template makes merge and replace drop the matcher (D27).
- **Merge.** Only when both matchers are plain alternations (`[A-Za-z0-9_|]`). The result is the existing alternatives in order, then the template's missing ones: `implementation|foo` with `implementation|integration` gives `implementation|foo|integration` (D21, D27).
- **Replace** gives the template's matcher. **Keep** leaves the group as it is and prints a Warnings line.
- **Choosing the mode:**
  - `--matchers=merge|replace|keep` answers every group. Any other value exits 2, and the error names the three modes (D23).
  - At a terminal on both stdin and stdout, prompt per group (D25, D26):
    - The prompt names the event and the scaffold command and shows the current, replace and merge lines. For a mixed group it also lists every hook in the group.
    - Enter merges, `r` replaces, `k` keeps.
  - Without a terminal (D22, D26):
    - A template-only group is merged, with a Warnings line.
    - A mixed group (it also runs a non-template hook) is kept, with a Warnings line.
    - A non-plain matcher is kept, with a Warnings line.
- **`--dry-run`** never reads input. Without `--matchers` it previews the no-terminal outcome; with `--matchers` it previews that mode (D29).
- **`--force`** does not change matchers: they follow the rule above.
- **Docs.** The `install.sh` header and `--help` (the `# Usage:` block) name `--matchers`, the three modes and the no-terminal rule (D24). Header lines that the change makes wrong are fixed too: step 3 hook groups, step 4 "(same hook rules)", the Conflicts `--force` sentence, the comment above `JQ_MERGE`, and the test list.

**Seam:** The `install.sh` command line on a fixture target, as `tests/scripts/install-upgrade.sh` drives it. The tests check the exit code, `.claude/settings.json` after the run, the Warnings lines on stdout, the `--dry-run` preview, and the prompt and answers under a pseudo-terminal (JRN-006, JRN-011 to JRN-013).

**Acceptance criteria:**

- [ ] JRN-011:
  - With stdin not a terminal, the old template-only stop-audit group is merged to cover `implementation` and `integration`, leaving one SubagentStop entry for it.
  - The mixed group is kept. Match-all and covered groups are untouched.
  - A Warnings line names each merged or kept group, and a third run writes nothing.
- [ ] JRN-012:
  - `merge`, `replace` and `keep` give `implementation|foo|integration`, the template's matcher, and the unchanged matcher with a warning.
  - `bogus` exits 2 and names the modes.
  - `--dry-run` writes nothing, previews the outcome and finishes on an open stdin.
  - `--force` alone merges as the no-terminal rule does.
  - `(a|b)c` is never merged, and a warning names it.
- [ ] JRN-013: under a pseudo-terminal the prompt names the event and command and shows current, replace and merge (and every hook for a mixed group). Enter merges, `r` replaces and `k` keeps.
- [ ] JRN-006: an upgrade from the old template leaves one SubagentStop entry, and its matcher matches `implementation` and `integration`.
- [ ] Every other `install.sh` suite keeps its verdicts. No `read` runs without a terminal, and none runs inside the `while read ... < <(jq ...)` loops. The Claude and Codex merges share the rule. Exit codes stay 0 / 1 / 2, and every check still runs before any write.
- [ ] `tests/scripts/install-upgrade.sh` passes in full (with T1 merged), the install suites pass, and shellcheck is clean on `install.sh`.

**Predicted files:** `install.sh`

**Phase 1 tests:** `tests/scripts/install-upgrade.sh`

**Size:** M (1 file, about 250 changed lines).

**Mode:** afk.

**Notes:**
- Installer audit in `codebase-map.md` ("### installer") lists the hooks this builds on and the constraints:
  - `JQ_MERGE` is one pure jq pass. Per-group answers need bash to find the differing groups first, then apply the answers.
  - Under `set -euo pipefail`, a bare `read` at EOF exits.
  - `LC_ALL=C` is exported, and `jq -S` does not sort alternatives, so keep their order stable for idempotence.
  - The existing `--argjson force` channel is how a `--matchers` value reaches jq.
- The Codex `.codex/hooks.json` groups carry no matcher, so the rule leaves them alone in effect.
- `tests/lint/install-matcher-docs.sh` checks the header and `--help` lines too, but T07 owns that suite. It goes green once T07 merges.
- Data model M2 (`data-model.md`): upgraded targets' `implementation` matcher becomes `implementation|integration` through the default merge.
