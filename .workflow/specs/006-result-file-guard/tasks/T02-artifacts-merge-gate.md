# T02: Artifacts merge gate

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** `.agents/skills/feature-workflow/scripts/check-merge-artifacts.sh --spec-dir <dir> --rev <branch or commit> [--cwd <dir>]`, which replaces the Phase 1 stub. Before the orchestrator merges a branch or a light-path commit into the spec branch, the gate refuses the merge when the revision adds, modifies or deletes anything under `<spec_dir>/artifacts/` since its merge-base with `spec/NNN-slug`. Result files and evidence then reach the spec branch only through the main checkout, never through an agent's branch.

**Seam:** The script's command line (exit code, stdout lines, stderr) on a fixture repo with a spec branch, task branches and detached commits (`tests/scripts/check-merge-artifacts.sh`, JRN-007).

**Acceptance criteria:**

- [ ] Exit 0 when the revision changes nothing under `<spec_dir>/artifacts/` since the merge-base. Files already committed there on the spec branch do not trip it.
- [ ] Exit 1 for an add, a modify or a delete under `artifacts/`, printing one stdout line per offending path that names the path. This holds for a branch and for a detached commit.
- [ ] Exit 2 for a usage error (missing `--spec-dir` or `--rev`, an unknown flag), an unknown revision, a missing spec branch, a spec folder `wf_norm_folder` rejects, or a cwd outside git.
- [ ] Paths are matched as literal pathspecs. Only the given spec's `artifacts/` counts.
- [ ] The `# File:` header is the interface doc: usage, exits, and why the gate is never piped into another command.
- [ ] `tests/scripts/check-merge-artifacts.sh` passes and shellcheck is clean.

**Predicted files:** `.agents/skills/feature-workflow/scripts/check-merge-artifacts.sh`

**Phase 1 tests:** `tests/scripts/check-merge-artifacts.sh`

**Size:** S (1 file, about 90 changed lines).

**Mode:** afk.

**Notes:** Reuse the main-checkout gate pattern of `scripts/commit-workflow-data.sh` (`wf_main_root`, `wf_norm_folder`, literal pathspecs). `PROVENANCE.md` already has the row from Phase 1; the manifest covers the script through `skills/feature-workflow`.
