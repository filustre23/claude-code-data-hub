Use when the user asks to inspect BigQuery datasets, list tables, view schemas, or perform admin operations via `bq`. For ad-hoc SELECT queries, prefer `/data-run-query`.

Query, explore, and manage BigQuery datasets using the `bq` CLI.

requires: [bigquery]

## Instructions

1. **Parse $ARGUMENTS** for the action and parameters. Supported actions:
   - **query** (default): Run a SQL query
   - **list**: List datasets or tables
   - **schema**: Inspect a table's schema

2. **Detect the GCP project** (check in this order):
   a. **Region catalog**: If args contain a region name (e.g., "kanto"), read `catalog/<region>.yml` for `gcp_project` and dataset names
   b. **dbt profiles.yml**: If present, read for the `project` field
   c. **Ask the user**: If neither catalog nor profiles.yml resolves, ask which GCP project to use

3. **Execute the action**:

   ### Query
   ```bash
   bq query --use_legacy_sql=false --format=prettyjson --max_rows=500 'SELECT ...'
   ```
   - Always use `--use_legacy_sql=false`
   - Add a default `LIMIT 100` unless the user specifies otherwise
   - Use fully-qualified table names: `` `project.dataset.table` ``

   ### List datasets
   ```bash
   bq ls --project_id=<project>
   ```

   ### List tables in a dataset
   ```bash
   bq ls --project_id=<project> <dataset>
   ```

   ### Schema
   ```bash
   bq show --schema --format=prettyjson <project>:<dataset>.<table>
   ```

4. **Format results** as readable markdown tables.

5. **If auth fails**: tell the user to run `gcloud auth application-default login`.

Use $ARGUMENTS for the action and parameters.
