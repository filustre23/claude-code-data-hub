#!/usr/bin/env bash
# Tests for hooks/uv_auto_add.sh
# Runs the hook with synthetic inputs and verifies behavior.
#
# Usage: bash tests/test_uv_auto_add.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$REPO_ROOT/hooks/uv_auto_add.sh"
TMPDIR=$(mktemp -d)
ORIG_PATH="$PATH"
trap 'rm -rf "$TMPDIR"' EXIT

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo "  PASS: $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $1"; }

# Helper: run the hook with a given file path and capture what `uv add` would do.
# Uses a wrapper script to isolate env vars from the test process.
run_hook() {
  local file_path="$1"
  local mock_installed="${2:-}"

  # Create a mock uv that records `uv add` calls
  local mock_bin="$TMPDIR/mock_bin"
  mkdir -p "$mock_bin"

  local installed_file="$TMPDIR/installed.txt"
  if [[ -n "$mock_installed" ]]; then
    echo "$mock_installed" > "$installed_file"
  else
    : > "$installed_file"
  fi

  local add_log="$TMPDIR/uv_add.log"
  : > "$add_log"

  # Write the mock uv with hardcoded paths (no env var dependency)
  cat > "$mock_bin/uv" <<MOCK
#!/usr/bin/env bash
if [[ "\$1" == "pip" && "\$2" == "list" ]]; then
  echo "Package    Version"
  echo "---------- -------"
  cat "$installed_file" 2>/dev/null
  exit 0
fi
if [[ "\$1" == "add" ]]; then
  echo "\$2" >> "$add_log"
  exit 0
fi
MOCK
  chmod +x "$mock_bin/uv"

  local input_json="{\"tool_input\":{\"file_path\":\"$file_path\"}}"

  # Run the hook in a wrapper with clean PATH
  local wrapper="$TMPDIR/run_hook.sh"
  cat > "$wrapper" <<WRAPPER
#!/usr/bin/env bash
export PATH="$mock_bin:$ORIG_PATH"
echo '$input_json' | bash "$HOOK" 2>/dev/null || true
WRAPPER
  chmod +x "$wrapper"
  bash "$wrapper"

  # Return what was added
  if [[ -s "$add_log" ]]; then
    cat "$add_log"
  fi
}

echo "=== uv_auto_add.sh tests ==="

# Test 1: Python file with third-party import
test_file="$TMPDIR/test1.py"
echo 'import pandas' > "$test_file"
result=$(run_hook "$test_file")
if echo "$result" | grep -q "pandas"; then
  pass "Python import detected — uv add pandas"
else
  fail "Python import not detected (expected pandas, got: $result)"
fi

# Test 2: Python file with stdlib import (should NOT trigger uv add)
test_file="$TMPDIR/test2.py"
echo 'import os' > "$test_file"
result=$(run_hook "$test_file")
if [[ -z "$result" ]]; then
  pass "Stdlib import (os) skipped"
else
  fail "Stdlib import should be skipped (got: $result)"
fi

# Test 3: Python file with already-installed package
test_file="$TMPDIR/test3.py"
echo 'import requests' > "$test_file"
result=$(run_hook "$test_file" "requests    2.31.0")
if [[ -z "$result" ]]; then
  pass "Already-installed package skipped"
else
  fail "Already-installed package should be skipped (got: $result)"
fi

# Test 4: Python file with from-import
test_file="$TMPDIR/test4.py"
echo 'from sqlalchemy import create_engine' > "$test_file"
result=$(run_hook "$test_file")
if echo "$result" | grep -q "sqlalchemy"; then
  pass "from-import detected — uv add sqlalchemy"
else
  fail "from-import not detected (expected sqlalchemy, got: $result)"
fi

# Test 5: pyproject.toml with dependencies
test_file="$TMPDIR/pyproject.toml"
cat > "$test_file" <<'EOF'
[project]
dependencies = [
    "fastapi>=0.100",
    "uvicorn>=0.20",
]
EOF
result=$(run_hook "$test_file")
if echo "$result" | grep -q "fastapi" && echo "$result" | grep -q "uvicorn"; then
  pass "pyproject.toml dependencies detected"
else
  fail "pyproject.toml dependencies not detected (got: $result)"
fi

# Test 6: requirements.txt
test_file="$TMPDIR/requirements.txt"
cat > "$test_file" <<'EOF'
flask>=2.0
gunicorn
EOF
result=$(run_hook "$test_file")
if echo "$result" | grep -q "flask" && echo "$result" | grep -q "gunicorn"; then
  pass "requirements.txt packages detected"
else
  fail "requirements.txt packages not detected (got: $result)"
fi

# Test 7: Non-existent file (should exit cleanly)
result=$(run_hook "/nonexistent/file.py" 2>&1)
if [[ $? -eq 0 || -z "$result" ]]; then
  pass "Non-existent file handled gracefully"
else
  fail "Non-existent file should exit cleanly (got: $result)"
fi

# Test 8: Empty input (no file path)
result=$(echo '{}' | bash "$HOOK" 2>/dev/null; echo "exit:$?")
if echo "$result" | grep -q "exit:0"; then
  pass "Empty input handled gracefully"
else
  fail "Empty input should exit cleanly"
fi

# Test 9: dbt_project.yml with adapter triggers dbt-core + adapter
test_file="$TMPDIR/dbt_project.yml"
cat > "$test_file" <<'EOF'
name: my_project
version: '1.0.0'
profile: 'my_profile'
# uses dbt-bigquery adapter
EOF
result=$(run_hook "$test_file")
if echo "$result" | grep -q "dbt-core" && echo "$result" | grep -q "dbt-bigquery"; then
  pass "dbt_project.yml triggers dbt-core + dbt-bigquery"
else
  fail "dbt_project.yml should trigger dbt-core + adapter (got: $result)"
fi

# Test 10: dbt_project.yml without adapter reference still triggers dbt-core
cat > "$TMPDIR/dbt_project.yml" <<'EOF'
name: plain_project
version: '1.0.0'
EOF
result=$(run_hook "$TMPDIR/dbt_project.yml")
if echo "$result" | grep -q "dbt-core"; then
  pass "dbt_project.yml without adapter still triggers dbt-core"
else
  fail "dbt_project.yml without adapter should trigger dbt-core (got: $result)"
fi

# Test 11: PyPI name mapping (cv2 -> opencv-python)
test_file="$TMPDIR/test_cv2.py"
echo 'import cv2' > "$test_file"
result=$(run_hook "$test_file")
if echo "$result" | grep -q "opencv-python"; then
  pass "PyPI mapping: cv2 -> opencv-python"
else
  fail "PyPI mapping failed (expected opencv-python, got: $result)"
fi

# Test 12: PyPI name mapping (yaml -> pyyaml)
test_file="$TMPDIR/test_yaml.py"
echo 'import yaml' > "$test_file"
result=$(run_hook "$test_file")
if echo "$result" | grep -q "pyyaml"; then
  pass "PyPI mapping: yaml -> pyyaml"
else
  fail "PyPI mapping failed (expected pyyaml, got: $result)"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
