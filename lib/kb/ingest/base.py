"""KB ingest framework — idempotent upserts with content-hash change detection.

Design:
- `IngestRow` carries one row's logical content.
- `IngestRunner.dry_run()` computes a diff vs. what's already in the KB.
  Returns counts and a sample. Never writes.
- `IngestRunner.apply()` performs the upsert into ChromaDB. Re-uses existing
  rows when content hasn't changed (skips re-embedding). Refuses to run
  unless `confirmed=True` is passed by the caller.
- IDs are stable hashes of `(doc_type, project, title)` so re-runs upsert
  the same row instead of duplicating.
"""

from __future__ import annotations

import hashlib
from dataclasses import dataclass, field
from typing import Iterable

from lib.kb.client import get_collection


def _content_hash(content: str) -> str:
    return hashlib.sha256(content.encode("utf-8")).hexdigest()


def _stable_id(doc_type: str, project: str | None, title: str | None) -> str:
    key = f"{doc_type}|{project or ''}|{title or ''}"
    return hashlib.sha1(key.encode("utf-8")).hexdigest()


@dataclass
class IngestRow:
    doc_type: str
    title: str
    content: str
    metadata: dict = field(default_factory=dict)
    tags: list[str] = field(default_factory=list)
    project: str | None = None
    source: str | None = None

    @property
    def stable_id(self) -> str:
        return _stable_id(self.doc_type, self.project, self.title)

    def to_chroma_metadata(self) -> dict:
        meta = {
            "doc_type": self.doc_type,
            "title": self.title or "",
            "project": self.project or "",
            "tags": ",".join(self.tags) if self.tags else "",
            "source": self.source or "",
            "content_hash": _content_hash(self.content),
        }
        for k, v in (self.metadata or {}).items():
            meta[f"x_{k}"] = v if isinstance(v, (str, int, float, bool)) else str(v)
        return meta


@dataclass
class IngestDiff:
    new: list[IngestRow] = field(default_factory=list)
    updated: list[IngestRow] = field(default_factory=list)
    unchanged: list[IngestRow] = field(default_factory=list)

    def summary(self) -> str:
        return (
            f"new={len(self.new)} "
            f"updated={len(self.updated)} "
            f"unchanged={len(self.unchanged)}"
        )

    def has_writes(self) -> bool:
        return bool(self.new) or bool(self.updated)


class IngestRunner:
    """Coordinates dry-run + apply with idempotent upserts."""

    def dry_run(self, rows: Iterable[IngestRow]) -> IngestDiff:
        rows = list(rows)
        diff = IngestDiff()
        if not rows:
            return diff

        collection = get_collection()
        ids = [r.stable_id for r in rows]
        try:
            existing_raw = collection.get(ids=ids)
        except Exception:
            existing_raw = {"ids": [], "metadatas": []}

        existing: dict[str, dict] = {}
        for doc_id, meta in zip(
            existing_raw.get("ids") or [],
            existing_raw.get("metadatas") or [],
        ):
            existing[doc_id] = meta or {}

        for r in rows:
            prior = existing.get(r.stable_id)
            if prior is None:
                diff.new.append(r)
                continue
            prior_hash = prior.get("content_hash")
            if prior_hash != _content_hash(r.content):
                diff.updated.append(r)
            else:
                diff.unchanged.append(r)
        return diff

    def apply(
        self,
        rows: Iterable[IngestRow],
        *,
        confirmed: bool,
    ) -> IngestDiff:
        if not confirmed:
            raise RuntimeError(
                "IngestRunner.apply requires confirmed=True. "
                "Run dry_run() first, show the diff, get user approval."
            )
        rows = list(rows)
        diff = self.dry_run(rows)
        to_write = diff.new + diff.updated
        if not to_write:
            return diff

        from lib.kb.ingest.contextual import embed_with_context

        collection = get_collection()
        ids = [r.stable_id for r in to_write]
        documents = [embed_with_context(r) for r in to_write]
        metadatas = [r.to_chroma_metadata() for r in to_write]

        collection.upsert(ids=ids, documents=documents, metadatas=metadatas)
        return diff
