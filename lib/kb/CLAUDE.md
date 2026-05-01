# KB module rules

The ChromaDB-backed knowledge base. Single source of truth for Pokemon data context.

## API surface

`lib.kb` exports four functions — keep this surface stable, callers depend on it:

- `search(query, *, doc_types=None, project=None, tags=None, limit=10)` — semantic search via cosine similarity.
- `get_context(question, *, limit=10)` — `search()` results grouped by `doc_type` for SQL grounding.
- `get_documents(*, doc_type=None, project=None, limit=50)` — direct fetch, no embedding.
- `ping()` — connectivity check.

## Storage

ChromaDB `PersistentClient` writing to `kb_data/` at the repo root by default. Override with `KB_PERSIST_DIR`. The directory is gitignored — `lib/kb/ingest/<doc_type>.py` scripts seed it locally.

## Embedding model

`all-MiniLM-L6-v2` via `sentence-transformers` (384 dims). Local, no API key. If you upgrade the model, wipe `kb_data/` and re-ingest — vectors from a different model are silently incompatible.

## Doc types

Active: `table_summary`, `glossary_term`, `query_example`, `routing_rule`, `pokedex_entry`, `move_definition`, `region_quirk`, `join_recipe`, `post_mortem`, `runbook`, `freshness_sla`, `metric_definition`, `column_semantic`, `cross_skill_convention`, `qa_log`.

`doc_type` lives in chroma metadata — adding a new one is content-only, no migration. Ingest scripts live in `lib/kb/ingest/<doc_type>.py`, one per type, idempotent.

## When editing

- `search.py` — additive only. Existing callers (skills, hooks) rely on the four exported functions.
- `models.py` — `KBDocument` is a dataclass that round-trips to chroma's `(id, document, metadata)` shape. New fields go on the dataclass and into the `to_chroma`/`from_chroma` mapping.
- New retrieval features (hybrid BM25, reranker) live in their own modules (`lib/kb/rerank.py`) and compose via `search.py`.

## When reading

- The `UserPromptSubmit` hook (`hooks/kb_prelude.sh`) calls `search()` on every prompt — keep it fast. Embedding model loads on first call; subsequent calls are sub-100ms locally.
- Errors must be soft-fail. Hook scripts and skill preludes catch all exceptions and degrade to "no KB context" rather than crashing.
