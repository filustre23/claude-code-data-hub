#!/usr/bin/env bash
# SessionEnd hook: scan the transcript for project mentions and surface a
# memory-update proposal to the user.
#
# Behavior:
#   - Reads the SessionEnd JSON from stdin (Claude Code passes session metadata).
#   - If the input has `transcript_path`, scans that file for /retrieve-memory
#     and /save-memory invocations + project-name mentions to identify which
#     project(s) the session worked on.
#   - For each identified project, emits a stdout block proposing manual review
#     of `memory/<project>/PROJECT.md` — the user decides what (if anything)
#     to append.
#
# Append-only: this hook NEVER writes to memory/. It only proposes. The user
# follows up with `/save-memory <project>` or edits the PROJECT.md directly.
#
# Secrets scrub: the `/save-memory` skill applies the regex scrub before any write
# to shared memory. We don't repeat that here because we never write.

set -euo pipefail

INPUT=$(cat)

# Pull the transcript path from the SessionEnd input. Claude Code's SessionEnd
# hook input shape isn't strictly documented for shell hooks; we accept either
# `transcript_path` or `session.transcript_path` and fall back to scanning
# `~/.claude/projects/<sanitized-cwd>/sessions/` if neither is present.
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // .session.transcript_path // empty')

if [[ -z "$TRANSCRIPT" || ! -f "$TRANSCRIPT" ]]; then
  # No transcript handed to us — nothing to scan. Stay quiet so we don't add
  # noise to every session end.
  exit 0
fi

# Find candidate projects mentioned in the session.
# Sources of evidence (in priority order):
#   1. /retrieve-memory <project> or /save-memory <project> invocations
#   2. References to memory/<project>/ paths (e.g. in tool inputs)
#   3. Direct mention of known project dirs
PROJECTS=$(
  {
    # /retrieve-memory <project> or /save-memory <project>
    grep -oE '/(retrieve|save)-memory[[:space:]]+[a-z0-9_-]+' "$TRANSCRIPT" 2>/dev/null \
      | awk '{print $2}'
    # memory/<project>/ path references
    grep -oE 'memory/[a-z0-9_-]+/' "$TRANSCRIPT" 2>/dev/null \
      | sed 's|^memory/||;s|/$||'
  } 2>/dev/null \
  | sort -u
)

# Filter to projects that actually exist as directories.
EXISTING_PROJECTS=()
if [[ -n "$PROJECTS" ]]; then
  while IFS= read -r p; do
    [[ -z "$p" ]] && continue
    if [[ -d "memory/$p" ]]; then
      EXISTING_PROJECTS+=("$p")
    fi
  done <<< "$PROJECTS"
fi

# Nothing to propose.
if [[ ${#EXISTING_PROJECTS[@]} -eq 0 ]]; then
  exit 0
fi

# Emit the proposal block.
{
  echo ""
  echo "── Memory consolidation proposal ──"
  echo "This session referenced ${#EXISTING_PROJECTS[@]} project(s) with shared memory."
  echo "Review whether anything notable should be appended to PROJECT.md."
  echo ""
  for p in "${EXISTING_PROJECTS[@]}"; do
    echo "  • memory/$p/PROJECT.md"
  done
  echo ""
  echo "To append: run \`/save-memory <project>\` in your next session, or edit the file directly."
  echo "This hook never writes memory itself — append-only by review."
  echo "──────────────────────────────────"
} >&2

exit 0
