---
cache_stamps:
  modules: 58019c8c55ed4443f78f085b13abdfb5d96c28ea
  flows: 58019c8c55ed4443f78f085b13abdfb5d96c28ea
  architecture: 58019c8c55ed4443f78f085b13abdfb5d96c28ea
---

# Codebase map: The bash graph extractor never reads quoted text as commands

Affected area: module `regenerate-caches` (owns `.agents/skills/regenerate-caches/**`): `.agents/skills/regenerate-caches/scripts/extractors/bash.sh`; its suite in module `tests`: `tests/scripts/extractor-bash.sh`, fixture `tests/fixtures/graph-extractors.sh`.

## Relevant code

| Item | What it does today | Source |
| --- | --- | --- |
| Usage and output contract | `extractors/bash.sh --root DIR --scope PATH...`; prints `{"modules","exports"}`; exit 0 printed, 2 usage or tool failure | `.agents/skills/regenerate-caches/scripts/extractors/bash.sh:2-24` |
| File claim | `*.sh` files and files with a bash/sh shebang, from `git ls-files`; symlinks skipped | `bash.sh:62-73, 82, 91-92` |
| Per-file reset | Resets `open_quote`, heredoc and continuation state on each file's first line | `bash.sh:89-98` (`open_quote = ""` at `:96`) |
| Line pre-filter | Strips CR; skips heredoc bodies; skips `#` comment lines before any quote or continuation update | `bash.sh:100, 102-109` |
| Continued lines | `continues_mid_command` from a trailing `\` not after an operator | `bash.sh:113-115` |
| `source` / `.` branch | One edge per `source`/`.` line; a bare name only if not a jq `. as $name`; calls not scanned on these lines | `bash.sh:139-145` |
| Anchored call scan | `$`-anchored token ending `.sh`, or a `/` path that `resolve_anchored`/`is_claimed_script` accept, is an edge | `bash.sh:146-160` |
| cwd-relative calls | `report_cwd_relative_calls(line)`: `./x`, `../x`, `bash x`, `sh x` give an unresolved edge | `bash.sh:161, 410-429` |
| Bare relative calls | `report_bare_relative_calls(code, continued_mid_command)`: a plain `dir/x` first word gives an unresolved edge | `bash.sh:162, 465-476` |
| Heredoc start | Regex on the raw line, guarded by `((`; sets the end marker | `bash.sh:166-171` |
| Quote state across lines | `open_quote` is written only in `unquoted_code`; only `report_bare_relative_calls` reads it (`quote_opened_before`) | `bash.sh:440-453`, `:466`, `:469` |
| `unquoted_code` | Drops single-quoted text and double-quoted text holding a space; a span open at line end carries in `open_quote` | `bash.sh:434-457` |
| `split_commands` | Drops single-quoted spans and text after an unclosed `'` on the line; `(` and `$(` start commands | `bash.sh:388-403` |
| Double quotes | `remove_double_quotes` strips every `"` before the anchored scan and the cwd reporter | `bash.sh:124, 182-185` |
| Case patterns | `blank_case_patterns` reads `open_quote` but writes only its local `quote` | `bash.sh:322-375` |
| Edge output and final JSON | `add_edge` prints `E` records; unresolved edges keep every line | `bash.sh:480-507` |
| Cached false edge | `tests/scripts/extractor-bash.sh:205 ./x` under Unresolved edges | `.workflow/cache/architecture.md` § Unresolved edges |
| Why line 205 is read | Inside the jq program opened on 204; `"(./x"` loses its quotes, `(` starts a command in `split_commands`, `./x` is a cwd-relative call | `bash.sh:124, 161, 388-395, 410-420`; `tests/scripts/extractor-bash.sh:204-205` |
| Multi-line quote suite cases | Only one: a jq program whose continuation starts with a backtick (`:137-143`); line 205 has no assertion | `tests/scripts/extractor-bash.sh:114-115, 137-143, 155-157` |
| Fixture | `bash_project_repo` and `BASH_*` variables pin line numbers; no multi-line quoted string in its code lines | `tests/fixtures/graph-extractors.sh:24-33, 35-131` |

## Seams and interfaces

| Interface | Shape (signature, type, contract) | Callers | Source |
| --- | --- | --- | --- |
| CLI | `--root DIR`, repeatable `--scope PATH`; stdout JSON; exit 0 or 2 | `build-architecture.sh:128-143, 269-272`; `tests/scripts/extractor-bash.sh:25, 102, 195, 228` | `bash.sh:17-24, 35-55` |
| Output JSON | `{"modules":[{"source","dependencies":[{"module","resolved"\|"couldNotResolve":true,"line"}]}],"exports":{...}}`, byte-sorted | `build-architecture.sh` (ADR-0003: the one reader); the suite | `bash.sh:20-21, 489-507`; ADR-0003 |
| Unresolved record | `couldNotResolve: true`, `module` = path text, one record per line | same | `bash.sh:487, 500-502`; ADR-0003 |
| Suite helpers | `resolved_of`, `unresolved_of` read the JSON with jq | `tests/scripts/extractor-bash.sh` | `tests/scripts/extractor-bash.sh:30-33` |
| Fixture seam | `BASH_*_LINE`, `BASH_*_TEXT` pin lines in `bash_project_repo` | `tests/scripts/extractor-bash.sh:37-57`, other cache suites | `tests/fixtures/graph-extractors.sh:24-33, 39` |

## Prior decisions

| Decision or item | What it says | Source |
| --- | --- | --- |
| ADR-0003 graph extractor per work profile | dependency-cruiser JSON shape; an unresolvable path is `couldNotResolve`, never a guessed edge | `.workflow/decisions/adr/0003-graph-extractor-per-profile.md` |
| Pitfall: report a detected call as unresolved | Never filter a detected call; prevented by the call-form cases in the suite | `.workflow/decisions/pitfalls.md` § Report a detected call as unresolved; never filter it out |
| CAP-005 bash graph extractor | File graph from `source`/`.` and calls; unresolved under Unresolved edges | `.workflow/capabilities.md` CAP-005 |
| Retrospective 005 open item | The line-205 false entry, predating 005, deferred to this backlog item | `.workflow/decisions/retrospectives/005-cache-build-followups.md` |
| Retrospective 003 | The quote scanner was added in rework 2 (F10) | `.workflow/decisions/retrospectives/003-bash-cache-extractor.md` |
| Rules | `regenerate-caches` owns `.agents/skills/regenerate-caches/**`; bash 3.2, no bash 4 constructs; scripts are bash | `.workflow/rules.md` § Ownership, § Required versions |
| Shelf `bash-case-fallthrough.md` | `;&`/`;;&` terminators; not a match | `.workflow/deferred/bash-case-fallthrough.md` |

## Library options

### Quote tracking

Verdict: Use existing. Keep the in-house awk in `extractors/bash.sh` and close the gap there; no library. Every parser candidate adds a runtime outside the `bash.sh:24` (git, awk, jq) and `install.sh:143-144` contract.

| Option | Fit | Licence | Maintenance | Security | Cost |
| --- | --- | --- | --- | --- | --- |
| In-house awk, bash.sh (incumbent) | caution: covers bare-relative calls; gap on cwd, source and `$var` paths for lines starting inside a quote | pass | pass | pass | pass: 0 deps |
| mvdan/sh v3.14.1 | caution: full AST, Go module, adapter needed | pass: BSD-3-Clause | pass: Maintained 10 | caution | fail: Go 1.26+ as a new install requirement |
| tree-sitter-bash 0.25.1 | caution: grammar only, needs runtime | pass: MIT | caution: Maintained 0 | caution | fail: runtime plus Node or native binding |
| bash-parser 0.5.0 | unknown | pass: MIT | fail: last release 2017 | caution | fail: Node runtime |

Evidence:
- https://github.com/mvdan/sh; https://api.deps.dev/v3/systems/go/packages/mvdan.cc%2Fsh%2Fv3/versions/v3.14.1; https://api.deps.dev/v3/projects/github.com%2Fmvdan%2Fsh
- https://github.com/tree-sitter/tree-sitter-bash; https://api.deps.dev/v3/systems/npm/packages/tree-sitter-bash/versions/0.25.1; https://api.deps.dev/v3/projects/github.com%2Ftree-sitter%2Ftree-sitter-bash
- https://github.com/vorpaljs/bash-parser; https://api.deps.dev/v3/systems/npm/packages/bash-parser/versions/0.5.0; https://api.deps.dev/v3/projects/github.com%2Fvorpaljs%2Fbash-parser
- community: https://jsr.io/@ein/bash-parser@3.0.0; https://npmjs.com/@ericcornelissen/bash-parser

Risks (from the return):
- A continuation line inside a double-quoted string (`./build.sh is ready"`) gets an unresolved edge at `:161`; a `source x` or `$here/...` at the start of a line inside a string would become an edge.
- Quote state advances only on non-source, non-comment lines (`:109`, `:139`, `:162`), so a string closing on a `#`-led line could leave `open_quote` set.

## Not found

- Shelf match for multi-line quoted text: none in the 19 `.workflow/deferred/*.md` files. Reported by retrieval.
- flows.md has no section for `extractors/bash.sh`. Reported by retrieval.
- Suite or fixture cases with a cwd-relative, `$var/...` or bare path on a line inside a multi-line quote: none. Reported by retrieval.
- Heredoc start regex runs on the raw line, so a `<<` inside a string would start a skip; no suite case. Read from code by retrieval, not run.
- Main-session probes at `8e832be` (scratch repo): a line starting `./x` inside a multi-line single quote is reported (`./line-start-in-quote`); a line `./x` inside a multi-line double quote is reported; `$(./y.sh)` inside it is reported (correct); a trailing comment with an apostrophe (`echo hi # don't`) makes the bare-relative reader drop the real `scripts/x.sh` calls on later lines until the quote parity flips back; without that comment line both calls are reported. Trailing-comment apostrophes exist at `check-write.sh:71`, `:73`, `post-implementation-audit.sh:217`, `build-architecture.sh:114`.
