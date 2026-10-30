# Verification plan: Done folder for finished specs

Spec: [spec.md](spec.md)

## End state

- [ ] CAP-NEW-done-folder: `move-to-done.sh --check` on a fixture spec with every task `done`/`split-out` and every backlog item from it `open`/`promoted`/`moved-to-deferred`/`dismissed` exits 0; with one task `pending` it exits non-zero, names that task, and changes no file.
- [ ] CAP-NEW-done-folder: sign-off 5.7 runs the check before `status ... done`; a failing check leaves the spec `in-review`.
- [ ] CAP-NEW-done-folder: moving a `done` fixture spec puts it at `.workflow/specs/done/NNN-slug/` with no `.step`, `spec_branch` unchanged, and the old folder gone.
- [ ] CAP-NEW-done-folder: after the move, every `.workflow/` file outside `cache/` and `initiatives/` that named the spec (repo-relative, `../specs/`, `../../specs/`, `specs/`, and `../NNN-slug/` from `work-backlog/` or a sibling spec) names the `done/` path; files under `cache/` and `initiatives/` are byte-identical; no other text in any file changed.
- [ ] CAP-NEW-done-folder: inside the moved spec, every relative link that leaves the folder still resolves to an existing path, and its own `.workflow/specs/NNN-slug` strings name the `done/` path.
- [ ] CAP-NEW-done-folder: moving a spec whose status is not `done`, or whose `done/NNN-slug` already exists, is refused with nothing changed.
- [ ] CAP-NEW-done-folder: `--sweep` moves every top-level `done` spec and leaves `draft`/`in-progress` specs and `work-backlog/` in place.
- [ ] CAP-NEW-done-folder: the 0.1.1 scan counts a spec in `done/`, so the next number is above it.
- [ ] CAP-NEW-done-folder: `spec_done_on_main` is true for a `done` spec on main at the top level and in `done/`; the 6.13 rewrite fixes the initiative's links on the initiative branch.
- [ ] CAP-NEW-done-folder: `check-write.sh` denies a Write/Edit under `.workflow/specs/done/**` (main session and sub-agent).
- [ ] CAP-NEW-done-folder: `review-lessons.sh validate` accepts `origin_spec: .workflow/specs/done/NNN-slug` and a slug with uppercase, `.` or `_`; rejects a path outside `.workflow/specs/`.
- [ ] CAP-NEW-done-folder: a spec with a five-digit number (`00010-x`) is checked, moved, counted by 0.1.1 and accepted by `review-lessons.sh` exactly like a three-digit one.
- [ ] CAP-NEW-done-folder: sign-off 5.8 runs the move after the pre-move `check-pr-body.sh`; the moved `pr-body.md` differs from the approved one only in the spec path, `check-pr-body.sh` exits 0 on it, and the publish block with `SPEC_DIR=.workflow/specs/done/NNN-slug` builds the merge message from it (D14).
- [ ] CAP-NEW-done-folder: `sign-off.md` 5.8 says a fault on the moved body stops sign-off unpublished as a move bug and names no write into the moved folder; the `<!-- 5.8 publish commands -->` marker stays directly above the publish block (D15).
- [ ] CAP-NEW-done-folder: in this repo, every spec done on main before this feature (001-006, 008) sits under `.workflow/specs/done/` after the sweep, 009 and 00010 stay at the top level, and `tests/run-all.sh` passes.

## Journeys

No running application: each journey is a harness suite run against a fixture project.

| Id | Journey | Proves | Steps | Expected outcome | Check |
| --- | --- | --- | --- | --- | --- |
| JRN-001 | Check refuses an open task | CAP-NEW-done-folder | 1. Fixture spec `in-review`, one task `pending`. 2. Run `move-to-done.sh --check`. 3. Run the 5.7 sequence. | Non-zero exit naming T<n>; spec stays `in-review`; tree unchanged | `tests/scripts/move-to-done.sh` |
| JRN-002 | Sign-off move with links | CAP-NEW-done-folder | 1. Fixture `done` spec referenced from a shelf file, retrospective, capabilities row, review lesson, backlog item (`../NNN-slug/`), sibling spec, cache and initiative file. 2. Run the move. | Spec in `done/`, no `.step`; every reference outside `cache/`/`initiatives/` rewritten; cache and initiative untouched; outbound links inside resolve | `tests/scripts/move-to-done.sh` |
| JRN-003 | Sweep | CAP-NEW-done-folder | 1. Fixture with two `done` specs, one `draft`, `work-backlog/`. 2. Run `--sweep`. | Both `done` specs in `done/`; `draft` and backlog untouched | `tests/scripts/move-to-done.sh` |
| JRN-004 | Readers after the move | CAP-NEW-done-folder | 1. Spec in `done/`. 2. Run the 0.1.1 scan, `spec_done_on_main`, `check-write.sh` on a file in it, `review-lessons.sh validate`. | Number counted; done-on-main true; write denied; lesson valid | `tests/scripts/move-to-done.sh`, `tests/scripts/check-write-paths.sh`, `tests/scripts/lib-workflow-paths.sh`, `tests/scripts/review-lessons.sh`, `tests/hooks/session-start-initiatives.sh` |
| JRN-005 | This repo swept | CAP-NEW-done-folder | 1. Run `--sweep` here. 2. `tests/run-all.sh`. | 001-006 and 008 under `done/`; 009 and 00010 untouched; all suites pass | `tests/run-all.sh` after the real sweep (manual run at 3.x) |
| JRN-006 | Sign-off PR body after the move | CAP-NEW-done-folder | 1. Fixture `done` spec with a valid `pr-body.md` naming `.workflow/specs/NNN-slug`. 2. Run the move. 3. Run `check-pr-body.sh` on the moved body. 4. Run the 5.8 publish block (local merge line) with `SPEC_DIR` on the `done/` path. | Body differs only in the spec path; check exits 0; merge message holds the moved body | `tests/scripts/move-to-done.sh`, `tests/scripts/sign-off-pr.sh`, `tests/lint/done-folder-docs.sh` |
| JRN-007 | Any-digit spec numbers | CAP-NEW-done-folder | 1. Fixture with `00010-x` `done` and `009-y` `done`. 2. `--sweep`. 3. 0.1.1 scan. | Both moved; next number is `00011` | `tests/scripts/move-to-done.sh` |

## Fixtures and oracles

| Fixture or oracle | What it provides | Source | Used by |
| --- | --- | --- | --- |
| Fixture project with a spec, tasks, backlog items and back-links | A `.workflow/` tree in a temp git repo | `tests/fixtures/workflow-folders.sh`, extended | JRN-001 to JRN-004 |
| Expected-tree oracle | `git diff --stat` and a grep for the old path after the move: only path strings change, no old-path reference remains outside `cache/`/`initiatives/` | the test itself | JRN-002, JRN-003 |
| Link-resolution oracle | Every relative Markdown link in the moved spec resolves with `test -e` from its file's directory | the test itself | JRN-002 |

## Targets

<!-- 1.1. Measured by review-targets (4.3); reported in report.md "Targets vs measured". -->

Run every command in bash from the repo root on a clean checkout of the feature's HEAD. `BASE` is the baseline:

```bash
BASE=$(yq --front-matter=extract '.baseline_revision' .workflow/specs/done/007-done-folder/spec.md 2>/dev/null || yq --front-matter=extract '.baseline_revision' .workflow/specs/007-done-folder/spec.md)
```

| Id | Kind | Target | Threshold | Command | Source |
| --- | --- | --- | --- | --- | --- |
| TGT-001 | errors | Script lint clean | exit 0; 0 shellcheck findings | `script-lint` below (the `lint` key of the shell-scripts profile) | `.workflow/profiles/shell-scripts.md` § Toolchain |
| TGT-002 | errors | Harness lint clean | exit 0; 0 shellcheck findings | `harness-lint` below (the `lint` key of the test-harness profile) | `.workflow/profiles/test-harness.md` § Toolchain |
| TGT-003 | errors | Agent-docs lint clean | exit 0; each lint suite reports 0 failed | `agent-docs-lint` below (the `lint` key of the agent-docs profile) | `.workflow/profiles/agent-docs.md` § Toolchain |
| TGT-004 | errors | Literal Done folder paths in scripts outside the path library | `0` printed | `done-literal` below | `spec.md` Constraints ("The Done folder path is built from `WF_SPECS` ... never a literal") |
| TGT-005 | coverage | Scripts added or changed since the baseline that no suite names | `0` printed | `script-coverage` below | `.workflow/profiles/test-harness.md` § Mini-review checklist ("A new or changed script has a suite") |
| TGT-006 | coverage | Files added under `.agents/` since the baseline missing from the manifest (or a listed directory) or from `PROVENANCE.md` | `0` printed | `asset-coverage` below | `.workflow/rules.md` § Cross-cutting policy (manifest, PROVENANCE) |
| TGT-007 | performance | Wall time of `move-to-done.sh --sweep` on a scratch clone at the baseline (moves 001-006 and 008, rewrites their links) | real ≤ 30 s, best of 3 | `sweep-time` below: a fresh clone per run, the HEAD `.agents/` copied in, only the sweep timed | Stakeholder decision 2026-10-30 (1.1) |
| TGT-008 | coverage | Line coverage of changed shell code | not measured | Cannot be measured: no bash coverage tool is installed and the scaffold bans new dependencies. TGT-005 and the 3.7 profile checklist stand in for it. | Stakeholder decision 2026-10-30 (1.1) |

Commands referenced above (pipes keep them out of the table cells):

```bash
# script-lint
git ls-files -z -co --exclude-standard -- '.agents/hooks/*.sh' '.agents/lib/*.sh' '.agents/skills/*/scripts/*.sh' install.sh 'scripts/*.sh' | xargs -0 shellcheck -x -P SCRIPTDIR
# harness-lint
git ls-files -z -co --exclude-standard -- 'tests/*.sh' | xargs -0 shellcheck -x -P SCRIPTDIR
# agent-docs-lint
tests/run-all.sh --suite lint/frontmatter && tests/run-all.sh --suite lint/step-list && tests/run-all.sh --suite lint/symlinks && tests/run-all.sh --suite lint/upstream-lineage
# done-literal: script lines naming specs/done outside workflow-paths.sh; the threshold is 0
git grep -n -E 'specs/done' -- '.agents/hooks/*.sh' '.agents/skills/*/scripts/*.sh' install.sh 'scripts/*.sh' | grep -v -E '^[^:]+:[0-9]+:[[:space:]]*#' | wc -l | tr -d ' '
# script-coverage: prints the count of uncovered scripts; the threshold is 0
git diff --name-only --diff-filter=AM "$BASE"..HEAD -- '.agents/hooks/*.sh' '.agents/lib/*.sh' '.agents/skills/*/scripts/*.sh' install.sh | while read -r f; do grep -rqF -- "$(basename "$f")" tests/ || echo "$f"; done | wc -l | tr -d ' '
# asset-coverage: prints the count of new .agents/ files missing from the manifest or PROVENANCE.md; the threshold is 0
git diff --name-only --diff-filter=A "$BASE"..HEAD -- .agents | while read -r f; do r=${f#.agents/}; m=0; while IFS= read -r l; do case "$r" in "$l"|"${l%/}"/*) m=1;; esac; done < .agents/install-manifest.txt; [ "$m" = 1 ] || echo "manifest: $f"; grep -qF -- "$(basename "$f")" PROVENANCE.md || echo "provenance: $f"; done | wc -l | tr -d ' '
# sweep-time: the smallest real value must be at most 30
for i in 1 2 3; do tmp=$(mktemp -d); git clone -q . "$tmp/r" && git -C "$tmp/r" checkout -q "$BASE" && rm -rf "$tmp/r/.agents" && cp -R .agents "$tmp/r/.agents" && (cd "$tmp/r" && /usr/bin/time -p .agents/skills/feature-workflow/scripts/move-to-done.sh --sweep >/dev/null) 2>&1 | awk '/^real/{print $2}'; rm -rf "$tmp"; done | sort -n | head -1
```

## Suites

<!-- 1.2-1.4. Commands come from the profile Toolchain keys: `test` (.workflow/profiles/test-harness.md) and `e2e` (.workflow/profiles/e2e-browser.md). Gates 3.9 and 3.10 run them. -->

| Suite | Profile key | Command (copied from the profile) | CI check | Known-bad-build evidence (1.4) |
| --- | --- | --- | --- | --- |
| Harness | `test` in `.workflow/profiles/test-harness.md` | `tests/run-all.sh` | none (no CI; the run by hand is the whole gate) | [artifacts/phase-1-known-bad/record.md](artifacts/phase-1-known-bad/record.md) Run 1, log [harness.log](artifacts/phase-1-known-bad/harness.log): 122 failures across 7 suites, all assertions |
| Browser | `e2e`: not applicable (no e2e work type, no browser; JRN-001 to JRN-007 are harness suites) | none | none | not applicable; see record.md Run 2 |
