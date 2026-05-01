Use when the user asks to profile, explore, or characterize a table — distributions, nulls, cardinality, value ranges, date coverage.

requires: [bigquery]

## Instructions

1. **Parse $ARGUMENTS** for the table/dataset name and optional target.

2. **Resolve the warehouse connection** (check in this order):
   a. **Region catalog**: If args contain a region name (e.g., "kanto"), read `catalog/<region>.yml` for the GCP project and dataset. Use the `resolution_order` to find which dataset contains the table.
   b. **dbt profiles.yml**: If present in the working directory or additionalDirectories, read for connection type
   c. **Ask the user**: If neither catalog nor profiles.yml resolves, ask which project/dataset to query

3. **Pull KB context** for the target table:
   ```bash
   uv run python -c "
   import json
   from lib.kb.search import search
   doc_types = ['table_summary', 'column_semantic', 'glossary_term']
   results = search('<table_name>', doc_types=doc_types, limit=12)
   for r in results:
       print(f'[{r[\"similarity\"]:.3f}] {r[\"doc_type\"]:18} | {(r[\"content\"] or \"\")[:200]}')
   "
   ```
   Use KB results to understand:
   - What the table represents (grain, business context) — from `table_summary`
   - Per-column meaning, units, valid value ranges — from `column_semantic`. These tell you what's an anomaly vs. expected.
   - Key columns and their business meaning — from `glossary_term`

   If `column_semantic` rows exist for this table, focus profiling on those columns and validate values against the documented ranges. If the KB is unreachable, continue with the catalog YAML.

4. **Profile the table** by running queries using the appropriate CLI:
   - BigQuery: `bq query --use_legacy_sql=false --format=prettyjson`
   - Snowflake: `snowsql` or `snow sql`
   - **If CLI auth fails**: tell the user what credentials are needed and offer to generate the profiling SQL without executing it

   Queries to run:
   - **Row count**: total rows
   - **Column inventory**: name, data type, nullable
   - **Null analysis**: null count and percentage per column
   - **Cardinality**: distinct value count per column
   - **Numeric columns**: min, max, mean, median, stddev
   - **String columns**: min/max length, most frequent values (top 10)
   - **Date columns**: min, max, distribution by month/year
   - **Potential duplicates**: check if any ID-like columns have duplicates

5. **Flag anomalies**:
   - Columns with >50% nulls
   - Columns with cardinality of 1 (constant)
   - Numeric outliers (values beyond 3 standard deviations)
   - Date gaps (missing expected dates)

6. **If the user provides two columns**, compute correlation or cross-tabulation.

7. **Output results** as formatted markdown tables with a summary section highlighting key findings and potential data quality issues.

Use $ARGUMENTS for table name and optional target.
