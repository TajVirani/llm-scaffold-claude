# .agents

The distribution unit of the scaffold. See the repo [README.md](../README.md) for the index of workflow skills, agents, hooks and helper scripts, [../PROVENANCE.md](../PROVENANCE.md) for what is first-party and where each asset came from, and `install-manifest.txt` for what `install.sh` ships to target projects. Run the tests with `tests/run-all.sh` from the repo root.

# data-structure-audit bundle

Incremental, git-anchored audit of data structures: invalid representable
states, unnecessary complexity, and (evidence-gated) performance. Only
re-checks code that changed since the last recorded run.

## Install (per project)

Run `install.sh` from the scaffold repo root against the target project. It ships the first-party payload named in `install-manifest.txt`, which includes `data-structure-audit` and `pr-review-data`:

    ./install.sh <target-project>

See the repo [README.md](../README.md) for options and what it creates.

## Invoking

- /pr-review-data            — alias skill (optionally: /pr-review-data internal/models)
- /data-structure-audit      — the skill's native slash name
- Auto-triggers on natural-language requests matching its description
  (audit/review types, structs, models, schemas, impossible states, etc.)

## State

The skill records audited commits in .workflow/data-structure-audit-state.jsonl
(commit it with your changes) and adds a `merge=union` .gitattributes rule so
parallel branches merge cleanly. Delete the state file to force a full re-audit.
See skills/data-structure-audit/references/incremental.md for mechanics.
