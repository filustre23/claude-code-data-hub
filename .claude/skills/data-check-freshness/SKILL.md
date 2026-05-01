Use when the user asks "is this data fresh?", "when did X last update?", or wants a freshness audit across sources and models.

requires: [bigquery]

## Instructions

1. **Parse $ARGUMENTS** for optional region name, dataset, or specific model to check.

2. **Resolve the warehouse connection** (check in this order):
   a. **Region catalog**: If args contain a region name (e.g., "kanto"), read `catalog/<region>.yml` for the GCP project and all datasets. Default to the `role: prod` dataset unless specified otherwise.
   b. **dbt project**: If `dbt_project.yml` is present, run `dbt source freshness --target <target>` if configured, or read source YAML for `loaded_at_field` and freshness configs
   c. **Ask the user**: If neither catalog nor dbt project resolves, ask which project/dataset to check

3. **Pull SLAs from the KB**:
   ```bash
   uv run python -c "
   from lib.kb.search import get_documents
   slas = get_documents(doc_type='freshness_sla', project='<region>', limit=200)
   for s in slas:
       m = s['metadata'] or {}
       print(f'{m.get(\"table\"):40} sla={m.get(\"sla_hours\"):>4}h owner={m.get(\"owner\")}')
   "
   ```
   Use these instead of any static yaml. If the KB returns no rows for the region, fall back to a 48-hour default (with a one-line warning that no SLAs are configured yet — the user can add some via a `lib/kb/ingest/freshness_sla.py` module).

4. **Check freshness** by querying table metadata (see step 5)

5. **Query table metadata** using the appropriate CLI:
   - BigQuery: `bq query --use_legacy_sql=false` against `__TABLES__` metadata for `last_modified_time`, or `INFORMATION_SCHEMA.TABLE_OPTIONS`
   - Snowflake: `INFORMATION_SCHEMA.TABLES` for `LAST_ALTERED`

   **If CLI auth fails**: tell the user what access is needed and show the metadata queries they can run manually.

6. **Flag stale data**: any source/table not updated within its `freshness_sla` window (default: 48 hours if the KB returned no rows for that table).

7. **Cross-reference with CI/CD** (if available):
   - Check latest pipeline run status to see if a failed run explains stale data

8. **Output a summary table**:
   - Source/model name
   - Last updated timestamp
   - Hours since update
   - Status: fresh / warning / stale
   - SLA window (and owner, from KB)

Use $ARGUMENTS for optional target or model filter.
