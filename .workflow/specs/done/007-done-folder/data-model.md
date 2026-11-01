# Data model: Done folder for finished specs

Spec: [spec.md](spec.md) · Placement: feature-workflow

## Summary

| Part | Kind | Classification | Owning module |
| --- | --- | --- | --- |
| Spec folder location | field (path) | extend | feature-workflow |
| `WF_SPECS_DONE` | interface (path constant) | create | lib (shared core) |
| `wf_norm_folder spec` | interface | extend | lib (shared core) |
| `move-to-done.sh` (`--check`, move, `--sweep`) | interface | create | feature-workflow |
| Path references to a spec in `.workflow/` files | field | extend | feature-workflow (written by `move-to-done.sh`) |
| `origin_spec` pattern in review lessons | field | extend | feature-workflow |
| `check-write.sh` path class for `specs/done/**` | interface | extend | feature-workflow |
| Initiative links to emitted specs | field | extend (rewritten at 6.13) | feature-workflow |
| Task record `status` | field | unchanged | feature-workflow |
| Work-backlog item `status` | field | unchanged | feature-workflow |
| `.step` marker | entity | unchanged (removed on move) | feature-workflow |
| Sign-off PR description `pr-body.md` | field (path strings) | extend (rewritten by the move, checked again, published from `done/`, D14) | feature-workflow |

## Entities

### Spec folder (extend)

A spec's folder under `.workflow/specs/`; once moved it lives in the **Done folder**.

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| location | path | yes | `$WF_SPECS/NNN-slug` while not moved; `$WF_SPECS_DONE/NNN-slug` only when `status: done` (CAP-NEW-done-folder) | extend |
| status | enum | yes | unchanged set; `done` set at 5.7 only after the sub-item check passes (D8) | unchanged |
| tasks[].status | enum | yes | every record `done` or `split-out` before `done` and before the move (D4); backlog items from the spec `open`, `promoted`, `moved-to-deferred` or `dismissed` (D12) | unchanged |
| `.step` | file | no | absent in `done/` (removed on move) | unchanged |

**Relationships:** a spec is referenced by work-backlog items (`origin_spec`), shelf files (`origin_spec`, `superseded_by`), retrospectives (`spec:`), capabilities rows, review lessons (`origin_spec`), pitfalls, initiative `slices[].spec`, and other specs' files. On move every such path string is rewritten (D3, D6); none is deleted.

**State transitions:**

| From | Event | To | Guard |
| --- | --- | --- | --- |
| `in-review` at top level | 5.7 sub-item check passes, retrospective accepts | `done` at top level | every task `done`/`split-out`; every backlog item from this spec `open`/`promoted`/`moved-to-deferred`/`dismissed` |
| `done` at top level | 5.8 `move-to-done.sh` (or `--sweep`) | `done` in `done/` | same check re-run; target `done/NNN-slug` does not exist |
| `done` in `done/` | any Write/Edit | refused | `check-write.sh` denies (D11) |

**Invalid states ruled out:** a spec in `done/` whose status is not `done` (the script refuses to move it); a spec in `done/` with an open task record (check refuses). Still representable: a spec left `done` at the top level if 5.8 is never reached; the next `--sweep` moves it.

## Migrations

| # | Migration | Classification | Reversible | Depends on | Data handling |
| --- | --- | --- | --- | --- | --- |
| M1 | Add `WF_SPECS_DONE` and let `wf_norm_folder` accept a `done/` child | create / extend | yes (code revert) | - | none |
| M2 | Teach readers `done/`: 0.1.1 scan, `spec_done_on_main` / 6.13 (both locations), review-lessons regex and slug class, `check-write.sh` deny class | extend | yes (code revert) | M1 | none |
| M3 | `move-to-done.sh` and the 5.7 / 5.8 / 6.13 wiring | create / extend | yes (code revert) | M1, M2 | none |
| M4 | Run `--sweep` on this repo: move every spec done on main (001-006, 008) into `done/`, rewrite their links | refactor | yes (`git revert` of the sweep commit) | M3 | path strings rewritten in place; no content removed |
