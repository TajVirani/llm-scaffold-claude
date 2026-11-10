# Work backlog: <NNN-slug>

<!--
File: Template for .workflow/specs/work-backlog/<NNN-slug>.md, the backlog list of one spec: the work it found outside its scope that the stakeholder chose to keep for later. One line per item. The file sits outside the spec's folder because that spec will not solve it.
Written by the main session only, never by a sub-agent (check-write.sh): at 00.26 of the spec (an item kept at a batched ask or at 00.22, or a size-budget split), at its 5.9 (the 5.5 rulings: a line added, or a dropped line deleted) and by a new spec's 0.1.4 (an item started as that spec turns `promoted`).

One line per item, in this exact shape:
  - [<status>] B<n> <kind> (<origin node>): <problem>. Evidence: <the command and its output, a failing test, or the quoted rule line with its path:line>.
  status: open (kept, waiting for someone to start it) | promoted (started as a spec; the line ends " -> .workflow/specs/<new NNN-slug>")
  B<n>: numbered per list from B1, never reused. kind: bug | requirement | refactor | scope-expansion | decision | budget-split.
  origin node: the step it was found at, e.g. 3.7 or 4.4; a size-budget split names its tasks after the node: (00.29, split out of T3, T4).
  Facts only, with sources; no time estimates. A dropped item is deleted, not marked.

Check every line (prints nothing when all lines are well formed):
  grep -n '^- ' .workflow/specs/work-backlog/NNN-slug.md | grep -vE '^[0-9]+:- \[(open|promoted)\] B[0-9]+ (bug|requirement|refactor|scope-expansion|decision|budget-split) \([0-9.]+[^)]*\): .+ Evidence: .+'

Delete this comment in the finished file.
-->

- [open] B1 bug (4.4): <problem in one sentence>. Evidence: <the command and its output, or the quoted rule line with its path:line>.
