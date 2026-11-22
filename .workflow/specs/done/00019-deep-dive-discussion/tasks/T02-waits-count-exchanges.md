# T02: Waits count includes deep dive exchanges

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** The retrospective's Measurements step counts stakeholder waits from the design log. A deep dive now takes several exchanges but logs one `Answer:` line, so the waits count adds the numbers on the Deep dive entries' `Exchanges:` lines to the answers it already counts. A design log with no `Exchanges:` line gives the same count as today.

**Seam:** the waits command line in `.agents/skills/retrospective/modules/evidence.md`, found by its trailing `# Waits:` comment and run as written on fixture design logs by `tests/scripts/retrospective-evidence.sh` ("00019 JRN-006").

**Acceptance criteria:**

- [ ] The waits line keeps its trailing `# Waits:` comment and prints one number: answers recorded plus the sum of `Exchanges:` numbers (5 for one round answer plus a deep dive with `Exchanges: 3` and its own Answer; 2 for two answers and no Exchanges line).
- [ ] The line stays one shell line, passes shellcheck as the suite extracts it, and the Measurements table's Waits row says it includes deep dive exchanges.
- [ ] `tests/run-all.sh --suite scripts/retrospective-evidence` passes.

**Predicted files:** `.agents/skills/retrospective/modules/evidence.md`

**Phase 1 tests:** `tests/scripts/retrospective-evidence.sh`

**Size:** S (1 file, about 5 changed lines).

**Mode:** afk.

**Notes:** Follow `.workflow/profiles/agent-docs.md`. The command must stay portable (bash 3.2, BSD and GNU tools).
