#!/usr/bin/env bash
# Referential integrity tests for the Data Claude Hub ecosystem.
# Validates that agents, skills, and config files are internally consistent.

set -euo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== Ecosystem Integrity Tests ==="
echo ""

# --- Agent directories ---
echo "Agents:"
for dir in .claude/agents/*/; do
  name=$(basename "$dir")
  if [ -f "$dir/AGENT.md" ] && [ -s "$dir/AGENT.md" ]; then
    pass "$name has AGENT.md"
  else
    fail "$name missing or empty AGENT.md"
  fi
done
echo ""

# --- Skill directories ---
echo "Skills:"
for dir in .claude/skills/*/; do
  name=$(basename "$dir")
  if [ -f "$dir/SKILL.md" ] && [ -s "$dir/SKILL.md" ]; then
    pass "$name has SKILL.md"
  else
    fail "$name missing or empty SKILL.md"
  fi
done
echo ""

# --- Known services check ---
echo "Service references:"
KNOWN_SERVICES="bigquery|github|linear|snowflake"
for file in .claude/skills/*/SKILL.md; do
  name=$(basename "$(dirname "$file")")
  if grep -qE '^requires:' "$file"; then
    services=$(grep -oE 'requires: \[.*\]' "$file" | grep -oE '\[.*\]' | tr -d '[]' | tr ',' '\n' | tr -d ' ')
    for svc in $services; do
      if echo "$svc" | grep -qE "^($KNOWN_SERVICES)$"; then
        pass "$name requires '$svc' (known service)"
      else
        fail "$name requires '$svc' (UNKNOWN service)"
      fi
    done
  fi
done
echo ""

# --- Stale references check ---
echo "Stale references:"
STALE_PATTERN='dataform|\.gitlab-ci|glab |atlassian|jira|confluence|sqlserver|pymssql|aws.s3|redshift|databricks'
FOUND_STALE=0
for file in .claude/agents/*/AGENT.md .claude/skills/*/SKILL.md CLAUDE.md README.md memory/TEMPLATE.md; do
  if [ -f "$file" ] && grep -qiE "$STALE_PATTERN" "$file" 2>/dev/null; then
    fail "$(basename "$file") contains stale service references"
    grep -niE "$STALE_PATTERN" "$file" | head -3
    FOUND_STALE=1
  fi
done
if [ "$FOUND_STALE" -eq 0 ]; then
  pass "No stale service references found"
fi
echo ""

# --- JSON validity ---
echo "Config files:"
if python3 -c "import json; json.load(open('.claude/settings.json'))" 2>/dev/null; then
  pass "settings.json is valid JSON"
else
  fail "settings.json is invalid JSON"
fi

if python3 -c "import json; json.load(open('.claude/settings.local.json.example'))" 2>/dev/null; then
  pass "settings.local.json.example is valid JSON"
else
  fail "settings.local.json.example is invalid JSON"
fi
echo ""

# --- Memory template ---
echo "Memory:"
if [ -f "memory/TEMPLATE.md" ] && [ -s "memory/TEMPLATE.md" ]; then
  pass "memory/TEMPLATE.md exists"
else
  fail "memory/TEMPLATE.md missing or empty"
fi
echo ""

# --- Summary ---
echo "=== Results: $PASS passed, $FAIL failed ==="
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
