# Catalog directory rules

Structural metadata only — no descriptions, no row counts, no business logic. Those belong in the KB.

## When editing

- One `<region>.yml` per region. Copy an existing file as a template; do not invent new top-level keys.
- `resolution_order` is the lookup precedence: skills resolve a table by walking it top-to-bottom and returning the first dataset that contains the table. Put `prod` first unless there's a specific reason.
- `role` values are: `prod` | `staging` | `source` | `signal` | `analytics`. Stick to these.
- Don't add `description:` or `notes:` fields. Catalog is for connection routing, not documentation.

## When reading

- For ad-hoc queries: skills should `Read` only the requested region file (`catalog/<region>.yml`), never glob the whole directory.
- For descriptions, column semantics, join recipes, and freshness SLAs: query the KB (`lib/kb`) — those doc_types live there, not here.

## Adding a new region

1. Copy an existing yml.
2. Update `tenant`, `gcp_project`, `datasets`, `resolution_order`.
3. Add a corresponding `IngestRow(doc_type='table_summary', project=<region>, ...)` row per table (via `/kb-ingest`) so semantic lookups work.
