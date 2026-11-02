# T02: Output style reads the term list

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** The Concise Technical output style stops telling the agent to load `.workflow/GLOSSARY.md` whole at conversation start. Its vocabulary rule gives an inline shell command that prints one line per root-glossary entry with its `_Avoid_` aliases, and tells the agent to read a single entry only when it needs the definition. The style references no script (D1); glossary-map support lives only in the domain-modeling script (spec Assumptions). The "add a missing term following the existing format" rule stays.

**Seam:** the inline command in `.agents/output-styles/concise-technical.md`, run from this repo's root.

**Acceptance criteria:**

- [ ] The inline command, run from the repo root, prints one line per entry in `.workflow/GLOSSARY.md` (43 today) with aliases where the entry has them, and nothing else.
- [ ] The style names no path under `.agents/skills/` and no script.
- [ ] The style no longer says to load the glossary whole.

**Predicted files:** `.agents/output-styles/concise-technical.md`

**Phase 1 tests:** None.

**Size:** S (1 file, about 5 changed lines).

**Mode:** afk.

**Notes:** output-styles depends on nothing, so the command is self-contained (`awk`/`grep`/`sed` only).
