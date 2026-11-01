# Data model: PR template

Spec: [spec.md](spec.md) · Placement: feature-workflow

## Summary

| Part | Kind | Classification | Owning module |
| --- | --- | --- | --- |
| PR template (`assets/pr-template.md`) | entity (document shape) | create | feature-workflow |
| Filled body (`.workflow/specs/NNN-slug/pr-body.md`) | entity (document) | create | feature-workflow (written per spec) |
| `pr_template` Workflow setting | field | extend (new key in an existing block; value `workflow` or a template path, D12) | feature-workflow (`rules-setting.sh`); project-setup writes it |
| `check-pr-body.sh` | interface | create | feature-workflow |
| `rules-setting.sh <key>` | interface | extend | feature-workflow |
| Sign-off 5.8 PR call (`gh` / `glab` / local merge) | interface | extend (adds a body file) | feature-workflow |
| `report.md`, task PR body (`open-task-pr.sh`) | entity | unchanged | feature-workflow |

## Entities

### PR template (create)

The fixed sections a **Sign-off PR** description must fill (`.workflow/GLOSSARY.md`).

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| Link to issue | section | yes | non-empty; a URL or the fixed stub line (CAP-006) | create |
| What changed | section, bullets | yes | at least one bullet | create |
| Why the change | section, bullets | yes | at least one bullet | create |
| Why this approach | section | yes | non-empty | create |
| Special things to note | section | yes | non-empty ("None." allowed) | create |
| How to test | section, numbered steps | yes | at least one numbered step | create |
| Blast radius | section | yes | non-empty | create |
| Risk and reversibility | section | yes | contains `Risk: Low|Medium|High` and `Reversibility: Easy|Moderate|Hard|Irreversible`, each with a reason; Irreversible requires Risk: High (D5, D7) | create |
| Areas, concepts and seams changed | section | yes | non-empty | create |
| How to undo this PR | section | yes | non-empty; when the change cannot be undone, says why (D5) | create |

Sections appear in this order, each as one `##` heading so later work (Phase 4 review) can read them one by one.

### Filled body `pr-body.md` (create)

One per spec, filled at 5.4, approved at 5.5, sent unchanged at 5.8 (D3). Shape: the PR template when `pr_template` is `workflow` or unset; the headings of the template file `pr_template` names, at every level, each present at the same level with the same text and non-empty, a section running to the next heading of the same or a higher level, when it holds a path (D4, D12, D19).

**State transitions:**

| From | Event | To | Guard |
| --- | --- | --- | --- |
| absent | 5.4 fill | filled | `check-pr-body.sh` exits 0 |
| filled | 5.5 change request | absent (spec back to draft, 5.6) | stakeholder says No |
| filled | 5.5 approve | approved | stakeholder says Yes |
| approved | 5.8 publish | published | `check-pr-body.sh` exits 0 again; PR opened or local merge made with it |

**Invalid states ruled out:** a PR opened without a checked body: 5.8 reruns the check before publishing. Still representable: a body edited by hand between 5.5 and 5.8 after approval; the 5.8 check catches shape errors, not content drift (accepted).

### `pr_template` setting (extend)

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| `pr_template` | `workflow` \| repo-relative path to a `.md` host template | no | default `workflow`; a path must be relative, end in `.md`, hold no `..`, not start with `/` or `-`, and exist under the main checkout root found from `--cwd` (D12, D16); anything else exits 1 in `rules-setting.sh` | create (in the existing Workflow settings block) |

**State transitions:**

| From | Event | To | Guard |
| --- | --- | --- | --- |
| unset | project-setup answer | `workflow` / a found template path | the project has a host PR/MR template at one of the D15 locations; every found path is offered plus `workflow` (D14) |
| unset | 5.3 approves the 5.2 proposal row | `workflow` / a found template path | key unset and a host template exists |
| path set, file gone | 5.4 reads the setting (exit 1) | stops for a ruling: workflow template for this PR, or a new path through 5.2/5.3 | never a silent fallback (D13) |
| path set, template unusable | `check-pr-body.sh` exits 2 on the host template at 5.4 (unreadable, or no headings) | stops for the same ruling as D13 | never a silent fallback (D20) |
| set | any later sign-off | unchanged | never asked again while the setting reads clean |

## Migrations

| # | Migration | Classification | Reversible | Depends on | Data handling |
| --- | --- | --- | --- | --- | --- |
| M1 | Add `pr_template` to the Workflow settings block (project-setup template, this repo's rules.md via 5.3) | extend | yes (delete the key; default applies) | - | none: absent key reads as `workflow` |
