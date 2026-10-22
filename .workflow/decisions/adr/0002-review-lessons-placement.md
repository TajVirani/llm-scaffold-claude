---
status: accepted
---

# Review lessons: the retrospective owns them, the review lens only reads them

Lessons a retrospective records reached the Phase 4 review only after a human rewrote them as a rule or a profile line. We place the review lesson with the `retrospective` module: it defines the entry and is the only writer of `.workflow/review-lessons.md`, at 5.7 under the stakeholder's approval; the `review-lessons` lens in `agents` and the Phase 4 wiring in `feature-workflow` consume the file and never write it. The file is a top-level Tier A file with its own write-guard class rather than an entry under `decisions/`, because the decisions class is also writable at 0.3.7 and 5.3 and the lessons are review input, not a decision record.

## Considered Options

- `feature-workflow` as owner: it owns the Phase 4 step, the launch table and the guard classes, but the lessons are a retrospective output and the wiring only carries them; the stakeholder placed the feature with the producer.
- `agents` as owner: the lens is the visible new file, but the module cannot own the triage, guard or retrospective changes.
- `.workflow/decisions/review-lessons.md`: guarded for free by the existing Tier A class, but that class admits writes at 0.3.7 and 5.3 as well, and the lessons would read as decisions.

## Consequences

- `.agents/lib/workflow-paths.sh` gains one path variable for the file; it is shared core, so the change goes through the integration agent.
- A lesson a rule, lint or profile line already enforces is not a review lesson: those keep the proposal path, so the file stays the list of what only a reader can catch.
