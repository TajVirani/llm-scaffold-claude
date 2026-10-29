# T04: Bash graph extractor skips case arm patterns

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** The bash graph extractor tracks `case ... in` / `esac` and skips only each arm's pattern list, up to its first unquoted `)`, so patterns such as `../*|/*)` are never read as script calls. Commands after the `)`, on the same line or below, are still scanned and reported (a detected call is reported as unresolved, never filtered: D3 and `.workflow/decisions/pitfalls.md`). This repo's rebuilt architecture cache then has no `install.sh:133` or `install.sh:187` entry under Unresolved edges.

**Seam:** `extractors/bash.sh --root <fixture> --scope .` JSON on the `case` forms fixture, and `build-architecture.sh --cache architecture` over a copy of this repo in `tests/scripts/cache-repo-architecture.sh`.

**Acceptance criteria:**

- [ ] One-line, multi-line, `(pattern)`, `./x)`, `|`-alternation and default arms, a whole `case` on one line, and a `case` inside a loop: no pattern text in `couldNotResolve` or as an edge.
- [ ] Every arm-body call is still reported, resolved or unresolved, at its line.
- [ ] The rebuilt cache for this repo lists no `install.sh:133` / `:187` entry and keeps every other entry in `tests/fixtures/architecture-oracle.sh` (TGT-002).
- [ ] Architecture build for this repo's published scope stays at or under 1.2 s, best of 3 (TGT-001).
- [ ] `tests/scripts/extractor-bash.sh` and `tests/scripts/cache-repo-architecture.sh` pass; shellcheck clean.

**Predicted files:** `.agents/skills/regenerate-caches/scripts/extractors/bash.sh`

**Phase 1 tests:** `tests/scripts/extractor-bash.sh`, `tests/scripts/cache-repo-architecture.sh`

**Size:** S (1 file, about 80 changed lines).

**Mode:** afk.

**Notes:** Bash 4 `;&` and `;;&` terminators are out of scope (shelved: `.workflow/deferred/bash-case-fallthrough.md`). bash 3.2 only.
