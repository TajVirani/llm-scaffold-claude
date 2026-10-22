---
status: exploring                   # exploring | planned | done. Changed only by scripts/initiative-transition.sh.
origin: NNN-slug                    # folder name of the spec this initiative was converted from
created: YYYY-MM-DD                 # set once at conversion
branch: initiative/NNN-slug         # the branch every initiative commit lands on until `planned` merges
merge_pr: null                      # URL of the `planned` PR/MR, or null (always null under task_review: local)
slices: []
# slices record: {id: S1, title: "<two to eight words>", status: planned, questions: [IQ1], depends_on: [], spec: null}
---
<!--
File: Template for .workflow/initiatives/NNN-slug/initiative.md, the index of one initiative: a subject too large for one spec, planned into slices that each become one spec. Copied at conversion (6.1) together with questions.md; the converted spec's design log and codebase map move into the same folder.

Frontmatter contract (read with mikefarah yq v4, `--front-matter=extract`). initiative-transition.sh, session-start-resume.sh and check-write.sh depend on these keys:
  - status: one of
      exploring   set at conversion, or when the stakeholder reopens a planned initiative   questions are being asked and slices planned
      planned     set when the last slice is emitted   every slice `emitted` or `done`, no question `open` or `researching`; the branch then merges into main
      done        set on a resume that finds every emitted spec `done` on the main branch   terminal
  - origin: string, the `NNN-slug` of the converted spec. That folder no longer exists; its number stays consumed.
  - created: ISO date of the conversion.
  - branch: string, `initiative/NNN-slug`.
  - merge_pr: URL string or null. Written through `initiative-transition.sh set-pr` when the `planned` PR/MR opens.
  - slices: list, empty until the first slice is planned. Each record:
      id          `S<n>`, unique in this file, never reused
      title       two to eight words
      status      planned | emitted | done. `planned` has `spec: null`; `emitted` and `done` name their spec.
      questions   list of `IQ<n>` ids from questions.md that must all be `settled` before the slice is emitted
      depends_on  list of `S<n>` ids of this initiative; it orders the slices for the reader and blocks nothing
      spec        the emitted spec's folder name `NNN-slug`, or null
  Add no other keys. Status changes go only through initiative-transition.sh (`status`, `set-slice`, `set-pr`), never by hand.

Writing rules:
  - Single writer: the main session, on the initiative branch, at 6.1 (enter the initiative, where conversion creates it), 6.7 (plan the slices) and 6.9 (emit a settled slice). Sub-agents never write it.
  - Each commit on the initiative branch holds only files under this initiative's folder. An emitted spec's folder is never part of one.
  - Links, never copies: a slice's detail lives in its spec once emitted; a question's detail lives in questions.md.
  - Delete this comment in the finished file.

Validate the frontmatter (prints true, exits non-zero otherwise):
  yq --front-matter=extract -e '
    (.status | test("^(exploring|planned|done)$")) and
    ((.origin | tag) == "!!str") and
    ((.created | tag) == "!!str" or (.created | tag) == "!!timestamp") and
    ((.branch | tag) == "!!str") and
    (.merge_pr == null or (.merge_pr | tag) == "!!str") and
    ((.slices | tag) == "!!seq") and
    (.slices | all_c(
      ((.id | tag) == "!!str") and
      ((.title | tag) == "!!str") and
      (.status | test("^(planned|emitted|done)$")) and
      ((.questions | tag) == "!!seq") and
      ((.depends_on | tag) == "!!seq") and
      (.spec == null or (.spec | tag) == "!!str") and
      ((.status == "planned") == (.spec == null))
    )) and
    (([.slices[].id] | unique | length) == (.slices | length)) and
    (([.slices[].depends_on[]] - [.slices[].id]) | length == 0) and
    (.status == "exploring" or (.slices | all_c(.status != "planned"))) and
    (.status != "done" or (.slices | all_c(.status == "done")))
  ' .workflow/initiatives/NNN-slug/initiative.md
-->

# Initiative: <title>

## Why

<One paragraph: the goal of the whole subject, carried from the converted spec's Why and revised as exploration settles it. Every slice resolves against this paragraph.>

## Specs

<!-- One row per emitted slice, added at emission. A slice's status lives in the frontmatter; this table only links. -->

| Slice | Spec |
| --- | --- |
| S<n> <slice title> | [NNN-slug](../../specs/NNN-slug/spec.md) |

## Links

- Questions: [questions.md](questions.md)
- Design log: [design-log.md](design-log.md)
- Codebase map: [codebase-map.md](codebase-map.md)
