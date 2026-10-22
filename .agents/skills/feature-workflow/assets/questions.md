---
questions: []
# questions record: {id: IQ1, kind: research, state: open, question: "<one question>", depends_on: [], launched: null, settled: null}
---
<!--
File: Template for .workflow/initiatives/NNN-slug/questions.md, the open and settled questions of one initiative. Copied at conversion (6.1) beside initiative.md. The records are the whole file; there is no body beyond the title.

Frontmatter contract (read with mikefarah yq v4, `--front-matter=extract`). initiative-transition.sh, session-start-resume.sh and the launch resolver depend on these keys:
  - questions: list, empty until the first round. Each record:
      id          `IQ<n>`, unique in this file, never reused
      kind        research | decision. A research question is answered by agents, a decision by the stakeholder.
      state       open | researching | settled. Only a research question may be `researching`.
      question    string, one question
      depends_on  list of `IQ<n>` ids or emitted spec folder names `NNN-slug`. The question is on the frontier once every question it names is `settled` and every spec it names is `done` on the main branch.
      launched    `{task_type: <research | fact-lookup | retrieval | library-evaluation>, at: <UTC timestamp>}` or null. Present exactly while the question is `researching`, so a resumed session can see a launch that never reported back; cleared when the question settles or goes back to `open`.
      settled     string or null. The source (`path:line` or URL) for a research answer, the stakeholder's words verbatim for a decision. Non-null exactly when `state` is `settled`.
  Add no other keys. Records change only through `initiative-transition.sh set-question` (`--state`, `--settled <text>`, `--launched <task_type>|clear`), never by hand.

Writing rules:
  - Single writer: the main session, on the initiative branch, at any step. Sub-agents return answers; the main session writes them back.
  - A question is never deleted. One that turns out not to matter is settled with the reason it does not.
  - Delete this comment in the finished file.

Validate the frontmatter (prints true, exits non-zero otherwise):
  yq --front-matter=extract -e '
    ((.questions | tag) == "!!seq") and
    (.questions | all_c(
      ((.id | tag) == "!!str") and
      (.kind | test("^(research|decision)$")) and
      (.state | test("^(open|researching|settled)$")) and
      ((.question | tag) == "!!str") and
      ((.depends_on | tag) == "!!seq") and
      (.state != "researching" or .kind == "research") and
      ((.state == "researching") == (.launched != null)) and
      (.launched == null or (((.launched.task_type | tag) == "!!str") and ((.launched.at | tag) == "!!str" or (.launched.at | tag) == "!!timestamp"))) and
      ((.state == "settled") == (.settled != null)) and
      (.settled == null or (.settled | tag) == "!!str")
    )) and
    (([.questions[].id] | unique | length) == (.questions | length))
  ' .workflow/initiatives/NNN-slug/questions.md
-->

# Questions: <initiative title>
