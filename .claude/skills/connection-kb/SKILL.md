Use when the user asks to search, browse, list, or directly manage the local Knowledge Base (ChromaDB). Curator/admin operations only — most skills hit the KB automatically via the UserPromptSubmit prelude.

Search, browse, and manage the local KB (table summaries, glossary terms, query examples, routing rules, pokedex entries, move definitions, region quirks, post-mortems, runbooks) backed by a local ChromaDB persistent store.

requires: []

## Instructions

1. **Parse $ARGUMENTS** for the action and parameters. Supported actions:
   - **search** (default): Semantic search against KB documents
   - **browse**: List documents by type or project
   - **list-types**: Show all document types and counts
   - **get**: Fetch a specific document by ID
   - **context**: Get structured context for a question (grouped by doc_type — used by other skills)
   - **ping**: Test KB connectivity

2. **Execute the action** using `lib.kb`:

   ### search `<query>` [--type TYPE] [--project PROJECT] [--limit N]
   ```bash
   uv run python -c "
   from lib.kb.search import search
   results = search(
       '<query>',
       doc_types=['<type>'] if '<type>' != '' else None,
       project='<project>' if '<project>' != '' else None,
       limit=<N or 10>,
   )
   for r in results:
       sim = f'{r[\"similarity\"]:.3f}' if r['similarity'] is not None else '   - '
       print(f'[{sim}] {r[\"doc_type\"]:18} | {(r[\"title\"] or r[\"id\"]):40} | {r[\"content\"][:120]}')
   "
   ```

   ### browse [--type TYPE] [--project PROJECT] [--limit N]
   ```bash
   uv run python -c "
   from lib.kb.search import get_documents
   results = get_documents(doc_type='<type>' if '<type>' != '' else None, project='<project>' if '<project>' != '' else None, limit=<N or 50>)
   for r in results:
       print(f'{r[\"doc_type\"]:18} | {(r[\"title\"] or r[\"id\"]):40} | {r[\"content\"][:100]}')
   "
   ```

   ### list-types
   ```bash
   uv run python -c "
   from collections import Counter
   from lib.kb.search import get_documents
   docs = get_documents(limit=500)
   counts = Counter(d['doc_type'] for d in docs)
   for t, c in counts.most_common():
       print(f'  {t}: {c}')
   print(f'Total: {len(docs)} docs')
   "
   ```

   ### get `<document_id>`
   ```bash
   uv run python -c "
   from lib.kb.client import get_collection
   col = get_collection()
   r = col.get(ids=['<document_id>'])
   if r['ids']:
       meta = r['metadatas'][0]
       print(f'ID:       {r[\"ids\"][0]}')
       print(f'Type:     {meta.get(\"doc_type\")}')
       print(f'Title:    {meta.get(\"title\")}')
       print(f'Project:  {meta.get(\"project\")}')
       print(f'Tags:     {meta.get(\"tags\")}')
       print(f'Source:   {meta.get(\"source\")}')
       print(f'Created:  {meta.get(\"created_at\")}')
       print('---')
       print(r['documents'][0])
   else:
       print('Document not found')
   "
   ```

   ### context `<question>` [--limit N]
   ```bash
   uv run python -c "
   import json
   from lib.kb.search import get_context
   ctx = get_context('<question>', limit=<N or 10>)
   print(json.dumps(ctx, indent=2, default=str))
   "
   ```

   ### ping
   ```bash
   uv run python -c "
   from lib.kb.search import ping
   print('KB connection: OK' if ping() else 'KB connection: FAILED')
   "
   ```

3. **Format results** as readable markdown tables or structured output.

4. **If connection fails**: the local ChromaDB store is at `kb_data/` in the repo root (or `$KB_PERSIST_DIR` if set). If the directory is empty, seed it:
   ```bash
   uv run python -m lib.kb.ingest.pokedex_entry
   uv run python -m lib.kb.ingest.move_definition
   uv run python -m lib.kb.ingest.region_quirk
   ```

Use $ARGUMENTS for the action and parameters.
