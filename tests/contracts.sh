#!/usr/bin/env bash
#
# Validates that artifact files in a proto-maker idea folder satisfy the
# structural contracts declared in each stage skill.
#
# Usage: tests/contracts.sh <path-to-idea-folder>
# Defaults to: tests/fixtures/completed-idea/ideas/sample-idea
#
set -euo pipefail

IDEA="${1:-tests/fixtures/completed-idea/ideas/sample-idea}"
if [ ! -d "$IDEA" ]; then
  echo "Idea folder not found: $IDEA" >&2
  exit 2
fi

pass=0
fail=0

assert_file() {
  if [ -f "$1" ]; then
    echo "  PASS: $1 exists"; pass=$((pass + 1))
  else
    echo "  FAIL: $1 missing"; fail=$((fail + 1))
  fi
}

assert_frontmatter() {
  local f="$1" key
  for key in stage idea updated inputs; do
    if grep -q "^${key}:" "$f" 2>/dev/null; then
      echo "  PASS: $f has frontmatter $key"; pass=$((pass + 1))
    else
      echo "  FAIL: $f missing frontmatter $key"; fail=$((fail + 1))
    fi
  done
}

assert_section() {
  local f="$1" h="$2"
  if grep -q "^## $h" "$f" 2>/dev/null; then
    echo "  PASS: $f has section '## $h'"; pass=$((pass + 1))
  else
    echo "  FAIL: $f missing section '## $h'"; fail=$((fail + 1))
  fi
}

echo "=== Stage 1: 00-exploration.md ==="
assert_file "$IDEA/00-exploration.md"
assert_frontmatter "$IDEA/00-exploration.md"
for s in "One-liner" "Problem" "Whose problem" "Today's workaround" "Trigger" "Smallest valuable version" "Ambitious version" "Out of scope"; do
  assert_section "$IDEA/00-exploration.md" "$s"
done

echo "=== Stage 2: 01-alternatives.md ==="
assert_file "$IDEA/01-alternatives.md"
assert_frontmatter "$IDEA/01-alternatives.md"
if grep -qE "^recommendation: (proceed|revise|kill)" "$IDEA/01-alternatives.md"; then
  echo "  PASS: 01-alternatives.md has verdict block"; pass=$((pass + 1))
else
  echo "  FAIL: 01-alternatives.md missing verdict block"; fail=$((fail + 1))
fi

echo "=== Stage 3: 02-scope.md ==="
assert_file "$IDEA/02-scope.md"
assert_frontmatter "$IDEA/02-scope.md"
for s in "Hypothesis" "Success criteria" "Main risk being tested" "Personas served"; do
  assert_section "$IDEA/02-scope.md" "$s"
done

echo "=== Stage 4: 03-prototypes/ ==="
assert_file "$IDEA/03-prototypes/index.html"
ALT_COUNT=$(find "$IDEA/03-prototypes" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
if [ "$ALT_COUNT" -ge 1 ]; then
  echo "  PASS: $ALT_COUNT alternative folders found"; pass=$((pass + 1))
else
  echo "  FAIL: no alternative folders"; fail=$((fail + 1))
fi
for alt in "$IDEA/03-prototypes"/*/; do
  [ -d "$alt" ] || continue
  assert_file "$alt/index.html"
  assert_file "$alt/DESIGN-LOG.md"
  for role in critic user-advocate engineer; do
    assert_file "$alt/critiques/$role.md"
  done
done

echo "=== Stage 5: 04-review-notes.md + CHOSEN ==="
assert_file "$IDEA/04-review-notes.md"
assert_frontmatter "$IDEA/04-review-notes.md"
assert_file "$IDEA/03-prototypes/CHOSEN"
if [ -f "$IDEA/03-prototypes/CHOSEN" ]; then
  CHOSEN=$(cat "$IDEA/03-prototypes/CHOSEN" | tr -d '\n' | tr -d ' ')
  if [ "$CHOSEN" = "none" ] || [ -d "$IDEA/03-prototypes/$CHOSEN" ]; then
    echo "  PASS: CHOSEN points to a valid alternative or 'none'"; pass=$((pass + 1))
  else
    echo "  FAIL: CHOSEN ($CHOSEN) does not match any alternative folder"; fail=$((fail + 1))
  fi
fi

echo "=== Stage 7: 06-user-stories.md ==="
assert_file "$IDEA/06-user-stories.md"
assert_frontmatter "$IDEA/06-user-stories.md"

echo "=== Stage 8: HANDOFF.md ==="
assert_file "$IDEA/HANDOFF.md"
assert_frontmatter "$IDEA/HANDOFF.md"
for s in "Exec summary" "Hypothesis being tested" "Chosen prototype" "User stories"; do
  assert_section "$IDEA/HANDOFF.md" "$s"
done

echo ""
echo "Results: $pass passed, $fail failed"
[ "$fail" = "0" ]
