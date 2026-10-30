---
status: in-review # draft | ready-for-dev | in-progress | in-review | done | blocked. Changed only by scripts/status-transition.sh.
baseline_revision: "9347768cc6b32ccc89cea7fe536052fc87c8d4ee" # full SHA of the commit the work starts from; "" until captured, then never overwritten
spec_branch: spec/00012-extractor-multiline-quotes # spec/NNN-slug, created off main at 1.1 (0.3.20 on the light path); "" until then
impl_base_revision: "9347768cc6b32ccc89cea7fe536052fc87c8d4ee" # full SHA of the spec-branch tip when Phase 3 starts (3.1); "" until then, never overwritten
light_path: true # true once the 0.3.20 light-path test passes
followup_review_recommended: false # true when triage recommends another review pass after this one
deferred: [.workflow/deferred/browser-suite.md, .workflow/deferred/bash-extractor-quote-rules.md] # repo-relative paths of the .workflow/deferred/ files this spec wrote, e.g. .workflow/deferred/csv-export.md
origin: 005-cache-build-followups-disc-003.md
budget: {max_tasks: 10, max_changed_files: 30}
---

# The bash graph extractor never reads quoted text as commands

## Why

Origin: 005-cache-build-followups-disc-003.md, the bash extractor reads multi-line quoted text as commands.

The bash graph extractor does not carry a quoted string that spans lines into every reader of the following lines. Text on the second and later lines of such a string, such as a multi-line jq program or an awk script, is read as commands, so a path-like word inside it is reported as an unresolved call, and the published architecture cache lists calls that do not exist (`tests/scripts/extractor-bash.sh:205` `./x` since `99801e5`). The same quote tracking mis-pairs an apostrophe in a trailing comment and then drops real calls on later lines. The extractor must respect shell quoting across lines, so the architecture cache lists only calls the code really makes and drops none it does make.

## Capabilities

- **CAP-005** Bash graph extractor (changed: quote-aware across lines)
  - **intent:** The cache build can trust that every unresolved call the bash extractor reports is a real command, and that no real call is lost to quoting or comments.
  - **success:** In `tests/scripts/extractor-bash.sh`, fixture cases show no call reported from text inside a multi-line single-quoted string (jq program including the `(./x` form, awk script, plain block), nor from plain text inside a multi-line double-quoted string, while a `$(...)` inside it, calls after a trailing comment with an apostrophe, after the `'"'"'` idiom, after a `$'...'` string and after a quoted `<<` are all still reported; running the extractor on `tests/scripts/extractor-bash.sh` reports no `./x` at line 205; and a repo-wide before/after run shows every changed record is a removed in-quote edge or a restored call.

## Constraints

- Stays in the extractor's own awk program; no new parser or binary (`codebase-map.md` § Library options; bash 3.2 rules).
- One quote state per line, computed before any reader runs and shared by the `source`/`.` branch, the anchored token scan, cwd-relative and bare relative calls; it advances on every line that is code or inside a quote (D1).
- A `#` that starts a word outside quotes ends the code on its line; a `#`-led line inside an open quote is quoted text (D2).
- In the lines a double-quoted string spans, plain text is data and a `$(...)` inside it is code; a double-quoted string on one line keeps today's handling (D3).
- A `<<` inside a quoted string does not start a heredoc skip (D4).
- A detected call is never filtered: it is an edge or `couldNotResolve` (pitfall "Report a detected call as unresolved; never filter it out"; ADR-0003).
- The output JSON shape and the CLI do not change.

## Non-goals

- A full shell parser or AST.
- Changes to how `case` arm patterns are read.
- Heredoc handling beyond D4.
- Republishing the Tier B caches beyond what sign-off already does.

## Success signal

Regenerating the architecture cache lists no Unresolved edge that comes from quoted text (the `tests/scripts/extractor-bash.sh:205` `./x` entry is gone), and the repo-wide before/after diff of the extractor's output shows only removed in-quote edges and restored calls.

## Links

- Codebase map: [codebase-map.md](codebase-map.md)
- Design log: [design-log.md](design-log.md)
- Tasks: [tasks.md](tasks.md)

## Known gaps

- Gate skipped (3.10 browser suite): no `e2e-browser` profile in this repo. Handoff: [.workflow/deferred/browser-suite.md](../../deferred/browser-suite.md)
