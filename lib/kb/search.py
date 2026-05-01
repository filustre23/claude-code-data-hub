"""Semantic search and document retrieval against the ChromaDB KB."""

from __future__ import annotations

from lib.kb.client import get_collection


def _build_where(
    doc_types: list[str] | None,
    project: str | None,
) -> dict | None:
    """Build a chroma `where` filter from the supported fields."""
    clauses: list[dict] = []
    if doc_types:
        clauses.append({"doc_type": {"$in": doc_types}})
    if project:
        clauses.append({"project": project})
    if not clauses:
        return None
    if len(clauses) == 1:
        return clauses[0]
    return {"$and": clauses}


def _row(doc_id: str, document: str, metadata: dict, distance: float | None) -> dict:
    tags_str = metadata.get("tags", "") or ""
    return {
        "id": doc_id,
        "doc_type": metadata.get("doc_type", "unknown"),
        "title": metadata.get("title") or None,
        "content": document,
        "metadata": {k[2:]: v for k, v in metadata.items() if k.startswith("x_")},
        "tags": [t for t in tags_str.split(",") if t],
        "project": metadata.get("project") or None,
        "source": metadata.get("source") or None,
        "similarity": round(1 - distance, 4) if distance is not None else None,
    }


def search(
    query: str,
    *,
    doc_types: list[str] | None = None,
    project: str | None = None,
    tags: list[str] | None = None,
    limit: int = 10,
) -> list[dict]:
    """Semantic search via ChromaDB cosine similarity.

    `tags` is filtered post-query since chroma stores tags as a joined string.
    """
    collection = get_collection()
    if collection.count() == 0:
        return []

    where = _build_where(doc_types, project)
    result = collection.query(
        query_texts=[query],
        n_results=max(limit, 1),
        where=where,
    )

    ids = (result.get("ids") or [[]])[0]
    docs = (result.get("documents") or [[]])[0]
    metas = (result.get("metadatas") or [[]])[0]
    distances = (result.get("distances") or [[]])[0]

    rows = [
        _row(i, d, m, dist)
        for i, d, m, dist in zip(ids, docs, metas, distances)
    ]

    if tags:
        wanted = set(tags)
        rows = [r for r in rows if wanted.intersection(r["tags"])]

    return rows[:limit]


def get_context(question: str, *, limit: int = 10) -> dict[str, list[dict]]:
    """Get structured KB context for grounding, grouped by doc_type."""
    results = search(question, limit=limit * 3)
    grouped: dict[str, list[dict]] = {}
    for r in results[:limit]:
        grouped.setdefault(r["doc_type"], []).append(r)
    return grouped


def get_documents(
    *,
    doc_type: str | None = None,
    project: str | None = None,
    limit: int = 50,
) -> list[dict]:
    """Fetch documents by type/project without semantic search."""
    collection = get_collection()
    if collection.count() == 0:
        return []

    where = _build_where([doc_type] if doc_type else None, project)
    result = collection.get(where=where, limit=limit)

    ids = result.get("ids") or []
    docs = result.get("documents") or []
    metas = result.get("metadatas") or []

    return [_row(i, d, m, None) for i, d, m in zip(ids, docs, metas)]


def ping() -> bool:
    """Verify the KB is reachable and the collection is ready."""
    try:
        get_collection().count()
        return True
    except Exception:
        return False
