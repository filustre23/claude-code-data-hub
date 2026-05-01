#!/usr/bin/env bash
# Pre-commit hook: prevent committing files that contain Bearer tokens or API keys.
# Install: ln -sf ../../hooks/check_no_secrets.sh .git/hooks/pre-commit

set -euo pipefail

# Files to scan (staged files only)
STAGED=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true)

if [[ -z "$STAGED" ]]; then
  exit 0
fi

FOUND=0

while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  [[ ! -f "$file" ]] && continue

  # Skip binary files and lock files
  case "$file" in
    *.lock|*.png|*.jpg|*.gif|*.ico|*.woff*|*.ttf|*.eot) continue ;;
  esac

  # Check for Bearer tokens
  if grep -qE 'Bearer [A-Za-z0-9_\-]{20,}' "$file" 2>/dev/null; then
    echo "ERROR: Possible Bearer token found in staged file: $file"
    FOUND=1
  fi

  # Check for common API key patterns
  if grep -qiE '(api[_-]?key|secret[_-]?key|access[_-]?token)\s*[:=]\s*["\x27][A-Za-z0-9_\-]{16,}' "$file" 2>/dev/null; then
    echo "ERROR: Possible API key/secret found in staged file: $file"
    FOUND=1
  fi

done <<< "$STAGED"

if [[ $FOUND -ne 0 ]]; then
  echo ""
  echo "Commit blocked: potential secrets detected in staged files."
  echo "If this is a false positive (e.g. a placeholder), use: git commit --no-verify"
  exit 1
fi
