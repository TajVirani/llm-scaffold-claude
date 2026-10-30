# Design log: The bash graph extractor never reads quoted text as commands

Spec: [spec.md](spec.md)

## 2026-10-30 Origin: 005-cache-build-followups-disc-003.md

- Work item: 005-cache-build-followups-disc-003.md
- Origin spec and step: .workflow/specs/005-cache-build-followups, step 5.9
- Problem: The bash graph extractor does not track a single-quoted string that spans lines. Text on the second and later lines of such a string (a multi-line jq program, an awk script) is read as commands, so a path-like word inside it is reported as an unresolved call. The published architecture cache then lists a call that does not exist.
- Evidence:
  - JRN-008 regenerate-caches run at commit `99801e5`: the published `.workflow/cache/architecture.md` lists `tests/scripts/extractor-bash.sh:205` `./x` under Unresolved edges. Line 205 is the second line of a single-quoted jq program that opens on line 204. See `.workflow/specs/005-cache-build-followups/artifacts/JRN-008/record.md` and `oracle-diff.txt`.
  - The behaviour predates spec 005: the `case` fix changed only how arm pattern lists are read.
  - Reproduced at `8e832be`: `extractors/bash.sh --root . --scope tests/scripts/extractor-bash.sh` reports `{"module":"./x","couldNotResolve":true,"line":205}`.
- Why not a blocker (from the item): the entry is reported as unresolved, never filtered out, so no real call is lost; it only adds a false entry to the cache.
- Suggested scope and size (from the item): track single- and double-quoted strings across lines in `.agents/skills/regenerate-caches/scripts/extractors/bash.sh`, so text inside them is never read as a command. Add fixture cases to the extractor-bash suite for a multi-line jq program, an awk script and a heredoc-free quoted block. A detected call still stays reported as unresolved. 1 task, 1 module.

## 2026-10-30 Reframe: change to CAP-005

The goal changes an existing capability: CAP-005 (bash graph extractor). The spec keeps CAP-005. Owning module: `regenerate-caches` (`extractors/bash.sh`); the suite and fixture under `tests` accompany it, as in spec 005's placement. No placement ADR (0.3.3 Yes).

## 2026-10-30 Deeper prompt

**What this changes:** The bash graph extractor carries a quoted string that spans lines into every reader of the lines that follow, so text inside it (a multi-line jq program, an awk script) is never reported as a call.

**Why:** Today such text adds false Unresolved edges to the architecture cache.

**Ask:** Make the bash graph extractor's call detection respect shell quoting across lines, so the architecture cache lists only calls the code really makes.

**Goals:**
- No path-like word inside a single-quoted string spanning lines is reported by any reader (cwd-relative calls, bare relative calls, `source`/`.` lines, anchored tokens): a multi-line jq program, an awk script, a plain quoted block.
- The same for plain text inside a double-quoted string spanning lines, while a `$(...)` inside double quotes is still read as code.
- Every call reported today outside quoted text is still reported; nothing real is filtered.
- `tests/scripts/extractor-bash.sh:205` `./x` no longer appears when the extractor runs on the suite.
- The extractor-bash suite gains fixture cases for each of the above.

**Downstream:** none known.

**Tools and technologies:** the existing awk program in `extractors/bash.sh`; no new parser or binary.

**Gotchas:** a `$(...)` inside double quotes is code; an apostrophe in a trailing comment must not open a quote that swallows the next commands; escapes, the `'"'"'` idiom and `$'...'` strings; never filter a detected call.

**Not asked for:** a full shell parser; changes to heredoc handling (already skipped); changes to how `case` patterns are read; regenerating the published caches beyond what sign-off already does.

**Original request:** "track single- and double-quoted strings across lines in `.agents/skills/regenerate-caches/scripts/extractors/bash.sh`, so text inside them is never read as a command. Add fixture cases to the extractor-bash suite for a multi-line jq program, an awk script and a heredoc-free quoted block. A detected call still stays reported as unresolved." (the backlog item's Suggested scope)

Revisions: agreed as first restated.

## 2026-10-30 Questioning round 1

**Q1. How do all readers learn that a line starts inside a quote?**

- Why now: the deeper prompt asks that no reader read quoted text; today only the bare-relative reader knows (`codebase-map.md` § Relevant code, Quote state across lines).
- Options: A: one quote state computed once per line before any reader, the in-quote part of the line dropped from every reader, the state advanced on every code line (source lines included) · B: teach each reader separately
- Recommended: A, because one pass fixes all four readers alike and retires the `. as $name` jq workaround (`bash.sh:142`)
- Answer: "One shared state (Recommended)"
- Decision: **D1** The extractor computes one quote state per line before any reader runs; the part of a line inside a quote opened on an earlier line, up to its closing quote, is dropped from every reader (source/., anchored tokens, cwd-relative and bare relative calls); the state advances on every line that is code or inside a quote, source lines included.

**Q2. Does a trailing comment end the code on its line?**

- Why now: with D1 the state is shared, so an apostrophe in a trailing comment (`echo hi # don't`) would mis-pair quotes for every reader; today it already drops real bare calls (main-session probe; `check-write.sh:71`, `:73`).
- Options: A: a `#` that starts a word outside quotes ends the code on that line, in this spec · B: shelve it
- Recommended: A, because otherwise D1 spreads a dropped-call bug to every reader (pitfall: never filter a detected call)
- Answer: "Yes, in this spec (Recommended)"
- Decision: **D2** A `#` that starts a word outside quotes ends the code on that line for quote tracking and every reader; a `#`-led line inside an open quote is quoted text, not a comment.

**Q3. What is inside a double-quoted string that spans lines?**

- Why now: follows D1; a probe showed `./in-dquote` inside a multi-line double-quoted string is reported today.
- Options: A: plain text is data, but a `$(...)` inside the double quotes is still read as code; single-line double quotes keep today's handling · B: single quotes only
- Recommended: A, because command substitution runs inside double quotes
- Answer: "Data, except $(...) (Recommended)"
- Decision: **D3** In the lines a double-quoted string spans, plain text is data and a `$(...)` inside it is read as code; a double-quoted string that opens and closes on one line keeps today's handling.

**Q4. Does a `<<` inside quotes still start a heredoc skip?**

- Why now: follows D1; the heredoc regex reads the raw line (`bash.sh:166`), so a quoted `<<` would skip and drop the calls after it (read from code by retrieval).
- Options: A: no, use the same quote state, with a fixture · B: shelve it, as the deeper prompt's Not asked for said
- Recommended: A, a small change once D1 exists that prevents dropped calls
- Answer: "Yes, with a fixture (Recommended)"
- Decision: **D4** A `<<` inside a quoted string does not start a heredoc skip. This supersedes the deeper prompt's "changes to heredoc handling" Not-asked-for line for this one case, with the stakeholder's agreement.

Facts looked up instead of asked (main session probes at `8e832be`, `codebase-map.md` § Not found): in-quote `./x` lines reported; double-quoted multi-line `./x` reported; `$(./y.sh)` in double quotes reported (correct); trailing comment apostrophe drops later bare calls.

## 2026-10-30 Suite gap: browser suite

3.14: no `e2e-browser` profile, so the 3.10-3.11 browser gate was skipped and recorded as a known gap; the stakeholder confirmed it is the shelved item [.workflow/deferred/browser-suite.md](../../deferred/browser-suite.md) (Later requests line appended). The 3.9 harness gate passed: 3606 passed, 0 failed (`artifacts/gate-3.9-w1/toolchain.txt`). Repo-wide oracle: 437 -> 432 records, five in-quote false edges removed, nothing else changed (`artifacts/oracle/oracle-diff.txt`).
