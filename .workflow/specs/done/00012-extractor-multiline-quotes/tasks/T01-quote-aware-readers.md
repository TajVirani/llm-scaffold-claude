# T01: Share one quote state across lines with every reader of the bash extractor

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** The bash graph extractor never reports a call from text inside a quoted string, however many lines the string spans, and never drops a real call because of quoting or a comment.

- One quote state per line, computed before any reader runs, shared by the `source`/`.` branch, the anchored token scan, `report_cwd_relative_calls` and `report_bare_relative_calls`. The part of a line inside a quote opened on an earlier line, up to its closing quote, is dropped from every reader. The state advances on every line that is code or inside a quote, `source` lines included, and a `#`-led line inside an open quote is quoted text (D1, D2).
- A `#` that starts a word outside quotes ends the code on its line, so an apostrophe in a trailing comment (`echo hi # don't`) opens nothing (D2).
- In the lines a double-quoted string spans, plain text is data and a `$(...)` inside it is read as code; a double-quoted string on one line keeps today's handling (D3).
- A `<<` inside a quoted string does not start a heredoc skip (D4).
- The jq `. as $name` special case (`bash.sh:142`) may go if the shared state makes it redundant; keep its suite case green.

**Seam:** the extractor's CLI and output JSON (`extractors/bash.sh --root DIR --scope PATH`, `couldNotResolve` records with `line`), driven by `tests/scripts/extractor-bash.sh` through `resolved_of` / `unresolved_of` (`:30-33`) on fixture repos built at run time.

**Acceptance criteria:**

- [ ] A multi-line single-quoted jq program whose later lines hold `./x`, `(./x` (the `tests/scripts/extractor-bash.sh:205` form), `source x` and `$here/x.sh` at a line start reports none of them (D1).
- [ ] A multi-line awk script and a plain multi-line single-quoted block report nothing from inside (D1).
- [ ] A multi-line double-quoted string reports no call from its plain text, and still reports `$(./real.sh)` written inside it (D3).
- [ ] After `echo hi # don't`, a later bare call (`scripts/x.sh`) and a cwd-relative call (`./y.sh`) are reported (D2).
- [ ] Calls after `x='it'"'"'s'` and after `y=$'a\'b'` are reported.
- [ ] A `<<` inside a quoted string is not a heredoc: calls on the following lines are reported (D4).
- [ ] Running the extractor on the real `tests/scripts/extractor-bash.sh` reports no `./x` at line 205.
- [ ] Every existing case in `tests/scripts/extractor-bash.sh` (and the other cache suites using the fixture) still passes; the output JSON shape and CLI are unchanged.
- [ ] In `summary`, report the repo-wide comparison: the extractor's output with `--root <worktree> --scope .` at the base commit and at your head, and for every record that differs, whether it is a removed in-quote edge or a call restored by D2-D4. The orchestrator records the diff as evidence; any other change is a defect to fix.

**Predicted files:** `.agents/skills/regenerate-caches/scripts/extractors/bash.sh`, `tests/scripts/extractor-bash.sh`, `tests/fixtures/graph-extractors.sh` (only if a shared fixture is the right home)

**Phase 1 tests:** None.

**Size:** M (3 files, about 180 changed lines).

**Mode:** afk.

**Notes:** None. Main-session probes at `8e832be` (codebase-map.md § Not found): `./line-start-in-quote` inside a multi-line single quote is reported; `./in-dquote` inside a multi-line double quote is reported; `$(./in-dquote-subst.sh)` is reported (correct, keep it); `echo hi # don't` drops later bare calls until the quote parity flips. Real trailing-comment apostrophes exist at `.agents/skills/feature-workflow/scripts/check-write.sh:71`, `:73`. Never filter a detected call (`.workflow/decisions/pitfalls.md`).
