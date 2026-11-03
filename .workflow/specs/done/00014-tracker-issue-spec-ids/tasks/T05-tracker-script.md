# T05: Tracker script

Index: [../tasks.md](../tasks.md) · Blocked by: T1 (Shared host choice and path rewrite), T3 (next-spec-number.sh) · Parallel with: None

**What to build:** The new `issue-tracking` skill's tracker script, `.agents/skills/issue-tracking/scripts/issue-tracker.sh [--cwd DIR] <command>`. It reads `.workflow/issue-tracking.yaml` (the host and the three **Issue flow** labels) and picks gh or glab through the shared host choice.

Commands:

- `create-spec`: opens an issue with a placeholder title and an empty body, and prints its URL.
- `fill <issue-url> <spec.md>`: sets the title from the first `# ` heading and the body to the whole file. The body goes through a file argument, so a body starting with `#` or containing a `[` line arrives unchanged.
- `create-task <spec-issue-url> <task-file>`: on GitLab, a child task through `glab api graphql`, falling back to a `relates_to` linked issue when GraphQL refuses. On GitHub, `gh issue create --parent`. Prints the URL.
- `move <issue-url> backlog|in_progress|done`: removes the other flow labels and adds the new one. `done` also closes the issue, and `in_progress` on a closed issue reopens it.

Exits: with no tracker, it prints `skipped: no tracker` and exits 0; a tracker failure exits 1 naming the cause; usage or bad settings exits 2. Two starts against one tracker get two numbers. `SKILL.md` gets its frontmatter and the tracker-script section: what each command does and when the workflow calls it.

**Seam:** the `issue-tracker.sh` and `next-spec-number.sh` CLIs against the fake glab and gh call log (`tests/scripts/issue-tracking.sh`). Catches wrong calls, a lost body, a missing fallback and an unnamed failure. It misses the real GitLab GraphQL schema: D17 allows fakes only, and the `relates_to` fallback covers a refusal.

**Acceptance criteria:**

- [ ] JRN-002 / JRN-003: a gitlab `origin` with fake glab answering iid 42 makes `next-spec-number.sh` print `00042` and the URL; github with number 7 prints `00007`. One create call is made, with a placeholder title and an empty body, and the other CLI is never called.
- [ ] JRN-004: two runs from two clones against one fake tracker print two different numbers, with no local scan.
- [ ] JRN-005: `fill` sends the title and the whole body unchanged.
- [ ] JRN-006: `create-task` makes a child task, falls back to `relates_to` when GraphQL is refused, and makes a GitHub sub-issue with `--parent`.
- [ ] JRN-007: `move` swaps labels, closes on done and reopens on in_progress.
- [ ] JRN-008: a network or auth failure exits non-zero naming the cause, prints no number, and `next-spec-number.sh` creates no folder.
- [ ] With no tracker, every command prints `skipped: no tracker` and calls neither CLI.
- [ ] `.agents/skills/issue-tracking/SKILL.md` has valid frontmatter (`name: issue-tracking`) and passes `tests/run-all.sh --suite lint/frontmatter`.

**Predicted files:** `.agents/skills/issue-tracking/scripts/issue-tracker.sh`, `.agents/skills/issue-tracking/SKILL.md`.

**Phase 1 tests:** `tests/scripts/issue-tracking.sh`.

**Size:** M (2 files, about 350 changed lines).

**Mode:** afk.

**Notes:** Uses the T1 host-choice function and the T3 `WF_` settings path; `lint/shared-tracker-logic` requires the host choice through the lib. Call shapes are in codebase-map.md § Library options (`glab api` with `iid`, `gh api ... --jq .number`, `--description-file` / `--body-file`). The skill's install-manifest line and `PROVENANCE.md` rows are T09's.
