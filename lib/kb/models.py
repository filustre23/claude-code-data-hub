"""Lightweight document schema for the ChromaDB-backed KB.

ChromaDB stores `id`, `document` (text), and `metadata` (flat dict). We use
metadata to carry the structured fields the rest of the codebase expects:
`doc_type`, `title`, `project`, `tags` (joined), `source`.
"""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone


@dataclass
class KBDocument:
    """In-memory representation of a KB document."""

    id: str
    doc_type: str
    content: str
    title: str | None = None
    project: str | None = None
    tags: list[str] = field(default_factory=list)
    source: str | None = None
    metadata: dict | None = None
    created_at: str = field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )

    def to_chroma(self) -> tuple[str, str, dict]:
        """Return (id, document, metadata) for chroma `add`/`upsert`."""
        meta: dict = {
            "doc_type": self.doc_type,
            "title": self.title or "",
            "project": self.project or "",
            "tags": ",".join(self.tags) if self.tags else "",
            "source": self.source or "",
            "created_at": self.created_at,
        }
        if self.metadata:
            for k, v in self.metadata.items():
                meta[f"x_{k}"] = v if isinstance(v, (str, int, float, bool)) else str(v)
        return self.id, self.content, meta

    @classmethod
    def from_chroma(cls, doc_id: str, document: str, metadata: dict) -> "KBDocument":
        tags_str = metadata.get("tags", "") or ""
        extras = {k[2:]: v for k, v in metadata.items() if k.startswith("x_")}
        return cls(
            id=doc_id,
            doc_type=metadata.get("doc_type", "unknown"),
            content=document,
            title=metadata.get("title") or None,
            project=metadata.get("project") or None,
            tags=[t for t in tags_str.split(",") if t],
            source=metadata.get("source") or None,
            metadata=extras or None,
            created_at=metadata.get("created_at", ""),
        )

    def as_dict(self) -> dict:
        return asdict(self)
