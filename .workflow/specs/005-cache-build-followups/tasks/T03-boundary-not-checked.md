# T03: Boundary violations says Not checked when depcruise did not run

Index: [../tasks.md](../tasks.md) · Blocked by: T2 (Flow entry candidates read test files through the shared helper; same file) · Parallel with: None

**What to build:** When the architecture build runs the depcruise boundary check and depcruise does not run, Boundary violations reads `Not checked: depcruise did not run (<reason>).` instead of `None.`, and the build exits 0. Depcruise counts as run only when its output parses as JSON with a `.summary.violations` array (D9). The reason is one of three fixed strings: `not found` (the `DEPCRUISE` path or the `npx` fallback cannot be run, checked before running), `exited <n> without a JSON report`, `no .summary.violations in its output`. With violations, the section lists them as today.

**Seam:** `build-architecture.sh --cache architecture` on the JS fixture project in `tests/scripts/cache-boundary-check.sh`, with `DEPCRUISE` stand-ins.

**Acceptance criteria:**

- [ ] Missing `DEPCRUISE` path: exit 0, `Not checked: depcruise did not run (not found).` (not "exited 127").
- [ ] Stand-in exits 3 with no output: exit 0, `Not checked: depcruise did not run (exited 3 without a JSON report).`
- [ ] Stand-in prints JSON without `.summary.violations`: exit 0, `Not checked: depcruise did not run (no .summary.violations in its output).`
- [ ] Stand-in with violations: the list renders as before; a `--violations-json` file that does not parse still exits 2.
- [ ] depcruise's stderr never reaches the cache body.
- [ ] `tests/scripts/cache-boundary-check.sh` passes; shellcheck clean.

**Predicted files:** `.agents/skills/regenerate-caches/scripts/build-architecture.sh`

**Phase 1 tests:** `tests/scripts/cache-boundary-check.sh`

**Size:** S (1 file, about 60 changed lines).

**Mode:** afk.

**Notes:** None.
