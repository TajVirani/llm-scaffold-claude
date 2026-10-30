# Data model: Worktree guard and upgrade follow-ups

Spec: [spec.md](spec.md) · Placement: feature-workflow (`check-worktree-scope.sh`, D1); hooks, tests and scaffold records keep their files

## Summary

| Part | Kind | Classification | Owning module |
| --- | --- | --- | --- |
| Scope check contract (`check-worktree-scope.sh` CLI) | interface | extend | feature-workflow |
| Read-only chain (`read_only_chain`) | interface | extend | feature-workflow |
| Guard decisions (`worktree-write-guard.sh`) | interface | extend | hooks |
| Permission deny rules (`permissions.deny`) | field | extend | hooks (template); unowned (`.claude/settings.json`) |
| Deny and allow message wording | field | refactor | feature-workflow, hooks |
| Upgrade re-run checks | interface (test) | extend | tests |
| Asset record text (`assetlist.md`, `PROVENANCE.md`) | field | refactor | unowned scaffold records |
| `codex-write-guard.sh` call into the scope check | relationship | unchanged | hooks |

## Entities

### Scope check contract (extend)

The CLI of `check-worktree-scope.sh`, which decides whether a sub-agent's write or command stays inside its **Agent worktree**.

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| `--cwd` | path | yes | existing directory | unchanged |
| `--worktree-name` | name | no | plain directory name; usage text lists `s<NNN>_t<N>`, `s<NNN>_phase_1_<work type>`, `s<NNN>_integration_<work type>` and a Codex `task_name` (D11) | refactor (doc) |
| `--confined` | flag | no | when set and no confinement root is found (rule 1 and rule 2 both fail, or the cwd is outside any git repo), exit 2 for every path and command, before any other allow, with a reason naming the cause: cwd not in a git repo, no worktree name given, or `.workflow/.worktrees/<name>` does not exist (CAP-007, D10) | create |
| `--path` / `--command` | path / string | one of | exclusive, as today | unchanged |
| exit code | 0 / 1 / 2 | yes | 0 allow, 2 deny, 1 usage or environment error | unchanged |

**State transitions (confinement root):**

| From | Event | To | Guard |
| --- | --- | --- | --- |
| no root | named worktree exists | root = that worktree | rule 1 |
| no root | cwd in a linked worktree | root = its top level | rule 2 |
| no root | neither, `--confined` unset | allow (exit 0) | rule 3, today's behaviour (Codex path never reaches it) |
| no root | neither (or cwd outside any git repo), `--confined` set | deny every call (exit 2) | new rule 3, checked before the outside-checkout and read-only allows (CAP-007, D10) |

**Invalid states ruled out:** a confined agent with no root that is allowed: with `--confined`, rule 3 denies. Still representable: a caller that omits `--confined` for an agent that should be confined; accepted, as only the Claude hook knows the agent type and it always passes the flag for implementation and integration.

### Read-only chain (extend)

The allowlist check that lets a read pass without the leading `cd` (CAP-008).

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| quote state | outside / single / double | yes | scanned left to right; `'` toggles single only when outside or in single; `"` toggles double only when outside or in double | create |
| `$` | char | no | allowed only in single quotes; outside or in double quotes denies (CAP-008) | extend (was: denied anywhere) |
| backtick | char | no | allowed only in single quotes; elsewhere denies | extend (was: denied anywhere) |
| `\` | char | no | allowed only in single quotes; elsewhere denies, so a quote cannot be faked | create |
| unterminated quote | state | no | denies | create |
| other whole-command denials (`<`, `>`, `;`, `\|\|`, lone `&`, newline, CR, `tee`, empty segment) | chars | no | unchanged, still quote-blind | unchanged |

**Invalid states ruled out:** a `$` that the shell would expand passing the check: only single-quoted text is exempt, and a backslash outside single quotes, which could escape a quote, denies. Still representable: a `|`, `&&` or `;` inside quotes still splits or denies; accepted (costs a needless `cd`, non-goal).

### Guard decisions (extend)

What `worktree-write-guard.sh` decides before and around the scope check.

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| workflow installed | bool | yes | no `check-worktree-scope.sh` next to the hooks: allow silently | unchanged |
| jq present | bool | yes | missing: static deny JSON (CAP-007, D9) | extend (was: allow) |
| payload | JSON object | yes | unparsable or not an object: deny JSON (CAP-007, D4) | extend (was: allow) |
| agent_id / agent_type | strings | no | not a sub-agent, or a type other than implementation/integration: allow silently | unchanged |
| launch header | parsed header | no | transcript missing, prompt empty or header unparsable: no name, and the scope check runs with `--confined` and denies unless the cwd is a linked worktree (CAP-007, D3) | extend (was: allow) |
| worktree name | name | no | header the lib cannot name: deny (fail closed) | unchanged |

### Permission deny rules (extend)

The `permissions.deny` list of the Claude settings template and of this repo's `.claude/settings.json`.

| Field | Type | Required | Validation rule | Change |
| --- | --- | --- | --- | --- |
| `Bash(yq *--front-matter=extract* -i*)` | rule | yes | in both files; installed by the union merge (CAP-009) | create |
| `Bash(yq *-i* --front-matter=extract*)` | rule | yes | as above | create |
| `Bash(yq *--front-matter=extract* --inplace*)` | rule | yes | as above | create |
| `Bash(yq *--inplace* --front-matter=extract*)` | rule | yes | as above | create |
| existing `Edit(...)` deny entries | rules | yes | unchanged; template line 148 untouched (spec 007) | unchanged |
| `Bash(yq --front-matter=extract:*)` allow entry | rule | yes | kept; deny is checked first | unchanged |

**Invalid states ruled out:** none by construction: rules match command text. Still representable: `-Pi`, `-f extract` and other spellings; accepted as accident prevention (spec Assumptions).

## Migrations

| # | Migration | Classification | Reversible | Depends on | Data handling |
| --- | --- | --- | --- | --- | --- |
| M1 | Add `--confined` and the quote scanner to `check-worktree-scope.sh`; reword its messages | extend | yes (script change) | - | none |
| M2 | Guard passes `--confined` and denies on unparsable payload and missing jq | extend | yes | M1 | none |
| M3 | Add the four deny rules to the template and `.claude/settings.json`; a re-install adds them to target projects | extend | yes (remove the entries; installed copies keep them until the user removes them, as union merges never delete) | - | none |
| M4 | Rewrite `assetlist.md` and `PROVENANCE.md` text; tighten upgrade re-run checks | refactor | yes | - | none |
