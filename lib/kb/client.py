"""ChromaDB client management for the local knowledge base."""

from __future__ import annotations

import os
from functools import lru_cache
from pathlib import Path

import chromadb
from chromadb.config import Settings
from chromadb.utils import embedding_functions

_DEFAULT_DIR = Path(__file__).resolve().parents[2] / "kb_data"
_COLLECTION = "documents"
_EMBEDDING_MODEL = "all-MiniLM-L6-v2"


def _persist_dir() -> Path:
    """Return the on-disk persistence directory for ChromaDB."""
    override = os.environ.get("KB_PERSIST_DIR")
    return Path(override).expanduser().resolve() if override else _DEFAULT_DIR


@lru_cache(maxsize=1)
def get_client() -> chromadb.api.ClientAPI:
    """Create or reuse a persistent ChromaDB client."""
    persist_dir = _persist_dir()
    persist_dir.mkdir(parents=True, exist_ok=True)
    return chromadb.PersistentClient(
        path=str(persist_dir),
        settings=Settings(anonymized_telemetry=False),
    )


@lru_cache(maxsize=1)
def _embedder():
    """Default sentence-transformers embedder. No API key required."""
    return embedding_functions.SentenceTransformerEmbeddingFunction(
        model_name=_EMBEDDING_MODEL
    )


@lru_cache(maxsize=1)
def get_collection():
    """Return the documents collection, creating it if missing."""
    client = get_client()
    return client.get_or_create_collection(
        name=_COLLECTION,
        embedding_function=_embedder(),
        metadata={"hnsw:space": "cosine"},
    )
