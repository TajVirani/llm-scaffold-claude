# Data model: Cache build follow-ups from spec 003

Spec: [spec.md](spec.md) · Placement: lib, feature-workflow, regenerate-caches, agents (design-log 2026-10-26 Placement (0.3.4))

## Summary

No persisted data or schema changes. The parts are script interfaces and one cache section.

| Part | Kind | Classification | Owning module |
| --- | --- | --- | --- |
| `.agents/lib/test-paths.sh` (default test patterns, profile `test_patterns` loader, test-path matcher) | interface | create | lib |
| `.agents/lib/workflow-paths.sh`: `wf_main_root`, `wf_norm_folder spec\|initiative <arg>` | interface | extend | lib |
| `budget-check.sh` test-path copy and `norm_spec_dir`/`main_root` copy | interface | refactor | feature-workflow |
| `status-transition.sh`, `task-waves.sh`, `commit-workflow-data.sh`, `initiative-transition.sh` normaliser copies | interface | refactor | feature-workflow |
| `open-task-pr.sh` inline spec-path and `--record` normalising (both gain the parent-folder check, D10) | interface | refactor | feature-workflow |
| `budget-check.sh --spec-dir` CLI and JSON output | interface | unchanged | feature-workflow |
| `build-architecture.sh` test-path copy (`test_patterns`, `is_test_file`, defaults) | interface | refactor | regenerate-caches |
| `build-architecture.sh` entry-candidate JS regex (D8) | interface | unchanged | regenerate-caches |
| `build-architecture.sh` Boundary violations section (`Not checked: depcruise did not run (<reason>).`, three fixed reasons, D9) | interface | extend | regenerate-caches |
| `build-architecture.sh` CLI (`--cache`, `--scope`, `--violations-json`, `--print-generator`) | interface | unchanged | regenerate-caches |
| `extractors/bash.sh` `case`/`esac` state in the awk parser | interface | refactor | regenerate-caches |
| `extractors/<name>.sh` JSON output shape | interface | unchanged | regenerate-caches |
| `check-staged-cache.sh` Mermaid check (runs validate_mermaid.mjs or prints `not machine-validated` and the checklist path) | interface | extend | regenerate-caches |
| `.agents/agents/cache-regeneration.md` step 4 (visual-change-report references removed) | interface | refactor | agents |
| Profile Toolchain `test_patterns` key | field | unchanged | (profiles, Tier A) |
| `.workflow/rules.md` Ownership `agents.may_depend_on` | field | unchanged in this spec; P1 at 5.3 | (Tier A) |

## Migrations

None.
