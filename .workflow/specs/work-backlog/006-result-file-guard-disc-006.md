---
origin_spec: .workflow/specs/006-result-file-guard
origin_step: "3.7"
discovered_at: 2026-10-29
status: open
kind: decision
---

# End of input at the matcher prompt merges silently

## Problem

At the `install.sh` matcher prompt, end of input (Ctrl-D) counts as Enter, so a mergeable group is merged. In ask mode a merge prints no Warnings line, so the only trace of the change is the settings file. A user who presses Ctrl-D to back out gets a merge.

## Evidence

- `install.sh:440` and its header note at `install.sh:434`, at T6 head `0662bfe`.
- T6 mini-review round 2, `.workflow/specs/006-result-file-guard/artifacts/T6/mini-review-r2.yaml` `out_of_scope_noticed`: "At the matcher prompt, end of input (Ctrl-D) counts as Enter."

## Why not a blocker

D25 makes Enter merge, and the header records the end-of-input choice. JRN-013 (Enter merges, `r` replaces, `k` keeps) is met. No group is changed without a terminal on stdin and stdout.

## Suggested scope and size

- Scope: decide whether end of input at the prompt keeps the group (with a warning) or stops the run before any write. Then adjust the prompt and add a pseudo-terminal case to `tests/scripts/install-upgrade.sh`.
- Size: 1 task in the installer, 2 files; well inside the defaults (10 tasks, 30 changed files).

## Links

- Origin spec: [spec.md](../006-result-file-guard/spec.md)
- Design log entry: [design-log.md](../006-result-file-guard/design-log.md) (section 2026-10-29 Discovered work: prompt-eof-merges)
