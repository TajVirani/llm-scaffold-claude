# Data model: Hold the deep dive at once, as a discussion that reaches agreement

Spec: [spec.md](spec.md) · Placement: `feature-workflow` (design-log Placement entry, D1)

## Summary

| Part | Kind | Classification | Owning module |
| --- | --- | --- | --- |
| Deep dive (questioning loop 0.3.11–0.3.13) | interface | refactor | feature-workflow |
| Questioning loop Entry (resume) | interface | extend | feature-workflow |
| Deep dive entry (design log) | entity | refactor | feature-workflow |
| Questioning round entry (design log) | entity | extend | feature-workflow |
| Large path round (6.5) | interface | refactor | feature-workflow |
| Initiative round entry (design log) | entity | extend | feature-workflow |
| Initiative question `settled` | field | extend | feature-workflow |
| `steps.tsv` rows 0.3.11–0.3.13 | field | refactor | feature-workflow |
| Retrospective waits count | interface | extend | retrospective |
| Decision flow node titles (`PLAN/`) | field | refactor | scaffold-only |
| Initiative question states (`open`, `researching`, `settled`) | field | unchanged | feature-workflow |
| `step-progress.sh` totals | interface | unchanged | feature-workflow |

## Entities

### Deep dive (refactor)

A **Deep dive** on one question of a **Questioning round**, held straight after the round's answers return.

**State transitions:**

| From | Event | To | Guard |
| --- | --- | --- | --- |
| picked | round logged (spec loop) or answers returned (6.5) | restated | the agent has said back the question and its recommendation's reason and asked where that is wrong |
| restated | stakeholder replies | discussing | facts the reply raises are looked up, never asked |
| discussing | agent writes a statement of what was agreed | proposed | the statement is shown in full |
| proposed | stakeholder changes it | discussing | none |
| proposed | stakeholder's explicit yes | agreed | "whatever you think" is not a yes (D7) |
| agreed | round check | checked | each other answer in the round stands or is re-asked in one ask (D6) |

Several deep dives in one round run one at a time, in frontier order. A session that ends before **agreed** resumes at **restated** from the round block's "deep dive under way" answer.

**Invalid states ruled out:** a logged decision for a deep dive question without the stakeholder's yes: the decision id is written only in the Deep dive entry, which needs the Answer line. Still representable: a round block with "deep dive under way" and no Deep dive entry, which is the resume signal, not an error.

### Deep dive entry (refactor)

The design log's record of one deep dive.

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| From | text | yes | `Q<n> in round <n>` | unchanged |
| Restated | text | yes | the question and the recommendation's reason as first said back (CAP-NEW-deep-dive-discussion) | create |
| Where it was wrong | quote | yes | the stakeholder's words, verbatim | create |
| Explored | text | yes | facts looked up, with sources, or "None." | unchanged |
| Exchanges | integer | yes | back-and-forths until the yes, ≥ 1 | create |
| Agreed statement | quote | yes | the statement as confirmed, verbatim | create |
| Answer | quote | yes | the stakeholder's yes, verbatim | refactor (was the answer to a re-asked question) |
| Decision | text | yes | `**D<n>**` the agreed statement in one line | unchanged |
| Round check | text | yes | each other answer in the round: `Q<n> stands` or `Q<n> re-asked as D<n>` | create |

### Questioning round entry (extend)

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| Answer | quote | yes | verbatim, or `deep dive under way` for a question picked for one | extend |
| Decision | text | no for a deep dive question | omitted for a deep dive question; its id is in the Deep dive entry | extend |

### Initiative round entry (extend)

Gains one block per deep dive with the Deep dive entry's lines from Restated to Round check, under the question it belongs to.

### Initiative question (extend)

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| `settled` | string | when `state: settled` | the stakeholder's words verbatim, or after a deep dive the agreed statement followed by `(confirmed: "<their yes>")` | extend |
| `state` | enum | yes | `open`, `researching`, `settled` | unchanged |

## Migrations

None. Finished specs keep their old Deep dive entries; the retrospective's waits count adds 0 where no `Exchanges:` line exists.
