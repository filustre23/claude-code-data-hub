#!/usr/bin/env bash
# UserPromptSubmit hook: prepend top-3 KB hits to the user prompt.
# Reads hook JSON from stdin, calls lib.kb.search, emits additional context.
# Graceful no-op on any failure (KB unreachable, embedding fails, etc.).

set -euo pipefail

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

# Skip very short prompts (too little signal) and slash commands (skill handles its own context)
if [[ -z "$PROMPT" ]] || [[ ${#PROMPT} -lt 8 ]] || [[ "$PROMPT" =~ ^/ ]]; then
  exit 0
fi

# Run the KB search inside uv with a hard timeout. Any failure → no-op.
# Pulls top-20 vector hits, then re-ranks via Claude Haiku to top-3.
HITS=$(timeout 12 uv run --quiet python - "$PROMPT" 2>/dev/null <<'PY' || true
import sys
try:
    from lib.kb import search
    from lib.kb.rerank import rerank
except Exception:
    sys.exit(0)

prompt = sys.argv[1] if len(sys.argv) > 1 else ""
if not prompt:
    sys.exit(0)

try:
    candidates = search(prompt, limit=20)
except Exception:
    sys.exit(0)

if not candidates:
    sys.exit(0)

# Reranker is soft-failing — degrades to top-3 by cosine if unavailable.
hits = rerank(prompt, candidates, top_k=3)

lines = ["<kb_context source=\"chromadb top-20 → haiku rerank top-3\">"]
for h in hits:
    title = h.get("title") or "(untitled)"
    doc_type = h.get("doc_type") or "doc"
    sim = h.get("similarity") or 0
    content = (h.get("content") or "").strip()
    if len(content) > 600:
        content = content[:600].rstrip() + "..."
    lines.append(f"- [{doc_type}] {title} (sim={sim:.2f})")
    if content:
        lines.append(f"  {content}")
lines.append("</kb_context>")
print("\n".join(lines))
PY
)

if [[ -n "$HITS" ]]; then
  # Emit as additional context. Claude Code merges hookSpecificOutput.additionalContext into the prompt.
  jq -n --arg ctx "$HITS" '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $ctx}}'
fi

exit 0
