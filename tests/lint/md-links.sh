#!/usr/bin/env bash
# Suite: lint that every relative markdown link and #anchor in the markdown under .agents/ resolves.
# Covers: JRN-004. The lint passes on .agents/; on a scratch fixture holding a link to a missing heading and a link to a
#   missing file it fails and names both, while a good anchor, an anchor in the same file, an external URL and a link
#   inside a fenced code block or a code span pass. Reads the repo; writes only to a scratch dir.
#
#   A link is an inline [text](target) or ![alt](target) outside fenced code blocks and code spans. A target with a
#   scheme (https:, mailto:) or starting with / or // is not relative and is skipped. The path resolves against the
#   linking file's folder; an #anchor must match a heading of the target markdown file (or of the linking file when the
#   path is empty), slugged the way GitHub does: markup dropped, lowercased, punctuation other than - and _ removed,
#   each space turned into -, and -1, -2 added to repeated headings. An <a id> or <a name> tag also counts as an anchor.
#   Markdown under an assets/ folder is a template copied elsewhere before use, so its links point at where the copy
#   lands and are not checked here.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight
new_workdir

# heading_anchors FILE : the anchors FILE's headings and anchor tags give, one per line.
# shellcheck disable=SC1112  # the typographic quotes are characters GitHub drops from a heading anchor
heading_anchors() {
  LC_ALL=C awk '
    /^[[:space:]]*(```|~~~)/ { fenced = !fenced; next }
    fenced { next }
    {
      line = $0
      while (match(line, /<a[[:space:]]+(id|name)="[^"]+"/)) {
        tag = substr(line, RSTART, RLENGTH); line = substr(line, RSTART + RLENGTH)
        sub(/^[^"]*"/, "", tag); sub(/"$/, "", tag); print tag
      }
    }
    /^#{1,6}[[:space:]]/ {
      text = $0
      sub(/^#+[[:space:]]+/, "", text); sub(/[[:space:]]+#*[[:space:]]*$/, "", text)
      while (match(text, /\[[^]]*\]\([^)]*\)/)) {
        link = substr(text, RSTART, RLENGTH); sub(/\]\(.*$/, "", link); sub(/^\[/, "", link)
        text = substr(text, 1, RSTART - 1) link substr(text, RSTART + RLENGTH)
      }
      text = tolower(text)
      gsub(/–|—|→|←|↔|’|‘|“|”|·|…|§/, "", text)
      gsub(/[]!"#$%&'"'"'()*+,.\/:;<=>?@[\\^`{|}~]/, "", text)
      gsub(/ /, "-", text)
      slug = text
      if (slug in seen) { seen[slug]++; slug = slug "-" seen[text] } else seen[slug] = 0
      print slug
    }
  ' "$1"
}

# file_links FILE : "<line>\t<target>" for each inline link outside fenced code blocks and code spans.
file_links() {
  LC_ALL=C awk '
    /^[[:space:]]*(```|~~~)/ { fenced = !fenced; next }
    fenced { next }
    {
      line = $0
      gsub(/`[^`]*`/, "", line)
      while (match(line, /\]\([^)[:space:]]*(\)|[[:space:]]+"[^"]*"\))/)) {
        target = substr(line, RSTART + 2, RLENGTH - 3)
        line = substr(line, RSTART + RLENGTH)
        sub(/[[:space:]]+".*$/, "", target)
        sub(/^</, "", target); sub(/>$/, "", target)
        print NR "\t" target
      }
    }
  ' "$1"
}

# lint_links ROOT : prints "<file>:<line>: <target>: <reason>" for each broken relative link in the markdown under ROOT;
#   returns 1 when any is broken.
lint_links() {
  local root=$1 md line target path anchor dir resolved broken=0
  while IFS= read -r -d '' md; do
    dir=$(dirname "$md")
    while IFS=$'\t' read -r line target; do
      case "$target" in
        '' | /* | [a-zA-Z]*:*) continue ;;
      esac
      path=${target%%#*}
      anchor=""
      case "$target" in *'#'*) anchor=${target#*#} ;; esac
      path=${path//%20/ }
      if [ -z "$path" ]; then
        resolved=$md
      else
        resolved=$dir/$path
        if [ ! -e "$resolved" ]; then
          printf '%s:%s: %s: no such file\n' "${md#"$root"/}" "$line" "$target"
          broken=1
          continue
        fi
      fi
      if [ -n "$anchor" ] && [ -f "$resolved" ] && [ "${resolved%.md}" != "$resolved" ]; then
        if ! heading_anchors "$resolved" | grep -qxF -- "$anchor"; then
          printf '%s:%s: %s: no such heading\n' "${md#"$root"/}" "$line" "$target"
          broken=1
        fi
      fi
    done < <(file_links "$md")
  done < <(find "$root" -name "*.md" -type f -not -path "*/assets/*" -print0 | sort -z)
  return "$broken"
}

echo "== the fixture: a missing heading and a missing file"
FIX=$WORK/fixture
mkdir -p "$FIX/sub"
cat >"$FIX/target.md" <<'EOF'
# Target

## 0.3.20 Light-path test

## Step 2. Launch the lenses (4.1-4.3), or `review-combined`

## Repeated

## Repeated
EOF
cat >"$FIX/sub/source.md" <<'EOF'
# Source

## Local heading

Good: [heading](../target.md#0320-light-path-test), [code heading](../target.md#step-2-launch-the-lenses-41-43-or-review-combined),
[second repeat](../target.md#repeated-1), [same file](#local-heading), [folder](../sub/), [web](https://example.com/x.md#nope).
Code span: `[not a link](missing-in-code-span.md)`.

```markdown
[inside a fence](missing-in-fence.md)
```

Broken heading: [gone](../target.md#no-such-heading).
Broken file: [lost](../no-such-file.md).
EOF
fixture_report=$(lint_links "$FIX")
fixture_rc=$?
eq "the lint fails on the fixture" "$fixture_rc" 1
check "it names the link to the missing heading" 'grep -qF "sub/source.md:13: ../target.md#no-such-heading: no such heading" <<<"$fixture_report"' "$fixture_report"
check "it names the link to the missing file" 'grep -qF "sub/source.md:14: ../no-such-file.md: no such file" <<<"$fixture_report"' "$fixture_report"
eq "it names nothing else (good anchors, external URLs, code spans and fences pass)" "$(grep -c . <<<"$fixture_report")" 2

echo "== .agents/"
agents_report=$(lint_links "$AGENTS_SRC")
agents_rc=$?
eq "every relative link and anchor in the markdown under .agents/ resolves" "$agents_rc" 0
[ "$agents_rc" -eq 0 ] || printf '%s\n' "$agents_report" | sed 's/^/       /'

shellcheck_files "shellcheck: md-links suite" "$TESTS_DIR/lint/md-links.sh"
finish
