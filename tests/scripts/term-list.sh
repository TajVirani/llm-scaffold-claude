#!/usr/bin/env bash
# Suite: term-list.sh (domain-modeling/scripts).
# Covers: JRN-005. On a single root glossary it prints one line per entry, in file order, with the entry's _Avoid_
#   aliases and without its definition, and skips the Relationships and Flagged ambiguities sections. With a glossary map
#   naming two context glossaries it prints the terms of both, each line labelled with its context, and leaves out a root
#   glossary the map does not name. --define prints exactly the one whole entry (with or without an _Avoid_ line, and a
#   term from a mapped context), and exits non-zero for a term no glossary holds. Usage errors exit 2.
#   Map links resolve from the project root, as the glossary format's own example (./src/ordering/GLOSSARY.md) does.
# Env: TEST_BASH=<bash binary> runs the script under another bash (default: bash).
# shellcheck disable=SC2016,SC2329  # check expressions are single-quoted and eval'd on purpose, and call helpers shellcheck cannot see
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight
new_workdir

BASH_UNDER_TEST=${TEST_BASH:-bash}
SCRIPT_REL=.agents/skills/domain-modeling/scripts/term-list.sh

# term_list DIR ARGS... : run the fixture's own copy of the script from the project root DIR.
term_list() {
  local dir=$1
  shift
  (cd "$dir" && "$BASH_UNDER_TEST" "$dir/$SCRIPT_REL" "$@")
}

# line_of OUTPUT TERM : the output lines that name TERM as a whole word.
line_of() { grep -wF -- "$2" <<<"$1"; }

echo "== one root glossary"
SINGLE=$WORK/single
git_init_repo "$SINGLE"
copy_agents "$SINGLE"
mkdir -p "$SINGLE/.workflow"
cat >"$SINGLE/.workflow/GLOSSARY.md" <<'EOF'
# Shop

Orders, invoices and the people who place them.

## Language

### Selling

**Order**:
A customer's request to buy goods.
_Avoid_: Purchase, transaction

**Invoice**:
A request for payment sent after delivery.
_Avoid_: Bill, payment request

### People

**Customer**:
A person or organisation that places orders.

## Relationships

- An **Order** produces one or more **Invoices**

## Flagged ambiguities

- "account" was used to mean both **Customer** and **User**: resolved, these are distinct concepts.
EOF
list=$(term_list "$SINGLE")
rc=$?
eq "the list exits 0" "$rc" 0
eq "one line per entry" "$(grep -c . <<<"$list")" 3
eq "entries in file order" "$(grep -oE 'Order|Invoice|Customer' <<<"$list" | awk '!seen[$0]++' | tr '\n' ' ')" "Order Invoice Customer "
check "the Order line carries its aliases" 'line_of "$list" Order | grep -qF Purchase && line_of "$list" Order | grep -qF transaction' "$list"
check "the Invoice line carries its aliases" 'line_of "$list" Invoice | grep -qF Bill && line_of "$list" Invoice | grep -qF "payment request"' "$list"
check "an entry without _Avoid_ still has its line" '[ -n "$(line_of "$list" Customer)" ]' "$list"
check "no definition text is printed" '! grep -qF "request to buy goods" <<<"$list"' "$list"
check "Relationships and Flagged ambiguities add no line" '! grep -qwF User <<<"$list"' "$list"

echo "== --define"
eq "--define prints exactly the whole entry" "$(term_list "$SINGLE" --define Invoice)" \
  "$(printf '%s\n' '**Invoice**:' 'A request for payment sent after delivery.' '_Avoid_: Bill, payment request')"
eq "--define of an entry without _Avoid_ stops before the next section" "$(term_list "$SINGLE" --define Customer)" \
  "$(printf '%s\n' '**Customer**:' 'A person or organisation that places orders.')"
check "--define of an unknown term exits non-zero" '! term_list "$SINGLE" --define Refund >/dev/null 2>&1'
t "--define without a term is a usage error" 2 term_list "$SINGLE" --define
t "an unknown option is a usage error" 2 term_list "$SINGLE" --bogus

echo "== a glossary map with two contexts"
MAPPED=$WORK/mapped
git_init_repo "$MAPPED"
copy_agents "$MAPPED"
mkdir -p "$MAPPED/.workflow" "$MAPPED/src/ordering" "$MAPPED/src/billing"
cat >"$MAPPED/.workflow/GLOSSARY-MAP.md" <<'EOF'
# Glossary Map

## Contexts

- [Ordering](./src/ordering/GLOSSARY.md): receives and tracks customer orders
- [Billing](./src/billing/GLOSSARY.md): generates invoices and runs payments

## Relationships

- **Ordering → Billing**: Ordering emits `OrderPlaced` events; Billing consumes them
EOF
cat >"$MAPPED/src/ordering/GLOSSARY.md" <<'EOF'
# Ordering

## Language

**Order**:
A customer's request to buy goods.
_Avoid_: Purchase

**Customer**:
A person or organisation that places orders.
_Avoid_: Client
EOF
cat >"$MAPPED/src/billing/GLOSSARY.md" <<'EOF'
# Billing

## Language

**Invoice**:
A request for payment sent after delivery.
_Avoid_: Bill

**Payment run**:
One batch of payments collected on the same day.
_Avoid_: Settlement
EOF
printf '# Old root\n\n## Language\n\n**Leftover**:\nA term from before the map.\n' >"$MAPPED/.workflow/GLOSSARY.md"
mapped=$(term_list "$MAPPED")
rc=$?
eq "the mapped list exits 0" "$rc" 0
eq "one line per entry across both contexts" "$(grep -c . <<<"$mapped")" 4
check "Ordering terms are labelled Ordering" \
  'line_of "$mapped" Order | grep -qF Ordering && line_of "$mapped" Customer | grep -qF Ordering' "$mapped"
check "Billing terms are labelled Billing" \
  'line_of "$mapped" Invoice | grep -qF Billing && line_of "$mapped" "Payment run" | grep -qF Billing' "$mapped"
check "mapped lines carry their aliases" \
  'line_of "$mapped" Customer | grep -qF Client && line_of "$mapped" "Payment run" | grep -qF Settlement' "$mapped"
check "the root glossary the map does not name is not read" '! grep -qF Leftover <<<"$mapped"' "$mapped"
defined=$(term_list "$MAPPED" --define "Payment run")
check "--define finds a term in a mapped context" \
  'grep -qxF "**Payment run**:" <<<"$defined" && grep -qxF "One batch of payments collected on the same day." <<<"$defined"' "$defined"
check "--define prints that entry only" '! grep -qF Invoice <<<"$defined"' "$defined"

shellcheck_files "shellcheck: term-list.sh" "$AGENTS_SRC/skills/domain-modeling/scripts/term-list.sh"
finish
