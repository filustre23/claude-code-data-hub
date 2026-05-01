#!/usr/bin/env bash
# SessionStart hook: detect first-time setup and prompt user to configure their environment.
# Checks for .claude/settings.local.json — if missing, this is a new user.
# All configuration is optional.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOCAL_SETTINGS="$REPO_ROOT/.claude/settings.local.json"

# If settings.local.json exists, user has already initialized
[[ -f "$LOCAL_SETTINGS" ]] && exit 0

echo ""
echo "FIRST_TIME_SETUP: Welcome to data-claude-hub!"
echo ""
echo "It looks like this is your first time launching Claude from this repo."
echo "All configuration below is optional — pick what applies to you."
echo ""
echo "To get started, ask Claude: \"help me set up my settings.local.json\""
echo "or create .claude/settings.local.json manually. Minimal example:"
echo ""
echo '  {}'
echo ""
echo "Even an empty file will suppress this message. Add what you need:"
echo ""
echo "  RECOMMENDED (all users):"
echo '    "permissions.additionalDirectories" — paths to your project folders'
echo ""
echo "  Full example:"
echo '  {'
echo '    "permissions": {'
echo '      "additionalDirectories": ['
echo '        "~/Documents/my-projects"'
echo '      ]'
echo '    }'
echo '  }'
echo ""
echo "  Run /setup-init to configure access to your external services."
echo ""
