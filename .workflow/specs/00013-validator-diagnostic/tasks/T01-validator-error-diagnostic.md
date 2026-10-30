# T01: Report a broken validator with yq's diagnostic in both single writers

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** When the template validator cannot run, `status-transition.sh set-task` and `initiative-transition.sh` (every `write_validated` caller) say so with yq's own error text and exit 1; when the validator runs and rejects the write, they refuse exactly as today.

- Run the validator without `-e`, capturing what it prints and its stderr: printed `true` moves the prepared copy into place; printed `false` refuses with today's message and code; a non-zero yq exit, or any other output, is a validator error whose message includes yq's stderr (D1).
- A validator error exits 1 in both writers; an ordinary rejection keeps exit 1 (status-transition) and exit 2 (initiative-transition). Update each `# Exit:` header so it names the validator-error case (D2).
- The prepared copy is removed on every refusal and error; the target file and the step marker are untouched. The validator expressions do not change.

**Seam:** the two CLIs (`status-transition.sh set-task <spec-dir> T<n> ...`, `initiative-transition.sh <command> ...`): exit code, stderr and the files on disk, driven by `tests/scripts/status-transition-tasks.sh` and `tests/scripts/initiative-transition.sh` on run-time fixtures, with a PATH yq shim for the broken validator (the pattern at `tests/scripts/initiative-transition.sh:107-115`).

**Acceptance criteria:**

- [ ] status-transition: with a yq shim that fails only the validator call (stderr diagnostic, no stdout), `set-task` exits 1, stderr includes the diagnostic, tasks.md is byte-identical, `.step` is unchanged and no `tasks.md.*` copy is left (D1, D2, D3).
- [ ] initiative-transition: the same for a `write_validated` caller (exit 1, diagnostic in stderr, file byte-identical, no copy left) (D1, D2, D3).
- [ ] An ordinary rejection in each writer keeps today's message and exit code (1 and 2) and its stderr holds no yq `Error:` text (D3).
- [ ] Every existing case in `tests/scripts/status-transition-tasks.sh`, `tests/scripts/status-transition-specs.sh` and `tests/scripts/initiative-transition.sh` still passes, including the validator-text equality check.
- [ ] Both `# Exit:` headers name the validator-error exit (D2).

**Predicted files:** `.agents/skills/feature-workflow/scripts/status-transition.sh`, `.agents/skills/feature-workflow/scripts/initiative-transition.sh`, `tests/scripts/status-transition-tasks.sh`, `tests/scripts/initiative-transition.sh`

**Phase 1 tests:** None.

**Size:** S (4 files, about 90 changed lines).

**Mode:** afk.

**Notes:** None. Probes on mikefarah yq v4.54.1 (codebase-map.md § Not found): without `-e`, a false result prints `false` with rc 0 and no stderr, true prints `true` rc 0, and a runtime error gives rc 1 with `Error: <diagnostic>` on stderr; with `-e`, a false result also writes `Error: no matches found` to stderr, which is why `-e` goes.
