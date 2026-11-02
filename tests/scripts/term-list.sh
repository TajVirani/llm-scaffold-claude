#!/usr/bin/env bash
# Suite: term-list.sh (domain-modeling/scripts).
# Covers: JRN-005. On a single root glossary it prints one line per entry, in file order, with the entry's _Avoid_
#   aliases and without its definition, and skips the Relationships and Flagged ambiguities sections. With a glossary map
#   naming two context glossaries it prints the terms of both, each line labelled with its context, and leaves out a root
#   glossary the map does not name. --define prints exactly the one whole entry (with or without an _Avoid_ line, and a
#   term from a mapped context), and exits non-zero for a term no glossary holds. Usage errors exit 2, and so does a map
#   that links no context glossary (a misspelt or missing ## Contexts heading), a context link with an empty path or with
#   nothing between its parentheses, a context link or root glossary that is a folder rather than a file, a map or
#   root glossary that is a broken link, a .workflow that is a file, a broken link or a folder the script cannot search,
#   a Contexts list item that is not a well-formed `- [<context>](<path>)` link, and an argument the usage does not
#   name. A backslash in a context name or a --define term is kept as written.
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

echo "== a glossary map that names no readable glossary"
# map_fixture NAME MAP_BODY : a project holding a root glossary and a GLOSSARY-MAP.md with MAP_BODY; prints its root.
map_fixture() {
  local dir=$WORK/$1
  git_init_repo "$dir"
  copy_agents "$dir"
  mkdir -p "$dir/.workflow"
  printf '# Root\n\n## Language\n\n**Leftover**:\nA root term.\n' >"$dir/.workflow/GLOSSARY.md"
  printf '%s\n' "$2" >"$dir/.workflow/GLOSSARY-MAP.md"
  printf '%s\n' "$dir"
}
EMPTY_PATH=$(map_fixture empty-path "$(printf '%s\n' '# Glossary Map' '' '## Contexts' '' '- [Billing](./)')")
t "a context link with an empty path exits 2" 2 term_list "$EMPTY_PATH"
empty_path_err=$(term_list "$EMPTY_PATH" 2>&1 >/dev/null)
check "the empty-path message names the context" 'grep -qF Billing <<<"$empty_path_err"' "$empty_path_err"
NO_PATH=$(map_fixture no-path "$(printf '%s\n' '# Glossary Map' '' '## Contexts' '' '- [Billing]()')")
t "a context link with nothing between its parentheses exits 2" 2 term_list "$NO_PATH"
no_path_err=$(term_list "$NO_PATH" 2>&1 >/dev/null)
check "the no-path message names the context" 'grep -qF Billing <<<"$no_path_err"' "$no_path_err"
FOLDER_LINK=$(map_fixture folder-link "$(printf '%s\n' '# Glossary Map' '' '## Contexts' '' '- [Ordering](./src/ordering/)')")
mkdir -p "$FOLDER_LINK/src/ordering"
t "a context link to a folder exits 2" 2 term_list "$FOLDER_LINK"
folder_link_err=$(term_list "$FOLDER_LINK" 2>&1 >/dev/null)
check "the folder-link message names the context" 'grep -qF Ordering <<<"$folder_link_err"' "$folder_link_err"
MISSPELT=$(map_fixture misspelt "$(printf '%s\n' '# Glossary Map' '' '## Context' '' '- [Billing](./src/billing/GLOSSARY.md)')")
t "a map whose Contexts heading is misspelt exits 2" 2 term_list "$MISSPELT"
misspelt_err=$(term_list "$MISSPELT" 2>&1 >/dev/null)
check "the misspelt-heading message names the Contexts section" 'grep -qF "## Contexts" <<<"$misspelt_err"' "$misspelt_err"
t "--define on a map naming no context exits 2" 2 term_list "$MISSPELT" --define Leftover
NO_HEADING=$(map_fixture no-heading '# Glossary Map')
t "a map with no Contexts section exits 2" 2 term_list "$NO_HEADING"

echo "== a root glossary that is a folder"
ROOT_FOLDER=$WORK/root-folder
git_init_repo "$ROOT_FOLDER"
copy_agents "$ROOT_FOLDER"
mkdir -p "$ROOT_FOLDER/.workflow/GLOSSARY.md"
t "a root glossary that is a folder exits 2" 2 term_list "$ROOT_FOLDER"

echo "== a glossary or map that is a broken link"
DANGLING_MAP=$(map_fixture dangling-map '# Glossary Map')
rm "$DANGLING_MAP/.workflow/GLOSSARY-MAP.md"
ln -s missing-map.md "$DANGLING_MAP/.workflow/GLOSSARY-MAP.md"
t "a map that is a broken link exits 2" 2 term_list "$DANGLING_MAP"
dangling_map_err=$(term_list "$DANGLING_MAP" 2>&1 >/dev/null)
check "the broken-map message names the map" 'grep -qF GLOSSARY-MAP.md <<<"$dangling_map_err"' "$dangling_map_err"
t "--define under a map that is a broken link exits 2" 2 term_list "$DANGLING_MAP" --define Leftover
DANGLING_ROOT=$WORK/dangling-root
git_init_repo "$DANGLING_ROOT"
copy_agents "$DANGLING_ROOT"
mkdir -p "$DANGLING_ROOT/.workflow"
ln -s missing-glossary.md "$DANGLING_ROOT/.workflow/GLOSSARY.md"
t "a root glossary that is a broken link exits 2" 2 term_list "$DANGLING_ROOT"
dangling_root_err=$(term_list "$DANGLING_ROOT" 2>&1 >/dev/null)
check "the broken-glossary message names the glossary" 'grep -qF GLOSSARY.md <<<"$dangling_root_err"' "$dangling_root_err"
MAP_FOLDER=$(map_fixture map-folder '# Glossary Map')
rm "$MAP_FOLDER/.workflow/GLOSSARY-MAP.md"
mkdir "$MAP_FOLDER/.workflow/GLOSSARY-MAP.md"
map_folder_err=$(term_list "$MAP_FOLDER" 2>&1 >/dev/null)
check "a map that is a folder is named as not a readable file" 'grep -qF "not a readable file" <<<"$map_folder_err"' "$map_folder_err"

echo "== a workflow folder the glossary cannot be read from"
WF_FILE=$WORK/wf-file
git_init_repo "$WF_FILE"
copy_agents "$WF_FILE"
printf 'not a folder\n' >"$WF_FILE/.workflow"
t "a .workflow that is a file exits 2" 2 term_list "$WF_FILE"
WF_DANGLING=$WORK/wf-dangling
git_init_repo "$WF_DANGLING"
copy_agents "$WF_DANGLING"
ln -s missing-folder "$WF_DANGLING/.workflow"
t "a .workflow that is a broken link exits 2" 2 term_list "$WF_DANGLING"
WF_LOCKED=$(map_fixture wf-locked '# Glossary Map')
rm "$WF_LOCKED/.workflow/GLOSSARY-MAP.md"
chmod 000 "$WF_LOCKED/.workflow"
t "a .workflow the script cannot search exits 2" 2 term_list "$WF_LOCKED"
chmod 755 "$WF_LOCKED/.workflow"

echo "== a Contexts list item that is not a context link"
# linked_map_fixture NAME MAP_BODY : map_fixture plus an Ordering glossary at src/ordering/GLOSSARY.md; prints its root.
linked_map_fixture() {
  local dir
  dir=$(map_fixture "$1" "$2")
  mkdir -p "$dir/src/ordering"
  printf '# Ordering\n\n## Language\n\n**Order**:\nA request to buy.\n' >"$dir/src/ordering/GLOSSARY.md"
  printf '%s\n' "$dir"
}
ORDERING_LINK='- [Ordering](./src/ordering/GLOSSARY.md): receives orders'
PLAIN_ITEM=$(linked_map_fixture plain-item "$(printf '%s\n' '# Glossary Map' '' '## Contexts' '' "$ORDERING_LINK" '- Billing: ./src/billing/GLOSSARY.md')")
t "a Contexts item with no link beside a good one exits 2" 2 term_list "$PLAIN_ITEM"
plain_item_err=$(term_list "$PLAIN_ITEM" 2>&1 >/dev/null)
check "the message quotes the item" 'grep -qF "Billing: ./src/billing/GLOSSARY.md" <<<"$plain_item_err"' "$plain_item_err"
UNCLOSED=$(linked_map_fixture unclosed "$(printf '%s\n' '# Glossary Map' '' '## Contexts' '' "$ORDERING_LINK" '- [Billing](./src/billing/GLOSSARY.md')")
t "a Contexts link with no closing parenthesis exits 2" 2 term_list "$UNCLOSED"
NO_NAME=$(linked_map_fixture no-name "$(printf '%s\n' '# Glossary Map' '' '## Contexts' '' "$ORDERING_LINK" '- [](./src/billing/GLOSSARY.md)')")
t "a Contexts link with no context name exits 2" 2 term_list "$NO_NAME"
NUMBERED=$(linked_map_fixture numbered "$(printf '%s\n' '# Glossary Map' '' '## Contexts' '' "$ORDERING_LINK" '1. [Billing](./src/billing/GLOSSARY.md)')")
t "a numbered Contexts item exits 2" 2 term_list "$NUMBERED"
NOTES=$(linked_map_fixture notes "$(printf '%s\n' '# Glossary Map' '' '## Contexts' '' 'Each context keeps its own glossary.' '' "$ORDERING_LINK" '  - owns the order book')")
notes_list=$(term_list "$NOTES")
rc=$?
eq "a prose line and a nested item under a context link are not context items" "$rc:$notes_list" "0:[Ordering] Order"

echo "== a backslash in a context name or a defined term"
BACKSLASH=$(map_fixture backslash "$(printf '%s\n' '# Glossary Map' '' '## Contexts' '' '- [Sales\Ops](./src/sales/GLOSSARY.md)')")
mkdir -p "$BACKSLASH/src/sales"
printf '# Sales\n\n## Language\n\n**CD**:\nA compact disc.\n' >"$BACKSLASH/src/sales/GLOSSARY.md"
eq "a context label keeps its backslash" "$(term_list "$BACKSLASH")" '[Sales\Ops] CD'
t "--define of a term with a backslash does not match the term without it" 1 term_list "$BACKSLASH" --define 'C\D'

echo "== arguments the script does not take"
t "an empty first argument is a usage error" 2 term_list "$SINGLE" ''
t "a stray argument is a usage error" 2 term_list "$SINGLE" extra
t "a third argument after --define <term> is a usage error" 2 term_list "$SINGLE" --define Order extra

shellcheck_files "shellcheck: term-list.sh" "$AGENTS_SRC/skills/domain-modeling/scripts/term-list.sh"
finish
