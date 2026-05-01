Use when the user asks any question that needs a SQL answer against the warehouse — natural language or raw SQL, BigQuery or Snowflake (auto-detected). The default workhorse for data questions.

requires: [bigquery]

## Instructions

1. **Parse $ARGUMENTS** for an optional target/tenant and a SQL query or natural language question.

2. **Resolve the warehouse connection** (check in this order):
   a. **Region catalog**: If args contain a region name (e.g., "kanto"), read `catalog/<region>.yml` for the GCP project, default dataset, and dataset roles. Use the `role: prod` dataset unless the user specifies staging/signal/source.
   b. **dbt profiles.yml**: If present in the working directory or additionalDirectories, read for connection type and project
   c. **Ask the user**: If neither catalog nor profiles.yml resolves, ask which project/dataset to query

3. **Pull KB context** before generating SQL — run this for every query (natural language or SQL):
   ```bash
   uv run python -c "
   import json
   from lib.kb.search import search
   doc_types = ['table_summary', 'glossary_term', 'query_example',
                'routing_rule', 'join_recipe', 'column_semantic',
                'cross_skill_convention']
   results = search('<user question or table names from SQL>',
                    doc_types=doc_types, limit=12)
   for r in results:
       print(f'[{r[\"similarity\"]:.3f}] {r[\"doc_type\"]:24} | {(r[\"content\"] or \"\")[:200]}')
   "
   ```
   Use the returned context to ground your work:
   - **table_summary** → correct column names, types, and table relationships
   - **column_semantic** → fine-grained column meanings, units, valid value ranges
   - **glossary_term** → business definitions (e.g. "active trainer", "shiny encounter")
   - **query_example** → validated SQL patterns for similar questions
   - **join_recipe** → canonical join patterns (battle_log↔move_used, etc.) — never re-derive
   - **routing_rule** → dataset routing and region-specific logic
   - **cross_skill_convention** → SQL style, partitioning rules to follow

   The `UserPromptSubmit` hook also prepends the top-3 KB hits before this skill runs — use those as a head start, then this query for finer-grained doc_type filtering. If the KB is unreachable, fall back to the catalog YAML and continue.

4. **If natural language**, convert to SQL:
   - Use KB context (step 3) plus the region catalog to understand available tables and columns
   - Prefer patterns from `query_example` results when available
   - Generate appropriate SQL based on the question
   - Show the generated SQL before running

5. **Route to the correct dataset/schema** based on target:
   - Use the catalog's `resolution_order` to find which dataset contains the requested table
   - Use fully-qualified table names: `` `project.dataset.table` ``

6. **Run the query** using the appropriate CLI:
   - BigQuery: `bq query --use_legacy_sql=false --format=prettyjson`
   - Snowflake: `snowsql` or `snow sql`
   - Add a default `LIMIT 100` safety cap unless the user specifies otherwise

   **If CLI auth fails**: tell the user what credentials are needed and offer to generate the SQL without executing it.

7. **Format results** as a readable markdown table.

8. **Show the executed SQL** so the user can refine it.

Use $ARGUMENTS for optional target and SQL query or natural language question.
