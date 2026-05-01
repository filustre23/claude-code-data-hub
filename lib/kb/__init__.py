"""Knowledge Base client backed by ChromaDB."""

from lib.kb.search import get_context, get_documents, ping, search

__all__ = ["get_context", "get_documents", "ping", "search"]
