"""Anthropic contextual-retrieval pattern: prepend a 1-sentence chunk-level
context before embedding so semantic search lands more precisely on
domain jargon.

Pattern source: https://platform.claude.com/cookbook/capabilities-contextual-embeddings-guide
"""

from __future__ import annotations

from lib.kb.ingest.base import IngestRow

_DOC_TYPE_DESCRIPTIONS: dict[str, str] = {
    "table_summary": "a summary of a data warehouse table",
    "glossary_term": "a glossary entry defining a domain term",
    "query_example": "a canonical SQL query example",
    "routing_rule": "a routing rule for which dataset to query",
    "pokedex_entry": "a Pokedex entry describing a Pokemon species",
    "move_definition": "a Pokemon move with type, power, and effects",
    "region_quirk": "a region-specific data anomaly or convention",
    "join_recipe": "a canonical SQL join pattern",
    "post_mortem": "a post-mortem of a past data incident",
    "runbook": "an operational SOP for a known failure mode",
    "freshness_sla": "a per-table freshness SLA",
    "metric_definition": "a business metric definition with formula and SQL",
    "column_semantic": "the meaning, units, and gotchas for one column",
    "cross_skill_convention": "a cross-cutting team convention (SQL style, naming, partitioning)",
    "qa_log": "a captured Q&A from a past Claude Code session",
}


def contextualize(row: IngestRow) -> str:
    """Return a 1–2 sentence prefix that frames this row for embedding."""
    parts: list[str] = []
    desc = _DOC_TYPE_DESCRIPTIONS.get(
        row.doc_type, row.doc_type.replace("_", " ")
    )
    if row.project:
        parts.append(f"From project '{row.project}', this is {desc}.")
    else:
        parts.append(f"This is {desc}.")
    if row.title:
        parts.append(f"Title: {row.title}.")
    return " ".join(parts)


def embed_with_context(row: IngestRow) -> str:
    """Compose the full text that should be sent to the embedding model."""
    return contextualize(row) + "\n\n" + row.content
