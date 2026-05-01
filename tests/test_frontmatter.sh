#!/usr/bin/env bash
# Smoke test: validate that all agent .md files have valid YAML frontmatter
# and all skill .md files have a non-empty first line (description).
#
# Usage: bash tests/test_frontmatter.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AGENTS_DIR="$REPO_ROOT/.claude/agents"
SKILLS_DIR="$REPO_ROOT/.claude/skills"

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo "  PASS: $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $1"; }

echo "=== Agent frontmatter validation ==="

for f in "$AGENTS_DIR"/*/AGENT.md; do
  name=$(basename "$f")

  # Must start with ---
  first_line=$(head -1 "$f")
  if [[ "$first_line" != "---" ]]; then
    fail "$name — missing opening '---'"
    continue
  fi

  # Must have closing ---
  closing_line=$(awk 'NR>1 && /^---$/{print NR; exit}' "$f")
  if [[ -z "$closing_line" ]]; then
    fail "$name — missing closing '---'"
    continue
  fi

  # Extract frontmatter (between the two ---)
  frontmatter=$(sed -n "2,$((closing_line - 1))p" "$f")

  # Required fields: name, description, model, tools
  for field in name description model tools; do
    if ! echo "$frontmatter" | grep -qE "^${field}:"; then
      fail "$name — missing required field '$field'"
      continue 2
    fi
  done

  # Model must be a known value
  model=$(echo "$frontmatter" | grep -E '^model:' | sed 's/^model:[[:space:]]*//')
  if [[ "$model" != "opus" && "$model" != "sonnet" && "$model" != "haiku" ]]; then
    fail "$name — invalid model '$model' (expected opus, sonnet, or haiku)"
    continue
  fi

  pass "$name"
done

echo ""
echo "=== Skill description validation ==="

for f in "$SKILLS_DIR"/*/SKILL.md; do
  name=$(basename "$f")
  first_line=$(head -1 "$f")

  # First line must be non-empty (it's the skill description)
  if [[ -z "$first_line" ]]; then
    fail "$name — empty first line (missing description)"
    continue
  fi

  # First line should not be a markdown header or frontmatter
  if [[ "$first_line" == "---" ]]; then
    fail "$name — first line is '---' (skills should start with a plain-text description, not frontmatter)"
    continue
  fi

  if [[ "$first_line" == "#"* ]]; then
    fail "$name — first line is a markdown header (should be a plain-text description)"
    continue
  fi

  # Should have ## Instructions section
  if ! grep -q '^## Instructions' "$f"; then
    fail "$name — missing '## Instructions' section"
    continue
  fi

  pass "$name"
done

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
