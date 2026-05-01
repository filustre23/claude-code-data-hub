Use when the user (typically operating as `context-manager` or a curator) asks to ingest content into the local KB — pokedex entries, move definitions, region quirks, join recipes, post-mortems, runbooks, freshness SLAs, metric definitions, column semantics, conventions, or Q&A logs. Always dry-runs first; writes only after explicit confirmation.

requires: []

## Instructions

1. **Parse `$ARGUMENTS`** for `<doc_type>` and (optionally) a path to a YAML source file:
   ```
   /kb-ingest <doc_type> [<path-to-yaml>]
   ```
   Valid `doc_type` values (each maps to a module under `lib/kb/ingest/`):
   - `pokedex_entry` — Pokemon species summaries
   - `move_definition` — moves with type/power/effects
   - `region_quirk` — region-specific data anomalies
   - `join_recipe` — canonical SQL join patterns
   - `post_mortem` — past data incidents
   - `runbook` — operational SOPs
   - `freshness_sla` — per-table SLAs
   - `metric_definition` — business metrics with formula + canonical SQL
   - `column_semantic` — per-column meaning, units, gotchas
   - `cross_skill_convention` — SQL style, naming, partition strategy
   - `qa_log` — captured Q&A pairs

   If `<doc_type>` is missing, list the choices above.

2. **Verify KB connectivity** before doing anything:
   ```bash
   uv run python -c "from lib.kb import ping; print('KB up' if ping() else 'KB unreachable')"
   ```

3. **Dry-run** first — never write without showing the diff. Each ingest module exposes a `rows()` function and an `IngestRunner`:
   ```bash
   uv run python -c "
   from lib.kb.ingest.<doc_type> import rows
   from lib.kb.ingest.base import IngestRunner
   r = IngestRunner()
   print(r.dry_run(rows()).summary())
   "
   ```
   The output shows: `new=N updated=M unchanged=K`. The runner uses content-hash idempotency, so re-runs after edits only re-embed what changed.

4. **Show the diff to the user** in a structured block:
   ```
   ## KB Ingest Dry Run

   **Doc type**: <doc_type>
   **Source**: <yaml path or built-in seeds>
   **Diff**: new=N updated=M unchanged=K

   ### Sample (first 3 of each)
   - [NEW] <title>
   - [UPDATED] <title>
   ```

5. **Wait for explicit user approval** before applying. Do NOT proceed past dry-run unless the user says "apply" or "yes" or similar. The runner refuses to write without `confirmed=True` — preserve that gate.

6. **Apply** with the module's `__main__` (auto-applies if there are writes) or call `apply()` explicitly:
   ```bash
   uv run python -m lib.kb.ingest.<doc_type>
   ```
   Print the final summary: `Applied: new=N updated=M unchanged=K`.

7. **Re-embed reminder**: when changing the embedding model or chunking strategy, wipe `kb_data/` and re-ingest. Vectors from a different model are silently incompatible.

## Notes

- This skill is **curator-only**. The trigger phrase is intentionally narrow ("user asks to ingest content into the KB") so it doesn't autoload during routine data work.
- For ad-hoc KB queries (search, browse, list), use `/connection-kb` instead.
- The `context-manager` agent owns this flow end-to-end. Route to context-manager when the curation is part of a larger plan.
