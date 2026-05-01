"""Claude Haiku reranker pass for KB search results.

Pattern: vector search returns top-N (e.g. 20) candidates by cosine distance.
A small fast model (Haiku 4.5) re-ranks them against the query, returning
top-K (e.g. 5). Cheap, big precision win on the UserPromptSubmit prepend.

Usage:

    from lib.kb.search import search
    from lib.kb.rerank import rerank

    candidates = search(query, limit=20)
    top = rerank(query, candidates, top_k=5)

The reranker is soft-failing — any exception (auth, rate limit, network)
returns the original candidates unchanged so the prelude hook never breaks.
"""

from __future__ import annotations

import json
import logging
import os
from typing import Any

logger = logging.getLogger(__name__)

_RERANKER_MODEL = "claude-haiku-4-5-20251001"


def rerank(
    query: str,
    candidates: list[dict[str, Any]],
    *,
    top_k: int = 5,
) -> list[dict[str, Any]]:
    """Return the top_k candidates most relevant to query, soft-failing.

    candidates: list of dicts as returned by lib.kb.search.search().
    Each dict is expected to have at least 'id', 'title', 'content', 'doc_type'.
    """
    if not candidates:
        return candidates
    if len(candidates) <= top_k:
        return candidates

    try:
        import anthropic
    except ImportError:
        logger.debug("anthropic SDK not available; returning candidates unchanged")
        return candidates[:top_k]

    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        logger.debug("ANTHROPIC_API_KEY not set; returning candidates unchanged")
        return candidates[:top_k]

    summaries = []
    for i, c in enumerate(candidates):
        title = c.get("title") or "(untitled)"
        doc_type = c.get("doc_type", "doc")
        content = (c.get("content") or "")[:500]
        summaries.append(
            f"[{i}] doc_type={doc_type} title={title}\n  {content}"
        )

    prompt = (
        f"Rank these {len(candidates)} KB documents by relevance to the user query "
        f"and return ONLY a JSON array of the top {top_k} indices, most relevant first. "
        f"No prose, no markdown — just the array.\n\n"
        f"User query: {query}\n\n"
        f"Documents:\n" + "\n\n".join(summaries)
    )

    try:
        client = anthropic.Anthropic(api_key=api_key)
        response = client.messages.create(
            model=_RERANKER_MODEL,
            max_tokens=200,
            messages=[{"role": "user", "content": prompt}],
        )
        text = response.content[0].text.strip()
        # Tolerate accidental markdown fences
        if text.startswith("```"):
            text = text.strip("`").lstrip("json").strip()
        indices = json.loads(text)
        if not isinstance(indices, list):
            raise ValueError("reranker returned non-list")
        seen = set()
        ranked: list[dict[str, Any]] = []
        for i in indices:
            if not isinstance(i, int) or i < 0 or i >= len(candidates):
                continue
            if i in seen:
                continue
            seen.add(i)
            ranked.append(candidates[i])
            if len(ranked) >= top_k:
                break
        if not ranked:
            return candidates[:top_k]
        return ranked
    except Exception as e:
        logger.debug("reranker soft-failed: %s; returning candidates unchanged", e)
        return candidates[:top_k]
