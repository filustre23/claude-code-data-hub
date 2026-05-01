#!/usr/bin/env bash
set -euo pipefail

echo "Setting up Data Claude Hub environment..."

# Install uv
if ! command -v uv &>/dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi

# Install Claude Code CLI
if ! command -v claude &>/dev/null; then
  npm install -g @anthropic-ai/claude-code 2>/dev/null || echo "Note: Claude Code CLI install requires npm. Install manually if needed."
fi

# Sync Python environment
uv sync

# Link pre-commit hook
ln -sf ../../hooks/check_no_secrets.sh .git/hooks/pre-commit

# Set up GCP credentials from Codespace secret
if [ -n "${GOOGLE_APPLICATION_CREDENTIALS_JSON:-}" ]; then
  mkdir -p ~/.config/gcloud
  echo "$GOOGLE_APPLICATION_CREDENTIALS_JSON" > ~/.config/gcloud/application_default_credentials.json
  export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/application_default_credentials.json"
  echo "export GOOGLE_APPLICATION_CREDENTIALS=\"$HOME/.config/gcloud/application_default_credentials.json\"" >> ~/.bashrc
  echo "BigQuery/FHIR: Configured from Codespace secret"
else
  echo "BigQuery/FHIR: Not configured. Add GOOGLE_APPLICATION_CREDENTIALS_JSON as a Codespace secret or run: gcloud auth application-default login"
fi

# Check Linear
if [ -n "${LINEAR_API_KEY:-}" ]; then
  echo "Linear: Configured from Codespace secret"
else
  echo "Linear: Not configured. Add LINEAR_API_KEY as a Codespace secret."
fi

# Check GitHub (auto-configured in Codespaces)
if gh auth status &>/dev/null; then
  echo "GitHub: Authenticated"
fi

# Display ticket context if present (created by /work Slack command)
TICKET_CONTEXT=".claude/ticket-context.md"
if [ -f "$TICKET_CONTEXT" ]; then
  echo ""
  echo "=========================================="
  echo "  TICKET CONTEXT LOADED"
  echo "=========================================="
  cat "$TICKET_CONTEXT"
  echo ""
  echo "Claude can read this at: $TICKET_CONTEXT"
  echo "=========================================="
fi

echo ""
echo "Environment ready. Run 'claude' to start."
