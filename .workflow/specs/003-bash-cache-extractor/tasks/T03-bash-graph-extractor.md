# T03: Bash graph extractor

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** `extractors/bash.sh` replaces the Phase 1 stub. It claims `*.sh` files and files with a bash or sh shebang under the scopes and prints dependency-cruiser-shaped JSON: an edge for every `source`/`.` line and script call whose path resolves statically (dir-anchored, `$here`-style variable, one variable hop, inline `dirname`, runtime-root call with an existing tail), `couldNotResolve: true` with the source text in `module` and the 1-based `line` for each that does not (D3, D9, D15), and an `exports` map of sorted unique top-level functions of sourced files (D6).

**Seam:** extractors/bash.sh --root DIR --scope PATH... and its Graph JSON on stdout.

**Acceptance criteria:**

- [ ] Output passes the shape gate and is sorted and deterministic; paths are repo-root relative.
- [ ] Every statically resolvable source and call is an edge; nothing is guessed.
- [ ] Each unresolvable path is `couldNotResolve` with `module` and `line`.
- [ ] `exports` lists only sourced files' top-level functions.
- [ ] A single-directory scope claims only its files; no arguments, `--root` without `--scope` and a missing root exit 2.
- [ ] bash 3.2 with BSD/GNU-portable awk, grep and jq only.

**Predicted files:** `.agents/skills/regenerate-caches/scripts/extractors/bash.sh`

**Phase 1 tests:** `tests/scripts/extractor-bash.sh`

**Size:** M (1 files, about 200 changed lines).

**Mode:** afk.

**Notes:** Performance target: under 30 s on this repo (verification-plan Targets, extractor-time); prefer one awk pass per file over per-line subprocesses.
