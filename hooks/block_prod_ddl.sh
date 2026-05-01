#!/usr/bin/env bash
# PreToolUse:Bash hook — block destructive DDL/DML against known production datasets.
# Safety net: prevent accidental DROP/TRUNCATE/DELETE on prod data.
# Exit 2 = block; exit 0 = allow.

set -euo pipefail

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[[ -z "$CMD" ]] && exit 0

# Production datasets to protect. Update as new regions are added.
# Pattern format: "<gcp_project>.<dataset>" or just "<dataset>" for any project.
PROTECTED=(
  "pokemon-warehouse.kanto"
  "pokemon-warehouse.johto"
  "pokemon-warehouse.pokeapi"
)

# Destructive patterns (case-insensitive). These are the operations we block on prod.
# We allow them on staging/signal/analytics datasets and on personal/sandbox projects.
LOWER_CMD=$(echo "$CMD" | tr '[:upper:]' '[:lower:]')

is_destructive=false
for pat in "drop table" "drop view" "drop schema" "drop dataset" "truncate table" "truncate "; do
  if [[ "$LOWER_CMD" == *"$pat"* ]]; then is_destructive=true; break; fi
done

# Guard DELETE FROM only when no WHERE clause (full-table delete) — bare DELETE is destructive
if echo "$LOWER_CMD" | grep -qE 'delete[[:space:]]+from'; then
  if ! echo "$LOWER_CMD" | grep -qE 'where[[:space:]]'; then
    is_destructive=true
  fi
fi

if [[ "$is_destructive" != true ]]; then
  exit 0
fi

# Check if any protected dataset is referenced
for ds in "${PROTECTED[@]}"; do
  if [[ "$LOWER_CMD" == *"$ds"* ]]; then
    {
      echo "BLOCKED by hooks/block_prod_ddl.sh"
      echo ""
      echo "Refusing to run a destructive operation against a protected production dataset: $ds"
      echo ""
      echo "If this is intentional:"
      echo "  1. Run against staging/signal first."
      echo "  2. If you really need to run this on prod, edit the command outside Claude Code"
      echo "     or temporarily comment out the protected entry in hooks/block_prod_ddl.sh."
      echo ""
      echo "Detected command:"
      echo "  $CMD"
    } >&2
    exit 2
  fi
done

exit 0
